package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// WeatherOracleChaincode ingests, validates, and stores weather data from multiple sources
type WeatherOracleChaincode struct {
	contractapi.Contract
}

// WeatherData represents a weather observation from an oracle source
type WeatherData struct {
	DataID          string    `json:"dataID"`          // Unique data identifier
	OracleID        string    `json:"oracleID"`        // Oracle provider identifier
	Location        string    `json:"location"`        // Geographic location/region
	Latitude        float64   `json:"latitude"`        // Latitude coordinate
	Longitude       float64   `json:"longitude"`       // Longitude coordinate
	Timestamp       time.Time `json:"timestamp"`       // Observation timestamp
	Rainfall        float64   `json:"rainfall"`        // Rainfall in mm
	Temperature     float64   `json:"temperature"`     // Temperature in Celsius
	Humidity        float64   `json:"humidity"`        // Humidity percentage
	WindSpeed       float64   `json:"windSpeed"`       // Wind speed in km/h
	DataHash        string    `json:"dataHash"`        // Hash of raw data for verification
	ValidationScore float64   `json:"validationScore"` // Consensus validation score
	Status          string    `json:"status"`          // Pending, Validated, Anomalous
	SubmittedBy     string    `json:"submittedBy"`     // Oracle submitter identity
}

// OracleProvider represents an authorized weather data source
type OracleProvider struct {
	OracleID         string    `json:"oracleID"`         // Unique oracle identifier
	ProviderName     string    `json:"providerName"`     // Oracle provider name
	ProviderType     string    `json:"providerType"`     // API, Satellite, IoT, Manual
	DataSources      []string  `json:"dataSources"`      // Source APIs/systems
	ReputationScore  float64   `json:"reputationScore"`  // Trust score (0-100)
	TotalSubmissions int       `json:"totalSubmissions"` // Total data submissions
	AnomalousCount   int       `json:"anomalousCount"`   // Number of anomalous submissions
	Status           string    `json:"status"`           // Active, Suspended, Revoked
	RegisteredDate   time.Time `json:"registeredDate"`   // Registration timestamp
	LastSubmission   time.Time `json:"lastSubmission"`   // Last data submission time
}

// ConsensusRecord tracks multi-oracle consensus for a location and time
type ConsensusRecord struct {
	RecordID         string             `json:"recordID"`         // Unique consensus record ID
	Location         string             `json:"location"`         // Geographic location
	Timestamp        time.Time          `json:"timestamp"`        // Observation timestamp
	OracleCount      int                `json:"oracleCount"`      // Number of oracles submitted
	Consensus        map[string]float64 `json:"consensus"`        // Agreed weather values
	ConsensusReached bool               `json:"consensusReached"` // 2/3+ agreement reached
	CreatedDate      time.Time          `json:"createdDate"`      // Record creation timestamp
}

// ========================================
// ORACLE PROVIDER MANAGEMENT
// ========================================

// RegisterOracleProvider adds an authorized weather data source
func (wo *WeatherOracleChaincode) RegisterOracleProvider(ctx contractapi.TransactionContextInterface,
	oracleID string, providerName string, providerType string, dataSources []string) error {

	// Check if oracle already exists
	exists, err := wo.oracleExists(ctx, oracleID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("oracle %s already exists", oracleID)
	}

	// Validate provider type
	validTypes := map[string]bool{"API": true, "Satellite": true, "IoT": true, "Manual": true}
	if !validTypes[providerType] {
		return fmt.Errorf("invalid provider type: %s", providerType)
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	oracle := OracleProvider{
		OracleID:         oracleID,
		ProviderName:     providerName,
		ProviderType:     providerType,
		DataSources:      dataSources,
		ReputationScore:  100.0, // Start with perfect score
		TotalSubmissions: 0,
		AnomalousCount:   0,
		Status:           "Active",
		RegisteredDate:   timestamp,
		LastSubmission:   time.Time{},
	}

	oracleJSON, err := json.Marshal(oracle)
	if err != nil {
		return fmt.Errorf("failed to marshal oracle: %v", err)
	}

	err = ctx.GetStub().PutState("ORACLE_"+oracleID, oracleJSON)
	if err != nil {
		return fmt.Errorf("failed to put oracle: %v", err)
	}

	return nil
}

// GetOracleProvider retrieves oracle provider details
func (wo *WeatherOracleChaincode) GetOracleProvider(ctx contractapi.TransactionContextInterface,
	oracleID string) (*OracleProvider, error) {

	oracleJSON, err := ctx.GetStub().GetState("ORACLE_" + oracleID)
	if err != nil {
		return nil, fmt.Errorf("failed to read oracle: %v", err)
	}
	if oracleJSON == nil {
		return nil, fmt.Errorf("oracle %s does not exist", oracleID)
	}

	var oracle OracleProvider
	err = json.Unmarshal(oracleJSON, &oracle)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal oracle: %v", err)
	}

	return &oracle, nil
}

