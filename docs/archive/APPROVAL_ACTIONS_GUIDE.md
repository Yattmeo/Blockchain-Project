# Approval Actions - User Guide

**Updated:** November 11, 2025  
**Status:** Approval buttons now fully functional! ✅

---

## 🎯 Overview

The Approvals page now shows **action buttons** (Approve, Reject, Execute) in the **Actions column** of the approval table. These buttons only appear when:

1. Your organization is required to approve the request
2. Your organization hasn't already approved/rejected it
3. The request is in the correct status

---

## 🔑 How It Works

### Organization Mapping

When you log in, your organization ID is mapped to the MSP format used by the blockchain:

| Login Organization | MSP ID | Can Approve |
|-------------------|--------|-------------|
| `insurer1` | `Insurer1MSP` | Requests requiring Insurer1MSP |
| `insurer2` | `Insurer2MSP` | Requests requiring Insurer2MSP |
| `coop` | `CoopMSP` | Requests requiring CoopMSP |
| `platform` | `PlatformMSP` | Admin requests |

### Permission Logic

The approval buttons follow these rules:

#### 👍 **Approve Button** (Green)
Shows when:
- ✅ Request status is `PENDING`
- ✅ Your organization is in the `requiredOrgs` list
- ✅ Your organization hasn't already approved (`approvals[YourMSP]` is not `true`)

#### 👎 **Reject Button** (Red)
Shows when:
- ✅ Request status is `PENDING`
- ✅ Your organization is in the `requiredOrgs` list
- ✅ Your organization hasn't already rejected (no entry in `rejections[YourMSP]`)

#### ▶️ **Execute Button** (Blue)
Shows when:
- ✅ Request status is `APPROVED` (all required orgs have approved)
- ✅ Your role is `admin` or `insurer`

---

## 📊 Test Scenarios with Mock Data

### Scenario 1: Login as Coop

**Login:**
- Organization: `Farmers Cooperative`
- Name: `Test User`

**What You'll See:**

| Request ID | Status | Your Org Status | Action Available |
|-----------|--------|-----------------|------------------|
| REQ_FARM_001 | PENDING | ✅ Already Approved | ❌ No buttons (already approved) |
| REQ_FARM_002 | PENDING | ⏳ Not approved | ✅ 👍 Approve + 👎 Reject |
| REQ_POL_001 | PENDING | ⏳ Not approved | ✅ 👍 Approve + 👎 Reject |
| REQ_POOL_001 | REJECTED | ❌ Already Rejected | ❌ No buttons (rejected status) |
| REQ_CLAIM_002 | PENDING | ⏳ Not approved | ✅ 👍 Approve + 👎 Reject |

**Expected Counts:**
- **Awaiting Your Action:** 3 requests

---

### Scenario 2: Login as Insurer1

**Login:**
- Organization: `Insurance Company 1`
- Name: `Test User`

**What You'll See:**

| Request ID | Status | Your Org Status | Action Available |
|-----------|--------|-----------------|------------------|
| REQ_FARM_001 | PENDING | ⏳ Not approved | ✅ 👍 Approve + 👎 Reject |
| REQ_FARM_002 | PENDING | ⏳ Not approved | ✅ 👍 Approve + 👎 Reject |
| REQ_POL_001 | PENDING | ✅ Already Approved | ❌ No buttons (already approved) |
| REQ_POL_002 | APPROVED | ✅ All approved | ✅ ▶️ Execute (role: insurer) |
| REQ_CLAIM_001 | APPROVED | ✅ All approved | ✅ ▶️ Execute (role: insurer) |
| REQ_CLAIM_002 | PENDING | ✅ Already Approved | ❌ No buttons (already approved) |

**Expected Counts:**
- **Awaiting Your Action:** 2 approval requests + 2 execution requests

---

### Scenario 3: Login as Insurer2

**Login:**
- Organization: `Insurance Company 2`
- Name: `Test User`

**What You'll See:**

| Request ID | Status | Your Org Status | Action Available |
|-----------|--------|-----------------|------------------|
| REQ_CLAIM_001 | APPROVED | ✅ Already Approved | ✅ ▶️ Execute (role: insurer) |
| REQ_CLAIM_002 | PENDING | ✅ Already Approved | ❌ No buttons (already approved) |
| REQ_POOL_001 | REJECTED | ❌ Already Rejected | ❌ No buttons (rejected status) |

**Expected Counts:**
- **Awaiting Your Action:** 0 approval requests + 1 execution request

---

## 🎨 Visual Indicators

### Alert Banner (Top of Page)

The alert banner at the top of the page shows:

**When you have actions to take (Warning - Orange):**
```
⏸️ Your Organization: CoopMSP • Role: coop • 
Awaiting Your Action: 3 requests - Look for 👍 Approve and 👎 Reject buttons in the Actions column
```

**When you have no actions (Info - Blue):**
```
ℹ️ Your Organization: Insurer2MSP • Role: insurer • 
Awaiting Your Action: 0 requests
```

