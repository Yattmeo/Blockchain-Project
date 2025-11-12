# Approval Dashboard UI Guide

## Page Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  🎯 Approval Management                                      [🔄 Refresh]    │
│  Review and manage multi-party approval requests                             │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐                  │
│  │  ⏳ Pending │  ✅ Approved│  ❌ Rejected│  ▶️ Executed│                  │
│  │      5      │      12     │      2      │      8      │                  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘                  │
│                                                                               │
│  [✓ Success: Request approved successfully]                                  │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │  Status: [All Statuses ▼]    Type: [All Types ▼]                      │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │ Request ID    │ Type           │ Status    │ Progress        │ Actions │  │
│  ├───────────────┼────────────────┼───────────┼─────────────────┼─────────┤  │
│  │ REQ001...     │ 🏷️ Farmer Reg │ ⏳ PENDING│ 1/2 orgs (50%) ■│ ℹ️👍👎📜│  │
│  │               │                │           │ ████████░░░░░░░░│         │  │
│  ├───────────────┼────────────────┼───────────┼─────────────────┼─────────┤  │
│  │ REQ002...     │ 🏷️ Policy     │ ✅ APPROVED│ 2/2 orgs (100%)■│ ℹ️▶️📜 │  │
│  │               │                │           │ ████████████████│         │  │
│  ├───────────────┼────────────────┼───────────┼─────────────────┼─────────┤  │
│  │ REQ003...     │ 🏷️ Pool Wthdwl│ ❌ REJECTED│ 0/2 orgs (0%)  ░│ ℹ️📜   │  │
│  │               │                │           │ ░░░░░░░░░░░░░░░░│         │  │
│  └───────────────┴────────────────┴───────────┴─────────────────┴─────────┘  │
│                                                                               │
│  [< Previous]  Page 1 of 3  [Next >]  [10 rows ▼]                            │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Action Buttons

