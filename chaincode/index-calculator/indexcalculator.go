package main

import (
	"encoding/json"
	"fmt"
	"math"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// IndexCalculatorChaincode performs mathematical computations for weather indices
type IndexCalculatorChaincode struct {
	contractapi.Contract
}

// WeatherIndex represents a calculated index for policy evaluation
type WeatherIndex struct {
	IndexID         string    `json:"indexID"`         // Unique index identifier
	Location        string    `json:"location"`        // Geographic location
	IndexType       string    `json:"indexType"`       // Rainfall, Temperature, Drought
	StartDate       time.Time `json:"startDate"`       // Measurement period start
	EndDate         time.Time `json:"endDate"`         // Measurement period end
	CalculatedValue float64   `json:"calculatedValue"` // Computed index value
	BaselineValue   float64   `json:"baselineValue"`   // Historical average
	Deviation       float64   `json:"deviation"`       // Deviation from baseline (%)
	Severity        string    `json:"severity"`        // Mild, Moderate, Severe
	PayoutTriggered bool      `json:"payoutTriggered"` // Whether payout conditions met
	CalculatedDate  time.Time `json:"calculatedDate"`  // When index was calculated
}

// RegionalBaseline stores historical average weather data
type RegionalBaseline struct {
	BaselineID     string             `json:"baselineID"`     // Unique baseline identifier
	Region         string             `json:"region"`         // Geographic region
	Season         string             `json:"season"`         // Dry, Wet, Harvest, etc.
	YearsOfData    int                `json:"yearsOfData"`    // Years included in average
	BaselineValues map[string]float64 `json:"baselineValues"` // Historical averages
	StandardDev    map[string]float64 `json:"standardDev"`    // Standard deviations
	LastUpdated    time.Time          `json:"lastUpdated"`    // Last baseline update
}

// ========================================
// RAINFALL INDEX CALCULATIONS
// ========================================

// CalculateRainfallIndex computes cumulative rainfall deviation
func (ic *IndexCalculatorChaincode) CalculateRainfallIndex(ctx contractapi.TransactionContextInterface,
	indexID string, location string, startDateStr string, endDateStr string,
	totalRainfall float64, baselineRainfall float64) error {

	// Parse dates
	startDate, err := time.Parse(time.RFC3339, startDateStr)
	if err != nil {
		return fmt.Errorf("invalid start date: %v", err)
	}
	endDate, err := time.Parse(time.RFC3339, endDateStr)
	if err != nil {
		return fmt.Errorf("invalid end date: %v", err)
	}

	// Calculate deviation percentage
	deviation := ((totalRainfall - baselineRainfall) / baselineRainfall) * 100

	// Determine severity
	severity := ic.determineSeverity("Rainfall", deviation)

	// Check if payout should be triggered (deficit > 30%)
	payoutTriggered := deviation < -30

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	index := WeatherIndex{
		IndexID:         indexID,
		Location:        location,
		IndexType:       "Rainfall",
		StartDate:       startDate,
		EndDate:         endDate,
		CalculatedValue: totalRainfall,
		BaselineValue:   baselineRainfall,
		Deviation:       deviation,
		Severity:        severity,
		PayoutTriggered: payoutTriggered,
		CalculatedDate:  timestamp,
	}

	indexJSON, err := json.Marshal(index)
	if err != nil {
		return fmt.Errorf("failed to marshal index: %v", err)
	}

	err = ctx.GetStub().PutState(indexID, indexJSON)
	if err != nil {
		return fmt.Errorf("failed to store index: %v", err)
	}

	return nil
}

// ========================================
// TEMPERATURE INDEX CALCULATIONS
// ========================================

// CalculateTemperatureIndex assesses temperature anomalies
func (ic *IndexCalculatorChaincode) CalculateTemperatureIndex(ctx contractapi.TransactionContextInterface,
	indexID string, location string, startDateStr string, endDateStr string,
	avgTemperature float64, baselineTemperature float64) error {

	startDate, err := time.Parse(time.RFC3339, startDateStr)
	if err != nil {
		return fmt.Errorf("invalid start date: %v", err)
	}
	endDate, err := time.Parse(time.RFC3339, endDateStr)
	if err != nil {
		return fmt.Errorf("invalid end date: %v", err)
	}

	// Calculate deviation
	deviation := avgTemperature - baselineTemperature

	// Determine severity
	severity := ic.determineSeverity("Temperature", deviation)

	// Trigger payout if temperature exceeds +3°C or drops below -2°C
	payoutTriggered := deviation > 3.0 || deviation < -2.0

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	index := WeatherIndex{
		IndexID:         indexID,
		Location:        location,
		IndexType:       "Temperature",
		StartDate:       startDate,
		EndDate:         endDate,
		CalculatedValue: avgTemperature,
		BaselineValue:   baselineTemperature,
		Deviation:       deviation,
		Severity:        severity,
		PayoutTriggered: payoutTriggered,
		CalculatedDate:  timestamp,
	}

	indexJSON, err := json.Marshal(index)
	if err != nil {
		return fmt.Errorf("failed to marshal index: %v", err)
	}

	err = ctx.GetStub().PutState(indexID, indexJSON)
	if err != nil {
		return fmt.Errorf("failed to store index: %v", err)
	}

	return nil
}

// ========================================
// DROUGHT INDEX CALCULATIONS
// ========================================

// CalculateDroughtIndex evaluates drought severity metrics
func (ic *IndexCalculatorChaincode) CalculateDroughtIndex(ctx contractapi.TransactionContextInterface,
	indexID string, location string, startDateStr string, endDateStr string,
	consecutiveDryDays int, thresholdDays int) error {

	startDate, err := time.Parse(time.RFC3339, startDateStr)
	if err != nil {
		return fmt.Errorf("invalid start date: %v", err)
	}
	endDate, err := time.Parse(time.RFC3339, endDateStr)
	if err != nil {
		return fmt.Errorf("invalid end date: %v", err)
	}

	// Calculate drought intensity
	droughtIntensity := float64(consecutiveDryDays) / float64(thresholdDays) * 100

	// Determine severity based on dry days
	var severity string
	if consecutiveDryDays < thresholdDays {
		severity = "None"
	} else if consecutiveDryDays < int(float64(thresholdDays)*1.5) {
		severity = "Mild"
	} else if consecutiveDryDays < int(float64(thresholdDays)*2.0) {
		severity = "Moderate"
	} else {
		severity = "Severe"
	}

	// Trigger payout if consecutive dry days exceed threshold
	payoutTriggered := consecutiveDryDays >= thresholdDays

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	index := WeatherIndex{
		IndexID:         indexID,
		Location:        location,
		IndexType:       "Drought",
		StartDate:       startDate,
		EndDate:         endDate,
		CalculatedValue: float64(consecutiveDryDays),
		BaselineValue:   float64(thresholdDays),
		Deviation:       droughtIntensity,
		Severity:        severity,
		PayoutTriggered: payoutTriggered,
		CalculatedDate:  timestamp,
	}

	indexJSON, err := json.Marshal(index)
	if err != nil {
		return fmt.Errorf("failed to marshal index: %v", err)
	}

	err = ctx.GetStub().PutState(indexID, indexJSON)
	if err != nil {
		return fmt.Errorf("failed to store index: %v", err)
	}

	return nil
}

// ========================================
// BASELINE & COMPARISON
// ========================================

// StoreRegionalBaseline maintains historical average indices
func (ic *IndexCalculatorChaincode) StoreRegionalBaseline(ctx contractapi.TransactionContextInterface,
	baselineID string, region string, season string, yearsOfData int,
	avgRainfall float64, avgTemperature float64, avgHumidity float64) error {

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	baseline := RegionalBaseline{
		BaselineID:  baselineID,
		Region:      region,
		Season:      season,
		YearsOfData: yearsOfData,
		BaselineValues: map[string]float64{
			"rainfall":    avgRainfall,
			"temperature": avgTemperature,
			"humidity":    avgHumidity,
		},
		StandardDev: map[string]float64{
			"rainfall":    avgRainfall * 0.15, // 15% std dev estimate
			"temperature": 2.0,
			"humidity":    5.0,
		},
		LastUpdated: timestamp,
	}

	baselineJSON, err := json.Marshal(baseline)
	if err != nil {
		return fmt.Errorf("failed to marshal baseline: %v", err)
	}

	err = ctx.GetStub().PutState("BASELINE_"+baselineID, baselineJSON)
	if err != nil {
		return fmt.Errorf("failed to store baseline: %v", err)
	}

	return nil
}

// GetRegionalBaseline retrieves historical averages for a region
func (ic *IndexCalculatorChaincode) GetRegionalBaseline(ctx contractapi.TransactionContextInterface,
	baselineID string) (*RegionalBaseline, error) {

	baselineJSON, err := ctx.GetStub().GetState("BASELINE_" + baselineID)
	if err != nil {
		return nil, fmt.Errorf("failed to read baseline: %v", err)
	}
	if baselineJSON == nil {
		return nil, fmt.Errorf("baseline %s does not exist", baselineID)
	}

	var baseline RegionalBaseline
	err = json.Unmarshal(baselineJSON, &baseline)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal baseline: %v", err)
	}

	return &baseline, nil
}

