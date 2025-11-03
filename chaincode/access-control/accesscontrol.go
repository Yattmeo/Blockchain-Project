package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// AccessControlChaincode manages identity and role-based access control for the consortium
type AccessControlChaincode struct {
	contractapi.Contract
}

// Organization represents a member of the consortium
type Organization struct {
	OrgID          string    `json:"orgID"`          // Unique organization identifier
	OrgName        string    `json:"orgName"`        // Organization name
	OrgType        string    `json:"orgType"`        // Type: Insurer, Coop, Oracle, Validator, Auditor
	MSP            string    `json:"msp"`            // Membership Service Provider ID
	ContactEmail   string    `json:"contactEmail"`   // Primary contact
	Status         string    `json:"status"`         // Active, Suspended, Revoked
	RegisteredDate time.Time `json:"registeredDate"` // Registration timestamp
	RegisteredBy   string    `json:"registeredBy"`   // Admin who registered this org
}

// Role represents access permissions for an entity
type Role struct {
	RoleID      string    `json:"roleID"`      // Unique role identifier
	EntityID    string    `json:"entityID"`    // User/Organization ID
	RoleName    string    `json:"roleName"`    // Farmer, CoopAdmin, Insurer, Oracle, Validator, Auditor
	Permissions []string  `json:"permissions"` // List of permitted actions
	GrantedBy   string    `json:"grantedBy"`   // Admin who granted the role
	GrantedDate time.Time `json:"grantedDate"` // When role was granted
	ExpiryDate  time.Time `json:"expiryDate"`  // Role expiration (0 = no expiry)
	Status      string    `json:"status"`      // Active, Revoked
}

// Validator represents a validator node organization
type Validator struct {
	ValidatorID     string    `json:"validatorID"`     // Unique validator identifier
	OrgID           string    `json:"orgID"`           // Associated organization
	ReputationScore float64   `json:"reputationScore"` // Trust score (0-100)
	TotalBlocks     int       `json:"totalBlocks"`     // Blocks endorsed
	FailedEndorse   int       `json:"failedEndorse"`   // Failed endorsements
	Status          string    `json:"status"`          // Active, Suspended
	RegisteredDate  time.Time `json:"registeredDate"`  // Registration timestamp
}

// AccessLog tracks all permission changes for audit
type AccessLog struct {
	LogID       string    `json:"logID"`       // Unique log identifier
	Action      string    `json:"action"`      // RegisterOrg, AssignRole, RevokeRole, etc.
	EntityID    string    `json:"entityID"`    // Affected entity
	PerformedBy string    `json:"performedBy"` // Who performed the action
	Timestamp   time.Time `json:"timestamp"`   // When action occurred
	Details     string    `json:"details"`     // Additional context
}

// ========================================
// ORGANIZATION MANAGEMENT
// ========================================

// RegisterOrganization adds a new consortium member
func (ac *AccessControlChaincode) RegisterOrganization(ctx contractapi.TransactionContextInterface,
	orgID string, orgName string, orgType string, msp string, contactEmail string) error {

	// Check if organization already exists
	exists, err := ac.organizationExists(ctx, orgID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("organization %s already exists", orgID)
	}

	// Validate organization type
	validTypes := map[string]bool{
		"Insurer": true, "Coop": true, "Oracle": true,
		"Validator": true, "Auditor": true, "Platform": true,
	}
	if !validTypes[orgType] {
		return fmt.Errorf("invalid organization type: %s", orgType)
	}

	// Get caller identity
	callerID, err := getCallerID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Create organization
	org := Organization{
		OrgID:          orgID,
		OrgName:        orgName,
		OrgType:        orgType,
		MSP:            msp,
		ContactEmail:   contactEmail,
		Status:         "Active",
		RegisteredDate: timestamp,
		RegisteredBy:   callerID,
	}

	orgJSON, err := json.Marshal(org)
	if err != nil {
		return fmt.Errorf("failed to marshal organization: %v", err)
	}

	// Store organization
	err = ctx.GetStub().PutState(orgID, orgJSON)
	if err != nil {
		return fmt.Errorf("failed to put organization: %v", err)
	}

	// Log the action
	err = ac.logAccess(ctx, "RegisterOrganization", orgID, callerID,
		fmt.Sprintf("Registered %s as %s", orgName, orgType))
	if err != nil {
		return err
	}

	return nil
}

