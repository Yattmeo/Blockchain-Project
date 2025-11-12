/**
 * Automatic Payout Service
 * 
 * Orchestrates automatic claim triggering when weather consensus is reached
 * and policy thresholds are breached.
 * 
 * Flow:
 * 1. Consensus validated with weather data
 * 2. Query all active policies in the affected region
 * 3. For each policy, check if weather data breaches thresholds
 * 4. Automatically trigger claims for breached policies
 * 5. Execute payouts from premium pool
 */

import fabricGateway from './fabricGateway';
import config from '../config';
import logger from '../utils/logger';

interface ConsensusData {
  location: string;
  timestamp: string;
  rainfall: number;
  temperature: number;
  humidity: number;
}

interface PolicyThreshold {
  indexType: string;
  metric: string;
  thresholdValue: number;
  operator: string;
  measurementDays: number;
  payoutPercent: number;
  severity: string;
}

interface Policy {
  policyID: string;
  farmerID: string;
  templateID: string;
  farmLocation: string;
  coverageAmount: number;
  status: string;
}

interface PolicyTemplate {
  templateID: string;
  indexThresholds: PolicyThreshold[];
}

/**
 * Main orchestration function - called after consensus is validated
 */
export async function processConsensusAndTriggerPayouts(
  consensusData: ConsensusData
): Promise<{
  policiesChecked: number;
  thresholdsBreached: number;
  claimsTriggered: string[];
  errors: string[];
}> {
  const result = {
    policiesChecked: 0,
    thresholdsBreached: 0,
    claimsTriggered: [] as string[],
    errors: [] as string[],
  };

  try {
    logger.info(`🔍 Checking policies for automatic payout triggers in location: ${consensusData.location}`);

    // Step 1: Get all active policies
    const activePolicies = await getActivePolicies();
    logger.info(`Found ${activePolicies.length} active policies to check`);

    // Step 2: Filter policies by location
    const locationPolicies = filterPoliciesByLocation(activePolicies, consensusData.location);
    result.policiesChecked = locationPolicies.length;
    logger.info(`${locationPolicies.length} policies in affected location`);

    if (locationPolicies.length === 0) {
      logger.info('No policies in affected location - no claims to trigger');
      return result;
    }

    // Step 3: For each policy, check thresholds
    for (const policy of locationPolicies) {
      try {
        // Get policy template with thresholds
        const template = await getPolicyTemplate(policy.templateID);
        
        if (!template.indexThresholds || template.indexThresholds.length === 0) {
          logger.warn(`Policy ${policy.policyID} has no thresholds defined`);
          continue;
        }

        // Check each threshold
        for (const threshold of template.indexThresholds) {
          const breached = checkThreshold(threshold, consensusData);
          
          if (breached) {
            result.thresholdsBreached++;
            logger.warn(`⚠️  THRESHOLD BREACHED: Policy ${policy.policyID}, ${threshold.indexType} ${threshold.operator} ${threshold.thresholdValue}`);

            // Trigger automatic claim
            const claimID = await triggerAutomaticClaim(
              policy,
              threshold,
              consensusData
            );

            if (claimID) {
              result.claimsTriggered.push(claimID);
              logger.info(`✅ Automatic claim triggered: ${claimID} for policy ${policy.policyID}`);
            }
          }
        }
      } catch (error: any) {
        const errorMsg = `Error processing policy ${policy.policyID}: ${error.message}`;
        logger.error(errorMsg);
        result.errors.push(errorMsg);
      }
    }

    // Summary log
    logger.info(`
╔════════════════════════════════════════════════════════════╗
║           Automatic Payout Processing Complete             ║
╠════════════════════════════════════════════════════════════╣
║ Location:           ${consensusData.location.padEnd(38)} ║
║ Policies Checked:   ${result.policiesChecked.toString().padEnd(38)} ║
║ Thresholds Breached: ${result.thresholdsBreached.toString().padEnd(37)} ║
║ Claims Triggered:   ${result.claimsTriggered.length.toString().padEnd(38)} ║
║ Errors:             ${result.errors.length.toString().padEnd(38)} ║
╚════════════════════════════════════════════════════════════╝
    `);

    return result;
  } catch (error: any) {
    logger.error(`Error in automatic payout processing: ${error.message}`);
    result.errors.push(error.message);
    return result;
  }
}

/**
 * Get all active policies from the blockchain
 */
async function getActivePolicies(): Promise<Policy[]> {
  try {
    const result = await fabricGateway.evaluateTransaction(
      config.chaincodes.policy,
      'GetAllPolicies'
    );

    const policies = JSON.parse(result.toString());
    
    // Filter only active policies
    return policies.filter((p: Policy) => p.status === 'Active');
  } catch (error: any) {
    logger.error(`Error getting active policies: ${error.message}`);
    throw error;
  }
}

