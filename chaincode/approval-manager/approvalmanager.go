package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// ApprovalManagerChaincode manages multi-party approval workflows
type ApprovalManagerChaincode struct {
	contractapi.Contract
}

// ApprovalRequest represents a request that requires multi-party approval
type ApprovalRequest struct {
	RequestID       string            `json:"requestID"`       // Unique request identifier
	RequestType     string            `json:"requestType"`     // Type: "FARMER_REGISTRATION", "POLICY_CREATION", etc.
	ChaincodeName   string            `json:"chaincodeName"`   // Target chaincode to invoke
	FunctionName    string            `json:"functionName"`    // Target function to call
	Arguments       []string          `json:"arguments"`       // Arguments for the function
	RequiredOrgs    []string          `json:"requiredOrgs"`    // Organizations that must approve
	Approvals       map[string]bool   `json:"approvals"`       // Map of org -> approved status
	Rejections      map[string]string `json:"rejections"`      // Map of org -> rejection reason
	Status          string            `json:"status"`          // PENDING, APPROVED, REJECTED, EXECUTED
	CreatedBy       string            `json:"createdBy"`       // Requestor identity
	CreatedAt       string            `json:"createdAt"`       // Request creation timestamp (RFC3339)
	ExecutedAt      string            `json:"executedAt"`      // Execution timestamp (RFC3339, empty if not executed)
	ExecutionResult string            `json:"executionResult"` // Result of execution
	Metadata        map[string]string `json:"metadata"`        // Additional metadata
}

// ApprovalHistory tracks approval/rejection actions
type ApprovalHistory struct {
	RequestID    string `json:"requestID"`
	Action       string `json:"action"` // APPROVE, REJECT, CREATE, EXECUTE
	Organization string `json:"organization"`
	User         string `json:"user"`
	Reason       string `json:"reason"`
	Timestamp    string `json:"timestamp"` // RFC3339 format
}

// ========================================
// INITIALIZATION
// ========================================

// InitLedger initializes the chaincode
func (am *ApprovalManagerChaincode) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("Approval Manager chaincode initialized")
	return nil
}

// ========================================
// CREATE APPROVAL REQUEST
// ========================================

// CreateApprovalRequest creates a new approval request
func (am *ApprovalManagerChaincode) CreateApprovalRequest(ctx contractapi.TransactionContextInterface,
	requestID string, requestType string, chaincodeName string, functionName string,
	argumentsJSON string, requiredOrgsJSON string, metadataJSON string) error {

	// Check if request already exists
	exists, err := am.requestExists(ctx, requestID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("approval request %s already exists", requestID)
	}

	// Parse arguments
	var arguments []string
	if err := json.Unmarshal([]byte(argumentsJSON), &arguments); err != nil {
		return fmt.Errorf("failed to parse arguments: %v", err)
	}

	// Parse required organizations
	var requiredOrgs []string
	if err := json.Unmarshal([]byte(requiredOrgsJSON), &requiredOrgs); err != nil {
		return fmt.Errorf("failed to parse required organizations: %v", err)
	}

	// Parse metadata
	var metadata map[string]string
	if metadataJSON != "" {
		if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
			return fmt.Errorf("failed to parse metadata: %v", err)
		}
	} else {
		metadata = make(map[string]string)
	}

	// Get caller identity
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).Format(time.RFC3339)

	// Create approval request
	request := ApprovalRequest{
		RequestID:       requestID,
		RequestType:     requestType,
		ChaincodeName:   chaincodeName,
		FunctionName:    functionName,
		Arguments:       arguments,
		RequiredOrgs:    requiredOrgs,
		Approvals:       make(map[string]bool),
		Rejections:      make(map[string]string),
		Status:          "PENDING",
		CreatedBy:       callerID,
		CreatedAt:       timestamp,
		ExecutedAt:      "",
		ExecutionResult: "",
		Metadata:        metadata,
	}

	// Save to ledger
	requestJSON, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %v", err)
	}

	err = ctx.GetStub().PutState(requestID, requestJSON)
	if err != nil {
		return fmt.Errorf("failed to put request to ledger: %v", err)
	}

	// Record history
	err = am.recordHistory(ctx, requestID, "CREATE", "", callerID, "Request created", timestamp)
	if err != nil {
		return fmt.Errorf("failed to record history: %v", err)
	}

	return nil
}

// ========================================
// APPROVE / REJECT REQUEST
// ========================================

