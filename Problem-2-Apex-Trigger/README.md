# Problem 2 — Auto-Update Order Status with Apex Trigger

## Overview

This solution implements an automated Order status engine on Salesforce using
custom objects, a Master-Detail relationship, and a fully bulkified Apex
trigger built on the Thin Trigger + Handler pattern.

When `OrderItem__c` records are inserted or updated, the parent `Order__c`
record's `Status__c` is automatically recalculated based on the collective
status of **all** its line items:

| Condition                                   | Resulting Order Status |
|----------------------------------------------|-------------------------|
| Any `OrderItem__c` is `Cancelled`             | `Partially Cancelled`   |
| All `OrderItem__c` records are `Delivered`    | `Fulfilled`             |
| Neither condition is met                     | No change               |

> **Rule precedence:** Cancelled is evaluated before Fulfilled, since
> cancellation is treated as the stronger/exception signal.

## Data Model

```
Order__c (Master)
 └── OrderItem__c (Detail, Master-Detail to Order__c)
```

### Order__c

| Field        | API Name     | Type     | Picklist Values                          |
|--------------|--------------|----------|-------------------------------------------|
| Order Name   | `Name`       | Auto Number | —                                       |
| Status       | `Status__c`  | Picklist | `New`, `Fulfilled`, `Partially Cancelled` |

### OrderItem__c

| Field         | API Name           | Type             | Picklist Values                  |
|---------------|---------------------|------------------|-----------------------------------|
| Order         | `Order__c`          | Master-Detail    | —                                  |
| Product Name  | `Product_Name__c`   | Text(255)        | —                                  |
| Quantity      | `Quantity__c`        | Number(18,0)     | —                                  |
| Status        | `Status__c`          | Picklist         | `Pending`, `Delivered`, `Cancelled`|

## Architecture

This solution strictly follows the **Thin Trigger Pattern**:

- `OrderItemTrigger.trigger` contains **zero business logic** — it only
  delegates to the handler class for `after insert` and `after update`
  contexts.
- `OrderItemTriggerHandler.cls` contains all logic, fully bulkified:
  - **1 SOQL query** per transaction (queries *all* sibling `OrderItem__c`
    records for every affected `Order__c`, not just the trigger batch).
  - **1 DML statement** per transaction (`Database.update` on the list of
    Orders whose status actually changed).
  - No SOQL or DML inside any loop.
  - Supports 200+ records per transaction (validated by a dedicated bulk
    test with 250 records across 10 Orders).

```
OrderItemTrigger (after insert/update)
        │
        ▼
OrderItemTriggerHandler.handleAfterInsertUpdate()
        │
        ├─ collectOrderIds()        → Set<Id> (no SOQL)
        ├─ queryAllItemsForOrders() → 1 SOQL query
        ├─ evaluateOrderStatuses()  → in-memory rule evaluation
        └─ updateOrders()           → 1 DML statement
```

## File Structure

```
force-app/main/default/
├── objects/
│   ├── Order__c/
│   │   ├── Order__c.object-meta.xml
│   │   └── fields/
│   │       └── Status__c.field-meta.xml
│   └── OrderItem__c/
│       ├── OrderItem__c.object-meta.xml
│       └── fields/
│           ├── Order__c.field-meta.xml
│           ├── Product_Name__c.field-meta.xml
│           ├── Quantity__c.field-meta.xml
│           └── Status__c.field-meta.xml
├── classes/
│   ├── OrderItemTriggerHandler.cls
│   ├── OrderItemTriggerHandler.cls-meta.xml
│   ├── OrderItemTriggerHandlerTest.cls
│   └── OrderItemTriggerHandlerTest.cls-meta.xml
└── triggers/
    ├── OrderItemTrigger.trigger
    └── OrderItemTrigger.trigger-meta.xml
```

## Deployment

### Prerequisites
- Salesforce CLI (`sf`) installed and authenticated to a target org/sandbox/scratch org.

### Deploy

```bash
sf project deploy start --source-dir force-app
```

### Deploy with tests

```bash
sf project deploy start --source-dir force-app \
  --test-level RunSpecifiedTests \
  --tests OrderItemTriggerHandlerTest
```

> **Note:** Custom objects/fields must exist before the Apex trigger and
> handler are deployed, since the code references `Order__c`, `OrderItem__c`,
> and their custom fields directly.

### Deployment order (if deploying piecewise)

```
1. objects/Order__c/Order__c.object-meta.xml
2. objects/Order__c/fields/Status__c.field-meta.xml
3. objects/OrderItem__c/OrderItem__c.object-meta.xml
4. objects/OrderItem__c/fields/Order__c.field-meta.xml      (Master-Detail)
5. objects/OrderItem__c/fields/Product_Name__c.field-meta.xml
6. objects/OrderItem__c/fields/Quantity__c.field-meta.xml
7. objects/OrderItem__c/fields/Status__c.field-meta.xml
8. classes/OrderItemTriggerHandler.cls (+ .cls-meta.xml)
9. triggers/OrderItemTrigger.trigger (+ .trigger-meta.xml)
10. classes/OrderItemTriggerHandlerTest.cls (+ .cls-meta.xml)
```

## Running Tests

```bash
sf apex run test \
  --class-names OrderItemTriggerHandlerTest \
  --result-format human \
  --code-coverage \
  --synchronous
```

Expected: **6/6 tests pass**, `OrderItemTriggerHandler` coverage **≈100%**
(exceeds the 85% minimum requirement).

## Test Coverage Summary

| Test Method | Scenario |
|---|---|
| `testPositive_AllDelivered_OrderBecomesFulfilled` | All items updated to Delivered → Order = Fulfilled |
| `testNegative_MixedNonCancelledStatuses_OrderUnchanged` | Mixed Pending/Delivered, no Cancelled → Order unchanged |
| `testFulfilled_AllItemsInsertedAsDelivered` | Items inserted directly as Delivered → Order = Fulfilled |
| `testPartiallyCancelled_OneCancelledAmongDelivered` | One Cancelled item among Delivered → Order = Partially Cancelled |
| `testBulk_200PlusRecordsAcrossMultipleOrders` | 250 OrderItem__c records across 10 Orders in single DML operations |
| `testEdgeCase_NoOrderIdsCollected_NoExceptionThrown` | Defensive handling of empty trigger payload |

## Design Decisions

- **Master-Detail over Lookup:** `OrderItem__c` records have no independent
  lifecycle outside their Order, so Master-Detail enforces correct
  parent-child semantics and cascade delete.
- **Query all siblings, not just trigger batch:** Order status depends on
  *every* line item under it, so the handler always re-evaluates the full
  child set per affected Order rather than relying solely on `Trigger.new`.
- **`Database.update(list, false)`:** Avoids an all-or-nothing failure mode
  where one problematic Order blocks status updates for unrelated, valid
  Orders in the same transaction.
- **Recursion guard:** A static `isProcessing` flag is included defensively,
  even though current logic does not directly recurse on `OrderItem__c`.

## Author

Senior Apex implementation submitted for Salesforce Developer Intern
Assessment — Problem 2.
