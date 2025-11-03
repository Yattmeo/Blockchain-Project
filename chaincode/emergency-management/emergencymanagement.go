package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// EmergencyManagementChaincode handles system safety and disaster recovery
type EmergencyManagementChaincode struct {
	contractapi.Contract
}

// SystemStatus represents the operational state of the platform
type SystemStatus struct {
	StatusID        string    `json:"statusID"`        // Unique status identifier
	Status          string    `json:"status"`          // Operational, Paused, Emergency, Maintenance
	PausedAt        time.Time `json:"pausedAt"`        // When system was paused
	ResumedAt       time.Time `json:"resumedAt"`       // When system was resumed
	PausedBy        string    `json:"pausedBy"`        // Who initiated pause
	PauseReason     string    `json:"pauseReason"`     // Reason for pause
	AffectedModules []string  `json:"affectedModules"` // Which chaincodes are affected
	LastUpdated     time.Time `json:"lastUpdated"`     // Last status update
}

// GovernanceProposal represents a system upgrade or change proposal
type GovernanceProposal struct {
	ProposalID      string              `json:"proposalID"`      // Unique proposal identifier
	ProposalType    string              `json:"proposalType"`    // Upgrade, ConfigChange, EmergencyAction
	Title           string              `json:"title"`           // Proposal title
	Description     string              `json:"description"`     // Detailed description
	Proposer        string              `json:"proposer"`        // Who submitted proposal
	CreatedDate     time.Time           `json:"createdDate"`     // Proposal creation date
	VotingDeadline  time.Time           `json:"votingDeadline"`  // Deadline for votes
	Status          string              `json:"status"`          // Pending, Approved, Rejected, Executed
	Votes           map[string]string   `json:"votes"`           // ValidatorID -> Vote (Approve/Reject)
	VoteCount       map[string]int      `json:"voteCount"`       // Approve/Reject counts
	RequiredVotes   int                 `json:"requiredVotes"`   // Votes needed for approval
	ExecutedDate    time.Time           `json:"executedDate"`    // When proposal was executed
	ExecutionResult string              `json:"executionResult"` // Result of execution
}

// EmergencyPayout represents a fast-tracked payout during disasters
type EmergencyPayout struct {
	PayoutID        string    `json:"payoutID"`        // Unique payout identifier
	FarmerID        string    `json:"farmerID"`        // Recipient farmer
	Amount          float64   `json:"amount"`          // Payout amount
	Reason          string    `json:"reason"`          // Emergency reason
	ApprovedBy      []string  `json:"approvedBy"`      // List of approvers
	Status          string    `json:"status"`          // Pending, Approved, Paid
	CreatedDate     time.Time `json:"createdDate"`     // When created
	ProcessedDate   time.Time `json:"processedDate"`   // When processed
	PaymentTxID     string    `json:"paymentTxID"`     // Payment transaction ID
}

// VulnerabilityReport represents a security issue report
type VulnerabilityReport struct {
	ReportID        string    `json:"reportID"`        // Unique report identifier
	ReportedBy      string    `json:"reportedBy"`      // Who reported
	Severity        string    `json:"severity"`        // Low, Medium, High, Critical
	Component       string    `json:"component"`       // Affected chaincode/module
	Description     string    `json:"description"`     // Issue description
	Status          string    `json:"status"`          // Reported, Investigating, Resolved
	ReportedDate    time.Time `json:"reportedDate"`    // When reported
	ResolvedDate    time.Time `json:"resolvedDate"`    // When resolved
	Resolution      string    `json:"resolution"`      // How issue was resolved
}

// ========================================
// SYSTEM CONTROL
// ========================================

