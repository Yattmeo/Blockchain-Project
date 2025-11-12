/**
 * Comprehensive Mock Data for Development Testing
 * Provides realistic test data for all functionality
 */

import type { 
  ApprovalRequest, 
  ApprovalHistory,
  Farmer,
  Policy,
  PolicyTemplate,
  Claim,
  WeatherData 
} from '../types/blockchain';

// ============================================================================
// APPROVAL REQUESTS - Covering all scenarios
// ============================================================================

export const mockApprovalRequests: ApprovalRequest[] = [
  // PENDING - Needs Insurer approval (1 of 2 approvals)
  {
    requestId: 'REQ_FARM_001',
    requestType: 'FARMER_REGISTRATION',
    chaincodeName: 'farmer',
    functionName: 'RegisterFarmer',
    arguments: [
      'FARMER001',
      'Alice',
      'Johnson',
      'COOP001',
      '555-1001',
      'alice.johnson@farm.com',
      '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
      '13.7563',
      '100.5018',
      'Central',
      'Bangkok',
      '12.5',
      '["Rice","Corn"]',
      'kyc_hash_alice_001'
    ],
    requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
    status: 'PENDING',
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
    createdBy: 'CoopMSP',
    approvals: { 'CoopMSP': true },
    rejections: {},
    metadata: {
      farmerName: 'Alice Johnson',
      farmSize: '12.5 hectares',
      region: 'Central',
      cropTypes: 'Rice, Corn'
    },
  },

  // PENDING - Needs both Coop and Insurer approval (0 of 2)
  {
    requestId: 'REQ_FARM_002',
    requestType: 'FARMER_REGISTRATION',
    chaincodeName: 'farmer',
    functionName: 'RegisterFarmer',
    arguments: [
      'FARMER002',
      'Bob',
      'Smith',
      'COOP001',
      '555-1002',
      'bob.smith@farm.com',
      '0x853d46Cc7734D0643936b4c955e8f706g1cFcC',
      '13.7563',
      '100.5018',
      'Northeast',
      'Khon Kaen',
      '8.0',
      '["Rice"]',
      'kyc_hash_bob_002'
    ],
    requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
    status: 'PENDING',
    createdAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    createdBy: 'CoopMSP',
    approvals: {},
    rejections: {},
    metadata: {
      farmerName: 'Bob Smith',
      farmSize: '8.0 hectares',
      region: 'Northeast',
      cropTypes: 'Rice'
    },
  },

  // PENDING - Policy needs approval (1 of 2)
  {
    requestId: 'REQ_POL_001',
    requestType: 'POLICY_CREATION',
    chaincodeName: 'policy',
    functionName: 'CreatePolicy',
    arguments: [
      'POL001',
      'FARMER003',
      'TEMPLATE_RICE_001',
      '50000',
      '2500',
      '2025-11-15',
      '2026-05-15'
    ],
    requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
    status: 'PENDING',
    createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    approvals: { 'Insurer1MSP': true },
    rejections: {},
    metadata: {
      policyId: 'POL001',
      farmerName: 'Charlie Brown',
      coverageAmount: '$50,000',
      premiumAmount: '$2,500',
      cropType: 'Rice',
      duration: '6 months'
    },
  },

  // APPROVED - Ready to execute
  {
    requestId: 'REQ_POL_002',
    requestType: 'POLICY_CREATION',
    chaincodeName: 'policy',
    functionName: 'CreatePolicy',
    arguments: [
      'POL002',
      'FARMER004',
      'TEMPLATE_WHEAT_001',
      '75000',
      '3750',
      '2025-11-12',
      '2026-08-12'
    ],
    requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
    status: 'APPROVED',
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 22 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    approvals: { 'CoopMSP': true, 'Insurer1MSP': true },
    rejections: {},
    metadata: {
      policyId: 'POL002',
      farmerName: 'David Lee',
      coverageAmount: '$75,000',
      premiumAmount: '$3,750',
      cropType: 'Wheat',
      duration: '9 months'
    },
  },

  // APPROVED - Claim ready to execute
  {
    requestId: 'REQ_CLAIM_001',
    requestType: 'CLAIM_APPROVAL',
    chaincodeName: 'claim-processor',
    functionName: 'ProcessClaim',
    arguments: [
      'CLAIM001',
      'POL003',
      '35000',
      'APPROVED'
    ],
    requiredOrgs: ['Insurer1MSP', 'Insurer2MSP'],
    status: 'APPROVED',
    createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    approvals: { 'Insurer1MSP': true, 'Insurer2MSP': true },
    rejections: {},
    metadata: {
      claimId: 'CLAIM001',
      policyId: 'POL003',
      farmerName: 'Emma Wilson',
      claimAmount: '$35,000',
      lossType: 'Drought',
      verificationStatus: 'Verified'
    },
  },

  // REJECTED - Invalid documentation
  {
    requestId: 'REQ_FARM_003',
    requestType: 'FARMER_REGISTRATION',
    chaincodeName: 'farmer',
    functionName: 'RegisterFarmer',
    arguments: [
      'FARMER005',
      'Frank',
      'Miller',
      'COOP002',
      '555-1005',
      'frank.miller@farm.com',
      '0x964e57Dd8845E0754047c5d966f9g817h2dEdD',
      '13.7563',
      '100.5018',
      'South',
      'Phuket',
      '3.5',
      '["Cassava"]',
      'kyc_hash_frank_005'
    ],
    requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
    status: 'REJECTED',
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'CoopMSP',
    approvals: { 'CoopMSP': true },
    rejections: { 
      'Insurer1MSP': 'KYC documentation incomplete. Missing proof of land ownership and tax records.'
    },
    metadata: {
      farmerName: 'Frank Miller',
      farmSize: '3.5 hectares',
      region: 'South',
      cropTypes: 'Cassava',
      rejectionReason: 'Incomplete documentation'
    },
  },

  // REJECTED - Pool withdrawal denied
  {
    requestId: 'REQ_POOL_001',
    requestType: 'POOL_WITHDRAWAL',
    chaincodeName: 'premium-pool',
    functionName: 'WithdrawFunds',
    arguments: [
      'POOL_MAIN',
      '100000',
      'Emergency operational costs'
    ],
    requiredOrgs: ['Insurer1MSP', 'Insurer2MSP', 'CoopMSP'],
    status: 'REJECTED',
    createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    approvals: { 'Insurer1MSP': true },
    rejections: { 
      'Insurer2MSP': 'Insufficient justification for emergency withdrawal. Pool reserves are for claim payments only.',
      'CoopMSP': 'Request lacks proper documentation and stakeholder approval.'
    },
    metadata: {
      amount: '$100,000',
      reason: 'Emergency operational costs',
      poolBalance: '$1,250,000'
    },
  },

  // EXECUTED - Completed farmer registration
  {
    requestId: 'REQ_FARM_004',
    requestType: 'FARMER_REGISTRATION',
    chaincodeName: 'farmer',
    functionName: 'RegisterFarmer',
    arguments: [
      'FARMER006',
      'Grace',
      'Taylor',
      'COOP001',
      '555-1006',
      'grace.taylor@farm.com',
      '0xa75f68Ee9956F1865158d7e977ga928i3eFfeE',
      '13.7563',
      '100.5018',
      'North',
      'Chiang Mai',
      '15.0',
      '["Rice","Vegetables"]',
      'kyc_hash_grace_006'
    ],
    requiredOrgs: ['CoopMSP', 'Insurer1MSP'],
    status: 'EXECUTED',
    createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'CoopMSP',
    approvals: { 'CoopMSP': true, 'Insurer1MSP': true },
    rejections: {},
    metadata: {
      farmerName: 'Grace Taylor',
      farmSize: '15.0 hectares',
      region: 'North',
      cropTypes: 'Rice, Vegetables'
    },
  },

  // PENDING - Multi-org claim approval (2 of 3)
  {
    requestId: 'REQ_CLAIM_002',
    requestType: 'CLAIM_APPROVAL',
    chaincodeName: 'claim-processor',
    functionName: 'ProcessClaim',
    arguments: [
      'CLAIM002',
      'POL004',
      '45000',
      'APPROVED'
    ],
    requiredOrgs: ['Insurer1MSP', 'Insurer2MSP', 'CoopMSP'],
    status: 'PENDING',
    createdAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    approvals: { 'Insurer1MSP': true, 'Insurer2MSP': true },
    rejections: {},
    metadata: {
      claimId: 'CLAIM002',
      policyId: 'POL004',
      farmerName: 'Henry Rodriguez',
      claimAmount: '$45,000',
      lossType: 'Flood',
      verificationStatus: 'Pending CoopMSP verification'
    },
  },
];