// GetOrganization retrieves organization details
func (ac *AccessControlChaincode) GetOrganization(ctx contractapi.TransactionContextInterface, orgID string) (*Organization, error) {
	orgJSON, err := ctx.GetStub().GetState(orgID)
	if err != nil {
		return nil, fmt.Errorf("failed to read organization: %v", err)
	}
	if orgJSON == nil {
		return nil, fmt.Errorf("organization %s does not exist", orgID)
	}

	var org Organization
	err = json.Unmarshal(orgJSON, &org)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal organization: %v", err)
	}

	return &org, nil
}

// UpdateOrganizationStatus changes organization status (Active/Suspended/Revoked)
func (ac *AccessControlChaincode) UpdateOrganizationStatus(ctx contractapi.TransactionContextInterface,
	orgID string, newStatus string) error {

	org, err := ac.GetOrganization(ctx, orgID)
	if err != nil {
		return err
	}

	validStatuses := map[string]bool{"Active": true, "Suspended": true, "Revoked": true}
	if !validStatuses[newStatus] {
		return fmt.Errorf("invalid status: %s", newStatus)
	}

	org.Status = newStatus

	orgJSON, err := json.Marshal(org)
	if err != nil {
		return fmt.Errorf("failed to marshal organization: %v", err)
	}

	err = ctx.GetStub().PutState(orgID, orgJSON)
	if err != nil {
		return fmt.Errorf("failed to update organization: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = ac.logAccess(ctx, "UpdateOrganizationStatus", orgID, callerID,
		fmt.Sprintf("Status changed to %s", newStatus))

	return err
}

// ========================================
// ROLE MANAGEMENT
// ========================================

// AssignRole grants permissions to an entity
func (ac *AccessControlChaincode) AssignRole(ctx contractapi.TransactionContextInterface,
	roleID string, entityID string, roleName string, permissions []string, expiryDate string) error {

	// Check if role already exists
	exists, err := ac.roleExists(ctx, roleID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("role %s already exists", roleID)
	}

	// Validate role name
	validRoles := map[string]bool{
		"Farmer": true, "CoopAdmin": true, "Insurer": true,
		"Oracle": true, "Validator": true, "Auditor": true, "PlatformAdmin": true,
	}
	if !validRoles[roleName] {
		return fmt.Errorf("invalid role name: %s", roleName)
	}

	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Parse expiry date
	var expiry time.Time
	if expiryDate != "" && expiryDate != "0" {
		expiry, err = time.Parse(time.RFC3339, expiryDate)
		if err != nil {
			return fmt.Errorf("invalid expiry date format: %v", err)
		}
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	// Create role
	role := Role{
		RoleID:      roleID,
		EntityID:    entityID,
		RoleName:    roleName,
		Permissions: permissions,
		GrantedBy:   callerID,
		GrantedDate: timestamp,
		ExpiryDate:  expiry,
		Status:      "Active",
	}

	roleJSON, err := json.Marshal(role)
	if err != nil {
		return fmt.Errorf("failed to marshal role: %v", err)
	}

	// Store role with composite key
	err = ctx.GetStub().PutState("ROLE_"+roleID, roleJSON)
	if err != nil {
		return fmt.Errorf("failed to put role: %v", err)
	}

	// Log the action
	err = ac.logAccess(ctx, "AssignRole", entityID, callerID,
		fmt.Sprintf("Assigned role %s with %d permissions", roleName, len(permissions)))

	return err
}

// GetRole retrieves role details
func (ac *AccessControlChaincode) GetRole(ctx contractapi.TransactionContextInterface, roleID string) (*Role, error) {
	roleJSON, err := ctx.GetStub().GetState("ROLE_" + roleID)
	if err != nil {
		return nil, fmt.Errorf("failed to read role: %v", err)
	}
	if roleJSON == nil {
		return nil, fmt.Errorf("role %s does not exist", roleID)
	}

	var role Role
	err = json.Unmarshal(roleJSON, &role)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal role: %v", err)
	}

	return &role, nil
}

// RevokeRole removes permissions from an entity
func (ac *AccessControlChaincode) RevokeRole(ctx contractapi.TransactionContextInterface, roleID string) error {
	role, err := ac.GetRole(ctx, roleID)
	if err != nil {
		return err
	}

	role.Status = "Revoked"

	roleJSON, err := json.Marshal(role)
	if err != nil {
		return fmt.Errorf("failed to marshal role: %v", err)
	}

	err = ctx.GetStub().PutState("ROLE_"+roleID, roleJSON)
	if err != nil {
		return fmt.Errorf("failed to update role: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = ac.logAccess(ctx, "RevokeRole", role.EntityID, callerID,
		fmt.Sprintf("Revoked role %s", role.RoleName))

	return err
}

// CheckPermission validates if an entity can perform an action
func (ac *AccessControlChaincode) CheckPermission(ctx contractapi.TransactionContextInterface,
	entityID string, requiredPermission string) (bool, error) {

	// Query all roles for this entity
	queryString := fmt.Sprintf(`{"selector":{"entityID":"%s","status":"Active"}}`, entityID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return false, fmt.Errorf("failed to query roles: %v", err)
	}
	defer resultsIterator.Close()

	// Check if entity has the required permission
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return false, err
		}

		var role Role
		err = json.Unmarshal(queryResponse.Value, &role)
		if err != nil {
			continue
		}

		// Get transaction timestamp for expiry check
		txTimestamp, err := ctx.GetStub().GetTxTimestamp()
		if err != nil {
			return false, fmt.Errorf("failed to get transaction timestamp: %v", err)
		}
		currentTime := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

		// Check if role has expired
		if !role.ExpiryDate.IsZero() && currentTime.After(role.ExpiryDate) {
			continue
		}

		// Check if permission exists in role
		for _, perm := range role.Permissions {
			if perm == requiredPermission || perm == "*" {
				return true, nil
			}
		}
	}

	return false, nil
}

