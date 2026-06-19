# Problem 4 — Complete Solution Document

---

# 1. Solution Architecture

## Data Flow

```
Salesforce Opportunity Records
         │
         ▼
  Days_Until_Close__c                 ← Formula Field (computed at runtime)
  (CloseDate - TODAY())
         │
         ├──────────────────────────────────────────────────┐
         ▼                                                  ▼
  Open Opportunity                              At-Risk Opportunities
  Pipeline by Stage Report                      Report
  (Closed=False, grouped by Stage)              (Closed=False, CloseDate < TODAY)
         │                                                  │
         ├─────────────────────────────┐                    │
         ▼                             ▼                    ▼
  Bar Chart Component            KPI Tile              At-Risk List
  (Component 1)                  (Component 2)         (Component 4)

  Win Rate by Owner Report
  (Closed=True, grouped by Owner)
         │
         ▼
  Leaderboard Component
  (Component 3)

                    ↓ All 4 Components ↓
         ┌─────────────────────────────────────┐
         │  Sales Pipeline Performance         │
         │  Dashboard                          │
         │  (Run as Logged-In User)            │
         └─────────────────────────────────────┘
                         │
                         ▼
         Sales Director Dashboard Folder
         (Shared with Sales Team Role — Viewer)
```

## Reporting Architecture

| Report | Format | Source | Powers |
|---|---|---|---|
| Open Opportunity Pipeline by Stage | Summary | Opportunities | Bar Chart + KPI Tile |
| Win Rate by Owner | Summary | Opportunities | Leaderboard |
| At-Risk Opportunities (Overdue) | Tabular | Opportunities | At-Risk List |

## Security Architecture

```
Role Hierarchy → Folder Sharing → Dashboard Running User = Viewer
     │
     └── Sales Team Role
         └── Viewer access to both folders
             └── Dashboard shows data scoped to viewer's access
```

---

# 2. Formula Field

**Field Label:** Days Until Close  
**Field API Name:** `Days_Until_Close__c`  
**Return Type:** Number (18, 0)  

**Formula:**
```
IF(
  ISBLANK(CloseDate),
  0,
  CloseDate - TODAY()
)
```

**Logic:** If CloseDate is NULL → return 0. Otherwise return `CloseDate - TODAY()`. Salesforce Date subtraction returns a Number (days). Positive = future date. Negative = past date. Zero = today or NULL.

---

# 3. Report 1 — Open Opportunity Pipeline Report

**Report Type:** Opportunities  
**Format:** Summary  
**Folder:** Sales Pipeline Reports  

**Filters:**
- Closed = False

**Groupings:**
- Row Group: Stage (sorted by SUM Amount descending)

**Summary Fields on Amount:**
- SUM — Total Pipeline Value
- COUNT — Record Count  
- AVERAGE — Average Deal Size

**Sort Order:** Stage group by SUM(Amount) descending; detail rows by CloseDate ascending.

---

# 4. Report 2 — Win Rate by Owner Report

**Report Type:** Opportunities  
**Format:** Summary  
**Folder:** Sales Pipeline Reports  

**Filters:**
- Closed = True

**Groupings:**
- Row Group: Owner (sorted by Win Rate % descending)

**Columns:** Name, Stage, Amount (SUM, COUNT), IsWon (SUM), Close Date

**Custom Summary Formula:**

```
Name: Win_Rate_Pct
Label: Win Rate %
Output: Percent, 1 decimal

Formula:
IF(
  PARENTGROUPVAL(COUNT(Opportunity.Id), Owner) > 0,
  (SUM(Opportunity.IsWon) / PARENTGROUPVAL(COUNT(Opportunity.Id), Owner)) * 100,
  0
)
```

**Display:** All summary levels. Format as Percent.

---

# 5. Report 3 — At-Risk Opportunities Report

**Report Type:** Opportunities  
**Format:** Tabular  
**Folder:** Sales Pipeline Reports  

**Filters:**
- Closed = False  
- Close Date < TODAY (relative date)

**Columns:**
- Opportunity Name
- Account Name
- Owner
- Stage
- Amount (SUM in grand total)
- Close Date
- Days_Until_Close__c (shows negative = overdue days)
- Next Step

**Sort Order:** Days_Until_Close__c Ascending (most overdue first)

---

# 6. Dashboard Design

**Dashboard Name:** Sales Pipeline Performance  
**Folder:** Sales Director Dashboard  
**Running User:** The dashboard viewer (Logged-In User)  

### Component 1 — Bar Chart
- **Type:** Bar Chart  
- **Source Report:** Open Opportunity Pipeline by Stage  
- **X Axis:** SUM(Amount)  
- **Y Axis:** Stage  
- **Sort:** By Value, Descending  
- **Title:** Pipeline Value by Stage  