// ============================================================================
// APPROVAL HISTORY - Sample audit trail
// ============================================================================

export const mockApprovalHistory: Record<string, ApprovalHistory[]> = {
  'REQ_FARM_001': [
    {
      timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      action: 'CREATE',
      actor: 'CoopMSP',
      txID: 'tx_create_001',
    },
    {
      timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
      action: 'APPROVE',
      actor: 'CoopMSP',
      reason: 'Farmer documentation verified and complete',
      txID: 'tx_approve_001',
    },
  ],
  'REQ_POL_002': [
    {
      timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
      action: 'CREATE',
      actor: 'Insurer1MSP',
      txID: 'tx_create_002',
    },
    {
      timestamp: new Date(Date.now() - 23 * 60 * 60 * 1000).toISOString(),
      action: 'APPROVE',
      actor: 'Insurer1MSP',
      reason: 'Policy terms validated',
      txID: 'tx_approve_002',
    },
    {
      timestamp: new Date(Date.now() - 22 * 60 * 60 * 1000).toISOString(),
      action: 'APPROVE',
      actor: 'CoopMSP',
      reason: 'Farmer eligibility confirmed',
      txID: 'tx_approve_003',
    },
  ],
  'REQ_FARM_003': [
    {
      timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      action: 'CREATE',
      actor: 'CoopMSP',
      txID: 'tx_create_003',
    },
    {
      timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000 + 1000).toISOString(),
      action: 'APPROVE',
      actor: 'CoopMSP',
      reason: 'Local verification passed',
      txID: 'tx_approve_004',
    },
    {
      timestamp: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
      action: 'REJECT',
      actor: 'Insurer1MSP',
      reason: 'KYC documentation incomplete. Missing proof of land ownership and tax records.',
      txID: 'tx_reject_001',
    },
  ],
};

