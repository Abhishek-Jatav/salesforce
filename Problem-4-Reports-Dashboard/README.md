# Problem 4 — Sales Pipeline Performance Dashboard
### Salesforce Developer Intern Assessment

---

## Overview

This solution delivers a production-ready **Sales Pipeline Performance Dashboard** in Salesforce, enabling a Sales Director to monitor pipeline health in real time. It includes a custom formula field, three source reports, a four-component dashboard, and role-based security configuration.

---

## Deliverables

| # | Deliverable | Status |
|---|---|---|
| 1 | Formula Field — `Days_Until_Close__c` | ✅ Complete |
| 2 | Tabular Report — Open Pipeline by Stage | ✅ Complete |
| 3 | Summary Report — Win Rate by Owner | ✅ Complete |
| 4 | At-Risk Opportunities Report | ✅ Complete |
| 5 | Dashboard — 4 Components | ✅ Complete |
| 6 | Sharing Rule — Sales Team Role | ✅ Complete |

---

## Folder Structure

```
Problem-4-Reports-Dashboard/
│
├── README.md
├── Formula_Field.md
├── Reports/
│   ├── Open_Pipeline_Report.md
│   ├── Win_Rate_Report.md
│   └── At_Risk_Report.md
│
├── Dashboard/
│   └── Dashboard_Configuration.md
│
├── Security/
│   └── Sharing_Rules.md
│
└── Screenshots/
    ├── Formula_Field.png        ← Formula field setup & preview
    ├── Report_1.png             ← Open Pipeline Report (run view)
    ├── Report_2.png             ← Win Rate by Owner (run view)
    ├── Report_3.png             ← At-Risk Opportunities (run view)
    ├── Dashboard.png            ← Full dashboard view
    └── Sharing_Rule.png        ← Sharing rule configuration
```

---

## Architecture Summary

- **Object:** Opportunity (standard)
- **Formula Field:** `Days_Until_Close__c` (Number) — calculates days remaining or overdue
- **Reports Folder:** `Sales Pipeline Reports` (shared with Sales Team Role)
- **Dashboard Folder:** `Sales Director Dashboard` (shared with Sales Team Role)
- **Running User Setting:** Run as Logged-In User
- **Security:** Role-based sharing — Sales Team Role and above

---

## Key Design Decisions

1. **NULL-safe formula** uses `IF(ISBLANK(CloseDate), 0, CloseDate - TODAY())` to prevent formula errors on records with no close date.
2. **Win Rate formula** uses `PARENTGROUPVAL` scoped to Owner grouping so percentages calculate per person, not globally.
3. **At-Risk filter** uses `Close Date < TODAY` + `IsClosed = False` to catch all open overdue deals regardless of stage name.
4. **Running User = Logged-In User** ensures Sales Reps see only their own data while Directors see the full pipeline.

---

## Technologies

- Salesforce Lightning Experience
- Reports & Dashboards (Lightning)
- Custom Formula Fields
- Role Hierarchy & Sharing Rules

---

## Author

Salesforce Developer Intern Assessment — Problem 4  
Submitted via GitHub Repository