// CompareToBaseline compares current data against historical averages
func (ic *IndexCalculatorChaincode) CompareToBaseline(ctx contractapi.TransactionContextInterface,
	region string, season string, currentRainfall float64, currentTemperature float64) (map[string]float64, error) {

	// Query baseline for region and season
	baselineID := fmt.Sprintf("%s_%s", region, season)
	baseline, err := ic.GetRegionalBaseline(ctx, baselineID)
	if err != nil {
		return nil, fmt.Errorf("baseline not found: %v", err)
	}

	deviations := make(map[string]float64)

	// Calculate rainfall deviation percentage
	rainfallBaseline := baseline.BaselineValues["rainfall"]
	if rainfallBaseline > 0 {
		deviations["rainfall"] = ((currentRainfall - rainfallBaseline) / rainfallBaseline) * 100
	}

	// Calculate temperature deviation in degrees
	temperatureBaseline := baseline.BaselineValues["temperature"]
	deviations["temperature"] = currentTemperature - temperatureBaseline

	return deviations, nil
}

// ========================================
// SEVERITY & PAYOUT DETERMINATION
// ========================================

// DetermineSeverity classifies event severity
func (ic *IndexCalculatorChaincode) determineSeverity(indexType string, deviation float64) string {
	switch indexType {
	case "Rainfall":
		if math.Abs(deviation) < 20 {
			return "None"
		} else if math.Abs(deviation) < 40 {
			return "Mild"
		} else if math.Abs(deviation) < 60 {
			return "Moderate"
		}
		return "Severe"

	case "Temperature":
		if math.Abs(deviation) < 1.5 {
			return "None"
		} else if math.Abs(deviation) < 3.0 {
			return "Mild"
		} else if math.Abs(deviation) < 5.0 {
			return "Moderate"
		}
		return "Severe"

	default:
		return "Unknown"
	}
}