### Action Buttons in Table

Each row in the Actions column can show:

1. **ℹ️ Info** (always visible) - View full request details
2. **👍 Approve** (green) - Approve the request
3. **👎 Reject** (red) - Reject with reason
4. **▶️ Execute** (blue) - Execute approved request
5. **📜 History** (always visible) - View audit trail

---

## 🔄 Testing Approval Flow

### Step 1: Find a Request You Can Approve

1. Navigate to **Approvals** page
2. Check the alert banner: "Awaiting Your Action: X requests"
3. Look for rows with green 👍 and red 👎 buttons

### Step 2: Approve a Request

1. Click the **👍 Approve** button
2. Success message appears: "Request REQ_XXX approved successfully"
3. Table auto-refreshes
4. Button disappears (your org now shows as approved)
5. If all required orgs approved, status changes to APPROVED

### Step 3: Reject a Request

1. Click the **👎 Reject** button
2. Dialog opens asking for rejection reason
3. Enter reason: "Test rejection - documentation incomplete"
4. Click **Reject**
5. Success message appears
6. Status changes to REJECTED
7. Rejection reason displays in request details

### Step 4: Execute Approved Request

1. Filter by Status: **Approved**
2. Look for requests with **▶️ Execute** button
3. Click **Execute**
4. Confirm in the dialog
5. Request is executed (chaincode function called)
6. Status changes to EXECUTED

---

## 🐛 Troubleshooting

### "I don't see any approve buttons"

**Possible Reasons:**

1. **Not your organization's turn:**
   - Check the request's Required Organizations
   - Your org must be in that list
   
2. **Already approved:**
   - Check the Approvals section in request details
   - If your org shows with ✅, you already approved

3. **Wrong status:**
   - Approve buttons only show for PENDING requests
   - Check the Status column

4. **Wrong login:**
   - Verify you logged in with the correct organization
   - Check the alert banner for "Your Organization"

### "Execute button doesn't appear"

**Requirements for Execute:**

1. Request status must be **APPROVED** (not PENDING)
2. Your role must be `admin` or `insurer`
3. All required approvals must be complete

**Check:**
- Filter by Status: "Approved"
- Look at the Approvals section - all should be ✅
- Verify your role in the alert banner

### "Clicked approve but nothing happened"

**Check:**

1. Look for success/error message at top of page
2. Open browser console (F12) for errors
3. Verify API Gateway is running (if not in dev mode)
4. Check that actionLoading hasn't stuck buttons disabled

---

## 📝 Mock Data Reference

### Requests Awaiting CoopMSP Approval:
- ✅ **REQ_FARM_002** - Bob Smith (0/2 approvals)
- ✅ **REQ_POL_001** - Charlie Brown (1/2 approvals, needs CoopMSP)
- ✅ **REQ_CLAIM_002** - Henry Rodriguez (2/3 approvals, needs CoopMSP)

### Requests Awaiting Insurer1MSP Approval:
- ✅ **REQ_FARM_001** - Alice Johnson (1/2 approvals, needs Insurer1MSP)
- ✅ **REQ_FARM_002** - Bob Smith (0/2 approvals)

### Requests Ready to Execute (APPROVED):
- ✅ **REQ_POL_002** - David Lee (2/2 approvals complete)
- ✅ **REQ_CLAIM_001** - Emma Wilson (2/2 approvals complete)

### Rejected Requests (No actions available):
- ❌ **REQ_FARM_003** - Frank Miller (rejected by Insurer1MSP)
- ❌ **REQ_POOL_001** - Pool Withdrawal (rejected by 2 orgs)

### Executed Requests (Completed):
- ✅ **REQ_FARM_004** - Grace Taylor (executed 9 days ago)

---

## 💡 Pro Tips

1. **Use Status Filter**: Filter by "Pending" to see only requests awaiting approval

2. **Use Type Filter**: Filter by request type to focus on specific operations

3. **Check History**: Click 📜 History to see who approved and when

4. **View Details**: Click ℹ️ Info to see full request details and metadata

5. **Watch the Alert**: The banner shows your actionable count in real-time

6. **Auto-Refresh**: After approve/reject/execute, the list automatically refreshes

7. **Multiple Browsers**: Open different browsers for different orgs to test multi-party flow

---

## 🎉 Success Criteria

You've successfully tested approval actions when:

✅ Alert banner shows correct organization and actionable count  
✅ Approve buttons appear for requests needing your approval  
✅ Reject buttons work and require reason  
✅ Execute buttons appear for approved requests (insurer/admin only)  
✅ Success messages display after each action  
✅ Table refreshes and buttons disappear after approval  
✅ Request details show your approval in the list  
✅ Status changes correctly (PENDING → APPROVED → EXECUTED)  
✅ History dialog shows audit trail of all actions  
✅ No console errors during approval operations  

---

*Generated: November 11, 2025*  
*Approval Buttons: Fully Functional* ✅  
*Ready for Multi-Party Testing!* 🚀
