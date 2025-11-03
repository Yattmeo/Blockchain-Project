package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// PolicyChaincode manages insurance policy lifecycle and operations
type PolicyChaincode struct {
	contractapi.Contract
}

// Policy represents an active insurance policy for a farmer
type Policy struct {
	PolicyID       string    `json:"policyID"`       // Unique policy identifier
	FarmerID       string    `json:"farmerID"`       // Associated farmer
	TemplateID     string    `json:"templateID"`     // Policy template used
	CoopID         string    `json:"coopID"`         // Cooperative facilitating policy
	InsurerID      string    `json:"insurerID"`      // Insurance provider
	CoverageAmount float64   `json:"coverageAmount"` // Total coverage value
	PremiumAmount  float64   `json:"premiumAmount"`  // Premium paid
	StartDate      time.Time `json:"startDate"`      // Policy start date
	EndDate        time.Time `json:"endDate"`        // Policy end date
	Status         string    `json:"status"`         // Active, Expired, Claimed, Cancelled
	FarmLocation   string    `json:"farmLocation"`   // Farm region for weather tracking
	CropType       string    `json:"cropType"`       // Type of coffee covered
	FarmSize       float64   `json:"farmSize"`       // Farm size in hectares
	PolicyTerms    string    `json:"policyTerms"`    // Terms and conditions hash
	CreatedDate    time.Time `json:"createdDate"`    // Policy creation timestamp
	CreatedBy      string    `json:"createdBy"`      // Entity that created policy
	LastUpdated    time.Time `json:"lastUpdated"`    // Last modification timestamp
	ClaimCount     int       `json:"claimCount"`     // Number of claims made
	TotalPayouts   float64   `json:"totalPayouts"`   // Total amount paid out
}

// PolicyHistory tracks policy lifecycle events
type PolicyHistory struct {
	HistoryID   string    `json:"historyID"`   // Unique history record ID
	PolicyID    string    `json:"policyID"`    // Associated policy
	Action      string    `json:"action"`      // Created, Renewed, Claimed, Cancelled, Expired
	Timestamp   time.Time `json:"timestamp"`   // When action occurred
	PerformedBy string    `json:"performedBy"` // Who performed the action
	Details     string    `json:"details"`     // Additional context
}

// ========================================
// POLICY CREATION & MANAGEMENT
// ========================================

// CreatePolicy creates a new insurance policy for a farmer
func (pc *PolicyChaincode) CreatePolicy(ctx contractapi.TransactionContextInterface,
	policyID string, farmerID string, templateID string, coopID string, insurerID string,
	coverageAmount float64, premiumAmount float64, coverageDays int,
	farmLocation string, cropType string, farmSize float64, policyTermsHash string) error {

	// Check if policy already exists
	exists, err := pc.policyExists(ctx, policyID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("policy %s already exists", policyID)
	}

	// Validate coverage amount
	if coverageAmount <= 0 {
		return fmt.Errorf("coverage amount must be positive")
	}
	if premiumAmount <= 0 {
		return fmt.Errorf("premium amount must be positive")
	}
	if coverageDays <= 0 {
		return fmt.Errorf("coverage days must be positive")
	}

	// Get caller identity
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Calculate policy dates
	startDate := timestamp
	endDate := startDate.AddDate(0, 0, coverageDays)

	// Create policy
	policy := Policy{
		PolicyID:       policyID,
		FarmerID:       farmerID,
		TemplateID:     templateID,
		CoopID:         coopID,
		InsurerID:      insurerID,
		CoverageAmount: coverageAmount,
		PremiumAmount:  premiumAmount,
		StartDate:      startDate,
		EndDate:        endDate,
		Status:         "Active",
		FarmLocation:   farmLocation,
		CropType:       cropType,
		FarmSize:       farmSize,
		PolicyTerms:    policyTermsHash,
		CreatedDate:    timestamp,
		CreatedBy:      callerID,
		LastUpdated:    timestamp,
		ClaimCount:     0,
		TotalPayouts:   0,
	}

	policyJSON, err := json.Marshal(policy)
	if err != nil {
		return fmt.Errorf("failed to marshal policy: %v", err)
	}

	// Store policy
	err = ctx.GetStub().PutState(policyID, policyJSON)
	if err != nil {
		return fmt.Errorf("failed to put policy: %v", err)
	}

	// Record policy creation in history
	err = pc.recordHistory(ctx, policyID, "Created", callerID,
		fmt.Sprintf("Policy created with coverage %.2f, premium %.2f", coverageAmount, premiumAmount))
	if err != nil {
		return err
	}

	return nil
}

// GetPolicy retrieves policy details by policy ID
func (pc *PolicyChaincode) GetPolicy(ctx contractapi.TransactionContextInterface,
	policyID string) (*Policy, error) {

	policyJSON, err := ctx.GetStub().GetState(policyID)
	if err != nil {
		return nil, fmt.Errorf("failed to read policy: %v", err)
	}
	if policyJSON == nil {
		return nil, fmt.Errorf("policy %s does not exist", policyID)
	}

	var policy Policy
	err = json.Unmarshal(policyJSON, &policy)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal policy: %v", err)
	}

	return &policy, nil
}

