#!/bin/bash

# Complete setup script for Weather Index Insurance Platform
# This script generates crypto material and creates the genesis block

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/usr/local/bin:$HOME/fabric-tools/fabric-samples/bin:$PATH"

cd "${SCRIPT_DIR}"

echo "========================================="
echo "Weather Index Insurance Platform"
echo "Complete Network Setup"
echo "========================================="
echo ""

# Step 1: Clean old artifacts
echo "Step 1: Cleaning old artifacts..."
rm -rf organizations
rm -rf system-genesis-block
rm -rf channel-artifacts
mkdir -p channel-artifacts
mkdir -p system-genesis-block

# Step 2: Generate crypto material
echo ""
echo "Step 2: Generating crypto material..."
cryptogen generate --config=./crypto-config.yaml --output="organizations"

if [ $? -ne 0 ]; then
    echo "Failed to generate crypto material"
    exit 1
fi

# Step 3: Create configtx.yaml for genesis block and channel creation
echo ""
echo "Step 3: Creating channel configuration..."

cat > configtx.yaml << 'EOF'
Organizations:
  - &OrdererOrg
      Name: OrdererOrg
      ID: OrdererMSP
      MSPDir: organizations/ordererOrganizations/insurance.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('OrdererMSP.member')"
          Writers:
              Type: Signature
              Rule: "OR('OrdererMSP.member')"
          Admins:
              Type: Signature
              Rule: "OR('OrdererMSP.admin')"
      OrdererEndpoints:
          - orderer.insurance.com:7050

  - &Insurer1
      Name: Insurer1MSP
      ID: Insurer1MSP
      MSPDir: organizations/peerOrganizations/insurer1.insurance.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('Insurer1MSP.admin', 'Insurer1MSP.peer', 'Insurer1MSP.client')"
          Writers:
              Type: Signature
              Rule: "OR('Insurer1MSP.admin', 'Insurer1MSP.client')"
          Admins:
              Type: Signature
              Rule: "OR('Insurer1MSP.admin')"
          Endorsement:
              Type: Signature
              Rule: "OR('Insurer1MSP.peer')"

  - &Insurer2
      Name: Insurer2MSP
      ID: Insurer2MSP
      MSPDir: organizations/peerOrganizations/insurer2.insurance.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('Insurer2MSP.admin', 'Insurer2MSP.peer', 'Insurer2MSP.client')"
          Writers:
              Type: Signature
              Rule: "OR('Insurer2MSP.admin', 'Insurer2MSP.client')"
          Admins:
              Type: Signature
              Rule: "OR('Insurer2MSP.admin')"
          Endorsement:
              Type: Signature
              Rule: "OR('Insurer2MSP.peer')"

  - &Coop
      Name: CoopMSP
      ID: CoopMSP
      MSPDir: organizations/peerOrganizations/coop.insurance.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('CoopMSP.admin', 'CoopMSP.peer', 'CoopMSP.client')"
          Writers:
              Type: Signature
              Rule: "OR('CoopMSP.admin', 'CoopMSP.client')"
          Admins:
              Type: Signature
              Rule: "OR('CoopMSP.admin')"
          Endorsement:
              Type: Signature
              Rule: "OR('CoopMSP.peer')"

  - &Platform
      Name: PlatformMSP
      ID: PlatformMSP
      MSPDir: organizations/peerOrganizations/platform.insurance.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('PlatformMSP.admin', 'PlatformMSP.peer', 'PlatformMSP.client')"
          Writers:
              Type: Signature
              Rule: "OR('PlatformMSP.admin', 'PlatformMSP.client')"
          Admins:
              Type: Signature
              Rule: "OR('PlatformMSP.admin')"
          Endorsement:
              Type: Signature
              Rule: "OR('PlatformMSP.peer')"

Capabilities:
    Channel: &ChannelCapabilities
        V2_0: true
    Orderer: &OrdererCapabilities
        V2_0: true
    Application: &ApplicationCapabilities
        V2_0: true

Application: &ApplicationDefaults
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        LifecycleEndorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"
        Endorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"
    Capabilities:
        <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
    OrdererType: etcdraft
    Addresses:
        - orderer.insurance.com:7050
    EtcdRaft:
        Consenters:
        - Host: orderer.insurance.com
          Port: 7050
          ClientTLSCert: organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/tls/server.crt
          ServerTLSCert: organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/tls/server.crt
    BatchTimeout: 2s
    BatchSize:
        MaxMessageCount: 10
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 512 KB
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"

Channel: &ChannelDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    Capabilities:
        <<: *ChannelCapabilities

Profiles:
    InsuranceOrdererGenesis:
        <<: *ChannelDefaults
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - *OrdererOrg
            Capabilities:
                <<: *OrdererCapabilities
        Consortiums:
            InsuranceConsortium:
                Organizations:
                    - *Insurer1
                    - *Insurer2
                    - *Coop
                    - *Platform

    InsuranceChannel:
        Consortium: InsuranceConsortium
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *Insurer1
                - *Insurer2
                - *Coop
                - *Platform
            Capabilities:
                <<: *ApplicationCapabilities
EOF

# Step 4: Generate genesis block
echo ""
echo "Step 4: Generating genesis block..."
configtxgen -profile InsuranceOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

if [ $? -ne 0 ]; then
    echo "Failed to generate genesis block"
    exit 1
fi

# Step 5: Generate channel configuration transaction
echo ""
echo "Step 5: Generating channel configuration transaction..."
configtxgen -profile InsuranceChannel -outputCreateChannelTx ./channel-artifacts/insurance-main.tx -channelID insurance-main

if [ $? -ne 0 ]; then
    echo "Failed to generate channel configuration transaction"
    exit 1
fi

# Step 6: Generate anchor peer updates
echo ""
echo "Step 6: Generating anchor peer updates..."
configtxgen -profile InsuranceChannel -outputAnchorPeersUpdate ./channel-artifacts/Insurer1MSPanchors.tx -channelID insurance-main -asOrg Insurer1MSP
configtxgen -profile InsuranceChannel -outputAnchorPeersUpdate ./channel-artifacts/Insurer2MSPanchors.tx -channelID insurance-main -asOrg Insurer2MSP
configtxgen -profile InsuranceChannel -outputAnchorPeersUpdate ./channel-artifacts/CoopMSPanchors.tx -channelID insurance-main -asOrg CoopMSP
configtxgen -profile InsuranceChannel -outputAnchorPeersUpdate ./channel-artifacts/PlatformMSPanchors.tx -channelID insurance-main -asOrg PlatformMSP

echo ""
echo "========================================="
echo "✅ Setup complete!"
echo "========================================="
echo ""
echo "Generated:"
echo "  ✓ Crypto material for all organizations"
echo "  ✓ Genesis block"
echo "  ✓ Channel configuration transaction"
echo "  ✓ Anchor peer updates"
echo ""
echo "Next steps:"
echo "  1. Start the network: ./network.sh up"
echo "  2. Create channel: ./network.sh createChannel"
echo "  3. Deploy chaincodes: ../scripts/deploy-all.sh"
