/**
 * @description Handler class for OrderItemTrigger.
 *               Evaluates OrderItem__c status across each related Order__c
 *               and updates the parent Order's Status__c accordingly.
 *
 *               Rules (evaluated in this priority order):
 *               1. If ANY OrderItem__c under an Order__c is "Cancelled"
 *                  -> Order__c.Status__c = "Partially Cancelled"
 *               2. Else if ALL OrderItem__c under an Order__c are "Delivered"
 *                  -> Order__c.Status__c = "Fulfilled"
 *               3. Else -> no change is made to the Order.
 *
 *               Fully bulkified: exactly one SOQL query and one DML
 *               statement regardless of the number of triggering records.
 */
public with sharing class OrderItemTriggerHandler {

    private static final String STATUS_DELIVERED = 'Delivered';
    private static final String STATUS_CANCELLED = 'Cancelled';
    private static final String ORDER_STATUS_FULFILLED = 'Fulfilled';
    private static final String ORDER_STATUS_PARTIALLY_CANCELLED = 'Partially Cancelled';

    // Recursion guard - defensive, since this handler only writes to the
    // parent Order__c object, not back onto OrderItem__c.
    private static Boolean isProcessing = false;

    /**
     * @description Entry point invoked from OrderItemTrigger for both
     *              after insert and after update contexts.
     * @param triggerNewItems Trigger.new list of OrderItem__c records.
     */
    public static void handleAfterInsertUpdate(List<OrderItem__c> triggerNewItems) {
        if (isProcessing) {
            return;
        }
        isProcessing = true;

        try {
            Set<Id> orderIds = collectOrderIds(triggerNewItems);

            if (orderIds.isEmpty()) {
                return;
            }

            Map<Id, List<OrderItem__c>> itemsByOrderId = queryAllItemsForOrders(orderIds);

            List<Order__c> ordersToUpdate = evaluateOrderStatuses(orderIds, itemsByOrderId);

            updateOrders(ordersToUpdate);

        } finally {
            isProcessing = false;
        }
    }

    /**
     * @description Collects the distinct set of parent Order__c Ids
     *              referenced by the triggering OrderItem__c records.
     *              No SOQL/DML here - pure in-memory collection.
     */
    private static Set<Id> collectOrderIds(List<OrderItem__c> items) {
        Set<Id> orderIds = new Set<Id>();
        for (OrderItem__c item : items) {
            if (item.Order__c != null) {
                orderIds.add(item.Order__c);
            }
        }
        return orderIds;
    }

    /**
     * @description Single SOQL query to retrieve ALL OrderItem__c records
     *              (not just the trigger batch) for every affected Order__c.
     *              This is required because the status of an Order depends
     *              on the collective status of ALL its line items, not just
     *              the ones in the current trigger batch.
     * @param orderIds Set of parent Order__c Ids to query children for.
     * @return Map of Order__c Id -> List of all its OrderItem__c children.
     */
    private static Map<Id, List<OrderItem__c>> queryAllItemsForOrders(Set<Id> orderIds) {
        Map<Id, List<OrderItem__c>> itemsByOrderId = new Map<Id, List<OrderItem__c>>();

        // Initialize empty lists so every order id has an entry even if
        // (theoretically) no children are returned.
        for (Id orderId : orderIds) {
            itemsByOrderId.put(orderId, new List<OrderItem__c>());
        }

        List<OrderItem__c> allItems = [
            SELECT Id, Order__c, Status__c
            FROM OrderItem__c
            WHERE Order__c IN :orderIds
        ];

        for (OrderItem__c item : allItems) {
            itemsByOrderId.get(item.Order__c).add(item);
        }

        return itemsByOrderId;
    }

    /**
     * @description Applies the business rules per Order in memory and
     *              builds the list of Order__c records that actually need
     *              a Status__c change (avoids unnecessary DML/updates).
     */
    private static List<Order__c> evaluateOrderStatuses(
        Set<Id> orderIds,
        Map<Id, List<OrderItem__c>> itemsByOrderId
    ) {
        List<Order__c> ordersToUpdate = new List<Order__c>();

        for (Id orderId : orderIds) {
            List<OrderItem__c> children = itemsByOrderId.get(orderId);

            if (children == null || children.isEmpty()) {
                continue;
            }

            String newStatus = determineOrderStatus(children);

            if (newStatus != null) {
                ordersToUpdate.add(new Order__c(
                    Id = orderId,
                    Status__c = newStatus
                ));
            }
        }

        return ordersToUpdate;
    }

    /**
     * @description Determines the target Order status from its full set of
     *              line items. Returns null if neither rule condition is met
     *              (i.e. the Order status should remain unchanged).
     */
    private static String determineOrderStatus(List<OrderItem__c> children) {
        Boolean hasCancelled = false;
        Boolean allDelivered = true;

        for (OrderItem__c child : children) {
            if (child.Status__c == STATUS_CANCELLED) {
                hasCancelled = true;
            }
            if (child.Status__c != STATUS_DELIVERED) {
                allDelivered = false;
            }
        }

        // Rule priority: Cancelled overrides Fulfilled.
        if (hasCancelled) {
            return ORDER_STATUS_PARTIALLY_CANCELLED;
        }

        if (allDelivered) {
            return ORDER_STATUS_FULFILLED;
        }

        return null;
    }

    /**
     * @description Single bulk DML operation to update all affected Orders.
     *              Uses Database.update with allOrNone=false so that one
     *              bad record does not block updates to valid Orders, while
     *              still surfacing failures for debugging.
     */
    private static void updateOrders(List<Order__c> ordersToUpdate) {
        if (ordersToUpdate.isEmpty()) {
            return;
        }

        List<Database.SaveResult> results = Database.update(ordersToUpdate, false);

        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'OrderItemTriggerHandler: Failed to update Order__c ' +
                        result.getId() + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
}