// UpdatePolicyStatus modifies policy status
func (pc *PolicyChaincode) UpdatePolicyStatus(ctx contractapi.TransactionContextInterface,
	policyID string, newStatus string) error {

	validStatuses := map[string]bool{
		"Active": true, "Expired": true, "Claimed": true, "Cancelled": true,
	}
	if !validStatuses[newStatus] {
		return fmt.Errorf("invalid status: %s", newStatus)
	}

	policy, err := pc.GetPolicy(ctx, policyID)
	if err != nil {
		return err
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	oldStatus := policy.Status
	policy.Status = newStatus
	policy.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	policyJSON, err := json.Marshal(policy)
	if err != nil {
		return fmt.Errorf("failed to marshal policy: %v", err)
	}

	err = ctx.GetStub().PutState(policyID, policyJSON)
	if err != nil {
		return fmt.Errorf("failed to update policy status: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = pc.recordHistory(ctx, policyID, "StatusChanged", callerID,
		fmt.Sprintf("Status changed from %s to %s", oldStatus, newStatus))

	return err
}

// RenewPolicy extends policy coverage period
func (pc *PolicyChaincode) RenewPolicy(ctx contractapi.TransactionContextInterface,
	policyID string, additionalDays int, additionalPremium float64) error {

	policy, err := pc.GetPolicy(ctx, policyID)
	if err != nil {
		return err
	}

	if policy.Status != "Active" && policy.Status != "Expired" {
		return fmt.Errorf("cannot renew policy with status: %s", policy.Status)
	}

	if additionalDays <= 0 {
		return fmt.Errorf("additional days must be positive")
	}
	if additionalPremium <= 0 {
		return fmt.Errorf("additional premium must be positive")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	// Extend end date
	policy.EndDate = policy.EndDate.AddDate(0, 0, additionalDays)
	policy.PremiumAmount += additionalPremium
	policy.Status = "Active"
	policy.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	policyJSON, err := json.Marshal(policy)
	if err != nil {
		return fmt.Errorf("failed to marshal policy: %v", err)
	}

	err = ctx.GetStub().PutState(policyID, policyJSON)
	if err != nil {
		return fmt.Errorf("failed to renew policy: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = pc.recordHistory(ctx, policyID, "Renewed", callerID,
		fmt.Sprintf("Policy renewed for %d days with premium %.2f", additionalDays, additionalPremium))

	return err
}

// CancelPolicy terminates an active policy
func (pc *PolicyChaincode) CancelPolicy(ctx contractapi.TransactionContextInterface,
	policyID string, reason string) error {

	policy, err := pc.GetPolicy(ctx, policyID)
	if err != nil {
		return err
	}

	if policy.Status != "Active" {
		return fmt.Errorf("can only cancel active policies")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	policy.Status = "Cancelled"
	policy.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	policyJSON, err := json.Marshal(policy)
	if err != nil {
		return fmt.Errorf("failed to marshal policy: %v", err)
	}

	err = ctx.GetStub().PutState(policyID, policyJSON)
	if err != nil {
		return fmt.Errorf("failed to cancel policy: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = pc.recordHistory(ctx, policyID, "Cancelled", callerID, reason)

	return err
}

// ========================================
// POLICY CLAIMS & PAYOUTS
// ========================================

// RecordClaim updates policy with claim information
func (pc *PolicyChaincode) RecordClaim(ctx contractapi.TransactionContextInterface,
	policyID string, payoutAmount float64) error {

	policy, err := pc.GetPolicy(ctx, policyID)
	if err != nil {
		return err
	}

	if policy.Status != "Active" {
		return fmt.Errorf("cannot claim on non-active policy")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	policy.ClaimCount++
	policy.TotalPayouts += payoutAmount
	policy.Status = "Claimed"
	policy.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	policyJSON, err := json.Marshal(policy)
	if err != nil {
		return fmt.Errorf("failed to marshal policy: %v", err)
	}

	err = ctx.GetStub().PutState(policyID, policyJSON)
	if err != nil {
		return fmt.Errorf("failed to record claim: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = pc.recordHistory(ctx, policyID, "Claimed", callerID,
		fmt.Sprintf("Claim processed with payout %.2f", payoutAmount))

	return err
}

// ClaimHistorySummary represents claim history data
type ClaimHistorySummary struct {
	ClaimCount   int     `json:"claimCount"`
	TotalPayouts float64 `json:"totalPayouts"`
}

// GetPolicyClaimHistory retrieves claim count and total payouts
func (pc *PolicyChaincode) GetPolicyClaimHistory(ctx contractapi.TransactionContextInterface,
	policyID string) (*ClaimHistorySummary, error) {

	policy, err := pc.GetPolicy(ctx, policyID)
	if err != nil {
		return nil, err
	}

	return &ClaimHistorySummary{
		ClaimCount:   policy.ClaimCount,
		TotalPayouts: policy.TotalPayouts,
	}, nil
}

// ========================================
// POLICY QUERIES
// ========================================

// GetPoliciesByFarmer retrieves all policies for a specific farmer
func (pc *PolicyChaincode) GetPoliciesByFarmer(ctx contractapi.TransactionContextInterface,
	farmerID string) ([]*Policy, error) {

	queryString := fmt.Sprintf(`{"selector":{"farmerID":"%s"}}`, farmerID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query policies by farmer: %v", err)
	}
	defer resultsIterator.Close()

	var policies []*Policy
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var policy Policy
		err = json.Unmarshal(queryResponse.Value, &policy)
		if err != nil {
			return nil, err
		}
		policies = append(policies, &policy)
	}

	return policies, nil
}

// GetPoliciesByRegion retrieves all policies in a geographic area
func (pc *PolicyChaincode) GetPoliciesByRegion(ctx contractapi.TransactionContextInterface,
	region string) ([]*Policy, error) {

	queryString := fmt.Sprintf(`{"selector":{"farmLocation":"%s"}}`, region)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query policies by region: %v", err)
	}
	defer resultsIterator.Close()

	var policies []*Policy
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var policy Policy
		err = json.Unmarshal(queryResponse.Value, &policy)
		if err != nil {
			return nil, err
		}
		policies = append(policies, &policy)
	}

	return policies, nil
}

// GetActivePolicies retrieves all currently active policies
func (pc *PolicyChaincode) GetActivePolicies(ctx contractapi.TransactionContextInterface) ([]*Policy, error) {
	queryString := `{"selector":{"status":"Active"}}`
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query active policies: %v", err)
	}
	defer resultsIterator.Close()

	var policies []*Policy
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var policy Policy
		err = json.Unmarshal(queryResponse.Value, &policy)
		if err != nil {
			return nil, err
		}
		policies = append(policies, &policy)
	}

	return policies, nil
}

// GetPoliciesByInsurer retrieves all policies from a specific insurer
func (pc *PolicyChaincode) GetPoliciesByInsurer(ctx contractapi.TransactionContextInterface,
	insurerID string) ([]*Policy, error) {

	queryString := fmt.Sprintf(`{"selector":{"insurerID":"%s"}}`, insurerID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query policies by insurer: %v", err)
	}
	defer resultsIterator.Close()

	var policies []*Policy
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var policy Policy
		err = json.Unmarshal(queryResponse.Value, &policy)
		if err != nil {
			return nil, err
		}
		policies = append(policies, &policy)
	}

	return policies, nil
}

// GetExpiredPolicies retrieves policies that have expired
func (pc *PolicyChaincode) GetExpiredPolicies(ctx contractapi.TransactionContextInterface) ([]*Policy, error) {
	// Get all active policies first
	activePolicies, err := pc.GetActivePolicies(ctx)
	if err != nil {
		return nil, err
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	currentTime := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	var expiredPolicies []*Policy

	// Check which ones have passed end date
	for _, policy := range activePolicies {
		if currentTime.After(policy.EndDate) {
			// Update status to expired
			policy.Status = "Expired"
			policy.LastUpdated = currentTime

			policyJSON, err := json.Marshal(policy)
			if err != nil {
				continue
			}

			err = ctx.GetStub().PutState(policy.PolicyID, policyJSON)
			if err != nil {
				continue
			}

			expiredPolicies = append(expiredPolicies, policy)
		}
	}

	return expiredPolicies, nil
}

// ========================================
// POLICY HISTORY & AUDIT
// ========================================

// recordHistory logs a policy lifecycle event
func (pc *PolicyChaincode) recordHistory(ctx contractapi.TransactionContextInterface,
	policyID string, action string, performedBy string, details string) error {

	txID := ctx.GetStub().GetTxID()

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	history := PolicyHistory{
		HistoryID:   txID,
		PolicyID:    policyID,
		Action:      action,
		Timestamp:   time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)),
		PerformedBy: performedBy,
		Details:     details,
	}

	historyJSON, err := json.Marshal(history)
	if err != nil {
		return fmt.Errorf("failed to marshal history: %v", err)
	}

	err = ctx.GetStub().PutState("HISTORY_"+txID, historyJSON)
	if err != nil {
		return fmt.Errorf("failed to put history: %v", err)
	}

	return nil
}

// GetPolicyHistory retrieves all lifecycle events for a policy
func (pc *PolicyChaincode) GetPolicyHistory(ctx contractapi.TransactionContextInterface,
	policyID string) ([]*PolicyHistory, error) {

	queryString := fmt.Sprintf(`{"selector":{"policyID":"%s"}}`, policyID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query policy history: %v", err)
	}
	defer resultsIterator.Close()

	var history []*PolicyHistory
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var record PolicyHistory
		err = json.Unmarshal(queryResponse.Value, &record)
		if err != nil {
			return nil, err
		}
		history = append(history, &record)
	}

	return history, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (pc *PolicyChaincode) policyExists(ctx contractapi.TransactionContextInterface, policyID string) (bool, error) {
	policyJSON, err := ctx.GetStub().GetState(policyID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return policyJSON != nil, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&PolicyChaincode{})
	if err != nil {
		fmt.Printf("Error creating Policy chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting Policy chaincode: %v\n", err)
	}
}
