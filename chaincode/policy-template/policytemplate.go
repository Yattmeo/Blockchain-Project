package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// PolicyTemplateChaincode manages standardized policy templates for insurance products
type PolicyTemplateChaincode struct {
	contractapi.Contract
}

// PolicyTemplate defines a reusable insurance policy structure
type PolicyTemplate struct {
	TemplateID      string           `json:"templateID"`      // Unique template identifier
	TemplateName    string           `json:"templateName"`    // Descriptive name
	CropType        string           `json:"cropType"`        // Coffee type (Arabica, Robusta, etc.)
	Region          string           `json:"region"`          // Geographic region
	RiskLevel       string           `json:"riskLevel"`       // Low, Medium, High
	CoveragePeriod  int              `json:"coveragePeriod"`  // Coverage duration in days
	PricingModel    PricingModel     `json:"pricingModel"`    // Premium calculation formula
	IndexThresholds []IndexThreshold `json:"indexThresholds"` // Payout trigger conditions
	MaxCoverage     float64          `json:"maxCoverage"`     // Maximum coverage amount
	MinPremium      float64          `json:"minPremium"`      // Minimum premium required
	Version         int              `json:"version"`         // Template version number
	Status          string           `json:"status"`          // Active, Deprecated, Draft
	CreatedBy       string           `json:"createdBy"`       // Creator organization
	CreatedDate     time.Time        `json:"createdDate"`     // Creation timestamp
	LastUpdated     time.Time        `json:"lastUpdated"`     // Last modification timestamp
}

// PricingModel defines how premiums are calculated
type PricingModel struct {
	BaseRate        float64            `json:"baseRate"`        // Base premium rate (% of coverage)
	RiskMultiplier  float64            `json:"riskMultiplier"`  // Risk adjustment factor
	FarmSizeFactor  float64            `json:"farmSizeFactor"`  // Farm size adjustment
	HistoryDiscount float64            `json:"historyDiscount"` // Discount for claim-free history
	Parameters      map[string]float64 `json:"parameters"`      // Additional pricing parameters
}

// IndexThreshold defines conditions that trigger payouts
type IndexThreshold struct {
	IndexType       string  `json:"indexType"`       // Rainfall, Temperature, Drought, etc.
	Metric          string  `json:"metric"`          // Measurement unit
	ThresholdValue  float64 `json:"thresholdValue"`  // Trigger value
	Operator        string  `json:"operator"`        // <, >, <=, >=, ==
	MeasurementDays int     `json:"measurementDays"` // Days to measure over
	PayoutPercent   float64 `json:"payoutPercent"`   // Percentage of coverage to pay
	Severity        string  `json:"severity"`        // Mild, Moderate, Severe
}

// ========================================
// TEMPLATE CREATION & MANAGEMENT
// ========================================

// CreateTemplate defines a new policy template
func (pt *PolicyTemplateChaincode) CreateTemplate(ctx contractapi.TransactionContextInterface,
	templateID string, templateName string, cropType string, region string, riskLevel string,
	coveragePeriod int, maxCoverage float64, minPremium float64) error {

	// Check if template already exists
	exists, err := pt.templateExists(ctx, templateID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("template %s already exists", templateID)
	}

	// Validate risk level
	validRiskLevels := map[string]bool{"Low": true, "Medium": true, "High": true}
	if !validRiskLevels[riskLevel] {
		return fmt.Errorf("invalid risk level: %s", riskLevel)
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

	// Create template with default pricing model
	template := PolicyTemplate{
		TemplateID:     templateID,
		TemplateName:   templateName,
		CropType:       cropType,
		Region:         region,
		RiskLevel:      riskLevel,
		CoveragePeriod: coveragePeriod,
		PricingModel: PricingModel{
			BaseRate:        0.05, // Default 5% base rate
			RiskMultiplier:  1.0,
			FarmSizeFactor:  1.0,
			HistoryDiscount: 0.0,
			Parameters:      make(map[string]float64),
		},
		IndexThresholds: []IndexThreshold{},
		MaxCoverage:     maxCoverage,
		MinPremium:      minPremium,
		Version:         1,
		Status:          "Draft",
		CreatedBy:       callerID,
		CreatedDate:     timestamp,
		LastUpdated:     timestamp,
	}

	templateJSON, err := json.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(templateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to put template: %v", err)
	}

	return nil
}

// GetTemplate retrieves template specifications
func (pt *PolicyTemplateChaincode) GetTemplate(ctx contractapi.TransactionContextInterface,
	templateID string) (*PolicyTemplate, error) {

	templateJSON, err := ctx.GetStub().GetState(templateID)
	if err != nil {
		return nil, fmt.Errorf("failed to read template: %v", err)
	}
	if templateJSON == nil {
		return nil, fmt.Errorf("template %s does not exist", templateID)
	}

	var template PolicyTemplate
	err = json.Unmarshal(templateJSON, &template)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal template: %v", err)
	}

	return &template, nil
}