// GetOracleReputation retrieves the trust score for an oracle
func (wo *WeatherOracleChaincode) GetOracleReputation(ctx contractapi.TransactionContextInterface,
	oracleID string) (float64, error) {

	oracle, err := wo.GetOracleProvider(ctx, oracleID)
	if err != nil {
		return 0, err
	}

	return oracle.ReputationScore, nil
}

// UpdateOracleReputation adjusts oracle trust score
func (wo *WeatherOracleChaincode) UpdateOracleReputation(ctx contractapi.TransactionContextInterface,
	oracleID string, anomalousData bool) error {

	oracle, err := wo.GetOracleProvider(ctx, oracleID)
	if err != nil {
		return err
	}

	oracle.TotalSubmissions++
	if anomalousData {
		oracle.AnomalousCount++
	}

	// Calculate reputation: (total - anomalous) / total * 100
	if oracle.TotalSubmissions > 0 {
		successRate := float64(oracle.TotalSubmissions-oracle.AnomalousCount) / float64(oracle.TotalSubmissions)
		oracle.ReputationScore = successRate * 100
	}

	// Suspend oracle if reputation drops below 70%
	if oracle.ReputationScore < 70.0 {
		oracle.Status = "Suspended"
	}

	oracleJSON, err := json.Marshal(oracle)
	if err != nil {
		return fmt.Errorf("failed to marshal oracle: %v", err)
	}

	err = ctx.GetStub().PutState("ORACLE_"+oracleID, oracleJSON)
	if err != nil {
		return fmt.Errorf("failed to update oracle reputation: %v", err)
	}

	return nil
}

// ========================================
// WEATHER DATA SUBMISSION & VALIDATION
// ========================================

// SubmitWeatherData records weather readings from an oracle
func (wo *WeatherOracleChaincode) SubmitWeatherData(ctx contractapi.TransactionContextInterface,
	dataID string, oracleID string, location string, latitude float64, longitude float64,
	rainfall float64, temperature float64, humidity float64, windSpeed float64, dataHash string) error {

	// Check if data already exists
	exists, err := wo.weatherDataExists(ctx, dataID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("weather data %s already exists", dataID)
	}

	// Verify oracle is active
	oracle, err := wo.GetOracleProvider(ctx, oracleID)
	if err != nil {
		return fmt.Errorf("oracle not found: %v", err)
	}
	if oracle.Status != "Active" {
		return fmt.Errorf("oracle %s is not active", oracleID)
	}

	// Get caller identity
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Validate data ranges
	if rainfall < 0 || rainfall > 1000 {
		return fmt.Errorf("invalid rainfall value: %.2f", rainfall)
	}
	if temperature < -50 || temperature > 60 {
		return fmt.Errorf("invalid temperature value: %.2f", temperature)
	}
	if humidity < 0 || humidity > 100 {
		return fmt.Errorf("invalid humidity value: %.2f", humidity)
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	weatherData := WeatherData{
		DataID:          dataID,
		OracleID:        oracleID,
		Location:        location,
		Latitude:        latitude,
		Longitude:       longitude,
		Timestamp:       timestamp,
		Rainfall:        rainfall,
		Temperature:     temperature,
		Humidity:        humidity,
		WindSpeed:       windSpeed,
		DataHash:        dataHash,
		ValidationScore: 0.0,
		Status:          "Pending",
		SubmittedBy:     callerID,
	}

	dataJSON, err := json.Marshal(weatherData)
	if err != nil {
		return fmt.Errorf("failed to marshal weather data: %v", err)
	}

	err = ctx.GetStub().PutState(dataID, dataJSON)
	if err != nil {
		return fmt.Errorf("failed to put weather data: %v", err)
	}

	// Update oracle's last submission time (reuse timestamp from earlier)
	oracle.LastSubmission = timestamp
	oracleJSON, err := json.Marshal(oracle)
	if err != nil {
		return fmt.Errorf("failed to marshal oracle: %v", err)
	}

	err = ctx.GetStub().PutState("ORACLE_"+oracleID, oracleJSON)
	if err != nil {
		return fmt.Errorf("failed to update oracle: %v", err)
	}

	return nil
}

// GetWeatherData retrieves specific weather observation
func (wo *WeatherOracleChaincode) GetWeatherData(ctx contractapi.TransactionContextInterface,
	dataID string) (*WeatherData, error) {

	dataJSON, err := ctx.GetStub().GetState(dataID)
	if err != nil {
		return nil, fmt.Errorf("failed to read weather data: %v", err)
	}
	if dataJSON == nil {
		return nil, fmt.Errorf("weather data %s does not exist", dataID)
	}

	var weatherData WeatherData
	err = json.Unmarshal(dataJSON, &weatherData)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal weather data: %v", err)
	}

	return &weatherData, nil
}

