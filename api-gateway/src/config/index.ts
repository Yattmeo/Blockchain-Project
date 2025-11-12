import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const config = {
  // Server
  port: parseInt(process.env.PORT || '3001', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  apiPrefix: process.env.API_PREFIX || '/api',
  requestTimeout: parseInt(process.env.REQUEST_TIMEOUT || '30000', 10),

  // Fabric Network
  channelName: process.env.CHANNEL_NAME || 'insurance-channel',
  
  // Organization
  orgName: process.env.ORG_NAME || 'Org1',
  mspId: process.env.MSP_ID || 'Org1MSP',

  // Chaincodes
  chaincodes: {
    accessControl: process.env.CHAINCODE_ACCESS_CONTROL || 'access-control-cc',
    farmer: process.env.CHAINCODE_FARMER || 'farmer-cc',
    policyTemplate: process.env.CHAINCODE_POLICY_TEMPLATE || 'policy-template-cc',
    policy: process.env.CHAINCODE_POLICY || 'policy-cc',
    weatherOracle: process.env.CHAINCODE_WEATHER_ORACLE || 'weather-oracle-cc',
    indexCalculator: process.env.CHAINCODE_INDEX_CALCULATOR || 'index-calculator-cc',
    claimProcessor: process.env.CHAINCODE_CLAIM_PROCESSOR || 'claim-processor-cc',
    premiumPool: process.env.CHAINCODE_PREMIUM_POOL || 'premium-pool-cc',
    approvalManager: process.env.CHAINCODE_APPROVAL_MANAGER || 'approval-manager',
  },

  // Paths (relative to project root or absolute)
  connectionProfilePath: process.env.CONNECTION_PROFILE_PATH || 
    path.join(__dirname, '../../test-network/organizations/peerOrganizations/org1.example.com/connection-org1.json'),
  certificatePath: process.env.CERTIFICATE_PATH || 
    path.join(__dirname, '../../test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/cert.pem'),
  privateKeyPath: process.env.PRIVATE_KEY_PATH || 
    path.join(__dirname, '../../test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore/priv_sk'),
  tlsCertPath: process.env.TLS_CERT_PATH || 
    path.join(__dirname, '../../test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt'),

  // Gateway Peer
  gatewayPeer: process.env.GATEWAY_PEER || 'peer0.org1.example.com',
  gatewayPeerEndpoint: process.env.GATEWAY_PEER_ENDPOINT || 'localhost:7051',
  gatewayPeerHostAlias: process.env.GATEWAY_PEER_HOST_ALIAS || 'peer0.org1.example.com',

  // CORS
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:5173',

  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
};

export default config;
