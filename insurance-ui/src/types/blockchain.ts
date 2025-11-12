// Blockchain Data Types for Weather Index Insurance Platform

export interface Organization {
  orgID: string;
  orgName: string;
  orgType: 'Insurer' | 'Coop' | 'Oracle' | 'Validator' | 'Auditor';
  msp: string;
  contactEmail: string;
  status: 'Active' | 'Suspended' | 'Revoked';
  registeredDate: string;
  registeredBy: string;
}

export interface Farmer {
  farmerID: string;
  firstName: string;
  lastName: string;
  coopID: string;
  phoneNumber: string;
  email: string;
  walletAddress: string;
  farmLocation: {
    latitude: number;
    longitude: number;
    region: string;
    district: string;
  };
  farmSize: number;
  cropTypes: string[];
  status: 'Active' | 'Inactive' | 'Suspended';
  kycVerified: boolean;
  kycHash: string;
  registeredDate: string;
  registeredBy: string;
  lastUpdated: string;
}

export interface PolicyTemplate {
  templateID: string;
  templateName: string;
  cropType: string;
  region: string;
  riskLevel: 'Low' | 'Medium' | 'High';
  coveragePeriod: number; // days
  maxCoverage: number;
  minPremium: number;
  pricingModel: {
    baseRate: number;
    riskMultiplier: number;
    farmSizeFactor: number;
    historyDiscount: number;
    parameters: Record<string, any>;
  };
  indexThresholds: IndexThreshold[];
  version: number;
  status: 'Draft' | 'Active' | 'Deprecated';
  createdBy: string;
  createdDate: string;
  lastUpdated: string;
}

export interface IndexThreshold {
  indexType: 'Rainfall' | 'Temperature' | 'Drought' | 'Humidity';
  metric: string; // e.g., "mm", "celsius"
  thresholdValue: number;
  operator: '<' | '>' | '<=' | '>=' | '==';
  measurementDays: number;
  payoutPercent: number; // 0-100
  severity: 'Mild' | 'Moderate' | 'Severe';
}

export interface Policy {
  policyID: string;
  farmerID: string;
  templateID: string;
  coopID: string;
  insurerID: string;
  coverageAmount: number;
  premiumAmount: number;
  startDate: string;
  endDate: string;
  status: 'Active' | 'Expired' | 'Claimed' | 'Cancelled';
  farmLocation: string;
  cropType: string;
  farmSize: number;
  policyTermsHash: string;
  createdDate: string;
}

export interface WeatherData {
  dataID: string;
  oracleID: string;
  location: string;
  timestamp: string;
  temperature: number;
  rainfall: number;
  humidity: number;
  dataHash: string;
  status: 'Pending' | 'Validated' | 'Rejected';
  submittedDate: string;
}

export interface OracleProvider {
  oracleID: string;
  providerName: string;
  providerType: string;
  dataSources: string[];
  reputationScore: number;
  status: 'Active' | 'Suspended';
  registeredDate: string;
}

export interface WeatherIndex {
  indexID: string;
  policyID: string;
  location: string;
  indexType: string;
  indexValue: number;
  baseline: number;
  deviation: number;
  severity: string;
  payoutTriggered: boolean;
  payoutPercent: number;
  calculatedDate: string;
}

export interface Claim {
  claimID: string;
  policyID: string;
  farmerID: string;
  indexID: string; // Weather data ID that triggered the claim
  triggerDate: string;
  payoutAmount: number;
  payoutPercent: number;
  status: string; // 'Pending' | 'Approved' | 'Paid' | 'Failed' | 'Triggered' | 'Processing'
  approvedBy?: string;
  processedDate?: string;
  paymentTxID?: string;
  notes?: string;
}

export interface Transaction {
  txID: string;
  type: string;
  policyID?: string;
  farmerID?: string;
  amount: number;
  timestamp: string;
  status: string; // 'Completed' | 'Pending' | 'Failed' from chaincode
  blockNumber?: number;
  balanceBefore?: number;
  balanceAfter?: number;
  initiatedBy?: string;
  notes?: string;
}

export interface PremiumPool {
  poolID: string;
  totalBalance: number;
  totalPremiums: number;
  totalPayouts: number;
  reserves: number;
  lastUpdated: string;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  txId?: string;
}

export interface DashboardStats {
  totalFarmers: number;
  activePolicies: number;
  triggeredClaims: number; // Claims automatically triggered by smart contract
  totalPayouts: number;
  poolBalance: number;
  recentTransactions: Transaction[];
}

// Approval Management Types
export type ApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXECUTED';
export type ApprovalRequestType = 'FARMER_REGISTRATION' | 'POLICY_CREATION' | 'CLAIM_APPROVAL' | 'POOL_WITHDRAWAL';

export interface ApprovalRequest {
  requestId: string;
  requestType: ApprovalRequestType;
  chaincodeName: string;
  functionName: string;
  arguments: string[];
  requiredOrgs: string[];
  status: ApprovalStatus;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  approvals: Record<string, boolean>; // orgMSP -> approved
  rejections: Record<string, string>; // orgMSP -> reason
  executedAt?: string;
  executedBy?: string;
  executedTxID?: string;
  metadata?: Record<string, any>;
}

export interface ApprovalHistory {
  timestamp: string;
  action: 'CREATE' | 'APPROVE' | 'REJECT' | 'EXECUTE';
  actor: string;
  reason?: string;
  txID?: string;
}

// User Role Types
export type UserRole = 'insurer' | 'coop' | 'oracle' | 'admin';

export interface User {
  id: string;
  name: string;
  role: UserRole;
  orgId: string;
  permissions: string[];
}