// GetWeatherByRegion retrieves weather data for a specific location
func (wo *WeatherOracleChaincode) GetWeatherByRegion(ctx contractapi.TransactionContextInterface,
	location string, startDate string, endDate string) ([]*WeatherData, error) {

	// Parse dates
	start, err := time.Parse(time.RFC3339, startDate)
	if err != nil {
		return nil, fmt.Errorf("invalid start date format: %v", err)
	}
	end, err := time.Parse(time.RFC3339, endDate)
	if err != nil {
		return nil, fmt.Errorf("invalid end date format: %v", err)
	}

	queryString := fmt.Sprintf(`{"selector":{"location":"%s","timestamp":{"$gte":"%s","$lte":"%s"}}}`,
		location, start.Format(time.RFC3339), end.Format(time.RFC3339))

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query weather data: %v", err)
	}
	defer resultsIterator.Close()

	var weatherDataList []*WeatherData
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var data WeatherData
		err = json.Unmarshal(queryResponse.Value, &data)
		if err != nil {
			return nil, err
		}
		weatherDataList = append(weatherDataList, &data)
	}

	return weatherDataList, nil
}

// ========================================
// CONSENSUS & VALIDATION
// ========================================

// ValidateDataConsensus implements 2/3 consensus across multiple oracles
func (wo *WeatherOracleChaincode) ValidateDataConsensus(ctx contractapi.TransactionContextInterface,
	location string, timestampStr string, dataIDs []string) (bool, error) {

	if len(dataIDs) < 2 {
		return false, fmt.Errorf("need at least 2 oracle submissions for consensus")
	}

	timestamp, err := time.Parse(time.RFC3339, timestampStr)
	if err != nil {
		return false, fmt.Errorf("invalid timestamp format: %v", err)
	}

	// Collect all weather data submissions
	var submissions []*WeatherData
	for _, dataID := range dataIDs {
		data, err := wo.GetWeatherData(ctx, dataID)
		if err != nil {
			continue
		}
		submissions = append(submissions, data)
	}

	if len(submissions) < 2 {
		return false, fmt.Errorf("insufficient valid submissions")
	}

	// Calculate average values
	var totalRainfall, totalTemp, totalHumidity float64
	for _, data := range submissions {
		totalRainfall += data.Rainfall
		totalTemp += data.Temperature
		totalHumidity += data.Humidity
	}

	count := float64(len(submissions))
	avgRainfall := totalRainfall / count
	avgTemp := totalTemp / count
	avgHumidity := totalHumidity / count

	// Check if values are within acceptable variance (20%)
	consensusThreshold := 0.20
	consensusCount := 0

	for _, data := range submissions {
		rainfallDiff := abs(data.Rainfall-avgRainfall) / avgRainfall
		tempDiff := abs(data.Temperature-avgTemp) / abs(avgTemp)
		humidityDiff := abs(data.Humidity-avgHumidity) / avgHumidity

		// Count as consensus if all metrics within threshold
		if rainfallDiff <= consensusThreshold &&
			tempDiff <= consensusThreshold &&
			humidityDiff <= consensusThreshold {
			consensusCount++

			// Update data status to validated
			data.Status = "Validated"
			data.ValidationScore = 100.0

			dataJSON, _ := json.Marshal(data)
			ctx.GetStub().PutState(data.DataID, dataJSON)
		} else {
			// Mark as anomalous
			data.Status = "Anomalous"
			data.ValidationScore = 0.0

			dataJSON, _ := json.Marshal(data)
			ctx.GetStub().PutState(data.DataID, dataJSON)

			// Update oracle reputation
			wo.UpdateOracleReputation(ctx, data.OracleID, true)
		}
	}

	// Require 2/3 consensus
	required := int(float64(len(submissions)) * 2.0 / 3.0)
	consensusReached := consensusCount >= required

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return false, fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	currentTime := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Store consensus record
	recordID := fmt.Sprintf("CONSENSUS_%s_%d", location, timestamp.Unix())
	consensusRec := ConsensusRecord{
		RecordID:    recordID,
		Location:    location,
		Timestamp:   timestamp,
		OracleCount: len(submissions),
		Consensus: map[string]float64{
			"rainfall":    avgRainfall,
			"temperature": avgTemp,
			"humidity":    avgHumidity,
		},
		ConsensusReached: consensusReached,
		CreatedDate:      currentTime,
	}

	recordJSON, err := json.Marshal(consensusRec)
	if err != nil {
		return false, fmt.Errorf("failed to marshal consensus record: %v", err)
	}

	err = ctx.GetStub().PutState(recordID, recordJSON)
	if err != nil {
		return false, fmt.Errorf("failed to store consensus record: %v", err)
	}

	// If consensus reached, trigger automatic policy threshold checking
	if consensusReached {
		// Note: Automatic claim triggering happens via API Gateway orchestration
		// The API Gateway will call CheckPolicyThresholds after this function returns
		// This ensures proper separation of concerns and cross-chaincode coordination

		// Emit an event for external monitoring systems
		err = ctx.GetStub().SetEvent("ConsensusReached", []byte(fmt.Sprintf(
			`{"location":"%s","timestamp":"%s","rainfall":%.2f,"temperature":%.2f,"humidity":%.2f}`,
			location, timestamp.Format(time.RFC3339), avgRainfall, avgTemp, avgHumidity,
		)))
		if err != nil {
			// Log but don't fail - event emission is not critical
			fmt.Printf("Warning: failed to emit ConsensusReached event: %v\n", err)
		}
	}

	return consensusReached, nil
}