// UpdateTemplate modifies template parameters
func (pt *PolicyTemplateChaincode) UpdateTemplate(ctx contractapi.TransactionContextInterface,
	templateID string, coveragePeriod int, maxCoverage float64, minPremium float64) error {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return err
	}

	// Only allow updates to Draft templates
	if template.Status != "Draft" && template.Status != "Active" {
		return fmt.Errorf("cannot update template with status: %s", template.Status)
	}

	// Update mutable fields
	if coveragePeriod > 0 {
		template.CoveragePeriod = coveragePeriod
	}
	if maxCoverage > 0 {
		template.MaxCoverage = maxCoverage
	}
	if minPremium > 0 {
		template.MinPremium = minPremium
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	template.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	templateJSON, err := json.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(templateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to update template: %v", err)
	}

	return nil
}

// ========================================
// PRICING MODEL CONFIGURATION
// ========================================

// SetPricingModel configures premium calculation formula
func (pt *PolicyTemplateChaincode) SetPricingModel(ctx contractapi.TransactionContextInterface,
	templateID string, baseRate float64, riskMultiplier float64, farmSizeFactor float64, historyDiscount float64) error {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return err
	}

	// Validate pricing parameters
	if baseRate < 0 || baseRate > 1 {
		return fmt.Errorf("base rate must be between 0 and 1")
	}
	if riskMultiplier <= 0 {
		return fmt.Errorf("risk multiplier must be positive")
	}
	if historyDiscount < 0 || historyDiscount > 1 {
		return fmt.Errorf("history discount must be between 0 and 1")
	}

	template.PricingModel.BaseRate = baseRate
	template.PricingModel.RiskMultiplier = riskMultiplier
	template.PricingModel.FarmSizeFactor = farmSizeFactor
	template.PricingModel.HistoryDiscount = historyDiscount

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	template.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	templateJSON, err := json.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(templateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to update pricing model: %v", err)
	}

	return nil
}

// AddPricingParameter adds a custom pricing parameter
func (pt *PolicyTemplateChaincode) AddPricingParameter(ctx contractapi.TransactionContextInterface,
	templateID string, paramName string, paramValue float64) error {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return err
	}

	if template.PricingModel.Parameters == nil {
		template.PricingModel.Parameters = make(map[string]float64)
	}

	template.PricingModel.Parameters[paramName] = paramValue

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	template.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	templateJSON, err := json.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(templateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to add pricing parameter: %v", err)
	}

	return nil
}

// CalculatePremium computes premium based on pricing model
func (pt *PolicyTemplateChaincode) CalculatePremium(ctx contractapi.TransactionContextInterface,
	templateID string, coverageAmount float64, farmSize float64, claimFreeYears int) (float64, error) {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return 0, err
	}

	// Base premium calculation: coverage * base rate
	basePremium := coverageAmount * template.PricingModel.BaseRate

	// Apply risk multiplier
	adjustedPremium := basePremium * template.PricingModel.RiskMultiplier

	// Apply farm size factor
	if farmSize > 0 {
		adjustedPremium *= template.PricingModel.FarmSizeFactor
	}

	// Apply claim-free history discount
	if claimFreeYears > 0 {
		discount := template.PricingModel.HistoryDiscount * float64(claimFreeYears)
		if discount > 0.3 { // Cap at 30% discount
			discount = 0.3
		}
		adjustedPremium *= (1.0 - discount)
	}

	// Ensure minimum premium
	if adjustedPremium < template.MinPremium {
		adjustedPremium = template.MinPremium
	}

	return adjustedPremium, nil
}