// ============================================================================
// FARMERS - Test data for farmer management
// ============================================================================

export const mockFarmers: Farmer[] = [
  {
    farmerID: 'FARMER003',
    firstName: 'Charlie',
    lastName: 'Brown',
    coopID: 'COOP001',
    phoneNumber: '555-1003',
    email: 'charlie.brown@farm.com',
    walletAddress: '0xc86g79Ff0067G1865269e8f088hb039j4gGggF',
    farmLocation: {
      latitude: 13.7563,
      longitude: 100.5018,
      region: 'Central',
      district: 'Nakhon Pathom',
    },
    farmSize: 20.0,
    cropTypes: ['Rice', 'Soybeans'],
    status: 'Active',
    kycVerified: true,
    kycHash: 'kyc_hash_charlie_003',
    registeredDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
    registeredBy: 'admin@coop001.com',
    lastUpdated: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    farmerID: 'FARMER004',
    firstName: 'David',
    lastName: 'Lee',
    coopID: 'COOP001',
    phoneNumber: '555-1004',
    email: 'david.lee@farm.com',
    walletAddress: '0xd97h80Gg1178H2976380f199ic150k5hHhhG',
    farmLocation: {
      latitude: 13.8563,
      longitude: 100.6018,
      region: 'Central',
      district: 'Ayutthaya',
    },
    farmSize: 18.5,
    cropTypes: ['Wheat', 'Corn'],
    status: 'Active',
    kycVerified: true,
    kycHash: 'kyc_hash_david_004',
    registeredDate: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
    registeredBy: 'admin@coop001.com',
    lastUpdated: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    farmerID: 'FARMER006',
    firstName: 'Grace',
    lastName: 'Taylor',
    coopID: 'COOP001',
    phoneNumber: '555-1006',
    email: 'grace.taylor@farm.com',
    walletAddress: '0xa75f68Ee9956F1865158d7e977ga928i3eFfeE',
    farmLocation: {
      latitude: 18.7883,
      longitude: 98.9853,
      region: 'North',
      district: 'Chiang Mai',
    },
    farmSize: 15.0,
    cropTypes: ['Rice', 'Vegetables'],
    status: 'Active',
    kycVerified: true,
    kycHash: 'kyc_hash_grace_006',
    registeredDate: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000).toISOString(),
    registeredBy: 'admin@coop001.com',
    lastUpdated: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

// ============================================================================
// POLICY TEMPLATES - For policy creation
// ============================================================================

export const mockPolicyTemplates: PolicyTemplate[] = [
  {
    templateID: 'TEMPLATE_RICE_001',
    templateName: 'Rice Drought Protection',
    description: 'Comprehensive drought protection for rice farmers',
    cropType: 'Rice',
    coverageType: 'Drought Protection',
    basePrice: 5.0, // 5% of coverage amount
    minCoverage: 10000,
    maxCoverage: 100000,
    duration: 6, // months
    status: 'Active',
    createdDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    version: 1,
  },
  {
    templateID: 'TEMPLATE_WHEAT_001',
    templateName: 'Wheat Multi-Peril Insurance',
    description: 'Multi-peril coverage for wheat crops',
    cropType: 'Wheat',
    coverageType: 'Multi-Peril',
    basePrice: 6.5,
    minCoverage: 15000,
    maxCoverage: 150000,
    duration: 9,
    status: 'Active',
    createdDate: new Date(Date.now() - 85 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    version: 1,
  },
  {
    templateID: 'TEMPLATE_CORN_001',
    templateName: 'Corn Weather Index',
    description: 'Weather-based index insurance for corn',
    cropType: 'Corn',
    coverageType: 'Drought & Flood',
    basePrice: 5.5,
    minCoverage: 12000,
    maxCoverage: 120000,
    duration: 7,
    status: 'Active',
    createdDate: new Date(Date.now() - 80 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    version: 1,
  },
  {
    templateID: 'TEMPLATE_VEGETABLES_001',
    templateName: 'Vegetable Weather Protection',
    description: 'Weather index insurance for vegetables',
    cropType: 'Vegetables',
    coverageType: 'Weather Index',
    basePrice: 7.0,
    minCoverage: 5000,
    maxCoverage: 80000,
    duration: 4,
    status: 'Active',
    createdDate: new Date(Date.now() - 75 * 24 * 60 * 60 * 1000).toISOString(),
    createdBy: 'Insurer1MSP',
    version: 1,
  },
];

// ============================================================================
// POLICIES - Active and pending policies
// ============================================================================

export const mockPolicies: Policy[] = [
  {
    policyID: 'POL003',
    farmerID: 'FARMER003',
    templateID: 'TEMPLATE_RICE_001',
    coopID: 'COOP001',
    insurerID: 'INSURER001',
    coverageAmount: 80000,
    premiumAmount: 4000,
    startDate: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(),
    endDate: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000).toISOString(),
    status: 'Active',
    farmLocation: 'Central Thailand',
    cropType: 'Rice',
    farmSize: 20.0,
    policyTermsHash: 'hash_pol_003',
    createdDate: new Date(Date.now() - 65 * 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    policyID: 'POL004',
    farmerID: 'FARMER004',
    templateID: 'TEMPLATE_WHEAT_001',
    coopID: 'COOP001',
    insurerID: 'INSURER001',
    coverageAmount: 100000,
    premiumAmount: 6500,
    startDate: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000).toISOString(),
    endDate: new Date(Date.now() + 225 * 24 * 60 * 60 * 1000).toISOString(),
    status: 'Active',
    farmLocation: 'Central Thailand',
    cropType: 'Wheat',
    farmSize: 18.5,
    policyTermsHash: 'hash_pol_004',
    createdDate: new Date(Date.now() - 50 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

// ============================================================================
// CLAIMS - Various claim states
// ============================================================================

export const mockClaims: Claim[] = [
  {
    claimID: 'CLAIM001',
    policyID: 'POL003',
    farmerID: 'FARMER003',
    indexID: 'INDEX_DROUGHT_001',
    triggerDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
    payoutAmount: 35000,
    payoutPercent: 43.75, // 35000/80000 * 100
    status: 'Paid',
    processedDate: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000).toISOString(),
    paymentTxID: 'tx_payment_001',
    notes: 'Severe drought conditions confirmed. Automatic payout processed.',
  },
  {
    claimID: 'CLAIM002',
    policyID: 'POL004',
    farmerID: 'FARMER004',
    indexID: 'INDEX_FLOOD_001',
    triggerDate: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString(),
    payoutAmount: 45000,
    payoutPercent: 45.0, // 45000/100000 * 100
    status: 'Processing',
    processedDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    paymentTxID: '',
    notes: 'Excessive rainfall verified. Payment processing in progress.',
  },
];

// ============================================================================
// WEATHER DATA - For oracle testing
// ============================================================================

export const mockWeatherData: WeatherData[] = [
  {
    dataID: 'WEATHER_001',
    oracleID: 'ORACLE_TMD_001',
    location: 'Central Thailand (13.7563, 100.5018)',
    timestamp: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    temperature: 32.0,
    rainfall: 15.5,
    humidity: 75,
    dataHash: 'hash_weather_001',
    status: 'Validated',
    submittedDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    dataID: 'WEATHER_002',
    oracleID: 'ORACLE_TMD_001',
    location: 'Central Thailand (13.7563, 100.5018)',
    timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    temperature: 33.5,
    rainfall: 8.2,
    humidity: 68,
    dataHash: 'hash_weather_002',
    status: 'Validated',
    submittedDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

export const getMockApprovalsByStatus = (status: string) => {
  return mockApprovalRequests.filter(req => req.status === status);
};

export const getMockApprovalsByType = (type: string) => {
  return mockApprovalRequests.filter(req => req.requestType === type);
};

export const getMockPendingApprovals = () => {
  return mockApprovalRequests.filter(req => req.status === 'PENDING');
};

export const getMockApprovalHistory = (requestId: string) => {
  return mockApprovalHistory[requestId] || [];
};
