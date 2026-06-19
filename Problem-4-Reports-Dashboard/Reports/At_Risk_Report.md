# Report 3 — At-Risk Opportunities Report

---

## Report Metadata

| Property | Value |
|---|---|
| **Report Name** | At-Risk Opportunities (Overdue) |
| **Report Type** | Opportunities (standard) |
| **Report Format** | Tabular |
| **Folder** | Sales Pipeline Reports |
| **Description** | Lists all open opportunities whose close date has already passed. These are deals requiring immediate Sales Director attention. |

---

## Filters

| Filter | Field | Operator | Value |
|---|---|---|---|
| Filter 1 | `Closed` | equals | `False` |
| Filter 2 | `Close Date` | less than | `TODAY` |

> **Filter Logic:** `1 AND 2`
>
> - `Closed = False` → excludes Closed Won and Closed Lost (uses IsClosed system field)
> - `Close Date < TODAY` → only past-due records
>
> Together these two filters return **open opportunities that are overdue** — the exact definition of "at-risk."

**How to set "Close Date < TODAY" in Salesforce Report Builder:**
- Field: `Close Date`
- Operator: `less than`
- Value: Click the date picker → select **"Today"** from the relative date dropdown (not a hardcoded date)

Using the relative `TODAY` value ensures the filter updates automatically every day without manual maintenance.

---

## Columns

| Column | API Name | Notes |
|---|---|---|
| Opportunity Name | `Name` | Clickable link to record |
| Account Name | `Account.Name` | Parent account |
| Owner | `Owner.Name` | Assigned sales rep |
| Stage | `StageName` | Current pipeline stage |
| Amount | `Amount` | Deal value |
| Close Date | `CloseDate` | The overdue date |
| Days Until Close | `Days_Until_Close__c` | Will show negative values — days overdue |
| Next Step | `NextStep` | What action is planned |

---

## Sort Order

| Field | Direction | Reason |
|---|---|---|
| `Days_Until_Close__c` | **Ascending** | Most overdue deals (largest negative number) appear first — highest urgency at top |

---

## Summary Fields (Grand Total Row)

| Field | Aggregate | Label |
|---|---|---|
| Amount | SUM | Total At-Risk Pipeline Value |
| Record Count | COUNT | Number of At-Risk Deals |

---

## Expected Output Structure

```
Opportunity Name         Account          Owner          Stage              Amount     Close Date   Days Overdue
─────────────────────────────────────────────────────────────────────────────────────────────────────────────
Delta Project (OVERDUE)  Delta Corp       John Smith     Proposal           $95,000    2025-05-10   -40
Echo Initiative          Echo Retail      Jane Doe       Negotiation        $210,000   2025-05-22   -28
Foxtrot Deal             Foxtrot Mfg      Mark Lee       Needs Analysis     $45,000    2025-06-01   -18
─────────────────────────────────────────────────────────────────────────────────────────────────────────────
TOTAL                                                                       $350,000                Count: 3
```

---

## Dashboard Source

This report powers **Dashboard Component 4 (At-Risk Deals List)**.

The dashboard component will display this as a report table / list view showing the most overdue deals at the top, giving the Sales Director immediate visibility into stalled pipeline.
