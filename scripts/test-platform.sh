#!/bin/bash

# Test script for Weather Index Insurance Platform
# This script runs a complete end-to-end test scenario

set -e

CHANNEL_NAME="insurance-main"

echo "========================================="
echo "Weather Index Insurance Platform"
echo "End-to-End Test Script"
echo "========================================="
echo ""

# Function to invoke chaincode
invoke_cc() {
    local cc_name=$1
    local function=$2
    shift 2
    local args=("$@")
    
    echo "Invoking: ${cc_name}.${function}"
    
    # Build args string
    local args_str="["
    for arg in "${args[@]}"; do
        args_str+="\"${arg}\","
    done
    args_str="${args_str%,}]"  # Remove trailing comma
    
    docker exec cli peer chaincode invoke \
        -o orderer.insurance.com:7050 \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/insurance.com/orderers/orderer.insurance.com/msp/tlscacerts/tlsca.insurance.com-cert.pem \
        -C ${CHANNEL_NAME} \
        -n ${cc_name} \
        -c "{\"function\":\"${function}\",\"Args\":${args_str}}"
    
    echo "✓ Success"
    echo ""
    sleep 2
}

# Function to query chaincode
query_cc() {
    local cc_name=$1
    local function=$2
    shift 2
    local args=("$@")
    
    echo "Querying: ${cc_name}.${function}"
    
    # Build args string
    local args_str="["
    for arg in "${args[@]}"; do
        args_str+="\"${arg}\","
    done
    args_str="${args_str%,}]"
    
    docker exec cli peer chaincode query \
        -C ${CHANNEL_NAME} \
        -n ${cc_name} \
        -c "{\"function\":\"${function}\",\"Args\":${args_str}}"
    
    echo ""
    sleep 1
}

echo "========================================="
echo "Test 1: Register Organizations"
echo "========================================="
invoke_cc "access-control" "RegisterOrganization" \
    "ORG_TEST_INSURER" "TestInsurance Corp" "Insurer" "Insurer1MSP" "contact@testinsurance.com"

invoke_cc "access-control" "RegisterOrganization" \
    "ORG_TEST_COOP" "Test Farmers Cooperative" "Coop" "CoopMSP" "admin@testcoop.org"

echo "========================================="
echo "Test 2: Register Weather Oracle"
echo "========================================="
invoke_cc "weather-oracle" "RegisterOracleProvider" \
    "ORACLE_001" "NOAA Weather Service" "API" "[\"NOAA\",\"WeatherAPI\"]"

echo "========================================="
echo "Test 3: Register Farmer"
echo "========================================="
invoke_cc "farmer" "RegisterFarmer" \
    "FARMER_001" "John" "Doe" "ORG_TEST_COOP" \
    "+1234567890" "john.doe@email.com" "0x1234567890abcdef" \
    "14.5995" "120.9842" "Benguet" "La Trinidad" \
    "5.5" "[\"Arabica\",\"Robusta\"]" "KYC_HASH_123"

echo "========================================="
echo "Test 4: Create Policy Template"
echo "========================================="
invoke_cc "policy-template" "CreateTemplate" \
    "TEMPLATE_001" "Standard Rainfall Coverage" "Arabica" "Benguet" "Medium" \
    "180" "50000" "500"

invoke_cc "policy-template" "SetIndexThreshold" \
    "TEMPLATE_001" "Rainfall" "mm" "300" "<" "30" "50" "Moderate"

echo "========================================="
echo "Test 5: Create Insurance Policy"
echo "========================================="
invoke_cc "policy" "CreatePolicy" \
    "POLICY_001" "FARMER_001" "TEMPLATE_001" "ORG_TEST_COOP" "ORG_TEST_INSURER" \
    "25000" "1250" "180" "Benguet" "Arabica" "5.5" "POLICY_TERMS_HASH"

echo "========================================="
echo "Test 6: Deposit Premium"
echo "========================================="
invoke_cc "premium-pool" "DepositPremium" \
    "TX_PREMIUM_001" "FARMER_001" "POLICY_001" "1250"

echo "========================================="
echo "Test 7: Submit Weather Data"
echo "========================================="
# Current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

invoke_cc "weather-oracle" "SubmitWeatherData" \
    "WEATHER_001" "ORACLE_001" "Benguet" "14.5995" "120.9842" \
    "150.5" "22.3" "75.2" "12.5" "DATA_HASH_001"

echo "========================================="
echo "Test 8: Calculate Rainfall Index"
echo "========================================="
START_DATE="2025-01-01T00:00:00Z"
END_DATE="2025-10-23T00:00:00Z"

invoke_cc "index-calculator" "CalculateRainfallIndex" \
    "INDEX_001" "Benguet" "${START_DATE}" "${END_DATE}" \
    "150.5" "400.0"

echo "========================================="
echo "Test 9: Process Claim"
echo "========================================="
invoke_cc "claim-processor" "TriggerPayout" \
    "CLAIM_001" "POLICY_001" "FARMER_001" "INDEX_001" \
    "25000" "50"

echo "========================================="
echo "Test 10: Execute Payout"
echo "========================================="
invoke_cc "premium-pool" "ExecutePayout" \
    "TX_PAYOUT_001" "FARMER_001" "POLICY_001" "CLAIM_001" "12500"

echo "========================================="
echo "Test 11: Query Results"
echo "========================================="

echo "--- Farmer Details ---"
query_cc "farmer" "GetFarmerPublic" "FARMER_001"

echo "--- Policy Details ---"
query_cc "policy" "GetPolicy" "POLICY_001"

echo "--- Claim Details ---"
query_cc "claim-processor" "GetClaim" "CLAIM_001"

echo "--- Pool Balance ---"
query_cc "premium-pool" "GetPoolBalance"

echo "--- Weather Index ---"
query_cc "index-calculator" "GetWeatherIndex" "INDEX_001"

echo ""
echo "========================================="
echo "All tests completed successfully!"
echo "========================================="
echo ""
echo "Summary:"
echo "  ✓ Organizations registered"
echo "  ✓ Oracle provider registered"
echo "  ✓ Farmer registered"
echo "  ✓ Policy template created"
echo "  ✓ Policy issued"
echo "  ✓ Premium deposited"
echo "  ✓ Weather data submitted"
echo "  ✓ Index calculated"
echo "  ✓ Claim processed"
echo "  ✓ Payout executed"
echo ""
echo "Platform is functioning correctly!"