// ========================================
// INDEX THRESHOLD CONFIGURATION
// ========================================

// SetIndexThreshold defines trigger conditions for payouts
func (pt *PolicyTemplateChaincode) SetIndexThreshold(ctx contractapi.TransactionContextInterface,
	templateID string, indexType string, metric string, thresholdValue float64,
	operator string, measurementDays int, payoutPercent float64, severity string) error {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return err
	}

	// Validate index type
	validIndexTypes := map[string]bool{
		"Rainfall": true, "Temperature": true, "Drought": true, "Humidity": true,
	}
	if !validIndexTypes[indexType] {
		return fmt.Errorf("invalid index type: %s", indexType)
	}

	// Validate operator
	validOperators := map[string]bool{"<": true, ">": true, "<=": true, ">=": true, "==": true}
	if !validOperators[operator] {
		return fmt.Errorf("invalid operator: %s", operator)
	}

	// Validate payout percentage
	if payoutPercent < 0 || payoutPercent > 100 {
		return fmt.Errorf("payout percent must be between 0 and 100")
	}

	// Validate severity
	validSeverities := map[string]bool{"Mild": true, "Moderate": true, "Severe": true}
	if !validSeverities[severity] {
		return fmt.Errorf("invalid severity: %s", severity)
	}

	threshold := IndexThreshold{
		IndexType:       indexType,
		Metric:          metric,
		ThresholdValue:  thresholdValue,
		Operator:        operator,
		MeasurementDays: measurementDays,
		PayoutPercent:   payoutPercent,
		Severity:        severity,
	}

	template.IndexThresholds = append(template.IndexThresholds, threshold)

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	template.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	templateJSON, err := json.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(templateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to set index threshold: %v", err)
	}

	return nil
}

// GetIndexThresholds retrieves all trigger conditions for a template
func (pt *PolicyTemplateChaincode) GetIndexThresholds(ctx contractapi.TransactionContextInterface,
	templateID string) ([]IndexThreshold, error) {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return nil, err
	}

	return template.IndexThresholds, nil
}

// ========================================
// TEMPLATE VERSIONING & STATUS
// ========================================

// VersionTemplate creates a new version of an existing template
func (pt *PolicyTemplateChaincode) VersionTemplate(ctx contractapi.TransactionContextInterface,
	oldTemplateID string, newTemplateID string) error {

	// Get existing template
	oldTemplate, err := pt.GetTemplate(ctx, oldTemplateID)
	if err != nil {
		return err
	}

	// Check if new template ID already exists
	exists, err := pt.templateExists(ctx, newTemplateID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("template %s already exists", newTemplateID)
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Create new version
	newTemplate := *oldTemplate
	newTemplate.TemplateID = newTemplateID
	newTemplate.Version = oldTemplate.Version + 1
	newTemplate.Status = "Draft"
	newTemplate.CreatedDate = timestamp
	newTemplate.LastUpdated = timestamp

	templateJSON, err := json.Marshal(newTemplate)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(newTemplateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to create template version: %v", err)
	}

	// Mark old template as deprecated
	oldTemplate.Status = "Deprecated"
	oldTemplate.LastUpdated = timestamp

	oldTemplateJSON, err := json.Marshal(oldTemplate)
	if err != nil {
		return fmt.Errorf("failed to marshal old template: %v", err)
	}

	err = ctx.GetStub().PutState(oldTemplateID, oldTemplateJSON)
	if err != nil {
		return fmt.Errorf("failed to deprecate old template: %v", err)
	}

	return nil
}

// ActivateTemplate changes template status to Active
func (pt *PolicyTemplateChaincode) ActivateTemplate(ctx contractapi.TransactionContextInterface,
	templateID string) error {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return err
	}

	if template.Status != "Draft" {
		return fmt.Errorf("can only activate draft templates")
	}

	// Validate template has required configurations
	if len(template.IndexThresholds) == 0 {
		return fmt.Errorf("template must have at least one index threshold")
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	template.Status = "Active"
	template.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	templateJSON, err := json.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %v", err)
	}

	err = ctx.GetStub().PutState(templateID, templateJSON)
	if err != nil {
		return fmt.Errorf("failed to activate template: %v", err)
	}

	return nil
}