// CalculatePayoutPercentage computes graduated payout based on deviation
func (ic *IndexCalculatorChaincode) CalculatePayoutPercentage(ctx contractapi.TransactionContextInterface,
	indexType string, deviation float64, severity string) (float64, error) {

	var payoutPercent float64

	switch severity {
	case "None":
		payoutPercent = 0.0
	case "Mild":
		payoutPercent = 25.0
	case "Moderate":
		payoutPercent = 50.0
	case "Severe":
		payoutPercent = 100.0
	default:
		return 0, fmt.Errorf("unknown severity: %s", severity)
	}

	return payoutPercent, nil
}

// ValidateIndexTrigger confirms payout conditions are genuinely met
// TriggerValidation represents the result of index trigger validation
type TriggerValidation struct {
	IsTriggered   bool    `json:"isTriggered"`
	PayoutPercent float64 `json:"payoutPercent"`
}

func (ic *IndexCalculatorChaincode) ValidateIndexTrigger(ctx contractapi.TransactionContextInterface,
	indexID string, policyID string) (*TriggerValidation, error) {

	// Get the calculated index
	indexJSON, err := ctx.GetStub().GetState(indexID)
	if err != nil {
		return nil, fmt.Errorf("failed to read index: %v", err)
	}
	if indexJSON == nil {
		return nil, fmt.Errorf("index %s does not exist", indexID)
	}

	var index WeatherIndex
	err = json.Unmarshal(indexJSON, &index)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal index: %v", err)
	}

	// Check if payout is triggered
	if !index.PayoutTriggered {
		return &TriggerValidation{
			IsTriggered:   false,
			PayoutPercent: 0,
		}, nil
	}

	// Calculate payout percentage based on severity
	payoutPercent, err := ic.CalculatePayoutPercentage(ctx, index.IndexType, index.Deviation, index.Severity)
	if err != nil {
		return nil, err
	}

	return &TriggerValidation{
		IsTriggered:   true,
		PayoutPercent: payoutPercent,
	}, nil
}

// ========================================
// QUERY & RETRIEVAL
// ========================================

// GetWeatherIndex retrieves a calculated index
func (ic *IndexCalculatorChaincode) GetWeatherIndex(ctx contractapi.TransactionContextInterface,
	indexID string) (*WeatherIndex, error) {

	indexJSON, err := ctx.GetStub().GetState(indexID)
	if err != nil {
		return nil, fmt.Errorf("failed to read index: %v", err)
	}
	if indexJSON == nil {
		return nil, fmt.Errorf("index %s does not exist", indexID)
	}

	var index WeatherIndex
	err = json.Unmarshal(indexJSON, &index)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal index: %v", err)
	}

	return &index, nil
}

// GetIndicesByLocation retrieves all indices for a specific region
func (ic *IndexCalculatorChaincode) GetIndicesByLocation(ctx contractapi.TransactionContextInterface,
	location string) ([]*WeatherIndex, error) {

	queryString := fmt.Sprintf(`{"selector":{"location":"%s"}}`, location)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query indices: %v", err)
	}
	defer resultsIterator.Close()

	var indices []*WeatherIndex
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var index WeatherIndex
		err = json.Unmarshal(queryResponse.Value, &index)
		if err != nil {
			return nil, err
		}
		indices = append(indices, &index)
	}

	return indices, nil
}

// GetTriggeredIndices retrieves all indices that triggered payouts
func (ic *IndexCalculatorChaincode) GetTriggeredIndices(ctx contractapi.TransactionContextInterface) ([]*WeatherIndex, error) {
	queryString := `{"selector":{"payoutTriggered":true}}`
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query triggered indices: %v", err)
	}
	defer resultsIterator.Close()

	var indices []*WeatherIndex
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var index WeatherIndex
		err = json.Unmarshal(queryResponse.Value, &index)
		if err != nil {
			return nil, err
		}
		indices = append(indices, &index)
	}

	return indices, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&IndexCalculatorChaincode{})
	if err != nil {
		fmt.Printf("Error creating IndexCalculator chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting IndexCalculator chaincode: %v\n", err)
	}
}
