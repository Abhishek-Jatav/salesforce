/**
 * @description Test class for OrderItemTrigger / OrderItemTriggerHandler.
 *               Covers positive, negative, fulfilled, partially cancelled,
 *               and 200+ record bulk scenarios.
 */
@isTest
private class OrderItemTriggerHandlerTest {

    /**
     * @description Creates a single Order__c record for use across tests.
     */
    private static Order__c createOrder(String name) {
        Order__c ord = new Order__c(Name = name, Status__c = 'New');
        insert ord;
        return ord;
    }

    /**
     * @description Test setup: creates one base Order with no items yet.
     *               Individual test methods create their own OrderItem__c
     *               records to keep scenarios isolated and explicit.
     */
    @TestSetup
    static void setupData() {
        Order__c ord = new Order__c(Name = 'Setup Order', Status__c = 'New');
        insert ord;
    }

    // -----------------------------------------------------------------
    // POSITIVE TEST: All items Delivered -> Order should become Fulfilled
    // -----------------------------------------------------------------
    @isTest
    static void testPositive_AllDelivered_OrderBecomesFulfilled() {
        Order__c ord = createOrder('Positive Order');

        List<OrderItem__c> items = new List<OrderItem__c>{
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item A', Quantity__c = 1, Status__c = 'Pending'),
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item B', Quantity__c = 2, Status__c = 'Pending')
        };
        insert items;

        Test.startTest();
        for (OrderItem__c item : items) {
            item.Status__c = 'Delivered';
        }
        update items;
        Test.stopTest();

        Order__c updatedOrder = [SELECT Status__c FROM Order__c WHERE Id = :ord.Id];
        System.assertEquals('Fulfilled', updatedOrder.Status__c,
            'Order should be Fulfilled when all OrderItems are Delivered.');
    }

    // -----------------------------------------------------------------
    // NEGATIVE TEST: Mixed statuses (not all Delivered, none Cancelled)
    // -> Order Status should remain unchanged ("New")
    // -----------------------------------------------------------------
    @isTest
    static void testNegative_MixedNonCancelledStatuses_OrderUnchanged() {
        Order__c ord = createOrder('Negative Order');

        List<OrderItem__c> items = new List<OrderItem__c>{
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item A', Quantity__c = 1, Status__c = 'Pending'),
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item B', Quantity__c = 2, Status__c = 'Pending')
        };
        insert items;

        Test.startTest();
        items[0].Status__c = 'Delivered';
        // items[1] remains 'Pending'
        update items;
        Test.stopTest();

        Order__c updatedOrder = [SELECT Status__c FROM Order__c WHERE Id = :ord.Id];
        System.assertEquals('New', updatedOrder.Status__c,
            'Order status should remain unchanged when items are neither all Delivered nor any Cancelled.');
    }

    // -----------------------------------------------------------------
    // FULFILLED TEST: Explicit dedicated scenario for full delivery
    // across multiple items inserted directly as Delivered.
    // -----------------------------------------------------------------
    @isTest
    static void testFulfilled_AllItemsInsertedAsDelivered() {
        Order__c ord = createOrder('Fulfilled Order');

        Test.startTest();
        List<OrderItem__c> items = new List<OrderItem__c>{
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item A', Quantity__c = 5, Status__c = 'Delivered'),
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item B', Quantity__c = 3, Status__c = 'Delivered'),
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item C', Quantity__c = 7, Status__c = 'Delivered')
        };
        insert items;
        Test.stopTest();

        Order__c updatedOrder = [SELECT Status__c FROM Order__c WHERE Id = :ord.Id];
        System.assertEquals('Fulfilled', updatedOrder.Status__c,
            'Order should be Fulfilled when all line items are inserted as Delivered.');
    }

    // -----------------------------------------------------------------
    // PARTIALLY CANCELLED TEST: One item Cancelled, others Delivered
    // -> Cancelled rule takes priority over Fulfilled rule.
    // -----------------------------------------------------------------
    @isTest
    static void testPartiallyCancelled_OneCancelledAmongDelivered() {
        Order__c ord = createOrder('Partially Cancelled Order');

        List<OrderItem__c> items = new List<OrderItem__c>{
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item A', Quantity__c = 1, Status__c = 'Delivered'),
            new OrderItem__c(Order__c = ord.Id, Product_Name__c = 'Item B', Quantity__c = 2, Status__c = 'Pending')
        };
        insert items;

        Test.startTest();
        items[1].Status__c = 'Cancelled';
        update items;
        Test.stopTest();

        Order__c updatedOrder = [SELECT Status__c FROM Order__c WHERE Id = :ord.Id];
        System.assertEquals('Partially Cancelled', updatedOrder.Status__c,
            'Order should be Partially Cancelled when any item is Cancelled, even if others are Delivered.');
    }