// ========================================
// TEMPLATE QUERIES
// ========================================

// ListTemplates retrieves all templates matching criteria
func (pt *PolicyTemplateChaincode) ListTemplates(ctx contractapi.TransactionContextInterface,
	region string, cropType string, riskLevel string) ([]*PolicyTemplate, error) {

	// Build query selector
	selector := make(map[string]interface{})
	if region != "" {
		selector["region"] = region
	}
	if cropType != "" {
		selector["cropType"] = cropType
	}
	if riskLevel != "" {
		selector["riskLevel"] = riskLevel
	}

	queryMap := map[string]interface{}{
		"selector": selector,
	}

	queryJSON, err := json.Marshal(queryMap)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal query: %v", err)
	}

	resultsIterator, err := ctx.GetStub().GetQueryResult(string(queryJSON))
	if err != nil {
		return nil, fmt.Errorf("failed to query templates: %v", err)
	}
	defer resultsIterator.Close()

	var templates []*PolicyTemplate
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var template PolicyTemplate
		err = json.Unmarshal(queryResponse.Value, &template)
		if err != nil {
			return nil, err
		}
		templates = append(templates, &template)
	}

	return templates, nil
}

// GetActiveTemplates retrieves all currently active templates
func (pt *PolicyTemplateChaincode) GetActiveTemplates(ctx contractapi.TransactionContextInterface) ([]*PolicyTemplate, error) {
	queryString := `{"selector":{"status":"Active"}}`
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query active templates: %v", err)
	}
	defer resultsIterator.Close()

	var templates []*PolicyTemplate
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var template PolicyTemplate
		err = json.Unmarshal(queryResponse.Value, &template)
		if err != nil {
			return nil, err
		}
		templates = append(templates, &template)
	}

	return templates, nil
}

// ValidateTemplateParameters ensures template consistency
func (pt *PolicyTemplateChaincode) ValidateTemplateParameters(ctx contractapi.TransactionContextInterface,
	templateID string) (bool, error) {

	template, err := pt.GetTemplate(ctx, templateID)
	if err != nil {
		return false, err
	}

	// Check required fields
	if template.TemplateName == "" {
		return false, fmt.Errorf("template name is required")
	}
	if template.CropType == "" {
		return false, fmt.Errorf("crop type is required")
	}
	if template.Region == "" {
		return false, fmt.Errorf("region is required")
	}
	if template.CoveragePeriod <= 0 {
		return false, fmt.Errorf("coverage period must be positive")
	}
	if template.MaxCoverage <= 0 {
		return false, fmt.Errorf("max coverage must be positive")
	}
	if len(template.IndexThresholds) == 0 {
		return false, fmt.Errorf("at least one index threshold required")
	}

	// Validate pricing model
	if template.PricingModel.BaseRate <= 0 {
		return false, fmt.Errorf("base rate must be positive")
	}
	if template.PricingModel.RiskMultiplier <= 0 {
		return false, fmt.Errorf("risk multiplier must be positive")
	}

	return true, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (pt *PolicyTemplateChaincode) templateExists(ctx contractapi.TransactionContextInterface, templateID string) (bool, error) {
	templateJSON, err := ctx.GetStub().GetState(templateID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return templateJSON != nil, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&PolicyTemplateChaincode{})
	if err != nil {
		fmt.Printf("Error creating PolicyTemplate chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting PolicyTemplate chaincode: %v\n", err)
	}
}
