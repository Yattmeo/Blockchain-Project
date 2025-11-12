# Comprehensive Testing Guide - Enhanced with Mock Data

**Date:** November 11, 2025  
**Status:** Ready for End-to-End Testing  
**Mock Data:** ✅ Comprehensive test scenarios implemented

---

## 📋 Table of Contents

1. [Mock Data Overview](#mock-data-overview)
2. [Starting the Development Server](#starting-the-development-server)
3. [Test Scenarios](#test-scenarios)
4. [Mock Data Reference](#mock-data-reference)
5. [Troubleshooting](#troubleshooting)

---

## 🎯 Mock Data Overview

We've created comprehensive mock data to test all functionality without requiring blockchain connectivity. The mock data includes:

### Approval Requests (9 scenarios)
- **PENDING (3)**: Different approval stages for testing approval flow
- **APPROVED (2)**: Ready to execute for testing execution flow
- **REJECTED (2)**: Testing rejection display and reasons
- **EXECUTED (1)**: Completed workflow for history view
- **Multi-org Pending (1)**: 3-party approval (2/3 approved)

### Supporting Data
- **Farmers (3)**: Active farmers with complete profiles
- **Policy Templates (4)**: Rice, Wheat, Corn, Vegetables with varying terms
- **Policies (2)**: Active policies for claim testing
- **Claims (2)**: Paid and Processing states
- **Weather Data (2)**: Validated weather observations

---

## 🚀 Starting the Development Server

### Prerequisites
```bash
# Ensure Node.js and npm are installed
node --version  # Should be v18+ or v20+
npm --version   # Should be 9.0+
```

### Start Development Server
```bash
cd /Users/yattmeo/Desktop/SMU/Code/Blockchain\ proj/Blockchain-Project/insurance-ui
npm run dev
```

Expected output:
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h to show help
```

### Access the Application
Open browser to: **http://localhost:5173/**

---

## 🧪 Test Scenarios

### Scenario 1: Farmer Registration Approval Flow

**Objective:** Test complete multi-party approval workflow for farmer registration

**Test Steps:**

1. **Login as Coop User**
   - Username: `coop@example.com`
   - Password: `password123`
   - Role: Coop Member

2. **View Pending Approvals**
   - Navigate to "Farmers" page
   - Scroll to "Pending Approvals" section
   - Should see `REQ_FARM_001` - Alice Johnson
     - Status: PENDING
     - 1 of 2 approvals (CoopMSP approved)
     - Needs Insurer1MSP approval

3. **Test Approval Action**
   - For `REQ_FARM_002` - Bob Smith
   - Status: PENDING (0 of 2 approvals)
   - Click "👍 Approve" button
   - Verify success message displays
   - Check that approval count updates

4. **Create New Farmer**
   - Click "+ Register Farmer" button
   - Fill form with test data:
     ```
     Farmer ID: FARMER_TEST_001
     First Name: Test
     Last Name: User
     Phone: 555-9999
     Email: test@farm.com
     Wallet: 0xTest123...
     Latitude: 13.7563
     Longitude: 100.5018
     Region: Central
     District: Bangkok
     Farm Size: 10.0
     Crop Types: Rice, Corn
     KYC Hash: test_kyc_hash
     ```
   - Submit form
   - Verify approval request created
   - Check "Pending Approvals" section

5. **Test Rejection**
   - Select a pending request
   - Click "👎 Reject" button
   - Enter rejection reason: "Test rejection - incomplete documentation"
   - Verify:
     - Status changes to REJECTED
     - Rejection reason displays
     - Red badge shows status

---

### Scenario 2: Policy Creation Approval Flow

**Objective:** Test policy creation with auto-calculated premium

**Test Steps:**

1. **Navigate to Policies Page**
   - Click "Policies" in sidebar
   - View active policies and pending approvals

2. **View Pending Policy Approval**
   - See `REQ_POL_001` in pending section
   - Farmer: Charlie Brown (FARMER003)
   - Coverage: $50,000
   - Premium: $2,500 (auto-calculated)
   - Status: PENDING (1 of 2 approvals)

3. **Create New Policy**
   - Click "+ Create Policy" button
   - Select Farmer: FARMER003 (Charlie Brown)
   - Select Template: TEMPLATE_RICE_001 (Rice Drought Protection)
   - Enter Coverage Amount: 75000
   - Observe:
     - Premium auto-calculates: $3,750 (5% of 75000)
     - End date auto-calculates: 6 months from start
     - Template info displays: Base Price 5%, Duration 6 months, Max $100,000
   - Submit policy
   - Verify approval request created

4. **Test Approval Ready to Execute**
   - View `REQ_POL_002` - David Lee
   - Status: APPROVED (2 of 2 approvals)
   - Coverage: $75,000
   - Click "▶️ Execute" button
   - Confirm execution
   - Verify success message

---

### Scenario 3: Approvals Dashboard Testing

**Objective:** Test comprehensive approval dashboard features

**Test Steps:**

1. **Navigate to Approvals Page**
   - Click "Approvals" in sidebar
   - Dashboard loads with full data

2. **Test Statistics Cards**
   - Verify counts:
     - Pending: 4 requests
     - Approved: 2 requests
     - Rejected: 2 requests
     - Executed: 1 request

3. **Test Filters**
   - **Status Filter:**
     - Select "PENDING" → Shows 4 requests
     - Select "APPROVED" → Shows 2 requests
     - Select "REJECTED" → Shows 2 requests
     - Select "EXECUTED" → Shows 1 request
   
   - **Type Filter:**
     - Select "FARMER_REGISTRATION" → Shows farmer requests
     - Select "POLICY_CREATION" → Shows policy requests
     - Select "CLAIM_APPROVAL" → Shows claim requests
     - Select "POOL_WITHDRAWAL" → Shows withdrawal requests

4. **Test Search**
   - Search "Alice" → Find `REQ_FARM_001`
   - Search "Bob" → Find `REQ_FARM_002`
   - Search "POL" → Find policy requests

5. **Test Details Dialog**
   - Click "ℹ️ Info" button on any request
   - Verify dialog shows:
     - Request ID and type
     - All arguments
     - Required orgs
     - Current approvals
     - Rejections (if any)
     - Metadata
   - Close dialog

6. **Test History Dialog**
   - Click "📜 History" button on `REQ_POL_002`
   - Verify audit trail shows:
     - CREATE action (Insurer1MSP)
     - APPROVE action (Insurer1MSP) with reason
     - APPROVE action (CoopMSP) with reason
     - Transaction IDs for each action
   - Close dialog

7. **Test Rejection Dialog**
   - Select pending request
   - Click "👎 Reject"
   - Dialog opens with reason field
   - Enter: "Test rejection for demonstration"
   - Submit
   - Verify request updates

---

### Scenario 4: Permission-Based Actions

**Objective:** Verify role-based access control

**Test Steps:**

1. **Test as Coop User**
   - Login: `coop@example.com`
   - Can see:
     - Dashboard
     - Farmers page
     - Policies page
     - Approvals page
   - Can approve:
     - Farmer registration requests
     - Policy creation requests
   - Cannot see:
     - Claims page
     - Weather page (Oracle only)
     - Pool page (Insurer only)

2. **Test as Insurer User**
   - Login: `insurer@example.com`
   - Can see:
     - Dashboard
     - Policies page
     - Claims page
     - Approvals page
     - Premium Pool page
   - Can approve:
     - Policy creation requests
     - Claim approval requests
     - Pool withdrawal requests
   - Cannot see:
     - Farmers page (Coop only)
     - Weather page (Oracle only)

3. **Test Approval Permissions**
   - For `REQ_FARM_001`:
     - CoopMSP user: Cannot approve (already approved)
     - Insurer1MSP user: Can approve (required org, not yet approved)
     - Insurer2MSP user: Cannot approve (not in required orgs)

---

### Scenario 5: Form Validation Testing

**Objective:** Test form validation and error handling

**Test Steps:**

1. **Test Farmer Form Validation**
   - Open "Register Farmer" form
   - Try to submit empty form
   - Verify required field errors:
     - "Farmer ID is required"
     - "First name is required"
     - "Email is required"
     - etc.
   - Fill valid data
   - Submit successfully

2. **Test Policy Form Validation**
   - Open "Create Policy" form
   - Select template first (required for calculations)
   - Try coverage amount > max coverage
   - Verify error: "Max coverage is $XXX"
   - Enter valid coverage
   - Verify premium auto-calculates
   - Submit successfully

3. **Test Rejection Reason Validation**
   - Click reject button
   - Try to submit empty reason
   - Verify error or disable submit
   - Enter valid reason
   - Submit successfully

---

## 📊 Mock Data Reference

### Approval Requests

#### REQ_FARM_001 - Alice Johnson (PENDING)
- **Type:** FARMER_REGISTRATION
- **Status:** PENDING (1/2 approvals)
- **Approvals:** CoopMSP ✅
- **Needs:** Insurer1MSP approval
- **Created:** 2 hours ago
- **Metadata:** 12.5 hectares, Central region, Rice/Corn

#### REQ_FARM_002 - Bob Smith (PENDING)
- **Type:** FARMER_REGISTRATION
- **Status:** PENDING (0/2 approvals)
- **Needs:** CoopMSP + Insurer1MSP approval
- **Created:** 30 minutes ago
- **Metadata:** 8.0 hectares, Northeast region, Rice

#### REQ_POL_001 - Charlie Brown (PENDING)
- **Type:** POLICY_CREATION
- **Status:** PENDING (1/2 approvals)
- **Approvals:** Insurer1MSP ✅
- **Needs:** CoopMSP approval
- **Coverage:** $50,000
- **Premium:** $2,500
- **Created:** 4 hours ago

#### REQ_POL_002 - David Lee (APPROVED)
- **Type:** POLICY_CREATION
- **Status:** APPROVED (2/2 approvals)
- **Approvals:** CoopMSP ✅, Insurer1MSP ✅
- **Ready to Execute:** YES
- **Coverage:** $75,000
- **Premium:** $3,750
- **Created:** 1 day ago

#### REQ_CLAIM_001 - Emma Wilson (APPROVED)
- **Type:** CLAIM_APPROVAL
- **Status:** APPROVED (2/2 approvals)
- **Approvals:** Insurer1MSP ✅, Insurer2MSP ✅
- **Ready to Execute:** YES
- **Claim Amount:** $35,000
- **Loss Type:** Drought
- **Created:** 3 days ago

#### REQ_FARM_003 - Frank Miller (REJECTED)
- **Type:** FARMER_REGISTRATION
- **Status:** REJECTED
- **Rejected By:** Insurer1MSP
- **Reason:** "KYC documentation incomplete. Missing proof of land ownership and tax records."
- **Created:** 5 days ago

#### REQ_POOL_001 - Pool Withdrawal (REJECTED)
- **Type:** POOL_WITHDRAWAL
- **Status:** REJECTED
- **Amount:** $100,000
- **Rejected By:** Insurer2MSP, CoopMSP
- **Reasons:**
  - Insurer2MSP: "Insufficient justification for emergency withdrawal."
  - CoopMSP: "Request lacks proper documentation."
- **Created:** 7 days ago

#### REQ_FARM_004 - Grace Taylor (EXECUTED)
- **Type:** FARMER_REGISTRATION
- **Status:** EXECUTED
- **Approved By:** CoopMSP, Insurer1MSP
- **Executed:** 9 days ago
- **Result:** Farmer successfully registered

#### REQ_CLAIM_002 - Henry Rodriguez (PENDING)
- **Type:** CLAIM_APPROVAL
- **Status:** PENDING (2/3 approvals)
- **Approvals:** Insurer1MSP ✅, Insurer2MSP ✅
- **Needs:** CoopMSP verification
- **Claim Amount:** $45,000
- **Loss Type:** Flood
- **Created:** 6 hours ago

### Farmers

#### FARMER003 - Charlie Brown
- **Region:** Central (Nakhon Pathom)
- **Farm Size:** 20.0 hectares
- **Crops:** Rice, Soybeans
- **Status:** Active
- **Registered:** 30 days ago

#### FARMER004 - David Lee
- **Region:** Central (Ayutthaya)
- **Farm Size:** 18.5 hectares
- **Crops:** Wheat, Corn
- **Status:** Active
- **Registered:** 45 days ago

#### FARMER006 - Grace Taylor
- **Region:** North (Chiang Mai)
- **Farm Size:** 15.0 hectares
- **Crops:** Rice, Vegetables
- **Status:** Active
- **Registered:** 9 days ago

### Policy Templates

#### TEMPLATE_RICE_001 - Rice Drought Protection
- **Base Price:** 5.0% of coverage
- **Max Coverage:** $100,000
- **Duration:** 6 months
- **Status:** Active

#### TEMPLATE_WHEAT_001 - Wheat Multi-Peril
- **Base Price:** 6.5% of coverage
- **Max Coverage:** $150,000
- **Duration:** 9 months
- **Status:** Active

#### TEMPLATE_CORN_001 - Corn Weather Index
- **Base Price:** 5.5% of coverage
- **Max Coverage:** $120,000
- **Duration:** 7 months
- **Status:** Active

#### TEMPLATE_VEGETABLES_001 - Vegetable Weather Protection
- **Base Price:** 7.0% of coverage
- **Max Coverage:** $80,000
- **Duration:** 4 months
- **Status:** Active

### Active Policies

#### POL003 - Charlie Brown's Rice Policy
- **Coverage:** $80,000
- **Premium:** $4,000
- **Status:** Active
- **Start:** 60 days ago
- **End:** 120 days from now
- **Has Claim:** CLAIM001 ($35,000 paid)

#### POL004 - David Lee's Wheat Policy
- **Coverage:** $100,000
- **Premium:** $6,500
- **Status:** Active
- **Start:** 45 days ago
- **End:** 225 days from now
- **Has Claim:** CLAIM002 ($45,000 processing)

---

## 🔍 Testing Checklist

### Forms
- [ ] Farmer registration form validates all fields
- [ ] Farmer form submits successfully
- [ ] Farmer form resets after successful submission
- [ ] Policy creation form validates fields
- [ ] Policy premium auto-calculates correctly
- [ ] Policy end date auto-calculates correctly
- [ ] Policy form shows template info
- [ ] Rejection dialog requires reason

### Approvals Dashboard
- [ ] Statistics cards display correct counts
- [ ] Status filter works (PENDING, APPROVED, REJECTED, EXECUTED)
- [ ] Type filter works (4 request types)
- [ ] Search finds requests by keywords
- [ ] Table sorts by columns
- [ ] Pagination works if >10 requests
- [ ] Details dialog shows complete info
- [ ] History dialog shows audit trail
- [ ] Rejection dialog opens and submits

### Approval Actions
- [ ] Approve button shows for authorized users
- [ ] Approve button hidden after user approves
- [ ] Reject button shows for authorized users
- [ ] Reject button requires reason
- [ ] Execute button shows for APPROVED status
- [ ] Execute button confirms before action
- [ ] Success messages display after actions
- [ ] Error messages display on failure
- [ ] Lists auto-refresh after actions

### Permissions
- [ ] Coop users see Farmers page
- [ ] Insurer users see Claims page
- [ ] Oracle users see Weather page
- [ ] Unauthorized pages redirect to Unauthorized
- [ ] Approval buttons respect role permissions
- [ ] Navigation items filter by role

### UI/UX
- [ ] Loading states show during operations
- [ ] Error alerts display and auto-dismiss
- [ ] Success alerts display and auto-dismiss
- [ ] Dialogs open and close smoothly
- [ ] Forms validate on submit
- [ ] Buttons disable during loading
- [ ] Mobile responsive layout works
- [ ] Dark mode (if implemented) works

---

## 🐛 Troubleshooting

### Development Server Won't Start

**Issue:** `npm: command not found`
```bash
# Install Node.js and npm
# macOS with Homebrew:
brew install node

# Verify installation:
node --version
npm --version
```

**Issue:** Port 5173 already in use
```bash
# Kill process on port
lsof -ti:5173 | xargs kill -9

# Or change port in vite.config.ts
server: { port: 3000 }
```

### Mock Data Not Loading

**Issue:** All lists are empty
- Check browser console for errors
- Verify `/src/data/mockData.ts` exists
- Check service imports are correct
- Ensure `isDevMode()` returns `true` in `api.service.ts`

### Approval Actions Not Working

**Issue:** Click approve/reject but nothing happens
- Check browser console for errors
- Verify `useApprovalActions` hook is imported
- Check network tab for API calls
- Ensure user role matches required orgs

### Forms Not Submitting

**Issue:** Submit button disabled or validation errors
- Check all required fields are filled
- Verify email format is valid
- Check number fields have valid values
- Look for validation error messages below fields

---

## 📝 Next Steps

After completing manual testing:

1. **Document Issues**
   - Create list of bugs found
   - Note UI/UX improvements needed
   - Identify missing features

2. **Real API Integration**
   - Change `isDevMode()` to return `false`
   - Ensure API Gateway is running
   - Test with real blockchain data

3. **Multi-User Testing**
   - Test with multiple browser windows
   - Simulate different org users
   - Test concurrent approvals

4. **Performance Testing**
   - Test with 100+ approval requests
   - Check table pagination
   - Verify search performance

5. **Production Preparation**
   - Remove console.log statements
   - Add error boundaries
   - Optimize bundle size
   - Enable production build

---

## 🎉 Success Criteria

Testing is complete when:

✅ All 9 approval requests display correctly  
✅ Filters and search work as expected  
✅ Forms validate and submit successfully  
✅ Approval/Reject/Execute actions work  
✅ Dialogs (Details, History, Reject) function properly  
✅ Role-based permissions are enforced  
✅ UI responsive on desktop and tablet  
✅ No console errors during normal operation  
✅ Success/error messages display appropriately  
✅ Auto-refresh updates data after actions  

---

*Generated: November 11, 2025*  
*Mock Data Version: 1.0*  
*Ready for Testing!* 🚀