// GetRolesByEntity retrieves all roles for a specific entity
func (ac *AccessControlChaincode) GetRolesByEntity(ctx contractapi.TransactionContextInterface,
	entityID string) ([]*Role, error) {

	queryString := fmt.Sprintf(`{"selector":{"entityID":"%s"}}`, entityID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query roles: %v", err)
	}
	defer resultsIterator.Close()

	var roles []*Role
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var role Role
		err = json.Unmarshal(queryResponse.Value, &role)
		if err != nil {
			return nil, err
		}
		roles = append(roles, &role)
	}

	return roles, nil
}

// ========================================
// VALIDATOR MANAGEMENT
// ========================================

// RegisterValidator onboards a validator node organization
func (ac *AccessControlChaincode) RegisterValidator(ctx contractapi.TransactionContextInterface,
	validatorID string, orgID string) error {

	// Check if validator already exists
	exists, err := ac.validatorExists(ctx, validatorID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("validator %s already exists", validatorID)
	}

	// Verify organization exists
	_, err = ac.GetOrganization(ctx, orgID)
	if err != nil {
		return fmt.Errorf("organization does not exist: %v", err)
	}

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	validator := Validator{
		ValidatorID:     validatorID,
		OrgID:           orgID,
		ReputationScore: 100.0, // Start with perfect score
		TotalBlocks:     0,
		FailedEndorse:   0,
		Status:          "Active",
		RegisteredDate:  timestamp,
	}

	validatorJSON, err := json.Marshal(validator)
	if err != nil {
		return fmt.Errorf("failed to marshal validator: %v", err)
	}

	err = ctx.GetStub().PutState("VALIDATOR_"+validatorID, validatorJSON)
	if err != nil {
		return fmt.Errorf("failed to put validator: %v", err)
	}

	callerID, _ := ctx.GetClientIdentity().GetID()
	err = ac.logAccess(ctx, "RegisterValidator", validatorID, callerID,
		fmt.Sprintf("Registered validator for org %s", orgID))

	return err
}

// GetValidator retrieves validator details
func (ac *AccessControlChaincode) GetValidator(ctx contractapi.TransactionContextInterface,
	validatorID string) (*Validator, error) {

	validatorJSON, err := ctx.GetStub().GetState("VALIDATOR_" + validatorID)
	if err != nil {
		return nil, fmt.Errorf("failed to read validator: %v", err)
	}
	if validatorJSON == nil {
		return nil, fmt.Errorf("validator %s does not exist", validatorID)
	}

	var validator Validator
	err = json.Unmarshal(validatorJSON, &validator)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal validator: %v", err)
	}

	return &validator, nil
}

