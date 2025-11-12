package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// FarmerChaincode manages farmer identity and profile information with privacy controls
type FarmerChaincode struct {
	contractapi.Contract
}

// Farmer represents a coffee farmer in the system
type Farmer struct {
	FarmerID       string    `json:"farmerID"`       // Unique farmer identifier
	FirstName      string    `json:"firstName"`      // Farmer's first name (private data)
	LastName       string    `json:"lastName"`       // Farmer's last name (private data)
	CoopID         string    `json:"coopID"`         // Associated cooperative ID
	PhoneNumber    string    `json:"phoneNumber"`    // Contact number (private data)
	Email          string    `json:"email"`          // Email address (private data)
	WalletAddress  string    `json:"walletAddress"`  // Blockchain wallet for payouts
	FarmLocation   Location  `json:"farmLocation"`   // GPS coordinates (private data)
	FarmSize       float64   `json:"farmSize"`       // Farm size in hectares
	CropTypes      []string  `json:"cropTypes"`      // Types of coffee grown
	Status         string    `json:"status"`         // Active, Inactive, Suspended
	KYCVerified    bool      `json:"kycVerified"`    // KYC verification status
	KYCHash        string    `json:"kycHash"`        // Hash of KYC documents
	RegisteredDate time.Time `json:"registeredDate"` // Registration timestamp
	RegisteredBy   string    `json:"registeredBy"`   // Co-op admin who registered farmer
	LastUpdated    time.Time `json:"lastUpdated"`    // Last profile update
}

// Location represents GPS coordinates for farm location
type Location struct {
	Latitude  float64 `json:"latitude"`  // Latitude coordinate
	Longitude float64 `json:"longitude"` // Longitude coordinate
	Region    string  `json:"region"`    // Geographic region name
	District  string  `json:"district"`  // Administrative district
}

// FarmerPublic represents public farmer information (non-sensitive)
type FarmerPublic struct {
	FarmerID       string    `json:"farmerID"`
	CoopID         string    `json:"coopID"`
	Region         string    `json:"region"`
	FarmSize       float64   `json:"farmSize"`
	CropTypes      []string  `json:"cropTypes"`
	Status         string    `json:"status"`
	KYCVerified    bool      `json:"kycVerified"`
	RegisteredDate time.Time `json:"registeredDate"`
}

// CoopMembership tracks farmers associated with cooperatives
type CoopMembership struct {
	MembershipID  string    `json:"membershipID"`  // Unique membership identifier
	FarmerID      string    `json:"farmerID"`      // Farmer ID
	CoopID        string    `json:"coopID"`        // Cooperative ID
	JoinDate      time.Time `json:"joinDate"`      // When farmer joined co-op
	MembershipFee float64   `json:"membershipFee"` // Fee paid (if any)
	Status        string    `json:"status"`        // Active, Expired, Terminated
}

// ========================================
// FARMER REGISTRATION & MANAGEMENT
// ========================================

// RegisterFarmer onboards a new farmer with KYC verification
func (fc *FarmerChaincode) RegisterFarmer(ctx contractapi.TransactionContextInterface,
	farmerID string, firstName string, lastName string, coopID string,
	phoneNumber string, email string, walletAddress string,
	latitude float64, longitude float64, region string, district string,
	farmSize float64, cropTypes []string, kycHash string) error {

	// Check if farmer already exists
	exists, err := fc.farmerExists(ctx, farmerID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("farmer %s already exists", farmerID)
	}

	// Get caller identity (should be co-op admin)
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

	// Create farmer profile
	farmer := Farmer{
		FarmerID:      farmerID,
		FirstName:     firstName,
		LastName:      lastName,
		CoopID:        coopID,
		PhoneNumber:   phoneNumber,
		Email:         email,
		WalletAddress: walletAddress,
		FarmLocation: Location{
			Latitude:  latitude,
			Longitude: longitude,
			Region:    region,
			District:  district,
		},
		FarmSize:       farmSize,
		CropTypes:      cropTypes,
		Status:         "Active",
		KYCVerified:    kycHash != "", // If KYC hash provided, mark as verified
		KYCHash:        kycHash,
		RegisteredDate: timestamp,
		RegisteredBy:   callerID,
		LastUpdated:    timestamp,
	}

	// Store full farmer data in world state
	farmerJSON, err := json.Marshal(farmer)
	if err != nil {
		return fmt.Errorf("failed to marshal farmer: %v", err)
	}

	err = ctx.GetStub().PutState(farmerID, farmerJSON)
	if err != nil {
		return fmt.Errorf("failed to put farmer data: %v", err)
	}

	// Optionally store in private data collection for audit/backup
	err = ctx.GetStub().PutPrivateData("farmerPersonalInfo", farmerID, farmerJSON)
	if err != nil {
		// Log but don't fail if private data storage fails
		fmt.Printf("Warning: failed to put private farmer data: %v\n", err)
	}

	return nil
}

