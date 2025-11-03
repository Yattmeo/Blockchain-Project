package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// AuditLogChaincode provides comprehensive event logging and regulatory compliance
type AuditLogChaincode struct {
	contractapi.Contract
}

// AuditEvent represents a system event for audit trail
type AuditEvent struct {
	EventID     string                 `json:"eventID"`     // Unique event identifier
	EventType   string                 `json:"eventType"`   // PolicyCreated, ClaimProcessed, PaymentExecuted, etc.
	EntityType  string                 `json:"entityType"`  // Farmer, Policy, Claim, Transaction, etc.
	EntityID    string                 `json:"entityID"`    // ID of affected entity
	ActorID     string                 `json:"actorID"`     // Who performed the action
	ActorRole   string                 `json:"actorRole"`   // Role of actor
	Timestamp   time.Time              `json:"timestamp"`   // When event occurred
	Channel     string                 `json:"channel"`     // Which channel event occurred on
	Chaincode   string                 `json:"chaincode"`   // Which chaincode triggered event
	TxID        string                 `json:"txID"`        // Transaction ID
	Status      string                 `json:"status"`      // Success, Failed, Pending
	Details     map[string]interface{} `json:"details"`     // Event-specific data
	IPAddress   string                 `json:"ipAddress"`   // Source IP (if available)
	Notes       string                 `json:"notes"`       // Additional context
}

// ComplianceReport represents a regulatory report
type ComplianceReport struct {
	ReportID        string    `json:"reportID"`        // Unique report identifier
	ReportType      string    `json:"reportType"`      // Financial, Operational, Regulatory
	Period          string    `json:"period"`          // Reporting period
	GeneratedDate   time.Time `json:"generatedDate"`   // When report was created
	GeneratedBy     string    `json:"generatedBy"`     // Who generated report
	TotalEvents     int       `json:"totalEvents"`     // Number of events in period
	EventSummary    map[string]int `json:"eventSummary"` // Event counts by type
	ReportData      string    `json:"reportData"`      // Full report content
	Status          string    `json:"status"`          // Draft, Finalized, Submitted
}

// ========================================
// EVENT LOGGING
// ========================================

// LogEvent records a system event for audit trail
func (al *AuditLogChaincode) LogEvent(ctx contractapi.TransactionContextInterface,
	eventID string, eventType string, entityType string, entityID string,
	actorRole string, status string, detailsJSON string, notes string) error {

	// Get caller identity
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get transaction ID
	txID := ctx.GetStub().GetTxID()

	// Get channel name
	channelID := ctx.GetStub().GetChannelID()

	// Parse details JSON
	var details map[string]interface{}
	if detailsJSON != "" {
		err = json.Unmarshal([]byte(detailsJSON), &details)
		if err != nil {
			return fmt.Errorf("failed to parse details JSON: %v", err)
		}
	}

	event := AuditEvent{
		EventID:    eventID,
		EventType:  eventType,
		EntityType: entityType,
		EntityID:   entityID,
		ActorID:    callerID,
		ActorRole:  actorRole,
		Timestamp:  time.Now(),
		Channel:    channelID,
		Chaincode:  "audit-log", // Would be passed as parameter in production
		TxID:       txID,
		Status:     status,
		Details:    details,
		IPAddress:  "", // Would be captured from client request
		Notes:      notes,
	}

	eventJSON, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %v", err)
	}

	err = ctx.GetStub().PutState("EVENT_"+eventID, eventJSON)
	if err != nil {
		return fmt.Errorf("failed to store event: %v", err)
	}

	// Emit event for off-chain listeners
	err = ctx.GetStub().SetEvent("AuditEvent", eventJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// GetEvent retrieves a specific audit event
func (al *AuditLogChaincode) GetEvent(ctx contractapi.TransactionContextInterface,
	eventID string) (*AuditEvent, error) {

	eventJSON, err := ctx.GetStub().GetState("EVENT_" + eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to read event: %v", err)
	}
	if eventJSON == nil {
		return nil, fmt.Errorf("event %s does not exist", eventID)
	}

	var event AuditEvent
	err = json.Unmarshal(eventJSON, &event)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal event: %v", err)
	}

	return &event, nil
}

