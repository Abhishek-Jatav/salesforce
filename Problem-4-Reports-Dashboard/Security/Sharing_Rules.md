# Security & Sharing Configuration

---

## 1. Role Structure

The following role hierarchy is assumed (standard Sales org structure):

```
CEO / Executive
└── Sales Director
    └── Sales Manager (East)
    │   └── Sales Rep (East) ← Sales Team Role
    └── Sales Manager (West)
        └── Sales Rep (West) ← Sales Team Role
```

**"Sales Team Role"** refers to any role at or below **Sales Manager** in the hierarchy — i.e., all sales-facing users who should have dashboard visibility.

If your org uses a different role name, substitute accordingly. The key requirement is: only users in the Sales Team role hierarchy can view the dashboard.

---

## 2. Folder Configuration

### Reports Folder

| Property | Value |
|---|---|
| **Folder Name** | Sales Pipeline Reports |
| **Folder Type** | Report Folder |
| **Access Level** | Viewer — Sales Team Role |

**Setup Path:**
1. Reports tab → New Folder → `Sales Pipeline Reports`
2. Share: Role → `Sales Team` → Access: `Viewer`
3. Save all three reports into this folder

### Dashboard Folder

| Property | Value |
|---|---|
| **Folder Name** | Sales Director Dashboard |
| **Folder Type** | Dashboard Folder |
| **Access Level** | Viewer — Sales Team Role |

**Setup Path:**
1. Dashboards tab → New Folder → `Sales Director Dashboard`
2. Share: Role → `Sales Team` → Access: `Viewer`
3. Save dashboard into this folder

---

## 3. Sharing Rule

### Sharing Rule Name
`Sales_Team_Dashboard_Access`

### Rule Configuration

| Property | Value |
|---|---|
| **Rule Type** | Based on Criteria |
| **Object** | (Folder-level sharing — no object sharing rule needed for dashboards) |
| **Folder** | Sales Director Dashboard |
| **Share With** | Role: Sales Team (and subordinates) |
| **Access Level** | Viewer |

> **Important:** Salesforce dashboard/report sharing is done at the **Folder** level, not via traditional Sharing Rules on objects. The "Sharing Rule" for this requirement is implemented by setting folder permissions.

**Dashboard Folder Sharing Setup:**
1. Dashboards → All Folders → `Sales Director Dashboard` → Share
2. Share with: **Roles and Subordinates** → Select: `Sales Team`
3. Access: **Viewer**
4. Save

---

## 4. Dashboard Running User Setting

| Property | Value |
|---|---|
| **Setting** | View Dashboard As |
| **Value** | **The dashboard viewer** (Logged-in User) |

**Why this matters:**
- With `Run as Logged-In User`, Salesforce applies the viewer's OWD, role hierarchy, and sharing rules when loading dashboard data.
- Sales Reps see only their assigned opportunities.
- Sales Managers see their team's data (via role hierarchy).
- Sales Director sees all data.
- This eliminates the need for a "running user" who might see restricted data.

**Setup Path:**
1. Dashboard → Edit → Click gear/settings icon (top right)
2. View Dashboard As → Select: `The dashboard viewer`
3. Save

---

## 5. Profile-Level Field Security

For `Days_Until_Close__c` formula field:

| Profile | Visibility | Edit |
|---|---|---|
| System Administrator | Visible | Read-Only (formula) |
| Sales Director | Visible | Read-Only |
| Sales Manager | Visible | Read-Only |
| Sales Rep | Visible | Read-Only |

**Setup Path:**
Setup → Object Manager → Opportunity → Fields & Relationships → `Days_Until_Close__c` → Set Field-Level Security → Check "Visible" for all Sales profiles

---

## 6. OWD (Organization-Wide Default) — Prerequisite Check

For this dashboard to function correctly with `Run as Logged-in User`:

| Object | Required OWD |
|---|---|
| Opportunity | Private OR Public Read Only |

If OWD for Opportunity is **Public Read/Write**, all users see all records regardless — the dashboard will still work but won't respect rep-level filtering. This is acceptable for most Sales orgs.

---

## 7. Complete Access Configuration Summary

| User | Report Access | Dashboard Access | Data Visible |
|---|---|---|---|
| Sales Rep | Viewer (Sales Team folder) | Viewer (Sales Director folder) | Own opportunities only |
| Sales Manager | Viewer | Viewer | Team opportunities |
| Sales Director | Viewer / Manager | Viewer / Manager | All opportunities |
| System Admin | Full | Full | All |
| Other Profiles | None | None | None |

---

## 8. Dashboard Access Steps (End-to-End)

1. Create role `Sales Team` under Sales Director in Role Hierarchy (if not exists)
2. Create report folder `Sales Pipeline Reports` — share with Role: Sales Team (Viewer)
3. Save all 3 reports into `Sales Pipeline Reports` folder
4. Create dashboard folder `Sales Director Dashboard` — share with Role and Subordinates: Sales Team (Viewer)
5. Save dashboard into `Sales Director Dashboard` folder
6. Edit dashboard → Settings → View Dashboard As → The dashboard viewer → Save
7. On formula field `Days_Until_Close__c`: set Field-Level Security → Visible for Sales profiles
8. Test: Log in as a Sales Rep → navigate to Dashboards → confirm `Sales Pipeline Performance` appears → confirm data shows only their records
