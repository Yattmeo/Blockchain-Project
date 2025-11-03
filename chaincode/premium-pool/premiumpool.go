package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// PremiumPoolChaincode manages treasury and financial operations
type PremiumPoolChaincode struct {
	contractapi.Contract
}

// PremiumPool represents the main insurance fund
type PremiumPool struct {
	PoolID         string    `json:"poolID"`         // Unique pool identifier
	TotalBalance   float64   `json:"totalBalance"`   // Current pool balance
	TotalPremiums  float64   `json:"totalPremiums"`  // Cumulative premiums collected
	TotalPayouts   float64   `json:"totalPayouts"`   // Cumulative payouts made
	ReserveAmount  float64   `json:"reserveAmount"`  // Required reserve balance
	ActivePolicies int       `json:"activePolicies"` // Number of active policies
	LastUpdated    time.Time `json:"lastUpdated"`    // Last balance update
}

// Transaction represents a financial transaction
type Transaction struct {
	TxID          string    `json:"txID"`          // Unique transaction ID
	Type          string    `json:"type"`          // Premium, Payout, Contribution, Withdrawal
	FarmerID      string    `json:"farmerID"`      // Associated farmer (if applicable)
	PolicyID      string    `json:"policyID"`      // Associated policy (if applicable)
	Amount        float64   `json:"amount"`        // Transaction amount
	BalanceBefore float64   `json:"balanceBefore"` // Pool balance before transaction
	BalanceAfter  float64   `json:"balanceAfter"`  // Pool balance after transaction
	Status        string    `json:"status"`        // Completed, Pending, Failed
	Timestamp     time.Time `json:"timestamp"`     // Transaction timestamp
	InitiatedBy   string    `json:"initiatedBy"`   // Who initiated transaction
	Notes         string    `json:"notes"`         // Additional information
}

// ========================================
// PREMIUM MANAGEMENT
// ========================================

