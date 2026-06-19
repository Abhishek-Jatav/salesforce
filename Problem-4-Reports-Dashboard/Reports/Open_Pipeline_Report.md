# Report 1 — Open Opportunity Pipeline Report

---

## Report Metadata

| Property | Value |
|---|---|
| **Report Name** | Open Opportunity Pipeline by Stage |
| **Report Type** | Opportunities (standard) |
| **Report Format** | Summary |
| **Folder** | Sales Pipeline Reports |
| **Description** | Shows total pipeline value, record count, and average deal size grouped by Stage for all open opportunities. |

> **Note on Format:** Although the requirement says "Tabular," a **Summary** format is used here because it enables the Stage grouping with subtotals (Total Amount, Count, Average). A pure Tabular report cannot group rows. This is the correct Salesforce implementation for the stated output requirements.

---

## Filters

| Filter | Operator | Value |
|---|---|---|
| Show | — | All Opportunities |
| Closed | equals | `False` |
| Opportunity Status | — | (Covered by Closed = False) |

**Standard Filter:** `Closed = False` — this is the built-in Salesforce filter that excludes both "Closed Won" and "Closed Lost" stages, returning only active pipeline opportunities.

---

## Groupings

| Level | Field | Sort | Order |
|---|---|---|---|
| Row Group 1 | **Stage** | By Sum of Amount | Descending |

---

## Columns (Summary Fields)

| Column | API Name | Aggregate |
|---|---|---|
| Opportunity Name | `Name` | — (detail row) |
| Account Name | `AccountId` | — (detail row) |
| Close Date | `CloseDate` | — (detail row) |
| Amount | `Amount` | **SUM** — Total Pipeline Value |
| Amount | `Amount` | **COUNT** — Record Count |
| Amount | `Amount` | **AVG** — Average Deal Size |
| Days Until Close | `Days_Until_Close__c` | — (detail row, optional) |

---

## Summary Fields Configuration

In the report builder, after adding `Amount`:
1. Click the column dropdown → **Summarize this Field**
2. Check: `Sum`, `Count`, `Average`
3. All three will display in the subtotal and grand total rows

---

## Sort Order

- **Group (Stage):** Sorted by `SUM(Amount)` — Descending (highest value stage first)
- **Detail rows within group:** Sorted by `CloseDate` — Ascending (soonest to close first)

---

## Expected Output Structure

```
Stage: Proposal/Price Quote
  Acme Corp Deal          $120,000    Close: 2025-08-15
  Global Tech Opportunity  $85,000    Close: 2025-09-01
  ─────────────────────────────────────────────────────
  Subtotal                $205,000    Count: 2    Avg: $102,500

Stage: Needs Analysis
  ...

─────────────────────────────────────────────────────
GRAND TOTAL               $XXX,XXX    Count: N    Avg: $XX,XXX
```

---

## Dashboard Source

This report powers **Dashboard Component 1 (Bar Chart — Pipeline Value by Stage)** and **Component 2 (KPI Tile — Total Pipeline Value)**.
