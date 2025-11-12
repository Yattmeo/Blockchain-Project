/**
 * Utility functions for parsing Hyperledger Fabric identity strings
 */

/**
 * Extract organization name from Fabric identity string
 * 
 * Fabric identity format (base64 encoded):
 * x509::<subject>::<issuer>
 * 
 * Example subject: CN=Admin@insurer1.insurance.com,OU=admin,L=San Francisco,ST=California,C=US
 * 
 * @param identity - Base64 encoded Fabric identity string or MSP ID
 * @returns Friendly organization name (e.g., "Insurer1", "Coop")
 */
export function extractOrgFromIdentity(identity: string): string {
  if (!identity) {
    return 'Unknown';
  }

  // If it's already an MSP ID (e.g., "Insurer1MSP", "CoopMSP")
  if (identity.endsWith('MSP')) {
    return identity.replace('MSP', '');
  }

  try {
    // Decode base64
    const decoded = atob(identity);
    
    // Extract organization from the identity string
    // Format: x509::CN=Admin@insurer1.insurance.com,OU=admin,...::CN=ca.insurer1.insurance.com,O=insurer1.insurance.com,...
    
    // Look for O= (Organization) field in the issuer part
    const orgMatch = decoded.match(/O=([^,]+\.insurance\.com)/);
    if (orgMatch) {
      const orgDomain = orgMatch[1]; // e.g., "insurer1.insurance.com"
      const orgName = orgDomain.split('.')[0]; // e.g., "insurer1"
      
      // Capitalize first letter
      return orgName.charAt(0).toUpperCase() + orgName.slice(1);
    }
    
    // Fallback: Look for CN= with @organization pattern
    const cnMatch = decoded.match(/CN=Admin@([^,]+)/);
    if (cnMatch) {
      const domain = cnMatch[1]; // e.g., "insurer1.insurance.com"
      const orgName = domain.split('.')[0];
      return orgName.charAt(0).toUpperCase() + orgName.slice(1);
    }
    
    return 'Unknown';
  } catch (error) {
    // If decoding fails, try to extract from the string as-is
    if (identity.toLowerCase().includes('insurer1')) {
      return 'Insurer1';
    } else if (identity.toLowerCase().includes('insurer2')) {
      return 'Insurer2';
    } else if (identity.toLowerCase().includes('coop')) {
      return 'Coop';
    } else if (identity.toLowerCase().includes('platform')) {
      return 'Platform';
    }
    
    return 'Unknown';
  }
}

/**
 * Get friendly organization name with optional "MSP" suffix
 */
export function getOrgDisplayName(identity: string, includeMSP: boolean = false): string {
  const orgName = extractOrgFromIdentity(identity);
  return includeMSP ? `${orgName}MSP` : orgName;
}