// InitiateEmergencyPause halts system operations during critical issues
func (em *EmergencyManagementChaincode) InitiateEmergencyPause(ctx contractapi.TransactionContextInterface,
	statusID string, reason string, affectedModules []string) error {

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Check if system is already paused
	currentStatus, err := em.getSystemStatus(ctx)
	if err == nil && (currentStatus.Status == "Paused" || currentStatus.Status == "Emergency") {
		return fmt.Errorf("system is already paused")
	}

	status := SystemStatus{
		StatusID:        statusID,
		Status:          "Emergency",
		PausedAt:        time.Now(),
		ResumedAt:       time.Time{},
		PausedBy:        callerID,
		PauseReason:     reason,
		AffectedModules: affectedModules,
		LastUpdated:     time.Now(),
	}

	statusJSON, err := json.Marshal(status)
	if err != nil {
		return fmt.Errorf("failed to marshal status: %v", err)
	}

	err = ctx.GetStub().PutState("SYSTEM_STATUS", statusJSON)
	if err != nil {
		return fmt.Errorf("failed to update system status: %v", err)
	}

	// Emit emergency event
	err = ctx.GetStub().SetEvent("EmergencyPauseInitiated", statusJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// ResumeOperations re-enables system after resolution
func (em *EmergencyManagementChaincode) ResumeOperations(ctx contractapi.TransactionContextInterface) error {
	currentStatus, err := em.getSystemStatus(ctx)
	if err != nil {
		return fmt.Errorf("failed to get system status: %v", err)
	}

	if currentStatus.Status != "Paused" && currentStatus.Status != "Emergency" {
		return fmt.Errorf("system is not paused")
	}

	currentStatus.Status = "Operational"
	currentStatus.ResumedAt = time.Now()
	currentStatus.LastUpdated = time.Now()

	statusJSON, err := json.Marshal(currentStatus)
	if err != nil {
		return fmt.Errorf("failed to marshal status: %v", err)
	}

	err = ctx.GetStub().PutState("SYSTEM_STATUS", statusJSON)
	if err != nil {
		return fmt.Errorf("failed to update system status: %v", err)
	}

	// Emit resume event
	err = ctx.GetStub().SetEvent("OperationsResumed", statusJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// GetSystemStatus queries operational state
func (em *EmergencyManagementChaincode) GetSystemStatus(ctx contractapi.TransactionContextInterface) (*SystemStatus, error) {
	return em.getSystemStatus(ctx)
}

// ========================================
// GOVERNANCE & VOTING
// ========================================

// ProposeSystemUpgrade submits a governance proposal
func (em *EmergencyManagementChaincode) ProposeSystemUpgrade(ctx contractapi.TransactionContextInterface,
	proposalID string, proposalType string, title string, description string, votingDays int) error {

	// Check if proposal already exists
	exists, err := em.proposalExists(ctx, proposalID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("proposal %s already exists", proposalID)
	}

	validTypes := map[string]bool{"Upgrade": true, "ConfigChange": true, "EmergencyAction": true}
	if !validTypes[proposalType] {
		return fmt.Errorf("invalid proposal type: %s", proposalType)
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	votingDeadline := time.Now().AddDate(0, 0, votingDays)

	proposal := GovernanceProposal{
		ProposalID:      proposalID,
		ProposalType:    proposalType,
		Title:           title,
		Description:     description,
		Proposer:        callerID,
		CreatedDate:     time.Now(),
		VotingDeadline:  votingDeadline,
		Status:          "Pending",
		Votes:           make(map[string]string),
		VoteCount:       map[string]int{"Approve": 0, "Reject": 0},
		RequiredVotes:   3, // 2/3 of 5 validators = 3 required
		ExecutedDate:    time.Time{},
		ExecutionResult: "",
	}

	proposalJSON, err := json.Marshal(proposal)
	if err != nil {
		return fmt.Errorf("failed to marshal proposal: %v", err)
	}

	err = ctx.GetStub().PutState("PROPOSAL_"+proposalID, proposalJSON)
	if err != nil {
		return fmt.Errorf("failed to store proposal: %v", err)
	}

	// Emit proposal event
	err = ctx.GetStub().SetEvent("ProposalCreated", proposalJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// VoteOnProposal validator voting mechanism
func (em *EmergencyManagementChaincode) VoteOnProposal(ctx contractapi.TransactionContextInterface,
	proposalID string, vote string) error {

	proposal, err := em.getProposal(ctx, proposalID)
	if err != nil {
		return err
	}

	if proposal.Status != "Pending" {
		return fmt.Errorf("proposal is not open for voting")
	}

	if time.Now().After(proposal.VotingDeadline) {
		return fmt.Errorf("voting deadline has passed")
	}

	if vote != "Approve" && vote != "Reject" {
		return fmt.Errorf("invalid vote: must be Approve or Reject")
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Check if already voted
	if existingVote, exists := proposal.Votes[callerID]; exists {
		return fmt.Errorf("already voted: %s", existingVote)
	}

	// Record vote
	proposal.Votes[callerID] = vote
	proposal.VoteCount[vote]++

	// Check if proposal should be approved or rejected
	if proposal.VoteCount["Approve"] >= proposal.RequiredVotes {
		proposal.Status = "Approved"
	} else if proposal.VoteCount["Reject"] >= proposal.RequiredVotes {
		proposal.Status = "Rejected"
	}

	proposalJSON, err := json.Marshal(proposal)
	if err != nil {
		return fmt.Errorf("failed to marshal proposal: %v", err)
	}

	err = ctx.GetStub().PutState("PROPOSAL_"+proposalID, proposalJSON)
	if err != nil {
		return fmt.Errorf("failed to update proposal: %v", err)
	}

	return nil
}

// GetProposal retrieves proposal details
func (em *EmergencyManagementChaincode) GetProposal(ctx contractapi.TransactionContextInterface,
	proposalID string) (*GovernanceProposal, error) {
	return em.getProposal(ctx, proposalID)
}

// GetPendingProposals retrieves all proposals open for voting
func (em *EmergencyManagementChaincode) GetPendingProposals(ctx contractapi.TransactionContextInterface) ([]*GovernanceProposal, error) {
	queryString := `{"selector":{"status":"Pending"}}`
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query proposals: %v", err)
	}
	defer resultsIterator.Close()

	var proposals []*GovernanceProposal
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var proposal GovernanceProposal
		err = json.Unmarshal(queryResponse.Value, &proposal)
		if err != nil {
			return nil, err
		}
		proposals = append(proposals, &proposal)
	}

	return proposals, nil
}

// ========================================
// EMERGENCY PAYOUTS
// ========================================

// ExecuteEmergencyPayout fast-tracks payouts during disasters
func (em *EmergencyManagementChaincode) ExecuteEmergencyPayout(ctx contractapi.TransactionContextInterface,
	payoutID string, farmerID string, amount float64, reason string) error {

	if amount <= 0 {
		return fmt.Errorf("payout amount must be positive")
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	payout := EmergencyPayout{
		PayoutID:      payoutID,
		FarmerID:      farmerID,
		Amount:        amount,
		Reason:        reason,
		ApprovedBy:    []string{callerID},
		Status:        "Pending",
		CreatedDate:   time.Now(),
		ProcessedDate: time.Time{},
		PaymentTxID:   "",
	}

	payoutJSON, err := json.Marshal(payout)
	if err != nil {
		return fmt.Errorf("failed to marshal payout: %v", err)
	}

	err = ctx.GetStub().PutState("EMERGENCY_PAYOUT_"+payoutID, payoutJSON)
	if err != nil {
		return fmt.Errorf("failed to store emergency payout: %v", err)
	}

	// Emit emergency payout event
	err = ctx.GetStub().SetEvent("EmergencyPayoutCreated", payoutJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// ========================================
// VULNERABILITY REPORTING
// ========================================

// RecordVulnerability logs security issues for resolution
func (em *EmergencyManagementChaincode) RecordVulnerability(ctx contractapi.TransactionContextInterface,
	reportID string, severity string, component string, description string) error {

	validSeverities := map[string]bool{"Low": true, "Medium": true, "High": true, "Critical": true}
	if !validSeverities[severity] {
		return fmt.Errorf("invalid severity: %s", severity)
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	report := VulnerabilityReport{
		ReportID:     reportID,
		ReportedBy:   callerID,
		Severity:     severity,
		Component:    component,
		Description:  description,
		Status:       "Reported",
		ReportedDate: time.Now(),
		ResolvedDate: time.Time{},
		Resolution:   "",
	}

	reportJSON, err := json.Marshal(report)
	if err != nil {
		return fmt.Errorf("failed to marshal report: %v", err)
	}

	err = ctx.GetStub().PutState("VULNERABILITY_"+reportID, reportJSON)
	if err != nil {
		return fmt.Errorf("failed to store vulnerability report: %v", err)
	}

	// Emit vulnerability event
	err = ctx.GetStub().SetEvent("VulnerabilityReported", reportJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (em *EmergencyManagementChaincode) getSystemStatus(ctx contractapi.TransactionContextInterface) (*SystemStatus, error) {
	statusJSON, err := ctx.GetStub().GetState("SYSTEM_STATUS")
	if err != nil {
		return nil, fmt.Errorf("failed to read system status: %v", err)
	}
	if statusJSON == nil {
		// Initialize with operational status
		return &SystemStatus{
			StatusID:        "INIT",
			Status:          "Operational",
			PausedAt:        time.Time{},
			ResumedAt:       time.Time{},
			PausedBy:        "",
			PauseReason:     "",
			AffectedModules: []string{},
			LastUpdated:     time.Now(),
		}, nil
	}

	var status SystemStatus
	err = json.Unmarshal(statusJSON, &status)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal system status: %v", err)
	}

	return &status, nil
}

func (em *EmergencyManagementChaincode) proposalExists(ctx contractapi.TransactionContextInterface, proposalID string) (bool, error) {
	proposalJSON, err := ctx.GetStub().GetState("PROPOSAL_" + proposalID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return proposalJSON != nil, nil
}

func (em *EmergencyManagementChaincode) getProposal(ctx contractapi.TransactionContextInterface, proposalID string) (*GovernanceProposal, error) {
	proposalJSON, err := ctx.GetStub().GetState("PROPOSAL_" + proposalID)
	if err != nil {
		return nil, fmt.Errorf("failed to read proposal: %v", err)
	}
	if proposalJSON == nil {
		return nil, fmt.Errorf("proposal %s does not exist", proposalID)
	}

	var proposal GovernanceProposal
	err = json.Unmarshal(proposalJSON, &proposal)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal proposal: %v", err)
	}

	return &proposal, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&EmergencyManagementChaincode{})
	if err != nil {
		fmt.Printf("Error creating EmergencyManagement chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting EmergencyManagement chaincode: %v\n", err)
	}
}
