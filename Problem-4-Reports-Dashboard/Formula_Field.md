# Formula Field — Days_Until_Close__c

---

## Field Configuration

| Property | Value |
|---|---|
| **Object** | Opportunity |
| **Field Label** | Days Until Close |
| **Field API Name** | `Days_Until_Close__c` |
| **Return Type** | Number (18, 0) |
| **Decimal Places** | 0 |
| **Description** | Returns the number of days until the opportunity close date. Positive = future, Negative = overdue, 0 = NULL close date. |

---

## Formula

```
IF(
  ISBLANK(CloseDate),
  0,
  CloseDate - TODAY()
)
```

---

## Logic Explanation

| Condition | Result | Example |
|---|---|---|
| `CloseDate` is NULL / blank | Returns `0` — avoids divide-by-zero or null reference errors | No close date set |
| `CloseDate > TODAY()` | Returns a **positive** integer — days remaining | Close in 15 days → `+15` |
| `CloseDate = TODAY()` | Returns `0` — due today | Due today → `0` |
| `CloseDate < TODAY()` | Returns a **negative** integer — days overdue | 7 days past due → `-7` |

### Why `CloseDate - TODAY()` Works
Salesforce Date arithmetic subtracts two Date fields and returns a Number representing the difference in calendar days. No conversion functions are needed. `TODAY()` always reflects the server date at report/record runtime.

### NULL Handling
`ISBLANK(CloseDate)` catches both NULL and empty date values. Returning `0` instead of NULL prevents downstream formula errors in reports and dashboard components that aggregate this field.

---

## Setup Path in Salesforce

1. **Setup → Object Manager → Opportunity → Fields & Relationships → New**
2. Select **Formula** → Next
3. Field Label: `Days Until Close`
4. Return Type: **Number** → Decimal Places: **0** → Next
5. Paste formula above → Check Syntax → Next
6. Set field-level security (visible to all Sales profiles) → Next → Save

---

## Validation

After saving, open any Opportunity record and verify:
- Future close date → positive number in the field
- Past close date → negative number in the field
- No close date → `0` (not blank, not error)
