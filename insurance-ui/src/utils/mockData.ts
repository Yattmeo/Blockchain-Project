import type { 
  Farmer, 
  Policy, 
  Claim, 
  WeatherData, 
  Transaction,
  DashboardStats 
} from '../types/blockchain';

/**
 * Mock Data Generators for Development Mode
 * 
 * These functions generate realistic mock data that matches the blockchain types
 */

// Helper to generate random IDs
const generateId = (prefix: string) => `${prefix}${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

// Helper to generate random dates
const randomDate = (daysAgo: number = 30) => {
  const date = new Date();
  date.setDate(date.getDate() - Math.floor(Math.random() * daysAgo));
  return date.toISOString();
};

/**
 * Generate mock farmers
 */
export const generateMockFarmers = (count: number = 10): Farmer[] => {
  const firstNames = ['John', 'Mary', 'Ahmad', 'Siti', 'David', 'Sarah', 'Kumar', 'Lisa'];
  const lastNames = ['Tan', 'Lee', 'Ibrahim', 'Rahman', 'Wong', 'Lim', 'Singh', 'Chen'];
  const regions = ['North', 'South', 'East', 'West', 'Central'];
  const districts = ['District A', 'District B', 'District C'];
  const cooperatives = ['COOP001', 'COOP002', 'COOP003'];
  const cropTypes = [['Rice'], ['Corn'], ['Wheat'], ['Rice', 'Corn']];
  
  return Array.from({ length: count }, (_, i) => ({
    farmerID: generateId('F'),
    firstName: firstNames[i % firstNames.length],
    lastName: lastNames[i % lastNames.length],
    coopID: cooperatives[i % cooperatives.length],
    phone: `+65 ${Math.floor(Math.random() * 90000000) + 10000000}`,
    email: `farmer${i}@example.com`,
    walletAddress: `0x${Math.random().toString(16).substr(2, 40)}`,
    latitude: 1.3 + Math.random() * 0.3,
    longitude: 103.7 + Math.random() * 0.3,
    region: regions[i % regions.length],
    district: districts[i % districts.length],
    farmSize: Math.floor(Math.random() * 50) + 10,
    cropTypes: cropTypes[i % cropTypes.length],
    kycHash: `0x${Math.random().toString(16).substr(2, 64)}`,
    registrationDate: randomDate(365),
    status: 'Active' as const,
  }));
};

/**
 * Generate mock policies
 */
export const generateMockPolicies = (count: number = 10): Policy[] => {
  const statuses: Array<'Active' | 'Expired' | 'Claimed' | 'Cancelled'> = ['Active', 'Active', 'Active', 'Expired', 'Claimed', 'Cancelled'];
  const cropTypes = ['Rice', 'Corn', 'Wheat'];
  
  return Array.from({ length: count }, (_, i) => ({
    policyID: generateId('POL'),
    farmerID: generateId('F'),
    templateID: generateId('TPL'),
    coopID: `COOP00${(i % 3) + 1}`,
    insurerID: 'INS001',
    coverageAmount: Math.floor(Math.random() * 50000) + 10000,
    premiumAmount: Math.floor(Math.random() * 2000) + 500,
    startDate: randomDate(180),
    endDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(),
    status: statuses[i % statuses.length],
    farmLocation: `1.${Math.floor(Math.random() * 9000) + 1000},103.${Math.floor(Math.random() * 9000) + 1000}`,
    cropType: cropTypes[i % cropTypes.length],
    farmSize: Math.floor(Math.random() * 50) + 10,
    policyTermsHash: `0x${Math.random().toString(16).substr(2, 64)}`,
    createdDate: randomDate(180),
  }));
};

/**
 * Generate mock claims
 * Note: Claims are automatically triggered by smart contract when weather index meets threshold
 * No manual approval needed - this is parametric insurance!
 */
export const generateMockClaims = (count: number = 10): Claim[] => {
  const statuses: Array<'Triggered' | 'Processing' | 'Paid' | 'Failed'> = ['Paid', 'Paid', 'Paid', 'Processing', 'Triggered', 'Failed'];
  const triggerConditions = [
    'Rainfall below 50mm threshold',
    'Temperature above 35°C for 7 days',
    'Drought index exceeded 80%',
    'Excessive rainfall above 200mm',
    'Heat stress index above threshold',
  ];
  
  return Array.from({ length: count }, (_, i) => {
    const status = statuses[i % statuses.length];
    const triggerDate = randomDate(60);
    const autoApprovedDate = triggerDate; // Approved instantly by smart contract
    
    return {
      claimID: generateId('CLM'),
      policyID: generateId('POL'),
      farmerID: generateId('F'),
      indexID: generateId('IDX'),
      triggerDate,
      triggerCondition: triggerConditions[i % triggerConditions.length],
      indexValue: Math.floor(Math.random() * 100) + 50, // Actual measured value
      thresholdValue: Math.floor(Math.random() * 50) + 40, // Threshold that was exceeded
      payoutAmount: Math.floor(Math.random() * 10000) + 1000,
      payoutPercent: Math.floor(Math.random() * 80) + 20,
      status,
      autoApprovedDate,
      paymentTxID: status === 'Paid' ? generateId('TX') : '',
      paymentDate: status === 'Paid' ? randomDate(30) : '',
      notes: status === 'Failed' 
        ? 'Automatic payout failed - insufficient pool balance. Retry scheduled.' 
        : status === 'Processing'
        ? 'Payout transaction in progress on blockchain'
        : status === 'Triggered'
        ? 'Claim triggered by smart contract - payout queued'
        : 'Payout completed successfully via smart contract',
    };
  });
};

/**
 * Generate mock weather data
 */
export const generateMockWeatherData = (count: number = 10): WeatherData[] => {
  const locations = [
    '1.3521,103.8198', // Singapore
    '1.4927,103.7414', 
    '1.2897,103.8501',
  ];
  const statuses: Array<'Pending' | 'Validated' | 'Rejected'> = ['Validated', 'Validated', 'Validated', 'Pending', 'Rejected'];
  
  return Array.from({ length: count }, (_, i) => ({
    dataID: generateId('WD'),
    oracleID: generateId('O'),
    location: locations[i % locations.length],
    timestamp: randomDate(30),
    temperature: Math.floor(Math.random() * 15) + 22, // 22-37°C
    rainfall: Math.floor(Math.random() * 100), // 0-100mm
    humidity: Math.floor(Math.random() * 40) + 60, // 60-100%
    dataHash: `0x${Math.random().toString(16).substr(2, 64)}`,
    status: statuses[i % statuses.length],
    submittedDate: randomDate(30),
  }));
};

/**
 * Generate mock transactions
 */
export const generateMockTransactions = (count: number = 10): Transaction[] => {
  const types = ['Premium Deposit', 'Claim Payout', 'Pool Transfer'];
  const statuses: Array<'Pending' | 'Confirmed' | 'Failed'> = ['Confirmed', 'Confirmed', 'Confirmed', 'Pending'];
  
  return Array.from({ length: count }, (_, i) => ({
    txID: generateId('TX'),
    type: types[i % types.length],
    policyID: i % 2 === 0 ? generateId('POL') : undefined,
    farmerID: generateId('F'),
    amount: Math.floor(Math.random() * 10000) + 500,
    timestamp: randomDate(60),
    status: statuses[i % statuses.length],
    blockNumber: Math.floor(Math.random() * 100000) + 10000,
  }));
};

/**
 * Generate mock dashboard stats
 */
export const generateMockDashboardStats = (): DashboardStats => ({
  totalFarmers: Math.floor(Math.random() * 1000) + 500,
  activePolicies: Math.floor(Math.random() * 500) + 200,
  triggeredClaims: Math.floor(Math.random() * 50) + 5,
  totalPayouts: Math.floor(Math.random() * 500000) + 100000,
  poolBalance: Math.floor(Math.random() * 1000000) + 500000,
  recentTransactions: generateMockTransactions(5),
});

/**
 * Simulate API delay
 */
export const mockDelay = (ms: number = 500) => new Promise(resolve => setTimeout(resolve, ms));
