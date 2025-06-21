# Decentralized Calendar Management Smart Contract

A comprehensive blockchain-based calendar system built on the Stacks blockchain that enables users to create, manage, and securely share calendar events with granular permission controls.

## Features

- **Event CRUD Operations**: Create, read, update, and delete calendar events
- **Permission-Based Sharing**: Granular access control with view, edit, and delete permissions
- **Decentralized Synchronization**: All data stored on the Stacks blockchain
- **User Statistics**: Track calendar usage and event creation statistics
- **Secure Access Control**: Only authorized users can access and modify events

## Smart Contract Overview

The contract provides a decentralized alternative to traditional calendar applications, ensuring data ownership and privacy through blockchain technology.

### Key Components

- **Event Storage**: Secure storage of calendar events with metadata
- **Permission System**: Fine-grained access control for shared events
- **User Statistics**: Track user engagement and event creation
- **Input Validation**: Comprehensive validation for all user inputs

## Data Structures

### Calendar Events
```clarity
{
  event-owner: principal,
  event-title: (string-utf8 100),
  event-description: (string-utf8 500),
  scheduled-start-time: uint,
  scheduled-end-time: uint,
  event-location: (string-utf8 100),
  is-publicly-visible: bool,
  last-modification-timestamp: uint
}
```

### Access Control Permissions
```clarity
{
  has-view-permission: bool,
  has-edit-permission: bool,
  has-delete-permission: bool
}
```

### User Statistics
```clarity
{
  total-events-created: uint
}
```

## Public Functions

### `create-calendar-event`
Creates a new calendar event with comprehensive validation.

**Parameters:**
- `event-title` (string-utf8 100): Title of the event
- `event-description` (string-utf8 500): Detailed description
- `scheduled-start-time` (uint): Event start timestamp
- `scheduled-end-time` (uint): Event end timestamp
- `event-location` (string-utf8 100): Event location
- `is-publicly-visible` (bool): Public visibility flag

**Returns:** `(response uint uint)` - Event ID on success

**Example:**
```clarity
(contract-call? .calendar-contract create-calendar-event
  u"Team Meeting"
  u"Weekly team sync to discuss project progress"
  u1640995200  ;; Start time
  u1640998800  ;; End time
  u"Conference Room A"
  false)
```

### `update-calendar-event`
Updates an existing calendar event (requires edit permissions).

**Parameters:**
- `calendar-event-identifier` (uint): Event ID to update
- `updated-event-title` (string-utf8 100): New title
- `updated-event-description` (string-utf8 500): New description
- `updated-start-time` (uint): New start time
- `updated-end-time` (uint): New end time
- `updated-event-location` (string-utf8 100): New location
- `updated-visibility` (bool): New visibility setting

**Returns:** `(response bool uint)` - Success status

### `delete-calendar-event`
Deletes a calendar event (requires delete permissions).

**Parameters:**
- `calendar-event-identifier` (uint): Event ID to delete

**Returns:** `(response bool uint)` - Success status

### `share-calendar-event-with-permissions`
Shares an event with another user with specific permissions.

**Parameters:**
- `calendar-event-identifier` (uint): Event ID to share
- `recipient-user` (principal): User to share with
- `grant-view-access` (bool): Grant view permission
- `grant-edit-access` (bool): Grant edit permission
- `grant-delete-access` (bool): Grant delete permission

**Returns:** `(response bool uint)` - Success status

**Example:**
```clarity
(contract-call? .calendar-contract share-calendar-event-with-permissions
  u1  ;; Event ID
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; Recipient
  true   ;; View access
  true   ;; Edit access
  false) ;; No delete access
```

## Read-Only Functions

### `get-calendar-event-details`
Retrieves complete event information.

**Parameters:**
- `calendar-event-identifier` (uint): Event ID

**Returns:** Event details or error

### `get-user-calendar-statistics`
Gets user's calendar usage statistics.

**Parameters:**
- `target-user` (principal): User to query

**Returns:** User statistics

### `get-calendar-event-permissions`
Gets specific user permissions for an event.

**Parameters:**
- `calendar-event-identifier` (uint): Event ID
- `target-user` (principal): User to check permissions for

**Returns:** Permission details

## Error Codes

- `ERR-UNAUTHORIZED-ACCESS` (u100): User lacks required permissions
- `ERR-CALENDAR-EVENT-NOT-FOUND` (u101): Event does not exist
- `ERR-INVALID-TIME-RANGE` (u102): Start time is after end time
- `ERR-INVALID-INPUT-DATA` (u103): Invalid or empty input data

## Permission System

The contract implements a sophisticated permission system:

### Owner Permissions
- Event owners have full permissions (view, edit, delete) by default
- Only owners can share events with other users
- Owners can grant granular permissions to other users

### Shared Permissions
- **View Permission**: Read event details
- **Edit Permission**: Modify event information
- **Delete Permission**: Remove the event

### Permission Inheritance
- Edit permission does not automatically grant delete permission
- All permissions must be explicitly granted by the event owner

## Security Features

- **Input Validation**: All string inputs are validated for non-empty content
- **Time Validation**: Start time must be before end time
- **Authorization Checks**: Comprehensive permission validation before operations
- **Owner Protection**: Only event owners can modify sharing permissions
- **Self-Sharing Prevention**: Users cannot share events with themselves

## Usage Examples

### Creating and Sharing an Event
```clarity
;; 1. Create an event
(contract-call? .calendar-contract create-calendar-event
  u"Project Deadline"
  u"Final submission for Q4 project"
  u1640995200
  u1640998800
  u"Office"
  false)

;; 2. Share with team member (view and edit only)
(contract-call? .calendar-contract share-calendar-event-with-permissions
  u1
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
  true  ;; View
  true  ;; Edit
  false) ;; No delete
```

### Checking Permissions
```clarity
;; Check what permissions a user has for an event
(contract-call? .calendar-contract get-calendar-event-permissions
  u1
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## Development and Testing

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Understanding of Clarity smart contract language

### Deployment
1. Deploy the contract to the Stacks blockchain
2. Initialize with proper contract principals
3. Test all functions with various permission scenarios

### Testing Scenarios
- Event creation with valid and invalid data
- Permission sharing between different users
- Event updates by owners and shared users
- Event deletion with proper authorization
- Error handling for unauthorized access

## Gas Optimization

The contract is optimized for gas efficiency:
- Minimal storage operations
- Efficient permission checking
- Batched operations where possible
- Proper use of read-only functions