// GetFarmer retrieves full farmer profile (requires authorization)
func (fc *FarmerChaincode) GetFarmer(ctx contractapi.TransactionContextInterface, farmerID string) (*Farmer, error) {
	// Get from world state
	farmerJSON, err := ctx.GetStub().GetState(farmerID)
	if err != nil {
		return nil, fmt.Errorf("failed to read farmer data: %v", err)
	}
	if farmerJSON == nil {
		return nil, fmt.Errorf("farmer %s does not exist", farmerID)
	}

	var farmer Farmer
	err = json.Unmarshal(farmerJSON, &farmer)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal farmer: %v", err)
	}

	return &farmer, nil
}

// GetFarmerPublic retrieves only non-sensitive farmer information
func (fc *FarmerChaincode) GetFarmerPublic(ctx contractapi.TransactionContextInterface, farmerID string) (*FarmerPublic, error) {
	publicJSON, err := ctx.GetStub().GetState("PUBLIC_" + farmerID)
	if err != nil {
		return nil, fmt.Errorf("failed to read public farmer data: %v", err)
	}
	if publicJSON == nil {
		return nil, fmt.Errorf("farmer %s does not exist", farmerID)
	}

	var publicInfo FarmerPublic
	err = json.Unmarshal(publicJSON, &publicInfo)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal public farmer info: %v", err)
	}

	return &publicInfo, nil
}

// UpdateFarmerProfile modifies farmer information
func (fc *FarmerChaincode) UpdateFarmerProfile(ctx contractapi.TransactionContextInterface,
	farmerID string, phoneNumber string, email string, walletAddress string,
	farmSize float64, cropTypes []string) error {

	// Get existing farmer data
	farmer, err := fc.GetFarmer(ctx, farmerID)
	if err != nil {
		return err
	}

	// Update mutable fields
	if phoneNumber != "" {
		farmer.PhoneNumber = phoneNumber
	}
	if email != "" {
		farmer.Email = email
	}
	if walletAddress != "" {
		farmer.WalletAddress = walletAddress
	}
	if farmSize > 0 {
		farmer.FarmSize = farmSize
	}
	if len(cropTypes) > 0 {
		farmer.CropTypes = cropTypes
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	farmer.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Update private data
	farmerJSON, err := json.Marshal(farmer)
	if err != nil {
		return fmt.Errorf("failed to marshal farmer: %v", err)
	}

	err = ctx.GetStub().PutPrivateData("farmerPersonalInfo", farmerID, farmerJSON)
	if err != nil {
		return fmt.Errorf("failed to update private farmer data: %v", err)
	}

	// Update public data
	publicInfo := FarmerPublic{
		FarmerID:       farmer.FarmerID,
		CoopID:         farmer.CoopID,
		Region:         farmer.FarmLocation.Region,
		FarmSize:       farmer.FarmSize,
		CropTypes:      farmer.CropTypes,
		Status:         farmer.Status,
		KYCVerified:    farmer.KYCVerified,
		RegisteredDate: farmer.RegisteredDate,
	}

	publicJSON, err := json.Marshal(publicInfo)
	if err != nil {
		return fmt.Errorf("failed to marshal public farmer info: %v", err)
	}

	err = ctx.GetStub().PutState("PUBLIC_"+farmerID, publicJSON)
	if err != nil {
		return fmt.Errorf("failed to update public farmer data: %v", err)
	}

	return nil
}

// UpdateFarmerStatus changes farmer status (Active/Inactive/Suspended)
func (fc *FarmerChaincode) UpdateFarmerStatus(ctx contractapi.TransactionContextInterface,
	farmerID string, newStatus string) error {

	validStatuses := map[string]bool{"Active": true, "Inactive": true, "Suspended": true}
	if !validStatuses[newStatus] {
		return fmt.Errorf("invalid status: %s", newStatus)
	}

	farmer, err := fc.GetFarmer(ctx, farmerID)
	if err != nil {
		return err
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	farmer.Status = newStatus
	farmer.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Update private data
	farmerJSON, err := json.Marshal(farmer)
	if err != nil {
		return fmt.Errorf("failed to marshal farmer: %v", err)
	}

	err = ctx.GetStub().PutPrivateData("farmerPersonalInfo", farmerID, farmerJSON)
	if err != nil {
		return fmt.Errorf("failed to update farmer status: %v", err)
	}

	// Update public data
	publicInfo, err := fc.GetFarmerPublic(ctx, farmerID)
	if err != nil {
		return err
	}
	publicInfo.Status = newStatus

	publicJSON, err := json.Marshal(publicInfo)
	if err != nil {
		return fmt.Errorf("failed to marshal public farmer info: %v", err)
	}

	err = ctx.GetStub().PutState("PUBLIC_"+farmerID, publicJSON)
	if err != nil {
		return fmt.Errorf("failed to update public farmer data: %v", err)
	}

	return nil
}

// VerifyFarmerIdentity checks farmer credentials and KYC status
func (fc *FarmerChaincode) VerifyFarmerIdentity(ctx contractapi.TransactionContextInterface,
	farmerID string) (bool, error) {

	farmer, err := fc.GetFarmer(ctx, farmerID)
	if err != nil {
		return false, err
	}

	// Check if farmer is active and KYC verified
	if farmer.Status != "Active" {
		return false, fmt.Errorf("farmer is not active")
	}

	if !farmer.KYCVerified {
		return false, fmt.Errorf("farmer KYC not verified")
	}

	return true, nil
}

// ========================================
// COOPERATIVE MEMBERSHIP MANAGEMENT
// ========================================

// LinkFarmerToCoop associates a farmer with a cooperative
func (fc *FarmerChaincode) LinkFarmerToCoop(ctx contractapi.TransactionContextInterface,
	membershipID string, farmerID string, coopID string, membershipFee float64) error {

	// Check if membership already exists
	exists, err := fc.membershipExists(ctx, membershipID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("membership %s already exists", membershipID)
	}

	// Verify farmer exists
	_, err = fc.GetFarmer(ctx, farmerID)
	if err != nil {
		return fmt.Errorf("farmer does not exist: %v", err)
	}

	// Get deterministic transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	membership := CoopMembership{
		MembershipID:  membershipID,
		FarmerID:      farmerID,
		CoopID:        coopID,
		JoinDate:      time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos)),
		MembershipFee: membershipFee,
		Status:        "Active",
	}

	membershipJSON, err := json.Marshal(membership)
	if err != nil {
		return fmt.Errorf("failed to marshal membership: %v", err)
	}

	err = ctx.GetStub().PutState("MEMBERSHIP_"+membershipID, membershipJSON)
	if err != nil {
		return fmt.Errorf("failed to put membership: %v", err)
	}

	// Update farmer's co-op association
	farmer, err := fc.GetFarmer(ctx, farmerID)
	if err != nil {
		return err
	}

	// Get deterministic transaction timestamp
	txTimestamp, err = ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}

	farmer.CoopID = coopID
	farmer.LastUpdated = time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	farmerJSON, err := json.Marshal(farmer)
	if err != nil {
		return fmt.Errorf("failed to marshal farmer: %v", err)
	}

	err = ctx.GetStub().PutPrivateData("farmerPersonalInfo", farmerID, farmerJSON)
	if err != nil {
		return fmt.Errorf("failed to update farmer co-op: %v", err)
	}

	return nil
}

