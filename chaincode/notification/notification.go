package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// NotificationChaincode manages event notifications for stakeholders
type NotificationChaincode struct {
	contractapi.Contract
}

// Notification represents a notification to be sent to a user
type Notification struct {
	NotificationID   string    `json:"notificationID"`   // Unique notification identifier
	RecipientID      string    `json:"recipientID"`      // User/Entity to receive notification
	RecipientType    string    `json:"recipientType"`    // Farmer, Insurer, CoopAdmin, etc.
	NotificationType string    `json:"notificationType"` // PolicyCreated, ClaimApproved, PaymentSent, etc.
	Priority         string    `json:"priority"`         // Low, Medium, High, Urgent
	Title            string    `json:"title"`            // Notification title
	Message          string    `json:"message"`          // Notification content
	RelatedEntityType string   `json:"relatedEntityType"` // Policy, Claim, Payment, etc.
	RelatedEntityID  string    `json:"relatedEntityID"`  // ID of related entity
	Status           string    `json:"status"`           // Pending, Sent, Read, Failed
	CreatedDate      time.Time `json:"createdDate"`      // When notification was created
	SentDate         time.Time `json:"sentDate"`         // When notification was sent
	ReadDate         time.Time `json:"readDate"`         // When notification was read
	Channels         []string  `json:"channels"`         // SMS, Email, MobileApp, Dashboard
	DeliveryStatus   map[string]string `json:"deliveryStatus"` // Status per channel
}

// NotificationSubscription represents user notification preferences
type NotificationSubscription struct {
	SubscriptionID string   `json:"subscriptionID"` // Unique subscription identifier
	UserID         string   `json:"userID"`         // User identifier
	EventTypes     []string `json:"eventTypes"`     // Events to subscribe to
	Channels       []string `json:"channels"`       // Preferred notification channels
	Enabled        bool     `json:"enabled"`        // Whether subscription is active
	CreatedDate    time.Time `json:"createdDate"`   // Subscription creation date
	UpdatedDate    time.Time `json:"updatedDate"`   // Last update date
}

// ========================================
// NOTIFICATION MANAGEMENT
// ========================================

// PublishNotification creates and sends a notification
func (nc *NotificationChaincode) PublishNotification(ctx contractapi.TransactionContextInterface,
	notificationID string, recipientID string, recipientType string, notificationType string,
	priority string, title string, message string, relatedEntityType string, relatedEntityID string) error {

	// Check if notification already exists
	exists, err := nc.notificationExists(ctx, notificationID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("notification %s already exists", notificationID)
	}

	// Validate priority
	validPriorities := map[string]bool{"Low": true, "Medium": true, "High": true, "Urgent": true}
	if !validPriorities[priority] {
		return fmt.Errorf("invalid priority: %s", priority)
	}

	// Get user's notification preferences
	channels := []string{"MobileApp", "Dashboard"} // Default channels
	subscription, err := nc.getSubscriptionByUser(ctx, recipientID)
	if err == nil && subscription != nil && subscription.Enabled {
		channels = subscription.Channels
	}

	// Create notification
	notification := Notification{
		NotificationID:    notificationID,
		RecipientID:       recipientID,
		RecipientType:     recipientType,
		NotificationType:  notificationType,
		Priority:          priority,
		Title:             title,
		Message:           message,
		RelatedEntityType: relatedEntityType,
		RelatedEntityID:   relatedEntityID,
		Status:            "Pending",
		CreatedDate:       time.Now(),
		SentDate:          time.Time{},
		ReadDate:          time.Time{},
		Channels:          channels,
		DeliveryStatus:    make(map[string]string),
	}

	// Initialize delivery status for each channel
	for _, channel := range channels {
		notification.DeliveryStatus[channel] = "Pending"
	}

	notificationJSON, err := json.Marshal(notification)
	if err != nil {
		return fmt.Errorf("failed to marshal notification: %v", err)
	}

	err = ctx.GetStub().PutState(notificationID, notificationJSON)
	if err != nil {
		return fmt.Errorf("failed to store notification: %v", err)
	}

	// Emit event for off-chain notification service
	err = ctx.GetStub().SetEvent("NotificationPublished", notificationJSON)
	if err != nil {
		return fmt.Errorf("failed to emit event: %v", err)
	}

	return nil
}