// ========================================
// EVENT QUERIES
// ========================================

// QueryEventsByType retrieves events of a specific category
func (al *AuditLogChaincode) QueryEventsByType(ctx contractapi.TransactionContextInterface,
	eventType string, startDate string, endDate string) ([]*AuditEvent, error) {

	start, err := time.Parse(time.RFC3339, startDate)
	if err != nil {
		return nil, fmt.Errorf("invalid start date: %v", err)
	}
	end, err := time.Parse(time.RFC3339, endDate)
	if err != nil {
		return nil, fmt.Errorf("invalid end date: %v", err)
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"eventType": "%s",
			"timestamp": {
				"$gte": "%s",
				"$lte": "%s"
			}
		}
	}`, eventType, start.Format(time.RFC3339), end.Format(time.RFC3339))

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query events: %v", err)
	}
	defer resultsIterator.Close()

	var events []*AuditEvent
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var event AuditEvent
		err = json.Unmarshal(queryResponse.Value, &event)
		if err != nil {
			return nil, err
		}
		events = append(events, &event)
	}

	return events, nil
}

// QueryEventsByEntity retrieves all events for a specific entity
func (al *AuditLogChaincode) QueryEventsByEntity(ctx contractapi.TransactionContextInterface,
	entityID string) ([]*AuditEvent, error) {

	queryString := fmt.Sprintf(`{"selector":{"entityID":"%s"}}`, entityID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query events: %v", err)
	}
	defer resultsIterator.Close()

	var events []*AuditEvent
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var event AuditEvent
		err = json.Unmarshal(queryResponse.Value, &event)
		if err != nil {
			return nil, err
		}
		events = append(events, &event)
	}

	return events, nil
}

// QueryEventsByActor retrieves all events performed by a specific actor
func (al *AuditLogChaincode) QueryEventsByActor(ctx contractapi.TransactionContextInterface,
	actorID string) ([]*AuditEvent, error) {

	queryString := fmt.Sprintf(`{"selector":{"actorID":"%s"}}`, actorID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query events: %v", err)
	}
	defer resultsIterator.Close()

	var events []*AuditEvent
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var event AuditEvent
		err = json.Unmarshal(queryResponse.Value, &event)
		if err != nil {
			return nil, err
		}
		events = append(events, &event)
	}

	return events, nil
}

// GetAuditTrail retrieves full transaction history for a policy or claim
func (al *AuditLogChaincode) GetAuditTrail(ctx contractapi.TransactionContextInterface,
	entityType string, entityID string) ([]*AuditEvent, error) {

	queryString := fmt.Sprintf(`{
		"selector": {
			"entityType": "%s",
			"entityID": "%s"
		},
		"sort": [{"timestamp": "asc"}]
	}`, entityType, entityID)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query audit trail: %v", err)
	}
	defer resultsIterator.Close()

	var events []*AuditEvent
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var event AuditEvent
		err = json.Unmarshal(queryResponse.Value, &event)
		if err != nil {
			return nil, err
		}
		events = append(events, &event)
	}

	return events, nil
}

// ========================================
// COMPLIANCE REPORTING
// ========================================

// GenerateComplianceReport creates a regulatory report
func (al *AuditLogChaincode) GenerateComplianceReport(ctx contractapi.TransactionContextInterface,
	reportID string, reportType string, period string, startDate string, endDate string) error {

	start, err := time.Parse(time.RFC3339, startDate)
	if err != nil {
		return fmt.Errorf("invalid start date: %v", err)
	}
	end, err := time.Parse(time.RFC3339, endDate)
	if err != nil {
		return fmt.Errorf("invalid end date: %v", err)
	}

	// Query all events in period
	queryString := fmt.Sprintf(`{
		"selector": {
			"timestamp": {
				"$gte": "%s",
				"$lte": "%s"
			}
		}
	}`, start.Format(time.RFC3339), end.Format(time.RFC3339))

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return fmt.Errorf("failed to query events: %v", err)
	}
	defer resultsIterator.Close()

	// Count events by type
	eventSummary := make(map[string]int)
	totalEvents := 0

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return err
		}

		var event AuditEvent
		err = json.Unmarshal(queryResponse.Value, &event)
		if err != nil {
			continue
		}

		eventSummary[event.EventType]++
		totalEvents++
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Generate report content
	reportData := fmt.Sprintf(`