// ApproveRequest approves an approval request
func (am *ApprovalManagerChaincode) ApproveRequest(ctx contractapi.TransactionContextInterface,
	requestID string, reason string) error {

	// Get the request
	request, err := am.getRequest(ctx, requestID)
	if err != nil {
		return err
	}

	// Check if request is still pending
	if request.Status != "PENDING" {
		return fmt.Errorf("request %s is not pending (status: %s)", requestID, request.Status)
	}

	// Get caller organization
	callerOrg, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get caller organization: %v", err)
	}

	// Check if caller's org is required to approve
	isRequired := false
	for _, org := range request.RequiredOrgs {
		if org == callerOrg {
			isRequired = true
			break
		}
	}
	if !isRequired {
		return fmt.Errorf("organization %s is not required to approve this request", callerOrg)
	}

	// Check if org has already approved
	if request.Approvals[callerOrg] {
		return fmt.Errorf("organization %s has already approved this request", callerOrg)
	}

	// Check if org has rejected
	if _, rejected := request.Rejections[callerOrg]; rejected {
		return fmt.Errorf("organization %s has already rejected this request", callerOrg)
	}

	// Get caller identity
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).Format(time.RFC3339)

	// Record approval
	request.Approvals[callerOrg] = true

	// Check if all required approvals are received
	allApproved := true
	for _, org := range request.RequiredOrgs {
		if !request.Approvals[org] {
			allApproved = false
			break
		}
	}

	// Update status if all approved
	if allApproved {
		request.Status = "APPROVED"
	}

	// Save updated request
	requestJSON, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %v", err)
	}

	err = ctx.GetStub().PutState(requestID, requestJSON)
	if err != nil {
		return fmt.Errorf("failed to update request: %v", err)
	}

	// Record history
	err = am.recordHistory(ctx, requestID, "APPROVE", callerOrg, callerID, reason, timestamp)
	if err != nil {
		return fmt.Errorf("failed to record history: %v", err)
	}

	return nil
}

// RejectRequest rejects an approval request
func (am *ApprovalManagerChaincode) RejectRequest(ctx contractapi.TransactionContextInterface,
	requestID string, reason string) error {

	// Get the request
	request, err := am.getRequest(ctx, requestID)
	if err != nil {
		return err
	}

	// Check if request is still pending
	if request.Status != "PENDING" && request.Status != "APPROVED" {
		return fmt.Errorf("request %s cannot be rejected (status: %s)", requestID, request.Status)
	}

	// Get caller organization
	callerOrg, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get caller organization: %v", err)
	}

	// Check if caller's org is required to approve
	isRequired := false
	for _, org := range request.RequiredOrgs {
		if org == callerOrg {
			isRequired = true
			break
		}
	}
	if !isRequired {
		return fmt.Errorf("organization %s is not authorized to reject this request", callerOrg)
	}

	// Get caller identity
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).Format(time.RFC3339)

	// Record rejection
	request.Rejections[callerOrg] = reason
	request.Status = "REJECTED"

	// Save updated request
	requestJSON, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %v", err)
	}

	err = ctx.GetStub().PutState(requestID, requestJSON)
	if err != nil {
		return fmt.Errorf("failed to update request: %v", err)
	}

	// Record history
	err = am.recordHistory(ctx, requestID, "REJECT", callerOrg, callerID, reason, timestamp)
	if err != nil {
		return fmt.Errorf("failed to record history: %v", err)
	}

	return nil
}

// ========================================
// EXECUTE APPROVED REQUEST
// ========================================

// ExecuteApprovedRequest executes an approved request by invoking the target chaincode
func (am *ApprovalManagerChaincode) ExecuteApprovedRequest(ctx contractapi.TransactionContextInterface,
	requestID string) error {

	// Get the request
	request, err := am.getRequest(ctx, requestID)
	if err != nil {
		return err
	}

	// Check if request is approved
	if request.Status != "APPROVED" {
		return fmt.Errorf("request %s is not approved (status: %s)", requestID, request.Status)
	}

	// Get timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)).Format(time.RFC3339)

	// Invoke the target chaincode
	channel := ctx.GetStub().GetChannelID()
	invokeArgs := make([][]byte, len(request.Arguments)+1)
	invokeArgs[0] = []byte(request.FunctionName)
	for i, arg := range request.Arguments {
		invokeArgs[i+1] = []byte(arg)
	}

	response := ctx.GetStub().InvokeChaincode(request.ChaincodeName, invokeArgs, channel)

	// Get caller identity for history
	callerID, _ := ctx.GetClientIdentity().GetID()

	// Update request status
	request.Status = "EXECUTED"
	request.ExecutedAt = timestamp

	if response.Status != 200 {
		request.ExecutionResult = fmt.Sprintf("FAILED: %s", response.Message)
	} else {
		request.ExecutionResult = fmt.Sprintf("SUCCESS: %s", string(response.Payload))
	}

	// Save updated request
	requestJSON, err := json.Marshal(request)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %v", err)
	}

	err = ctx.GetStub().PutState(requestID, requestJSON)
	if err != nil {
		return fmt.Errorf("failed to update request: %v", err)
	}

	// Record history
	err = am.recordHistory(ctx, requestID, "EXECUTE", "", callerID, request.ExecutionResult, timestamp)
	if err != nil {
		return fmt.Errorf("failed to record history: %v", err)
	}

	// Return error if execution failed
	if response.Status != 200 {
		return fmt.Errorf("execution failed: %s", response.Message)
	}

	return nil
}