/**
 * Filter policies by location (matches policy farmLocation with consensus location)
 */
function filterPoliciesByLocation(policies: Policy[], location: string): Policy[] {
  // Normalize location strings for comparison
  const normalizeLocation = (loc: string) => 
    loc.toLowerCase().replace(/[_\s-]/g, '');

  const normalizedConsensusLocation = normalizeLocation(location);

  return policies.filter(policy => {
    const normalizedPolicyLocation = normalizeLocation(policy.farmLocation);
    
    // Check if locations match (exact or contains)
    return normalizedPolicyLocation.includes(normalizedConsensusLocation) ||
           normalizedConsensusLocation.includes(normalizedPolicyLocation);
  });
}

/**
 * Get policy template with thresholds
 */
async function getPolicyTemplate(templateID: string): Promise<PolicyTemplate> {
  try {
    const result = await fabricGateway.evaluateTransaction(
      config.chaincodes.policyTemplate,
      'GetTemplate',
      templateID
    );

    return JSON.parse(result.toString());
  } catch (error: any) {
    logger.error(`Error getting template ${templateID}: ${error.message}`);
    throw error;
  }
}

/**
 * Check if a threshold is breached by the consensus weather data
 */
function checkThreshold(threshold: PolicyThreshold, weather: ConsensusData): boolean {
  let actualValue: number;

  // Get the relevant weather metric
  switch (threshold.indexType.toLowerCase()) {
    case 'rainfall':
      actualValue = weather.rainfall;
      break;
    case 'temperature':
      actualValue = weather.temperature;
      break;
    case 'humidity':
      actualValue = weather.humidity;
      break;
    default:
      logger.warn(`Unknown index type: ${threshold.indexType}`);
      return false;
  }

  // Compare based on operator
  switch (threshold.operator) {
    case '<':
      return actualValue < threshold.thresholdValue;
    case '>':
      return actualValue > threshold.thresholdValue;
    case '<=':
      return actualValue <= threshold.thresholdValue;
    case '>=':
      return actualValue >= threshold.thresholdValue;
    case '==':
      return Math.abs(actualValue - threshold.thresholdValue) < 0.01;
    default:
      logger.warn(`Unknown operator: ${threshold.operator}`);
      return false;
  }
}

/**
 * Trigger an automatic claim for a breached policy
 */
async function triggerAutomaticClaim(
  policy: Policy,
  threshold: PolicyThreshold,
  weather: ConsensusData
): Promise<string | null> {
  try {
    const timestamp = Date.now();
    const claimID = `CLAIM_AUTO_${policy.policyID}_${timestamp}`;

    // Calculate payout amount
    const payoutAmount = (policy.coverageAmount * threshold.payoutPercent) / 100;

    logger.info(`Triggering claim ${claimID} for ${payoutAmount} (${threshold.payoutPercent}% of ${policy.coverageAmount})`);

    // Submit transaction to claim processor
    const result = await fabricGateway.submitTransaction(
      config.chaincodes.claimProcessor,
      'TriggerPayout',
      claimID,
      policy.policyID,
      policy.farmerID,
      `WEATHER_CONSENSUS_${weather.location}_${Date.now()}`, // Weather data reference
      policy.coverageAmount.toString(),
      threshold.payoutPercent.toString()
    );

    logger.info(`Claim created: ${claimID}`);

    // Execute payout from premium pool
    await executeAutomaticPayout(
      claimID,
      policy.farmerID,
      policy.policyID,
      payoutAmount
    );

    return claimID;
  } catch (error: any) {
    logger.error(`Error triggering claim for policy ${policy.policyID}: ${error.message}`);
    throw error;
  }
}

/**
 * Execute automatic payout from premium pool
 */
async function executeAutomaticPayout(
  claimID: string,
  farmerID: string,
  policyID: string,
  amount: number
): Promise<void> {
  try {
    const txID = `TX_PAYOUT_${claimID}_${Date.now()}`;

    logger.info(`Executing automatic payout: ${txID} for ${amount}`);

    await fabricGateway.submitTransaction(
      config.chaincodes.premiumPool,
      'ExecutePayout',
      txID,
      farmerID,
      policyID,
      claimID,
      amount.toString()
    );

    logger.info(`✅ Payout executed successfully: ${txID}`);
  } catch (error: any) {
    logger.error(`Error executing payout for claim ${claimID}: ${error.message}`);
    throw error;
  }
}

export default {
  processConsensusAndTriggerPayouts,
};