// DepositPremium records premium payment from farmer
func (pp *PremiumPoolChaincode) DepositPremium(ctx contractapi.TransactionContextInterface,
	txID string, farmerID string, policyID string, amount float64) error {

	if amount <= 0 {
		return fmt.Errorf("premium amount must be positive")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Get current pool state
	pool, err := pp.getPool(ctx)
	if err != nil {
		// Initialize pool if it doesn't exist
		pool = &PremiumPool{
			PoolID:         "MAIN_POOL",
			TotalBalance:   0,
			TotalPremiums:  0,
			TotalPayouts:   0,
			ReserveAmount:  0,
			ActivePolicies: 0,
			LastUpdated:    timestamp,
		}
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Record transaction
	transaction := Transaction{
		TxID:          txID,
		Type:          "Premium",
		FarmerID:      farmerID,
		PolicyID:      policyID,
		Amount:        amount,
		BalanceBefore: pool.TotalBalance,
		BalanceAfter:  pool.TotalBalance + amount,
		Status:        "Completed",
		Timestamp:     timestamp,
		InitiatedBy:   callerID,
		Notes:         fmt.Sprintf("Premium payment for policy %s", policyID),
	}

	txJSON, err := json.Marshal(transaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %v", err)
	}

	err = ctx.GetStub().PutState("TX_"+txID, txJSON)
	if err != nil {
		return fmt.Errorf("failed to store transaction: %v", err)
	}

	// Update pool balance
	pool.TotalBalance += amount
	pool.TotalPremiums += amount
	pool.ActivePolicies++
	pool.LastUpdated = timestamp

	poolJSON, err := json.Marshal(pool)
	if err != nil {
		return fmt.Errorf("failed to marshal pool: %v", err)
	}

	err = ctx.GetStub().PutState("POOL_MAIN", poolJSON)
	if err != nil {
		return fmt.Errorf("failed to update pool: %v", err)
	}

	return nil
}

// ========================================
// PAYOUT EXECUTION
// ========================================

// ExecutePayout transfers funds to farmer upon claim approval
func (pp *PremiumPoolChaincode) ExecutePayout(ctx contractapi.TransactionContextInterface,
	txID string, farmerID string, policyID string, claimID string, amount float64) error {

	if amount <= 0 {
		return fmt.Errorf("payout amount must be positive")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Get current pool state
	pool, err := pp.getPool(ctx)
	if err != nil {
		return fmt.Errorf("pool not initialized: %v", err)
	}

	// Check if sufficient balance
	if pool.TotalBalance < amount {
		return fmt.Errorf("insufficient pool balance: have %.2f, need %.2f", pool.TotalBalance, amount)
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Record transaction
	transaction := Transaction{
		TxID:          txID,
		Type:          "Payout",
		FarmerID:      farmerID,
		PolicyID:      policyID,
		Amount:        amount,
		BalanceBefore: pool.TotalBalance,
		BalanceAfter:  pool.TotalBalance - amount,
		Status:        "Completed",
		Timestamp:     timestamp,
		InitiatedBy:   callerID,
		Notes:         fmt.Sprintf("Payout for claim %s", claimID),
	}

	txJSON, err := json.Marshal(transaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %v", err)
	}

	err = ctx.GetStub().PutState("TX_"+txID, txJSON)
	if err != nil {
		return fmt.Errorf("failed to store transaction: %v", err)
	}

	// Update pool balance
	pool.TotalBalance -= amount
	pool.TotalPayouts += amount
	pool.LastUpdated = timestamp

	poolJSON, err := json.Marshal(pool)
	if err != nil {
		return fmt.Errorf("failed to marshal pool: %v", err)
	}

	err = ctx.GetStub().PutState("POOL_MAIN", poolJSON)
	if err != nil {
		return fmt.Errorf("failed to update pool: %v", err)
	}

	return nil
}

// ========================================
// POOL MANAGEMENT
// ========================================

// GetPoolBalance queries total funds in pool
func (pp *PremiumPoolChaincode) GetPoolBalance(ctx contractapi.TransactionContextInterface) (float64, error) {
	pool, err := pp.getPool(ctx)
	if err != nil {
		return 0, err
	}

	return pool.TotalBalance, nil
}

// CalculateReserves ensures sufficient funds for potential claims
func (pp *PremiumPoolChaincode) CalculateReserves(ctx contractapi.TransactionContextInterface,
	totalCoverage float64, riskFactor float64) error {

	// Reserve requirement: total coverage * risk factor
	requiredReserve := totalCoverage * riskFactor

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	pool, err := pp.getPool(ctx)
	if err != nil {
		return err
	}

	pool.ReserveAmount = requiredReserve
	pool.LastUpdated = timestamp

	// Check if current balance meets reserve requirement
	if pool.TotalBalance < requiredReserve {
		return fmt.Errorf("pool balance (%.2f) below required reserve (%.2f)",
			pool.TotalBalance, requiredReserve)
	}

	poolJSON, err := json.Marshal(pool)
	if err != nil {
		return fmt.Errorf("failed to marshal pool: %v", err)
	}

	err = ctx.GetStub().PutState("POOL_MAIN", poolJSON)
	if err != nil {
		return fmt.Errorf("failed to update pool reserves: %v", err)
	}

	return nil
}

// RecordContribution tracks insurer or donor contributions
func (pp *PremiumPoolChaincode) RecordContribution(ctx contractapi.TransactionContextInterface,
	txID string, contributorID string, amount float64, notes string) error {

	if amount <= 0 {
		return fmt.Errorf("contribution amount must be positive")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	pool, err := pp.getPool(ctx)
	if err != nil {
		return err
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	transaction := Transaction{
		TxID:          txID,
		Type:          "Contribution",
		FarmerID:      contributorID,
		PolicyID:      "",
		Amount:        amount,
		BalanceBefore: pool.TotalBalance,
		BalanceAfter:  pool.TotalBalance + amount,
		Status:        "Completed",
		Timestamp:     timestamp,
		InitiatedBy:   callerID,
		Notes:         notes,
	}

	txJSON, err := json.Marshal(transaction)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %v", err)
	}

	err = ctx.GetStub().PutState("TX_"+txID, txJSON)
	if err != nil {
		return fmt.Errorf("failed to store transaction: %v", err)
	}

	pool.TotalBalance += amount
	pool.LastUpdated = timestamp

	poolJSON, err := json.Marshal(pool)
	if err != nil {
		return fmt.Errorf("failed to marshal pool: %v", err)
	}

	err = ctx.GetStub().PutState("POOL_MAIN", poolJSON)
	if err != nil {
		return fmt.Errorf("failed to update pool: %v", err)
	}

	return nil
}

// ========================================
// QUERIES & REPORTING
// ========================================

// GetTransaction retrieves transaction details
func (pp *PremiumPoolChaincode) GetTransaction(ctx contractapi.TransactionContextInterface,
	txID string) (*Transaction, error) {

	txJSON, err := ctx.GetStub().GetState("TX_" + txID)
	if err != nil {
		return nil, fmt.Errorf("failed to read transaction: %v", err)
	}
	if txJSON == nil {
		return nil, fmt.Errorf("transaction %s does not exist", txID)
	}

	var transaction Transaction
	err = json.Unmarshal(txJSON, &transaction)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal transaction: %v", err)
	}

	return &transaction, nil
}

// GetTransactionHistory queries payment records
func (pp *PremiumPoolChaincode) GetTransactionHistory(ctx contractapi.TransactionContextInterface,
	farmerID string) ([]*Transaction, error) {

	queryString := fmt.Sprintf(`{"selector":{"farmerID":"%s"}}`, farmerID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query transactions: %v", err)
	}
	defer resultsIterator.Close()

	var transactions []*Transaction
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var tx Transaction
		err = json.Unmarshal(queryResponse.Value, &tx)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, &tx)
	}

	return transactions, nil
}

// GenerateFinancialReport produces audit trail for regulators
func (pp *PremiumPoolChaincode) GenerateFinancialReport(ctx contractapi.TransactionContextInterface) (string, error) {
	pool, err := pp.getPool(ctx)
	if err != nil {
		return "", err
	}

	report := fmt.Sprintf(`
Financial Report
================
Total Balance: %.2f
Total Premiums Collected: %.2f
Total Payouts Made: %.2f
Required Reserve: %.2f
Active Policies: %d
Net Position: %.2f
Reserve Coverage Ratio: %.2f%%
Last Updated: %s
`,
		pool.TotalBalance,
		pool.TotalPremiums,
		pool.TotalPayouts,
		pool.ReserveAmount,
		pool.ActivePolicies,
		pool.TotalPremiums-pool.TotalPayouts,
		(pool.TotalBalance/pool.ReserveAmount)*100,
		pool.LastUpdated.Format(time.RFC3339),
	)

	return report, nil
}

// GetFarmerBalance checks farmer's premium payment status
// FarmerBalance represents farmer's premium and payout totals
type FarmerBalance struct {
	TotalPremiums float64 `json:"totalPremiums"`
	TotalPayouts  float64 `json:"totalPayouts"`
}

func (pp *PremiumPoolChaincode) GetFarmerBalance(ctx contractapi.TransactionContextInterface,
	farmerID string) (*FarmerBalance, error) {

	queryString := fmt.Sprintf(`{"selector":{"farmerID":"%s"}}`, farmerID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query farmer transactions: %v", err)
	}
	defer resultsIterator.Close()

	var totalPremiums, totalPayouts float64

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var tx Transaction
		err = json.Unmarshal(queryResponse.Value, &tx)
		if err != nil {
			return nil, err
		}

		if tx.Type == "Premium" {
			totalPremiums += tx.Amount
		} else if tx.Type == "Payout" {
			totalPayouts += tx.Amount
		}
	}

	return &FarmerBalance{
		TotalPremiums: totalPremiums,
		TotalPayouts:  totalPayouts,
	}, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (pp *PremiumPoolChaincode) getPool(ctx contractapi.TransactionContextInterface) (*PremiumPool, error) {
	poolJSON, err := ctx.GetStub().GetState("POOL_MAIN")
	if err != nil {
		return nil, fmt.Errorf("failed to read pool: %v", err)
	}
	if poolJSON == nil {
		return nil, fmt.Errorf("pool not initialized")
	}

	var pool PremiumPool
	err = json.Unmarshal(poolJSON, &pool)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal pool: %v", err)
	}

	return &pool, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&PremiumPoolChaincode{})
	if err != nil {
		fmt.Printf("Error creating PremiumPool chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting PremiumPool chaincode: %v\n", err)
	}
}