### Component 2 — KPI Tile
- **Type:** Metric  
- **Source Report:** Open Opportunity Pipeline by Stage  
- **Metric:** Grand Total SUM(Amount)  
- **Title:** Total Pipeline Value  
- **Footer:** Active Pipeline  

### Component 3 — Leaderboard
- **Type:** Table  
- **Source Report:** Win Rate by Owner  
- **Columns:** Owner, SUM(Amount), Win Rate %  
- **Sort:** SUM(Amount) Descending  
- **Max Rows:** 10  
- **Title:** Top Owners by Won Revenue  

### Component 4 — At-Risk Deals List
- **Type:** Table  
- **Source Report:** At-Risk Opportunities (Overdue)  
- **Columns:** Name, Owner, Stage, Amount, Close Date, Days_Until_Close__c  
- **Sort:** Days_Until_Close__c Ascending  
- **Max Rows:** 10  
- **Title:** At-Risk Deals (Overdue)  

---

# 7. Sharing & Security Configuration

**Role Structure:** Sales Team Role (subordinate to Sales Director)

**Sharing Rule (Folder-level):**
- Report Folder `Sales Pipeline Reports` → Share with Roles and Subordinates: Sales Team → Viewer
- Dashboard Folder `Sales Director Dashboard` → Share with Roles and Subordinates: Sales Team → Viewer

**Visibility Rules:**
- Running User = Logged-in User → data scoped to viewer's record access
- Reps see own records; Managers see team; Director sees all

**Dashboard Access Steps:**
1. Create Sales Team role in hierarchy
2. Create & share both folders with Sales Team Role (Viewer)
3. Set dashboard Running User to "The dashboard viewer"
4. Set FLS on Days_Until_Close__c — Visible for all Sales profiles
5. Save all reports and dashboard in their respective folders

---

# 8. Sample Test Data

## 20 Test Opportunities

| # | Name | Owner | Stage | Amount | Close Date | Is Closed | Is Won | Days Until Close |
|---|---|---|---|---|---|---|---|---|
| 1 | Acme Corp Expansion | Sarah Johnson | Prospecting | $25,000 | 2025-09-30 | No | — | +102 |
| 2 | Beta Tech Platform | Sarah Johnson | Needs Analysis | $78,000 | 2025-08-15 | No | — | +57 |
| 3 | Gamma Retail Suite | Sarah Johnson | Proposal/Price Quote | $145,000 | 2025-07-30 | No | — | +41 |
| 4 | Delta Corp CRM | Sarah Johnson | Negotiation/Review | $210,000 | 2025-07-10 | No | — | +21 |
| 5 | Echo Media Deal | Sarah Johnson | Closed Won | $320,000 | 2025-05-01 | Yes | Yes | — |
| 6 | Foxtrot Insurance | Mark Williams | Prospecting | $15,000 | 2025-10-15 | No | — | +117 |
| 7 | Golf Industries | Mark Williams | Needs Analysis | $52,000 | 2025-09-01 | No | — | +73 |
| 8 | Hotel Chain Mgmt | Mark Williams | Proposal/Price Quote | $185,000 | 2025-08-20 | No | — | +62 |
| 9 | India Exports Inc | Mark Williams | Closed Won | $95,000 | 2025-04-15 | Yes | Yes | — |
| 10 | Juliet Fashion | Mark Williams | Closed Lost | $68,000 | 2025-05-20 | Yes | No | — |
| 11 | Kilo Logistics | Jane Doe | Value Proposition | $110,000 | 2025-08-05 | No | — | +47 |
| 12 | Lima Pharma | Jane Doe | Perception Analysis | $250,000 | 2025-09-15 | No | — | +87 |
| 13 | Mike Tech Startup | Jane Doe | Closed Won | $44,000 | 2025-03-30 | Yes | Yes | — |
| 14 | November Corp | Jane Doe | Closed Lost | $130,000 | 2025-04-10 | Yes | No | — |
| 15 | Oscar Retail | Jane Doe | Closed Won | $175,000 | 2025-02-28 | Yes | Yes | — |
| 16 | Papa Foods | Tom Baker | Negotiation/Review | $88,000 | **2025-05-15** | **No** | — | **-46 ⚠** |
| 17 | Quebec Software | Tom Baker | Proposal/Price Quote | $195,000 | **2025-05-01** | **No** | — | **-60 ⚠** |
| 18 | Romeo Auto Parts | Tom Baker | Needs Analysis | $35,000 | **2025-06-01** | **No** | — | **-29 ⚠** |
| 19 | Sierra Mining | Tom Baker | Closed Won | $500,000 | 2025-01-15 | Yes | Yes | — |
| 20 | Tango Textiles | Tom Baker | Closed Lost | $72,000 | 2025-03-20 | Yes | No | — |

> ⚠ Records 16, 17, 18 are **at-risk** (open + overdue). Days shown relative to assessment date of 2025-06-30.