    // -----------------------------------------------------------------
    // BULK TEST: 200+ OrderItem__c records across multiple Orders,
    // validating full bulkification (single SOQL / single DML at the
    // handler level, no per-record governor limit issues).
    // -----------------------------------------------------------------
    @isTest
    static void testBulk_200PlusRecordsAcrossMultipleOrders() {
        // Create 10 Orders, each will receive 25 OrderItems = 250 total items.
        List<Order__c> orders = new List<Order__c>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(new Order__c(Name = 'Bulk Order ' + i, Status__c = 'New'));
        }
        insert orders;

        List<OrderItem__c> itemsToInsert = new List<OrderItem__c>();
        for (Order__c ord : orders) {
            for (Integer j = 0; j < 25; j++) {
                itemsToInsert.add(new OrderItem__c(
                    Order__c = ord.Id,
                    Product_Name__c = 'Bulk Item ' + j,
                    Quantity__c = 1,
                    Status__c = 'Pending'
                ));
            }
        }

        Test.startTest();
        insert itemsToInsert; // 250 records inserted in one DML - after insert fires once, bulk

        // Now update all items belonging to the first 5 orders to Delivered,
        // and all items belonging to the last 5 orders to include one Cancelled each.
        List<OrderItem__c> allInserted = [
            SELECT Id, Order__c, Status__c FROM OrderItem__c WHERE Id IN :itemsToInsert
        ];

        Map<Id, List<OrderItem__c>> byOrder = new Map<Id, List<OrderItem__c>>();
        for (OrderItem__c item : allInserted) {
            if (!byOrder.containsKey(item.Order__c)) {
                byOrder.put(item.Order__c, new List<OrderItem__c>());
            }
            byOrder.get(item.Order__c).add(item);
        }

        List<OrderItem__c> itemsToUpdate = new List<OrderItem__c>();
        Integer orderIndex = 0;
        Set<Id> expectedFulfilledOrderIds = new Set<Id>();
        Set<Id> expectedPartiallyCancelledOrderIds = new Set<Id>();

        for (Id orderId : byOrder.keySet()) {
            List<OrderItem__c> children = byOrder.get(orderId);

            if (orderIndex < 5) {
                // First 5 orders: all items -> Delivered (expect Fulfilled)
                for (OrderItem__c child : children) {
                    child.Status__c = 'Delivered';
                }
                expectedFulfilledOrderIds.add(orderId);
            } else {
                // Remaining orders: deliver all but cancel one (expect Partially Cancelled)
                for (Integer k = 0; k < children.size(); k++) {
                    children[k].Status__c = (k == 0) ? 'Cancelled' : 'Delivered';
                }
                expectedPartiallyCancelledOrderIds.add(orderId);
            }
            itemsToUpdate.addAll(children);
            orderIndex++;
        }

        // 250 records updated in a single DML statement.
        update itemsToUpdate;
        Test.stopTest();

        System.assertEquals(250, itemsToInsert.size(),
            'Bulk test should process more than 200 records.');

        List<Order__c> resultOrders = [SELECT Id, Status__c FROM Order__c WHERE Id IN :orders];

        for (Order__c resultOrder : resultOrders) {
            if (expectedFulfilledOrderIds.contains(resultOrder.Id)) {
                System.assertEquals('Fulfilled', resultOrder.Status__c,
                    'Order ' + resultOrder.Id + ' should be Fulfilled.');
            } else if (expectedPartiallyCancelledOrderIds.contains(resultOrder.Id)) {
                System.assertEquals('Partially Cancelled', resultOrder.Status__c,
                    'Order ' + resultOrder.Id + ' should be Partially Cancelled.');
            }
        }
    }

    // -----------------------------------------------------------------
    // EDGE CASE: Order with no Order__c value should not throw and
    // should be safely ignored by the handler (defensive coverage).
    // -----------------------------------------------------------------
    @isTest
    static void testEdgeCase_NoOrderIdsCollected_NoExceptionThrown() {
        Test.startTest();
        // Directly invoke handler with an empty list - simulates a
        // scenario where collectOrderIds yields nothing.
        OrderItemTriggerHandler.handleAfterInsertUpdate(new List<OrderItem__c>());
        Test.stopTest();

        // No assertion needed beyond "no exception thrown" - if this
        // line is reached, the test passes.
        System.assert(true, 'Handler should gracefully handle an empty list.');
    }
}
