# Report 2 — Win Rate by Owner Report

---

## Report Metadata

| Property | Value |
|---|---|
| **Report Name** | Win Rate by Owner |
| **Report Type** | Opportunities (standard) |
| **Report Format** | Summary |
| **Folder** | Sales Pipeline Reports |
| **Description** | Shows Won vs. Lost opportunities grouped by Owner with a custom Win Rate % summary formula. |

---

## Filters

| Filter | Operator | Value |
|---|---|---|
| Show | — | All Opportunities |
| Closed | equals | `True` |

> **Why `Closed = True`:** This captures both Closed Won and Closed Lost, giving us the full denominator for win rate calculation. Open opportunities are excluded because they have no definitive outcome yet.

---

## Groupings

| Level | Field | Sort | Order |
|---|---|---|---|
| Row Group 1 | **Owner** (`OwnerId`) | By Win Rate Formula | Descending |

---

## Columns

| Column | API Name | Aggregate |
|---|---|---|
| Opportunity Name | `Name` | — |
| Stage | `StageName` | — |
| Amount | `Amount` | **SUM** |
| Amount | `Amount` | **COUNT** |
| Is Won | `IsWon` | **SUM** *(counts Won opportunities)* |
| Close Date | `CloseDate` | — |

---

## Custom Summary Formula

### Formula Name
`Win_Rate_Pct`

### Formula Label
`Win Rate %`

### Formula Location
Add as a **Custom Summary Formula** in the report builder (Columns panel → Add Summary Formula)

### Formula Syntax

```
PARENTGROUPVAL(SUM(Opportunity.IsWon), Owner) 
/ 
PARENTGROUPVAL(COUNT(Opportunity.Id), Owner) 
* 100
```

### Alternative Syntax (if IsWon SUM is unavailable)

Salesforce sometimes restricts boolean SUM directly. Use this alternative that counts Won records via stage:

```
(PARENTGROUPVAL(
  CASE(MAX(Opportunity.StageName), "Closed Won", 1, 0),
  Owner
))
```

**Recommended reliable formula:**

```
RowCount
/ 
PARENTGROUPVAL(RowCount, Owner, COLUMN_GRAND_SUMMARY) 
* 100
```

> **Correct approach for Win Rate in a single-grouped report:**

Since the report is grouped only by Owner (not by Stage + Owner), and filtered to Closed = True, we need to count Won records per owner. Use a formula column on `IsWon` boolean field summed:

**Final Formula (use this):**

```
IF(
  PARENTGROUPVAL(COUNT(Opportunity.Id), Owner) > 0,
  (SUM(Opportunity.IsWon) / PARENTGROUPVAL(COUNT(Opportunity.Id), Owner)) * 100,
  0
)
```

---

## Formula Settings

| Property | Value |
|---|---|
| **Formula Name** | `Win_Rate_Pct` |
| **Display Label** | `Win Rate %` |
| **Formula Output Type** | Percent |
| **Decimal Places** | 1 |
| **Where will this formula be displayed?** | All summary levels |

---

## Formatting

| Element | Setting |
|---|---|
| Win Rate % column | Format as Percent, 1 decimal place |
| SUM(Amount) | Format as Currency |
| Sort | By Win Rate % descending |

---

## Expected Output Structure

```
Owner: Sarah Johnson
  Acme Corp              Closed Won    $150,000
  Beta Inc               Closed Lost    $45,000
  Gamma LLC              Closed Won    $200,000
  ─────────────────────────────────────────────
  Subtotal: Won: 2 / Total: 3    Win Rate: 66.7%    Revenue: $350,000

Owner: Mark Williams
  ...

─────────────────────────────────────────────────────
GRAND TOTAL                Win Rate: XX.X%    Total Revenue: $X,XXX,XXX
```

---

## Dashboard Source

This report powers **Dashboard Component 3 (Leaderboard — Top Owners by Won Revenue)**.

To show Won Revenue only in the leaderboard, add a second report filtered to `IsWon = True` grouped by Owner with `SUM(Amount)` — or use this same report and configure the dashboard component to display the Amount SUM column.