## Data Summary for Validation

| Owner | Total Closed | Won | Lost | Win Rate | Total Won Revenue |
|---|---|---|---|---|---|
| Sarah Johnson | 1 | 1 | 0 | 100% | $320,000 |
| Mark Williams | 2 | 1 | 1 | 50% | $95,000 |
| Jane Doe | 3 | 2 | 1 | 66.7% | $219,000 |
| Tom Baker | 2 | 1 | 1 | 50% | $500,000 |

| Stage (Open) | Count | Total Amount |
|---|---|---|
| Prospecting | 2 | $40,000 |
| Needs Analysis | 3 | $165,000 |
| Value Proposition | 1 | $110,000 |
| Proposal/Price Quote | 3 | $525,000 |
| Negotiation/Review | 2 | $298,000 |
| Perception Analysis | 1 | $250,000 |

**At-Risk Deals:** 3 (Papa Foods, Quebec Software, Romeo Auto Parts)  
**Total At-Risk Value:** $318,000

---

# 9. Testing Checklist

## Positive Tests

| # | Test | Expected Result | Pass/Fail |
|---|---|---|---|
| P1 | Open opportunity with future close date — check Days_Until_Close__c | Positive integer matching days remaining | |
| P2 | Run Report 1 (Open Pipeline) | Only open opps show; Amount SUM/COUNT/AVG display per stage | |
| P3 | Run Report 2 (Win Rate) | Closed opps only; Win Rate % calculated per owner | |
| P4 | Run Report 3 (At-Risk) | Only shows Closed=False AND CloseDate < TODAY | |
| P5 | View Dashboard as Sales Director | All 4 components load with correct data | |
| P6 | Bar chart shows all pipeline stages with correct bar lengths | Highest $ stage has longest bar | |
| P7 | KPI Tile shows grand total of all open opportunity amounts | Matches SUM from Report 1 grand total | |
| P8 | Leaderboard ranks owners by Won Revenue descending | Tom Baker ($500K) appears first | |
| P9 | At-Risk list sorts by most overdue first | Quebec Software (-60 days) appears at top | |
| P10 | Log in as Sales Rep — dashboard shows only their records | Rep's own opps visible; others hidden | |

## Negative Tests

| # | Test | Expected Result | Pass/Fail |
|---|---|---|---|
| N1 | Open opp with NULL close date — check Days_Until_Close__c | Returns `0`, no error | |
| N2 | Closed Won opp appears in Report 1 (Open Pipeline) | Should NOT appear | |
| N3 | Open opp appears in Report 2 (Win Rate) | Should NOT appear | |
| N4 | Opp with future close date appears in At-Risk report | Should NOT appear | |
| N5 | User outside Sales Team Role tries to access dashboard folder | Access denied / folder not visible | |
| N6 | Win Rate formula result for owner with 0 closed deals | Returns 0%, no divide-by-zero error | |

## Edge Cases

| # | Test | Expected Result | Pass/Fail |
|---|---|---|---|
| E1 | Opportunity with CloseDate = TODAY() | Days_Until_Close__c = 0; does NOT appear in At-Risk (not < TODAY) | |
| E2 | Opportunity with Amount = $0 | Appears in reports; doesn't break averages | |
| E3 | Owner with all Lost deals | Win Rate = 0%; appears in leaderboard with $0 won revenue | |
| E4 | Owner with all Won deals | Win Rate = 100% | |
| E5 | At-Risk opp gets manually closed mid-day | Immediately drops off At-Risk report on next refresh | |
| E6 | Dashboard viewed on mobile device | Components stack vertically; data unchanged | |

---

# 10. Screenshots Checklist

| # | Screenshot | What to Capture | When |
|---|---|---|---|
| 1 | `Formula_Field.png` | Field definition screen (label, API name, formula, return type) AND a sample record showing the computed value | After creating formula field |
| 2 | `Report_1.png` | Open Pipeline report in run mode showing Stage groupings, SUM/COUNT/AVG columns, and grand total | After saving Report 1 |
| 3 | `Report_2.png` | Win Rate report in run mode showing Owner groupings and Win Rate % column with values | After saving Report 2 |
| 4 | `Report_3.png` | At-Risk report in run mode showing overdue records with negative Days Until Close values | After saving Report 3 |
| 5 | `Dashboard.png` | Full dashboard view in Lightning showing all 4 components with live data | After saving dashboard |
| 6 | `Sharing_Rule.png` | Dashboard folder sharing settings showing Sales Team Role with Viewer access | After configuring folder sharing |

**Optional Additional Screenshots:**
- Dashboard Settings screen showing "View Dashboard As: The dashboard viewer"
- Formula field syntax check (green checkmark)
- Each report's filter configuration screen
- Role hierarchy showing Sales Team Role position
