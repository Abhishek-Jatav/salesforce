# Problem 3 — Live Account Search Lightning Component

A production-ready Salesforce Lightning Web Component (LWC) that lets sales managers search Account records by name in real time, view results in a styled data table, and navigate to any Account record — without leaving the page.

---

## Table of Contents

1. [Solution Architecture](#solution-architecture)
2. [Prerequisites](#prerequisites)
3. [Folder Structure](#folder-structure)
4. [Deployment Instructions](#deployment-instructions)
5. [App Builder Configuration](#app-builder-configuration)
6. [Testing Checklist](#testing-checklist)
7. [Security Notes](#security-notes)

---

## Solution Architecture

### LWC Architecture

```
accountSearch (LWC)
│
├── accountSearch.html     — Declarative template; all conditional rendering
│                            via if:true / if:false directives
├── accountSearch.js       — Controller: debounce, imperative Apex call,
│                            state management, NavigationMixin
├── accountSearch.css      — SLDS-aligned component styles
└── accountSearch.js-meta.xml — Metadata: targets, targetConfigs, properties
```

### Apex Architecture

```
AccountSearchController.cls
└── searchAccounts(String searchTerm)
    ├── @AuraEnabled(cacheable=true)
    ├── SOQL LIKE query with String.escapeSingleQuotes()
    ├── WITH SECURITY_ENFORCED
    └── Returns: Id, Name, Industry, Phone, AnnualRevenue
```

### Data Flow

```
User types in search input
        │
        ▼
handleSearchChange() fires on every keystroke
        │
        ▼
Previous debounce timer is cleared
New timer is set (300 ms)
        │  (timer elapses without another keystroke)
        ▼
isLoading = true  →  spinner appears
        │
        ▼
Apex: AccountSearchController.searchAccounts(term)
        │
   ┌────┴────┐
success      error
   │              │
accounts[]   hasError = true
populated    errorMessage set
   │
   ▼
_enrichAccounts() adds formattedRevenue, phoneHref
        │
        ▼
Reactive state update → LWC re-renders table
```

### Search Flow & States

| State       | Condition                                     | UI                          |
|-------------|-----------------------------------------------|-----------------------------|
| **Idle**    | No search performed yet                       | Icon + invite message       |
| **Loading** | Apex call in flight                           | Brand spinner               |
| **Results** | `accounts.length > 0`                         | Striped, bordered SLDS table|
| **Empty**   | Search returned 0 records                     | Icon + "No accounts found"  |
| **Error**   | Apex threw / network failure                  | Error icon + message        |

---

## Prerequisites

| Tool | Version |
|------|---------|
| Salesforce CLI (`sf` / `sfdx`) | ≥ 2.x |
| Node.js | ≥ 18 LTS |
| Salesforce org | Developer Edition, Sandbox, or Scratch Org |
| API version | 59.0 (Spring '24) or later |

---

## Folder Structure

```
Problem-3-LWC/
│
├── sfdx-project.json
│
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/
│           │   ├── AccountSearchController.cls
│           │   ├── AccountSearchController.cls-meta.xml
│           │   ├── AccountSearchControllerTest.cls
│           │   └── AccountSearchControllerTest.cls-meta.xml
│           │
│           └── lwc/
│               └── accountSearch/
│                   ├── accountSearch.html
│                   ├── accountSearch.js
│                   ├── accountSearch.css
│                   └── accountSearch.js-meta.xml
│
└── README.md
```

---

## Deployment Instructions

### 1 — Authenticate to your org

```bash
# Production / Developer Edition
sf org login web --alias myOrg --instance-url https://login.salesforce.com

# Sandbox
sf org login web --alias myOrg --instance-url https://test.salesforce.com
```

### 2 — Clone / extract the project

```bash
cd Problem-3-LWC
```

### 3 — Deploy in order

**Step 1 — Apex controller first** (LWC depends on it)

```bash
sf project deploy start \
  --source-dir force-app/main/default/classes/AccountSearchController.cls \
  --target-org myOrg
```

**Step 2 — Apex test class**

```bash
sf project deploy start \
  --source-dir force-app/main/default/classes/AccountSearchControllerTest.cls \
  --target-org myOrg
```

**Step 3 — LWC component**

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountSearch \
  --target-org myOrg
```

**Or deploy everything at once:**

```bash
sf project deploy start --source-dir force-app --target-org myOrg
```

### 4 — Run Apex tests

```bash
sf apex run test \
  --class-names AccountSearchControllerTest \
  --target-org myOrg \
  --result-format human \
  --wait 10
```

Expected: **9/9 tests pass**, ≥ 90% code coverage on `AccountSearchController`.

---

## App Builder Configuration

### Add to Account List View (primary use case)

1. Navigate to **Setup → Object Manager → Account → List View Button Layout** (or use the Lightning App Builder directly).
2. Go to any **Account List View** page and click the **Setup** gear → **Edit Page**.
3. In Lightning App Builder, drag the **Account Search** component from the Custom section onto the page canvas.
4. *(Optional)* Set the **Card Title** property in the right-hand panel.
5. Click **Save → Activate**.
6. Set the page as the **Org Default** (or assign to specific profiles/apps as needed).

### Add to Home Page

1. **Setup → Home → Lightning App Builder → Home Page**.
2. Drag **Account Search** to the desired region.
3. Save and activate.

### Add to App Page

1. **Setup → Lightning App Builder → New → App Page**.
2. Choose a layout, then drag **Account Search** onto the canvas.
3. Save, activate, and add to navigation.

---

## Testing Checklist

### Search Tests

- [ ] Type `Acme` — rows for all matching accounts appear within 300 ms of stopping typing
- [ ] Type one character, then quickly type more — Apex is called **only once** (debounce verified in browser Network tab)
- [ ] Type, then clear the field — table disappears, idle state returns immediately without an Apex call
- [ ] Search term is case-insensitive (`DELTA` and `delta` both return `Delta Dynamics`)

### No-Result Tests

- [ ] Enter a string that matches no account (e.g. `ZZZNOMATCH`) — "No accounts found" empty state is displayed
- [ ] Empty-state icon and subtitle text are visible
- [ ] No spinner remains visible after the search completes

### Navigation Tests

- [ ] Click any row — Account record page opens in the **same tab** using standard Salesforce navigation
- [ ] Press **Enter** on a keyboard-focused row — same navigation occurs
- [ ] Click a phone number — `tel:` link fires; row-click navigation does **not** also trigger
- [ ] Browser back button returns to the list page with the component intact

### Security Tests

- [ ] Log in as a user with **Read** access on Account but no **Modify All** — component loads and returns results (SECURITY_ENFORCED respects FLS)
- [ ] Log in as a user with no Account access — component shows error state gracefully, no SOQL error is exposed to the UI
- [ ] Enter `' OR Name LIKE '%` as a search term — returns 0 results (injection is neutralised)

### UI Tests

- [ ] Loading spinner appears immediately after typing stops (< 50 ms before the 300 ms debounce elapses)
- [ ] Spinner disappears as soon as results render
- [ ] Annual Revenue column displays correctly formatted currency (e.g. `$5,000,000`)
- [ ] Accounts with no Industry show `—` in the Industry column
- [ ] Accounts with no Phone show `—` in the Phone column
- [ ] On a viewport narrower than 480 px, the Annual Revenue column is hidden
- [ ] Table is horizontally scrollable on small screens
- [ ] Striped rows, hover highlight, and column headers are correctly styled

---

## Security Notes

| Practice | Implementation |
|---|---|
| `WITH SECURITY_ENFORCED` | All SOQL queries respect field-level and object-level security |
| `with sharing` | Apex class enforces sharing rules of the running user |
| `String.escapeSingleQuotes()` | Prevents SOQL injection from user-supplied input |
| `@AuraEnabled(cacheable=true)` | Read-only; no DML in this controller |
| LWC `@track` / no eval | No dynamic code execution in the component |

---

## Author

**Abhishek** — Salesforce Developer Intern Assessment, Problem 3
