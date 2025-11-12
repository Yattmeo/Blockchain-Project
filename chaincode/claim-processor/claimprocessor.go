package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// ClaimProcessorChaincode automates claim evaluation and payout execution
type ClaimProcessorChaincode struct {
	contractapi.Contract
}

// Claim represents a processed insurance claim
type Claim struct {
	ClaimID       string    `json:"claimID"`       // Unique claim identifier
	PolicyID      string    `json:"policyID"`      // Associated policy
	FarmerID      string    `json:"farmerID"`      // Farmer receiving payout
	IndexID       string    `json:"indexID"`       // Weather index that triggered
	TriggerDate   time.Time `json:"triggerDate"`   // When conditions were met
	PayoutAmount  float64   `json:"payoutAmount"`  // Calculated payout
	PayoutPercent float64   `json:"payoutPercent"` // Percentage of coverage
	Status        string    `json:"status"`        // Pending, Approved, Paid, Rejected
	ApprovedBy    string    `json:"approvedBy"`    // Approver identity
	ProcessedDate time.Time `json:"processedDate"` // When claim was processed
	PaymentTxID   string    `json:"paymentTxID"`   // Payment transaction reference
	Notes         string    `json:"notes"`         // Additional information
}

// ========================================
// CLAIM EVALUATION
// ========================================

// EvaluatePolicy checks if policy meets payout conditions
func (cp *ClaimProcessorChaincode) EvaluatePolicy(ctx contractapi.TransactionContextInterface,
	claimID string, policyID string, indexID string, payoutPercent float64) (bool, error) {

	// Check if claim already exists
	exists, err := cp.claimExists(ctx, claimID)
	if err != nil {
		return false, err
	}
	if exists {
		return false, fmt.Errorf("claim %s already exists", claimID)
	}

	// Verify payout percentage is valid
	if payoutPercent < 0 || payoutPercent > 100 {
		return false, fmt.Errorf("invalid payout percentage: %.2f", payoutPercent)
	}

	// Check if policy is active (would query PolicyChaincode in production)
	// For now, we'll assume policy validation is done externally

	return true, nil
}

// TriggerPayout automatically initiates payout transaction
func (cp *ClaimProcessorChaincode) TriggerPayout(ctx contractapi.TransactionContextInterface,
	claimID string, policyID string, farmerID string, indexID string,
	coverageAmount float64, payoutPercent float64) error {

	// Calculate payout amount
	payoutAmount := coverageAmount * (payoutPercent / 100.0)

	if payoutAmount <= 0 {
		return fmt.Errorf("payout amount must be positive")
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get deterministic timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Create claim record
	claim := Claim{
		ClaimID:       claimID,
		PolicyID:      policyID,
		FarmerID:      farmerID,
		IndexID:       indexID,
		TriggerDate:   timestamp,
		PayoutAmount:  payoutAmount,
		PayoutPercent: payoutPercent,
		Status:        "Pending",
		ApprovedBy:    "",
		ProcessedDate: timestamp,
		PaymentTxID:   "",
		Notes:         fmt.Sprintf("Auto-triggered by index %s", indexID),
	}

	claimJSON, err := json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimID, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to store claim: %v", err)
	}

	// In production, this would trigger PremiumPoolChaincode.ExecutePayout
	// For now, we mark it as approved
	claim.Status = "Approved"
	claim.ApprovedBy = callerID

	claimJSON, err = json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal updated claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimID, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to update claim: %v", err)
	}

	return nil
}

// CalculatePayoutAmount computes payout based on severity
func (cp *ClaimProcessorChaincode) CalculatePayoutAmount(ctx contractapi.TransactionContextInterface,
	coverageAmount float64, severity string) (float64, error) {

	var payoutPercent float64

	switch severity {
	case "Mild":
		payoutPercent = 25.0
	case "Moderate":
		payoutPercent = 50.0
	case "Severe":
		payoutPercent = 100.0
	default:
		return 0, fmt.Errorf("invalid severity: %s", severity)
	}

	payoutAmount := coverageAmount * (payoutPercent / 100.0)
	return payoutAmount, nil
}

// ========================================
// CLAIM MANAGEMENT
// ========================================

// GetClaim retrieves claim details
func (cp *ClaimProcessorChaincode) GetClaim(ctx contractapi.TransactionContextInterface,
	claimID string) (*Claim, error) {

	claimJSON, err := ctx.GetStub().GetState(claimID)
	if err != nil {
		return nil, fmt.Errorf("failed to read claim: %v", err)
	}
	if claimJSON == nil {
		return nil, fmt.Errorf("claim %s does not exist", claimID)
	}

	var claim Claim
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal claim: %v", err)
	}

	return &claim, nil
}

// ApproveClaim marks claim as approved for payment
func (cp *ClaimProcessorChaincode) ApproveClaim(ctx contractapi.TransactionContextInterface,
	claimID string) error {

	claim, err := cp.GetClaim(ctx, claimID)
	if err != nil {
		return err
	}

	if claim.Status != "Pending" {
		return fmt.Errorf("can only approve pending claims")
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get deterministic timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	claim.Status = "Approved"
	claim.ApprovedBy = callerID
	claim.ProcessedDate = timestamp

	claimJSON, err := json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimID, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to approve claim: %v", err)
	}

	return nil
}