// UpdateValidatorReputation adjusts validator trust score based on performance
func (ac *AccessControlChaincode) UpdateValidatorReputation(ctx contractapi.TransactionContextInterface,
	validatorID string, blocksEndorsed int, failedEndorsements int) error {

	validator, err := ac.GetValidator(ctx, validatorID)
	if err != nil {
		return err
	}

	validator.TotalBlocks += blocksEndorsed
	validator.FailedEndorse += failedEndorsements

	// Calculate reputation score: (total - failed) / total * 100
	if validator.TotalBlocks > 0 {
		successRate := float64(validator.TotalBlocks-validator.FailedEndorse) / float64(validator.TotalBlocks)
		validator.ReputationScore = successRate * 100
	}

	validatorJSON, err := json.Marshal(validator)
	if err != nil {
		return fmt.Errorf("failed to marshal validator: %v", err)
	}

	err = ctx.GetStub().PutState("VALIDATOR_"+validatorID, validatorJSON)
	if err != nil {
		return fmt.Errorf("failed to update validator: %v", err)
	}

	return nil
}

// ========================================
// AUDIT & LOGGING
// ========================================

// logAccess records an access control event
func (ac *AccessControlChaincode) logAccess(ctx contractapi.TransactionContextInterface,
	action string, entityID string, performedBy string, details string) error {

	txID := ctx.GetStub().GetTxID()

	// Get transaction timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return fmt.Errorf("failed to get transaction timestamp: %v", err)
	}
	timestamp := time.Unix(txTimestamp.Seconds, int64(txTimestamp.Nanos))

	log := AccessLog{
		LogID:       txID,
		Action:      action,
		EntityID:    entityID,
		PerformedBy: performedBy,
		Timestamp:   timestamp,
		Details:     details,
	}

	logJSON, err := json.Marshal(log)
	if err != nil {
		return fmt.Errorf("failed to marshal access log: %v", err)
	}

	err = ctx.GetStub().PutState("LOG_"+txID, logJSON)
	if err != nil {
		return fmt.Errorf("failed to put access log: %v", err)
	}

	return nil
}

// GetAuditLog retrieves a specific access log entry
func (ac *AccessControlChaincode) GetAuditLog(ctx contractapi.TransactionContextInterface,
	logID string) (*AccessLog, error) {

	logJSON, err := ctx.GetStub().GetState("LOG_" + logID)
	if err != nil {
		return nil, fmt.Errorf("failed to read audit log: %v", err)
	}
	if logJSON == nil {
		return nil, fmt.Errorf("audit log %s does not exist", logID)
	}

	var log AccessLog
	err = json.Unmarshal(logJSON, &log)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal audit log: %v", err)
	}

	return &log, nil
}

// GetAuditLogsByEntity retrieves all access logs for a specific entity
func (ac *AccessControlChaincode) GetAuditLogsByEntity(ctx contractapi.TransactionContextInterface,
	entityID string) ([]*AccessLog, error) {

	queryString := fmt.Sprintf(`{"selector":{"entityID":"%s"}}`, entityID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query audit logs: %v", err)
	}
	defer resultsIterator.Close()

	var logs []*AccessLog
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var log AccessLog
		err = json.Unmarshal(queryResponse.Value, &log)
		if err != nil {
			return nil, err
		}
		logs = append(logs, &log)
	}

	return logs, nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (ac *AccessControlChaincode) organizationExists(ctx contractapi.TransactionContextInterface, orgID string) (bool, error) {
	orgJSON, err := ctx.GetStub().GetState(orgID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return orgJSON != nil, nil
}

func (ac *AccessControlChaincode) roleExists(ctx contractapi.TransactionContextInterface, roleID string) (bool, error) {
	roleJSON, err := ctx.GetStub().GetState("ROLE_" + roleID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return roleJSON != nil, nil
}

func (ac *AccessControlChaincode) validatorExists(ctx contractapi.TransactionContextInterface, validatorID string) (bool, error) {
	validatorJSON, err := ctx.GetStub().GetState("VALIDATOR_" + validatorID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return validatorJSON != nil, nil
}

// getCallerID retrieves the caller's identity from the transaction context
func getCallerID(ctx contractapi.TransactionContextInterface) (string, error) {
	// Get the client identity from the stub
	b64ID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("failed to get client identity: %v", err)
	}
	return b64ID, nil
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&AccessControlChaincode{})
	if err != nil {
		fmt.Printf("Error creating AccessControl chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting AccessControl chaincode: %v\n", err)
	}
}