// GetNotification retrieves a specific notification
func (nc *NotificationChaincode) GetNotification(ctx contractapi.TransactionContextInterface,
	notificationID string) (*Notification, error) {

	notificationJSON, err := ctx.GetStub().GetState(notificationID)
	if err != nil {
		return nil, fmt.Errorf("failed to read notification: %v", err)
	}
	if notificationJSON == nil {
		return nil, fmt.Errorf("notification %s does not exist", notificationID)
	}

	var notification Notification
	err = json.Unmarshal(notificationJSON, &notification)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal notification: %v", err)
	}

	return &notification, nil
}

// GetPendingNotifications retrieves unread notifications for a user
func (nc *NotificationChaincode) GetPendingNotifications(ctx contractapi.TransactionContextInterface,
	recipientID string) ([]*Notification, error) {

	queryString := fmt.Sprintf(`{
		"selector": {
			"recipientID": "%s",
			"status": {"$in": ["Pending", "Sent"]}
		},
		"sort": [{"createdDate": "desc"}]
	}`, recipientID)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query notifications: %v", err)
	}
	defer resultsIterator.Close()

	var notifications []*Notification
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var notification Notification
		err = json.Unmarshal(queryResponse.Value, &notification)
		if err != nil {
			return nil, err
		}
		notifications = append(notifications, &notification)
	}

	return notifications, nil
}

// AcknowledgeNotification marks notification as read
func (nc *NotificationChaincode) AcknowledgeNotification(ctx contractapi.TransactionContextInterface,
	notificationID string) error {

	notification, err := nc.GetNotification(ctx, notificationID)
	if err != nil {
		return err
	}

	notification.Status = "Read"
	notification.ReadDate = time.Now()

	notificationJSON, err := json.Marshal(notification)
	if err != nil {
		return fmt.Errorf("failed to marshal notification: %v", err)
	}

	err = ctx.GetStub().PutState(notificationID, notificationJSON)
	if err != nil {
		return fmt.Errorf("failed to acknowledge notification: %v", err)
	}

	return nil
}

// UpdateDeliveryStatus updates the delivery status for a specific channel
func (nc *NotificationChaincode) UpdateDeliveryStatus(ctx contractapi.TransactionContextInterface,
	notificationID string, channel string, status string) error {

	notification, err := nc.GetNotification(ctx, notificationID)
	if err != nil {
		return err
	}

	// Update delivery status for the channel
	notification.DeliveryStatus[channel] = status

	// Update overall status if sent to all channels
	allSent := true
	for _, deliveryStatus := range notification.DeliveryStatus {
		if deliveryStatus != "Sent" && deliveryStatus != "Failed" {
			allSent = false
			break
		}
	}

	if allSent && notification.Status == "Pending" {
		notification.Status = "Sent"
		notification.SentDate = time.Now()
	}

	notificationJSON, err := json.Marshal(notification)
	if err != nil {
		return fmt.Errorf("failed to marshal notification: %v", err)
	}

	err = ctx.GetStub().PutState(notificationID, notificationJSON)
	if err != nil {
		return fmt.Errorf("failed to update delivery status: %v", err)
	}

	return nil
}

// ========================================
// SUBSCRIPTION MANAGEMENT
// ========================================

// SubscribeToEvents registers user for notifications
func (nc *NotificationChaincode) SubscribeToEvents(ctx contractapi.TransactionContextInterface,
	subscriptionID string, userID string, eventTypes []string, channels []string) error {

	// Check if subscription already exists
	exists, err := nc.subscriptionExists(ctx, subscriptionID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("subscription %s already exists", subscriptionID)
	}

	subscription := NotificationSubscription{
		SubscriptionID: subscriptionID,
		UserID:         userID,
		EventTypes:     eventTypes,
		Channels:       channels,
		Enabled:        true,
		CreatedDate:    time.Now(),
		UpdatedDate:    time.Now(),
	}

	subscriptionJSON, err := json.Marshal(subscription)
	if err != nil {
		return fmt.Errorf("failed to marshal subscription: %v", err)
	}

	err = ctx.GetStub().PutState("SUB_"+subscriptionID, subscriptionJSON)
	if err != nil {
		return fmt.Errorf("failed to store subscription: %v", err)
	}

	return nil
}

