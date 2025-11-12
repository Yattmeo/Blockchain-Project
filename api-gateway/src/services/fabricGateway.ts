import * as grpc from '@grpc/grpc-js';
import { connect, Gateway, Identity, Signer, signers } from '@hyperledger/fabric-gateway';
import * as crypto from 'crypto';
import { promises as fs } from 'fs';
import * as path from 'path';
import config from '../config';
import logger from '../utils/logger';

// Organization configuration for multi-org support
interface OrgConfig {
  mspId: string;
  peerEndpoint: string;
  peerHostAlias: string;
  certPath: string;
  keyPath: string;
  tlsCertPath: string;
}

const ORG_CONFIGS: Record<string, OrgConfig> = {
  'Insurer1': {
    mspId: 'Insurer1MSP',
    peerEndpoint: 'localhost:7051',
    peerHostAlias: 'peer0.insurer1.insurance.com',
    certPath: '../network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/signcerts/User1@insurer1.insurance.com-cert.pem',
    keyPath: '../network/organizations/peerOrganizations/insurer1.insurance.com/users/User1@insurer1.insurance.com/msp/keystore/priv_sk',
    tlsCertPath: '../network/organizations/peerOrganizations/insurer1.insurance.com/peers/peer0.insurer1.insurance.com/tls/ca.crt',
  },
  'Insurer2': {
    mspId: 'Insurer2MSP',
    peerEndpoint: 'localhost:8051',
    peerHostAlias: 'peer0.insurer2.insurance.com',
    certPath: '../network/organizations/peerOrganizations/insurer2.insurance.com/users/User1@insurer2.insurance.com/msp/signcerts/User1@insurer2.insurance.com-cert.pem',
    keyPath: '../network/organizations/peerOrganizations/insurer2.insurance.com/users/User1@insurer2.insurance.com/msp/keystore/priv_sk',
    tlsCertPath: '../network/organizations/peerOrganizations/insurer2.insurance.com/peers/peer0.insurer2.insurance.com/tls/ca.crt',
  },
  'Coop': {
    mspId: 'CoopMSP',
    peerEndpoint: 'localhost:9051',
    peerHostAlias: 'peer0.coop.insurance.com',
    certPath: '../network/organizations/peerOrganizations/coop.insurance.com/users/User1@coop.insurance.com/msp/signcerts/User1@coop.insurance.com-cert.pem',
    keyPath: '../network/organizations/peerOrganizations/coop.insurance.com/users/User1@coop.insurance.com/msp/keystore/priv_sk',
    tlsCertPath: '../network/organizations/peerOrganizations/coop.insurance.com/peers/peer0.coop.insurance.com/tls/ca.crt',
  },
  'Platform': {
    mspId: 'PlatformMSP',
    peerEndpoint: 'localhost:10051',
    peerHostAlias: 'peer0.platform.insurance.com',
    certPath: '../network/organizations/peerOrganizations/platform.insurance.com/users/User1@platform.insurance.com/msp/signcerts/User1@platform.insurance.com-cert.pem',
    keyPath: '../network/organizations/peerOrganizations/platform.insurance.com/users/User1@platform.insurance.com/msp/keystore/priv_sk',
    tlsCertPath: '../network/organizations/peerOrganizations/platform.insurance.com/peers/peer0.platform.insurance.com/tls/ca.crt',
  },
};

class FabricGatewayService {
  private gateways: Map<string, Gateway> = new Map();
  private clients: Map<string, grpc.Client> = new Map();
  private currentOrg: string = 'Insurer1'; // Default organization

  /**
   * Set the current organization context
   */
  setOrganization(orgName: string): void {
    if (!ORG_CONFIGS[orgName]) {
      logger.warn(`Unknown organization: ${orgName}, using Insurer1`);
      this.currentOrg = 'Insurer1';
    } else {
      this.currentOrg = orgName;
      logger.debug(`Switched to organization: ${orgName}`);
    }
  }

  /**
   * Get current organization
   */
  getCurrentOrg(): string {
    return this.currentOrg;
  }

  /**
   * Initialize connection to Fabric Gateway for a specific organization
   */
  async connectOrg(orgName: string): Promise<void> {
    // Return if already connected
    if (this.gateways.has(orgName)) {
      return;
    }

    try {
      logger.info(`Connecting to Fabric network as ${orgName}...`);

      const orgConfig = ORG_CONFIGS[orgName];
      if (!orgConfig) {
        throw new Error(`Unknown organization: ${orgName}`);
      }

      // Resolve paths relative to api-gateway directory
      const basePath = path.resolve(__dirname, '../..');
      const tlsCertPath = path.resolve(basePath, orgConfig.tlsCertPath);
      const certPath = path.resolve(basePath, orgConfig.certPath);
      const keyPath = path.resolve(basePath, orgConfig.keyPath);

      // Read TLS certificate
      const tlsRootCert = await fs.readFile(tlsCertPath);

      // Create gRPC client
      const client = await this.newGrpcConnection(
        tlsRootCert,
        orgConfig.peerEndpoint,
        orgConfig.peerHostAlias
      );

      // Get identity and signer
      const identity = await this.newIdentity(certPath, orgConfig.mspId);
      const signer = await this.newSigner(keyPath);

      // Connect to gateway
      const gateway = connect({
        client,
        identity,
        signer,
        evaluateOptions: () => ({ deadline: Date.now() + 5000 }), // 5 seconds
        endorseOptions: () => ({ deadline: Date.now() + 15000 }), // 15 seconds
        submitOptions: () => ({ deadline: Date.now() + 5000 }), // 5 seconds
        commitStatusOptions: () => ({ deadline: Date.now() + 60000 }), // 1 minute
      });

      this.gateways.set(orgName, gateway);
      this.clients.set(orgName, client);

      logger.info(`Successfully connected to Fabric Gateway as ${orgName}`);
    } catch (error) {
      logger.error(`Failed to connect to Fabric Gateway as ${orgName}:`, error);
      throw error;
    }
  }