// FlagAnomalousData marks suspicious or outlier data
func (wo *WeatherOracleChaincode) FlagAnomalousData(ctx contractapi.TransactionContextInterface,
	dataID string, reason string) error {

	data, err := wo.GetWeatherData(ctx, dataID)
	if err != nil {
		return err
	}

	data.Status = "Anomalous"
	data.ValidationScore = 0.0

	dataJSON, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal weather data: %v", err)
	}

	err = ctx.GetStub().PutState(dataID, dataJSON)
	if err != nil {
		return fmt.Errorf("failed to flag anomalous data: %v", err)
	}

	// Update oracle reputation
	err = wo.UpdateOracleReputation(ctx, data.OracleID, true)
	if err != nil {
		return err
	}

	return nil
}

// GetConsensusData retrieves validated consensus weather data
func (wo *WeatherOracleChaincode) GetConsensusData(ctx contractapi.TransactionContextInterface,
	location string, timestampStr string) (*ConsensusRecord, error) {

	timestamp, err := time.Parse(time.RFC3339, timestampStr)
	if err != nil {
		return nil, fmt.Errorf("invalid timestamp format: %v", err)
	}

	recordID := fmt.Sprintf("CONSENSUS_%s_%d", location, timestamp.Unix())
	recordJSON, err := ctx.GetStub().GetState(recordID)
	if err != nil {
		return nil, fmt.Errorf("failed to read consensus record: %v", err)
	}
	if recordJSON == nil {
		return nil, fmt.Errorf("consensus record not found")
	}

	var record ConsensusRecord
	err = json.Unmarshal(recordJSON, &record)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal consensus record: %v", err)
	}

	return &record, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (wo *WeatherOracleChaincode) oracleExists(ctx contractapi.TransactionContextInterface, oracleID string) (bool, error) {
	oracleJSON, err := ctx.GetStub().GetState("ORACLE_" + oracleID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return oracleJSON != nil, nil
}

func (wo *WeatherOracleChaincode) weatherDataExists(ctx contractapi.TransactionContextInterface, dataID string) (bool, error) {
	dataJSON, err := ctx.GetStub().GetState(dataID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return dataJSON != nil, nil
}

func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&WeatherOracleChaincode{})
	if err != nil {
		fmt.Printf("Error creating WeatherOracle chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting WeatherOracle chaincode: %v\n", err)
	}
}