// GetSubscription retrieves subscription details
func (nc *NotificationChaincode) GetSubscription(ctx contractapi.TransactionContextInterface,
	subscriptionID string) (*NotificationSubscription, error) {

	subscriptionJSON, err := ctx.GetStub().GetState("SUB_" + subscriptionID)
	if err != nil {
		return nil, fmt.Errorf("failed to read subscription: %v", err)
	}
	if subscriptionJSON == nil {
		return nil, fmt.Errorf("subscription %s does not exist", subscriptionID)
	}

	var subscription NotificationSubscription
	err = json.Unmarshal(subscriptionJSON, &subscription)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal subscription: %v", err)
	}

	return &subscription, nil
}

// ConfigureNotificationPreferences sets user notification channels
func (nc *NotificationChaincode) ConfigureNotificationPreferences(ctx contractapi.TransactionContextInterface,
	subscriptionID string, eventTypes []string, channels []string, enabled bool) error {

	subscription, err := nc.GetSubscription(ctx, subscriptionID)
	if err != nil {
		return err
	}

	subscription.EventTypes = eventTypes
	subscription.Channels = channels
	subscription.Enabled = enabled
	subscription.UpdatedDate = time.Now()

	subscriptionJSON, err := json.Marshal(subscription)
	if err != nil {
		return fmt.Errorf("failed to marshal subscription: %v", err)
	}

	err = ctx.GetStub().PutState("SUB_"+subscriptionID, subscriptionJSON)
	if err != nil {
		return fmt.Errorf("failed to update subscription: %v", err)
	}

	return nil
}

// ========================================
// BULK NOTIFICATIONS
// ========================================

// SendBulkNotification sends notification to multiple recipients
func (nc *NotificationChaincode) SendBulkNotification(ctx contractapi.TransactionContextInterface,
	recipientIDs []string, notificationType string, priority string, title string, message string) error {

	for i, recipientID := range recipientIDs {
		notificationID := fmt.Sprintf("BULK_%d_%s", time.Now().Unix(), recipientID)
		
		err := nc.PublishNotification(ctx, notificationID, recipientID, "Farmer",
			notificationType, priority, title, message, "", "")
		if err != nil {
			// Log error but continue with other recipients
			fmt.Printf("Failed to send notification to %s: %v\n", recipientID, err)
			continue
		}

		// Avoid overwhelming the system
		if (i+1)%100 == 0 {
			time.Sleep(100 * time.Millisecond)
		}
	}

	return nil
}

// ========================================
// HELPER FUNCTIONS
// ========================================

func (nc *NotificationChaincode) notificationExists(ctx contractapi.TransactionContextInterface, notificationID string) (bool, error) {
	notificationJSON, err := ctx.GetStub().GetState(notificationID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return notificationJSON != nil, nil
}

func (nc *NotificationChaincode) subscriptionExists(ctx contractapi.TransactionContextInterface, subscriptionID string) (bool, error) {
	subscriptionJSON, err := ctx.GetStub().GetState("SUB_" + subscriptionID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return subscriptionJSON != nil, nil
}

func (nc *NotificationChaincode) getSubscriptionByUser(ctx contractapi.TransactionContextInterface, userID string) (*NotificationSubscription, error) {
	queryString := fmt.Sprintf(`{"selector":{"userID":"%s","enabled":true}}`, userID)
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to query subscription: %v", err)
	}
	defer resultsIterator.Close()

	if resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var subscription NotificationSubscription
		err = json.Unmarshal(queryResponse.Value, &subscription)
		if err != nil {
			return nil, err
		}
		return &subscription, nil
	}

	return nil, fmt.Errorf("no active subscription found for user")
}

// ========================================
// MAIN
// ========================================

func main() {
	chaincode, err := contractapi.NewChaincode(&NotificationChaincode{})
	if err != nil {
		fmt.Printf("Error creating Notification chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting Notification chaincode: %v\n", err)
	}
}
