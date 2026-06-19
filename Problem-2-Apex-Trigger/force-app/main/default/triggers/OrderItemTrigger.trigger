/**
 * @description Thin trigger on OrderItem__c. Contains no business logic.
 *               Delegates all processing to OrderItemTriggerHandler.
 */
trigger OrderItemTrigger on OrderItem__c (after insert, after update) {

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OrderItemTriggerHandler.handleAfterInsertUpdate(Trigger.new);
        }
    }
}