### Pending Requests
- **ℹ️ Info** - View full request details
- **👍 Approve** - Approve the request (if your org hasn't approved yet)
- **👎 Reject** - Reject the request with reason
- **📜 History** - View approval history/audit trail

### Approved Requests
- **ℹ️ Info** - View full request details
- **▶️ Execute** - Execute the approved request (admin/insurer only)
- **📜 History** - View approval history

### Rejected/Executed Requests
- **ℹ️ Info** - View full request details
- **📜 History** - View approval history

---

## Dialog Examples

### 1. Reject Dialog
```
┌──────────────────────────────────────┐
│  Reject Approval Request         [×] │
├──────────────────────────────────────┤
│  Please provide a reason for         │
│  rejecting this request:             │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Insufficient documentation     │ │
│  │ provided for farmer KYC        │ │
│  │                                │ │
│  │                                │ │
│  └────────────────────────────────┘ │
│                                      │
│           [Cancel] [Reject Request]  │
└──────────────────────────────────────┘
```

### 2. Details Dialog
```
┌─────────────────────────────────────────────────┐
│  Approval Request Details                   [×] │
├─────────────────────────────────────────────────┤
│  Request ID                                     │
│  TEST_REQ_1762799703                            │
│                                                 │
│  Type                                           │
│  🏷️ Farmer Registration                         │
│                                                 │
│  Status                                         │
│  ⏳ PENDING                                      │
│                                                 │
│  Target Chaincode                               │
│  farmer                                         │
│                                                 │
│  Function                                       │
│  RegisterFarmer                                 │
│                                                 │
│  Arguments                                      │
│  ┌───────────────────────────────────────────┐ │
│  │ [                                         │ │
│  │   "FARMER123",                            │ │
│  │   "John Doe",                             │ │
│  │   "COOP001",                              │ │
│  │   ...                                     │ │
│  │ ]                                         │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  Required Organizations                         │
│  ✅ Coop  ⏳ Insurer1                           │
│                                                 │
│  Metadata                                       │
│  • Farmer Name: John Doe                        │
│  • Farm Size: 5.0 ha                            │
│                                                 │
│  Created: Nov 11, 2025 10:30 AM                 │
│  Updated: Nov 11, 2025 12:45 PM                 │
│                                                 │
│                                       [Close]   │
└─────────────────────────────────────────────────┘
```

### 3. History Dialog
```
┌─────────────────────────────────────────┐
│  Approval History                   [×] │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐ │
│  │ CREATE              Nov 11, 10:30 │ │
│  │ Actor: CoopMSP                    │ │
│  │ TX: tx123456...                   │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ APPROVE             Nov 11, 12:00 │ │
│  │ Actor: CoopMSP                    │ │
│  │ Reason: Farmer docs verified      │ │
│  │ TX: tx123457...                   │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ APPROVE             Nov 11, 12:45 │ │
│  │ Actor: Insurer1MSP                │ │
│  │ Reason: Approved via UI           │ │
│  │ TX: tx123458...                   │ │
│  └───────────────────────────────────┘ │
│                                         │
│                              [Close]    │
└─────────────────────────────────────────┘
```

---

## Responsive Behavior

### Desktop (> 900px)
- 4 statistics cards in a row
- Full table with all columns
- Dialogs centered at medium width

### Tablet (600-900px)
- 2 statistics cards per row
- Table scrolls horizontally if needed
- Filters stack but maintain width

### Mobile (< 600px)
- 1 statistics card per row
- Table shows essential columns only
- Actions collapse to icon buttons
- Dialogs full-screen on small devices

---

## Color Coding

### Status Colors
- **PENDING** - Yellow/Warning (⏳)
- **APPROVED** - Green/Success (✅)
- **REJECTED** - Red/Error (❌)
- **EXECUTED** - Blue/Info (▶️)

### Progress Bar
- **< 100%** - Blue (primary)
- **100%** - Green (success)

### Action Buttons
- **Approve** - Green
- **Reject** - Red
- **Execute** - Blue
- **Info/History** - Default gray

---

## User Flows

### Scenario 1: Approving a Farmer Registration
1. User (from Coop) logs in
2. Navigates to "Approvals" from sidebar
3. Sees pending farmer registration (REQ001)
4. Progress shows "1/2 orgs (50%)" - Insurer1 already approved
5. Clicks 👍 Approve button
6. Success message appears: "Request REQ001 approved successfully"
7. Progress updates to "2/2 orgs (100%)"
8. Status changes from PENDING → APPROVED
9. Admin/Insurer can now click ▶️ Execute to register the farmer

### Scenario 2: Rejecting a Policy Creation
1. User (Insurer) reviews policy creation request
2. Clicks ℹ️ Info to see full details
3. Reviews arguments and metadata
4. Closes details, clicks 👎 Reject
5. Dialog opens requesting reason
6. Enters: "Coverage amount exceeds policy limits"
7. Clicks "Reject Request"
8. Request status changes to REJECTED
9. Other users can see rejection reason in details

### Scenario 3: Executing an Approved Request
1. Admin user sees approved farmer registration
2. Progress shows "2/2 orgs (100%)"
3. Status is APPROVED (green)
4. Clicks ▶️ Execute button
5. Confirmation dialog appears
6. Confirms execution
7. Cross-chaincode call to farmer.RegisterFarmer()
8. Status changes to EXECUTED (blue)
9. Farmer now registered on blockchain

---

## Key Features Demonstrated

✅ **Real-time Status** - Progress bars update as orgs approve
✅ **Multi-Org Visualization** - Clear display of who approved/pending
✅ **Role-Based Actions** - Only show actions user can perform
✅ **Audit Trail** - Complete history of all actions
✅ **Rich Details** - Full request information available
✅ **Graceful Errors** - Friendly error messages
✅ **Loading States** - Shows loading during API calls
✅ **Responsive Design** - Works on all screen sizes
✅ **Search & Filter** - Find approvals easily
✅ **Pagination** - Handle large datasets
✅ **Sorting** - Sort by any column

This dashboard provides a complete approval management experience for the multi-party blockchain workflow!
