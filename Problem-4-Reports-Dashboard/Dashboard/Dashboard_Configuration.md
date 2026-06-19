# Dashboard Configuration — Sales Pipeline Performance

---

## Dashboard Header

| Property | Value |
|---|---|
| **Dashboard Name** | Sales Pipeline Performance |
| **API Name** | Sales_Pipeline_Performance |
| **Folder** | Sales Director Dashboard |
| **Description** | Live pipeline health dashboard for Sales Director. Tracks stage value, win rates, top performers, and at-risk deals. |
| **Running User** | Run as Logged-In User |
| **Theme** | Lightning (default) |

---

## Running User Setting

**Setting:** `View Dashboard As` → **"The dashboard viewer"** (Logged-in User)

**Path:** Dashboard → Edit → (gear icon) → View Dashboard As → The dashboard viewer

This means:
- A Sales Rep sees only their own pipeline data
- A Sales Manager sees all data within their role hierarchy
- The Sales Director sees the full org pipeline

---

## Dashboard Layout

```
┌─────────────────────────────┬──────────────────┐
│  Component 1: Bar Chart     │  Component 2:    │
│  Pipeline Value by Stage    │  KPI Tile        │
│  (large, spans 2/3 width)   │  Total Pipeline  │
│                             │  Value           │
├─────────────────────────────┼──────────────────┤
│  Component 3: Leaderboard   │  Component 4:    │
│  Top Owners by Won Revenue  │  At-Risk Deals   │
│                             │  List            │
└─────────────────────────────┴──────────────────┘
```

---

## Component 1 — Bar Chart: Pipeline Value by Stage

| Property | Value |
|---|---|
| **Component Type** | Bar Chart |
| **Title** | Pipeline Value by Stage |
| **Source Report** | Open Opportunity Pipeline by Stage |
| **Chart Type** | Horizontal Bar (easier to read stage labels) |
| **X Axis (Value)** | `SUM(Amount)` |
| **Y Axis (Label)** | Stage |
| **Sort** | By Value — Descending |
| **Show Values** | On |
| **Color** | Blue gradient (default Salesforce palette) |
| **Drill-down** | Enabled — clicking a bar opens the filtered report |

**Setup Steps:**
1. Add Component → Bar Chart
2. Select source report: `Open Opportunity Pipeline by Stage`
3. Values (X Axis): `Sum of Amount`
4. Groupings (Y Axis): `Stage`
5. Title: `Pipeline Value by Stage`
6. Enable "Show Values on Chart"

---

## Component 2 — KPI Tile: Total Pipeline Value

| Property | Value |
|---|---|
| **Component Type** | Metric (KPI Tile) |
| **Title** | Total Pipeline Value |
| **Source Report** | Open Opportunity Pipeline by Stage |
| **Metric Field** | `SUM(Amount)` — Grand Total |
| **Display** | Large number with currency formatting |
| **Footer** | Open Opportunities Only |
| **Drill-down** | Enabled |

**Setup Steps:**
1. Add Component → Metric
2. Select source report: `Open Opportunity Pipeline by Stage`
3. Select metric: `Sum of Amount` (Grand Total row)
4. Title: `Total Pipeline Value`
5. Footer text: `Active Pipeline`

---

## Component 3 — Leaderboard: Top Owners by Won Revenue

| Property | Value |
|---|---|
| **Component Type** | Table (Leaderboard style) |
| **Title** | Top Owners by Won Revenue |
| **Source Report** | Win Rate by Owner |
| **Columns Shown** | Owner Name, SUM(Amount), Win Rate % |
| **Sort** | By SUM(Amount) — Descending |
| **Max Rows** | 10 |
| **Drill-down** | Enabled |

**Setup Steps:**
1. Add Component → Table
2. Select source report: `Win Rate by Owner`
3. Select columns: `Owner`, `Sum of Amount`, `Win Rate %` (custom formula)
4. Sort by: `Sum of Amount` → Descending
5. Max Rows: 10
6. Title: `Top Owners by Won Revenue`

> **Note:** If using the combined Won+Lost report, add an additional report `Won Opportunities by Owner` (filtered `IsWon = True`, grouped by Owner, SUM Amount) specifically for this leaderboard to display won revenue only. Both approaches are valid; the dedicated Won-only report is cleaner.

---

## Component 4 — At-Risk Deals List

| Property | Value |
|---|---|
| **Component Type** | Table |
| **Title** | At-Risk Deals (Overdue) |
| **Source Report** | At-Risk Opportunities (Overdue) |
| **Columns Shown** | Opportunity Name, Owner, Stage, Amount, Close Date, Days Until Close |
| **Sort** | By `Days_Until_Close__c` — Ascending (most overdue first) |
| **Max Rows** | 10 |
| **Conditional Highlighting** | Amount column: Red if Amount > $50,000 (high-value at-risk) |
| **Drill-down** | Enabled |

**Setup Steps:**
1. Add Component → Table
2. Select source report: `At-Risk Opportunities (Overdue)`
3. Select columns: `Name`, `Owner`, `StageName`, `Amount`, `CloseDate`, `Days_Until_Close__c`
4. Sort: `Days_Until_Close__c` Ascending
5. Max Rows: 10
6. Title: `At-Risk Deals (Overdue)`
7. Optional: Add conditional highlighting on Amount field

---

## Dashboard Refresh

| Setting | Value |
|---|---|
| **Auto-Refresh** | Every 24 hours (Lightning default) |
| **Manual Refresh** | Available via Refresh button |
| **Data As Of** | Displayed in dashboard header |

---

## Mobile Responsiveness

Lightning dashboards are mobile-responsive by default. The two-column layout will stack to single-column on mobile devices. No additional configuration required.