// RecordPayment updates claim with payment transaction ID
func (cp *ClaimProcessorChaincode) RecordPayment(ctx contractapi.TransactionContextInterface,
	claimID string, paymentTxID string) error {

	claim, err := cp.GetClaim(ctx, claimID)
	if err != nil {
		return err
	}

	if claim.Status != "Approved" {
		return fmt.Errorf("can only record payment for approved claims")
	}

	// Get deterministic timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	claim.Status = "Paid"
	claim.PaymentTxID = paymentTxID
	claim.ProcessedDate = timestamp

	claimJSON, err := json.Marshal(claim)
	if err != nil {
		return fmt.Errorf("failed to marshal claim: %v", err)
	}

	err = ctx.GetStub().PutState(claimID, claimJSON)
	if err != nil {
		return fmt.Errorf("failed to record payment: %v", err)
	}

	return nil
}

// PreventDuplicateClaim ensures single payout per triggering event
func (cp *ClaimProcessorChaincode) PreventDuplicateClaim(ctx contractapi.TransactionContextInterface,
	policyID string, indexID string) (bool, error) {

	queryString := fmt.Sprintf(`{"selector":{"policyID":"%s","indexID":"%s"}}`, policyID, indexID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return false, fmt.Errorf("failed to query claims: %v", err)
	}
	defer resultsIterator.Close()

	// If any claim exists for this policy and index, it's a duplicate
	if resultsIterator.HasNext() {
		return true, nil // Duplicate found
	}

	return false, nil // No duplicate
}

// ========================================
// CLAIM QUERIES
// ========================================

// GetClaimsByPolicy retrieves all claims for a specific policy
func (cp *ClaimProcessorChaincode) GetClaimsByPolicy(ctx contractapi.TransactionContextInterface,
	policyID string) ([]*Claim, error) {

	queryString := fmt.Sprintf(`{"selector":{"policyID":"%s"}}`, policyID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query claims: %v", err)
	}
	defer resultsIterator.Close()

	var claims []*Claim
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var claim Claim
		err = json.Unmarshal(queryResponse.Value, &claim)
		if err != nil {
			return nil, err
		}
		claims = append(claims, &claim)
	}

	return claims, nil
}

// GetClaimHistory retrieves past claims for farmer
func (cp *ClaimProcessorChaincode) GetClaimHistory(ctx contractapi.TransactionContextInterface,
	farmerID string) ([]*Claim, error) {

	queryString := fmt.Sprintf(`{"selector":{"farmerID":"%s"}}`, farmerID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query claim history: %v", err)
	}
	defer resultsIterator.Close()

	var claims []*Claim
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var claim Claim
		err = json.Unmarshal(queryResponse.Value, &claim)
		if err != nil {
			return nil, err
		}
		claims = append(claims, &claim)
	}

	return claims, nil
}

// GetPendingClaims retrieves all claims awaiting approval
func (cp *ClaimProcessorChaincode) GetPendingClaims(ctx contractapi.TransactionContextInterface) ([]*Claim, error) {
	queryString := `{"selector":{"status":"Pending"}}`
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query pending claims: %v", err)
	}
	defer resultsIterator.Close()

	var claims []*Claim
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var claim Claim
		err = json.Unmarshal(queryResponse.Value, &claim)
		if err != nil {
			return nil, err
		}
		claims = append(claims, &claim)
	}

	return claims, nil
}

// GetAllClaims returns all claims in the system
func (cp *ClaimProcessorChaincode) GetAllClaims(ctx contractapi.TransactionContextInterface) ([]*Claim, error) {
	// Query all claims using an empty selector (gets everything)
	queryString := `{"selector":{}}`
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query all claims: %v", err)
	}
	defer resultsIterator.Close()

	var claims []*Claim
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var claim Claim
		err = json.Unmarshal(queryResponse.Value, &claim)
		if err != nil {
			return nil, err
		}
		claims = append(claims, &claim)
	}

	return claims, nil
}

// GenerateClaimReport creates audit trail for claim
func (cp *ClaimProcessorChaincode) GenerateClaimReport(ctx contractapi.TransactionContextInterface,
	claimID string) (string, error) {

	claim, err := cp.GetClaim(ctx, claimID)
	if err != nil {
		return "", err
	}

	report := fmt.Sprintf(`
Claim Report
============
Claim ID: %s
Policy ID: %s
Farmer ID: %s
Index ID: %s
Trigger Date: %s
Payout Amount: %.2f
Payout Percent: %.2f%%
Status: %s
Approved By: %s
Processed Date: %s
Payment Transaction: %s
Notes: %s
`,
		claim.ClaimID,
		claim.PolicyID,
		claim.FarmerID,
		claim.IndexID,
		claim.TriggerDate.Format(time.RFC3339),
		claim.PayoutAmount,
		claim.PayoutPercent,
		claim.Status,
		claim.ApprovedBy,
		claim.ProcessedDate.Format(time.RFC3339),
		claim.PaymentTxID,
		claim.Notes,
	)

	return report, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (cp *ClaimProcessorChaincode) claimExists(ctx contractapi.TransactionContextInterface, claimID string) (bool, error) {
	claimJSON, err := ctx.GetStub().GetState(claimID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return claimJSON != nil, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&ClaimProcessorChaincode{})
	if err != nil {
		fmt.Printf("Error creating ClaimProcessor chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting ClaimProcessor chaincode: %v\n", err)
	}
}