// GetCoopMembers retrieves all farmers in a cooperative
func (fc *FarmerChaincode) GetCoopMembers(ctx contractapi.TransactionContextInterface,
	coopID string) ([]*Farmer, error) {

	queryString := fmt.Sprintf(`{"selector":{"coopID":"%s"}}`, coopID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query co-op members: %v", err)
	}
	defer resultsIterator.Close()

	var farmers []*Farmer
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var farmer Farmer
		err = json.Unmarshal(queryResponse.Value, &farmer)
		if err != nil {
			return nil, err
		}
		farmers = append(farmers, &farmer)
	}

	return farmers, nil
}

// GetFarmersByRegion queries farmers in a specific geographic area
func (fc *FarmerChaincode) GetFarmersByRegion(ctx contractapi.TransactionContextInterface,
	region string) ([]*Farmer, error) {

	queryString := fmt.Sprintf(`{"selector":{"farmLocation.region":"%s"}}`, region)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query farmers by region: %v", err)
	}
	defer resultsIterator.Close()

	var farmers []*Farmer
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var farmer Farmer
		err = json.Unmarshal(queryResponse.Value, &farmer)
		if err != nil {
			return nil, err
		}
		farmers = append(farmers, &farmer)
	}

	return farmers, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (fc *FarmerChaincode) farmerExists(ctx contractapi.TransactionContextInterface, farmerID string) (bool, error) {
	publicJSON, err := ctx.GetStub().GetState("PUBLIC_" + farmerID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return publicJSON != nil, nil
}

func (fc *FarmerChaincode) membershipExists(ctx contractapi.TransactionContextInterface, membershipID string) (bool, error) {
	membershipJSON, err := ctx.GetStub().GetState("MEMBERSHIP_" + membershipID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return membershipJSON != nil, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&FarmerChaincode{})
	if err != nil {
		fmt.Printf("Error creating Farmer chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting Farmer chaincode: %v\n", err)
	}
}
