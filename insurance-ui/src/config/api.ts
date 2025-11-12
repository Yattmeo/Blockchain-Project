// API Configuration for Hyperledger Fabric Gateway
import { API_CONFIG, APP_CONFIG, isDevMode } from './index';

// Re-export for convenience
export { API_CONFIG, APP_CONFIG, isDevMode };

// API Endpoints
export const ENDPOINTS = {
  // Access Control
  ACCESS_CONTROL: {
    REGISTER_ORG: '/access-control/register-organization',
    GET_ORG: '/access-control/organization',
    ASSIGN_ROLE: '/access-control/assign-role',
    CHECK_PERMISSION: '/access-control/check-permission',
  },

  // Farmer Management
  FARMER: {
    REGISTER: '/farmers',
    GET: '/farmers',
    UPDATE: '/farmers/update',
    LIST_BY_COOP: '/farmers/by-coop',
    LIST_BY_REGION: '/farmers/by-region',
  },

  // Policy Templates
  POLICY_TEMPLATE: {
    CREATE: '/policy-template/create',
    GET: '/policy-template',
    SET_THRESHOLD: '/policy-template/set-threshold',
    LIST: '/policy-template/list',
    ACTIVATE: '/policy-template/activate',
  },

  // Policies
  POLICY: {
    CREATE: '/policies',
    GET: '/policies',
    UPDATE_STATUS: '/policies/update-status',
    LIST_BY_FARMER: '/policies/by-farmer',
    LIST_BY_REGION: '/policies/by-region',
    LIST_ACTIVE: '/policies',  // Changed from /policies/active - uses base endpoint
    GET_CLAIM_HISTORY: '/policies/claim-history',
  },

  // Weather Oracle
  WEATHER_ORACLE: {
    // Backend route layout uses base '/weather-oracle' with RESTful subpaths
    REGISTER_PROVIDER: '/weather-oracle/register-provider', // implemented on gateway
    SUBMIT_DATA: '/weather-oracle', // POST /api/weather-oracle
    GET_DATA: '/weather-oracle', // GET /api/weather-oracle/:dataId
    GET_BY_REGION: '/weather-oracle/location', // GET /api/weather-oracle/location/:region
    VALIDATE_CONSENSUS: '/weather-oracle', // POST /api/weather-oracle/:dataId/validate
  },

  // Index Calculator
  INDEX_CALCULATOR: {
    CALCULATE_RAINFALL: '/index-calculator/calculate-rainfall',
    CALCULATE_TEMPERATURE: '/index-calculator/calculate-temperature',
    VALIDATE_TRIGGER: '/index-calculator/validate-trigger',
    GET_INDEX: '/index-calculator/index',
    GET_TRIGGERED: '/index-calculator/triggered',
  },

  // Claim Processor
  CLAIM_PROCESSOR: {
    TRIGGER_PAYOUT: '/claims', // POST /api/claims
    GET_CLAIM: '/claims', // GET /api/claims/:claimId
    LIST_ALL: '/claims', // GET /api/claims
    LIST_PENDING: '/claims/pending', // GET /api/claims/pending
    LIST_BY_FARMER: '/claims/farmer', // GET /api/claims/farmer/:farmerId
    LIST_BY_STATUS: '/claims/status', // GET /api/claims/status/:status
    APPROVE_CLAIM: '/claims/approve',
    LIST_BY_POLICY: '/claims/by-policy',
  },

  // Premium Pool
  PREMIUM_POOL: {
    // Gateway routes (see server): balance, stats, history, add, withdraw
    DEPOSIT: '/premium-pool/add', // POST /api/premium-pool/add
    EXECUTE_PAYOUT: '/premium-pool/withdraw', // POST /api/premium-pool/withdraw (maps to withdrawFunds)
    GET_BALANCE: '/premium-pool/balance', // GET /api/premium-pool/balance
    GET_TRANSACTION_HISTORY: '/premium-pool/history', // GET /api/premium-pool/history
    GET_FARMER_BALANCE: '/premium-pool/farmer-balance', // GET /api/premium-pool/farmer-balance/:farmerId (added)
  },

  // Dashboard
  DASHBOARD: {
    STATS: '/dashboard/stats',
    RECENT_TRANSACTIONS: '/dashboard/transactions',
  },

  // Approval Manager
  APPROVAL: {
    CREATE: '/approval',
    GET: '/approval',
    GET_ALL: '/approval',
    GET_PENDING: '/approval/pending',
    GET_BY_STATUS: '/approval/status',
    GET_HISTORY: '/approval',
    APPROVE: '/approval',
    REJECT: '/approval',
    EXECUTE: '/approval',
  },
};

// Chaincode Names
export const CHAINCODES = {
  ACCESS_CONTROL: 'access-control',
  FARMER: 'farmer',
  POLICY_TEMPLATE: 'policy-template',
  POLICY: 'policy',
  WEATHER_ORACLE: 'weather-oracle',
  INDEX_CALCULATOR: 'index-calculator',
  CLAIM_PROCESSOR: 'claim-processor',
  PREMIUM_POOL: 'premium-pool',
};

// Channel Name
export const CHANNEL_NAME = 'insurance-main';

// Organization MSP IDs
export const MSP_IDS = {
  INSURER1: 'Insurer1MSP',
  INSURER2: 'Insurer2MSP',
  COOP: 'CoopMSP',
  PLATFORM: 'PlatformMSP',
};