Compliance Report - %s
Period: %s
Generated: %s

Total Events: %d

Event Summary:
`, reportType, period, time.Now().Format(time.RFC3339), totalEvents)

	for eventType, count := range eventSummary {
		reportData += fmt.Sprintf("  %s: %d\n", eventType, count)
	}

	report := ComplianceReport{
		ReportID:      reportID,
		ReportType:    reportType,
		Period:        period,
		GeneratedDate: time.Now(),
		GeneratedBy:   callerID,
		TotalEvents:   totalEvents,
		EventSummary:  eventSummary,
		ReportData:    reportData,
		Status:        "Finalized",
	}

	reportJSON, err := json.Marshal(report)
	if err != nil {
		return fmt.Errorf("failed to marshal report: %v", err)
	}

	err = ctx.GetStub().PutState("REPORT_"+reportID, reportJSON)
	if err != nil {
		return fmt.Errorf("failed to store report: %v", err)
	}

	return nil
}

// GetComplianceReport retrieves a regulatory report
func (al *AuditLogChaincode) GetComplianceReport(ctx contractapi.TransactionContextInterface,
	reportID string) (*ComplianceReport, error) {

	reportJSON, err := ctx.GetStub().GetState("REPORT_" + reportID)
	if err != nil {
		return nil, fmt.Errorf("failed to read report: %v", err)
	}
	if reportJSON == nil {
		return nil, fmt.Errorf("report %s does not exist", reportID)
	}

	var report ComplianceReport
	err = json.Unmarshal(reportJSON, &report)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal report: %v", err)
	}

	return &report, nil
}

// ExportLogsForRegulator produces regulatory submission data
func (al *AuditLogChaincode) ExportLogsForRegulator(ctx contractapi.TransactionContextInterface,
	startDate string, endDate string) (string, error) {

	start, err := time.Parse(time.RFC3339, startDate)
	if err != nil {
		return "", fmt.Errorf("invalid start date: %v", err)
	}
	end, err := time.Parse(time.RFC3339, endDate)
	if err != nil {
		return "", fmt.Errorf("invalid end date: %v", err)
	}

	queryString := fmt.Sprintf(`{
		"selector": {
			"timestamp": {
				"$gte": "%s",
				"$lte": "%s"
			}
		},
		"sort": [{"timestamp": "asc"}]
	}`, start.Format(time.RFC3339), end.Format(time.RFC3339))

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return "", fmt.Errorf("failed to query events: %v", err)
	}
	defer resultsIterator.Close()

	exportData := "Timestamp,EventType,EntityType,EntityID,ActorID,Status,Notes\n"

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return "", err
		}

		var event AuditEvent
		err = json.Unmarshal(queryResponse.Value, &event)
		if err != nil {
			continue
		}

		exportData += fmt.Sprintf("%s,%s,%s,%s,%s,%s,%s\n",
			event.Timestamp.Format(time.RFC3339),
			event.EventType,
			event.EntityType,
			event.EntityID,
			event.ActorID,
			event.Status,
			event.Notes,
		)
	}

	return exportData, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&AuditLogChaincode{})
	if err != nil {
		fmt.Printf("Error creating AuditLog chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting AuditLog chaincode: %v\n", err)
	}
}