// ========================================
// QUERY FUNCTIONS
// ========================================

// GetApprovalRequest retrieves an approval request by ID
func (am *ApprovalManagerChaincode) GetApprovalRequest(ctx contractapi.TransactionContextInterface,
	requestID string) (*ApprovalRequest, error) {
	return am.getRequest(ctx, requestID)
}

// GetPendingApprovals retrieves all pending approval requests
func (am *ApprovalManagerChaincode) GetPendingApprovals(ctx contractapi.TransactionContextInterface) ([]*ApprovalRequest, error) {
	return am.queryRequestsByStatus(ctx, "PENDING")
}

// GetApprovalsByStatus retrieves approval requests by status
func (am *ApprovalManagerChaincode) GetApprovalsByStatus(ctx contractapi.TransactionContextInterface,
	status string) ([]*ApprovalRequest, error) {
	return am.queryRequestsByStatus(ctx, status)
}

// GetApprovalHistory retrieves approval history for a request
func (am *ApprovalManagerChaincode) GetApprovalHistory(ctx contractapi.TransactionContextInterface,
	requestID string) ([]*ApprovalHistory, error) {

	// Query history entries
	historyKey := fmt.Sprintf("HISTORY_%s", requestID)
	resultsIterator, err := ctx.GetStub().GetStateByPartialCompositeKey("ApprovalHistory", []string{historyKey})
	if err != nil {
		return nil, fmt.Errorf("failed to get history: %v", err)
	}
	defer resultsIterator.Close()

	var history []*ApprovalHistory
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %v", err)
		}

		var entry ApprovalHistory
		err = json.Unmarshal(queryResponse.Value, &entry)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal history: %v", err)
		}

		history = append(history, &entry)
	}

	return history, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

// requestExists checks if a request exists
func (am *ApprovalManagerChaincode) requestExists(ctx contractapi.TransactionContextInterface, requestID string) (bool, error) {
	requestJSON, err := ctx.GetStub().GetState(requestID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return requestJSON != nil, nil
}

// getRequest retrieves a request from the ledger
func (am *ApprovalManagerChaincode) getRequest(ctx contractapi.TransactionContextInterface, requestID string) (*ApprovalRequest, error) {
	requestJSON, err := ctx.GetStub().GetState(requestID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if requestJSON == nil {
		return nil, fmt.Errorf("approval request %s does not exist", requestID)
	}

	var request ApprovalRequest
	err = json.Unmarshal(requestJSON, &request)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal request: %v", err)
	}

	return &request, nil
}

// queryRequestsByStatus retrieves requests by status
func (am *ApprovalManagerChaincode) queryRequestsByStatus(ctx contractapi.TransactionContextInterface, status string) ([]*ApprovalRequest, error) {
	// For simplicity, we'll iterate through all requests and filter
	// In production, consider using CouchDB indexes for better performance

	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get state: %v", err)
	}
	defer resultsIterator.Close()

	var requests []*ApprovalRequest
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %v", err)
		}

		// Skip history entries
		if len(queryResponse.Key) > 8 && queryResponse.Key[:8] == "HISTORY_" {
			continue
		}

		var request ApprovalRequest
		err = json.Unmarshal(queryResponse.Value, &request)
		if err != nil {
			// Skip if not a valid request
			continue
		}

		if request.Status == status {
			requests = append(requests, &request)
		}
	}

	return requests, nil
}

// recordHistory records an approval history entry
func (am *ApprovalManagerChaincode) recordHistory(ctx contractapi.TransactionContextInterface,
	requestID string, action string, organization string, user string, reason string, timestamp string) error {

	history := ApprovalHistory{
		RequestID:    requestID,
		Action:       action,
		Organization: organization,
		User:         user,
		Reason:       reason,
		Timestamp:    timestamp,
	}

	// Parse timestamp to get nanoseconds for unique key
	ts, err := time.Parse(time.RFC3339, timestamp)
	if err != nil {
		// Fallback to current time if parsing fails
		ts = time.Now()
	}

	// Create composite key for history
	historyKey := fmt.Sprintf("HISTORY_%s_%d", requestID, ts.UnixNano())

	historyJSON, err := json.Marshal(history)
	if err != nil {
		return fmt.Errorf("failed to marshal history: %v", err)
	}

	err = ctx.GetStub().PutState(historyKey, historyJSON)
	if err != nil {
		return fmt.Errorf("failed to put history to ledger: %v", err)
	}

	return nil
}

// ========================================
// MAIN FUNCTION
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&ApprovalManagerChaincode{})
	if err != nil {
		fmt.Printf("Error creating approval manager chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting approval manager chaincode: %v\n", err)
	}
}