  /**
   * Initialize connection to Fabric Gateway (default organization)
   */
  async connect(): Promise<void> {
    // Connect all organizations on startup
    const orgs = Object.keys(ORG_CONFIGS);
    await Promise.all(orgs.map(org => this.connectOrg(org)));
    logger.info(`Connected to Fabric network for all ${orgs.length} organizations`);
  }

  /**
   * Create new gRPC connection
   */
  private async newGrpcConnection(
    tlsCertPem: Buffer,
    peerEndpoint: string,
    peerHostAlias: string
  ): Promise<grpc.Client> {
    const tlsCredentials = grpc.credentials.createSsl(tlsCertPem);
    
    return new grpc.Client(peerEndpoint, tlsCredentials, {
      'grpc.ssl_target_name_override': peerHostAlias,
    });
  }

  /**
   * Create identity from certificate
   */
  private async newIdentity(certPath: string, mspId: string): Promise<Identity> {
    const certPem = await fs.readFile(certPath);
    return {
      mspId,
      credentials: certPem,
    };
  }

  /**
   * Create signer from private key
   */
  private async newSigner(keyPath: string): Promise<Signer> {
    const privateKeyPem = await fs.readFile(keyPath);
    const privateKey = crypto.createPrivateKey(privateKeyPem);
    return signers.newPrivateKeySigner(privateKey);
  }

  /**
   * Get network (channel) for current organization
   */
  getNetwork() {
    const gateway = this.gateways.get(this.currentOrg);
    if (!gateway) {
      throw new Error(`Gateway not connected for ${this.currentOrg}. Call connect() first.`);
    }
    return gateway.getNetwork(config.channelName);
  }

  /**
   * Get contract (chaincode)
   */
  getContract(chaincodeName: string) {
    const network = this.getNetwork();
    return network.getContract(chaincodeName);
  }

  /**
   * Submit transaction (write to ledger)
   * Service discovery will automatically find and use the correct endorsing peers
   * based on the chaincode's endorsement policy and anchor peer configuration
   */
  async submitTransaction(
    chaincodeName: string,
    transactionName: string,
    ...args: string[]
  ): Promise<any> {
    try {
      const contract = this.getContract(chaincodeName);
      
      logger.info(`Submitting transaction: ${chaincodeName}.${transactionName}`, {
        args: args.length,
        currentOrg: this.currentOrg,
      });

      // Use Fabric Gateway's automatic service discovery for all chaincodes
      // Now that anchor peers are configured, discovery will work properly
      const resultBytes = await contract.submitTransaction(transactionName, ...args);
      const resultJson = this.utf8Decoder.decode(resultBytes);

      logger.info(`Transaction ${transactionName} submitted successfully`);
      
      return resultJson ? JSON.parse(resultJson) : null;
    } catch (error) {
      logger.error(`Failed to submit transaction ${transactionName}:`, error);
      throw error;
    }
  }

  /**
   * Evaluate transaction (read from ledger)
   */
  async evaluateTransaction(
    chaincodeName: string,
    transactionName: string,
    ...args: string[]
  ): Promise<any> {
    try {
      const contract = this.getContract(chaincodeName);
      
      logger.debug(`Evaluating transaction: ${chaincodeName}.${transactionName}`, {
        args: args.length,
      });

      const resultBytes = await contract.evaluateTransaction(transactionName, ...args);
      const resultJson = this.utf8Decoder.decode(resultBytes);

      return resultJson ? JSON.parse(resultJson) : null;
    } catch (error) {
      logger.error(`Failed to evaluate transaction ${transactionName}:`, error);
      throw error;
    }
  }

  /**
   * Close gateway connection
   */
  async disconnect(): Promise<void> {
    // Close all gateway connections
    for (const [org, gateway] of this.gateways.entries()) {
      gateway.close();
      logger.info(`Disconnected from Fabric Gateway for ${org}`);
    }
    this.gateways.clear();

    // Close all gRPC clients
    for (const client of this.clients.values()) {
      client.close();
    }
    this.clients.clear();

    logger.info('Disconnected from all Fabric Gateways');
  }

  /**
   * UTF-8 decoder for transaction results
   */
  private utf8Decoder = new TextDecoder();
}

// Export singleton instance
export const fabricGateway = new FabricGatewayService();
export default fabricGateway;
