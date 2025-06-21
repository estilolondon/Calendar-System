;; Decentralized Calendar Management Smart Contract
;; A comprehensive blockchain-based calendar system that enables users to create, manage, 
;; and securely share calendar events with granular permission controls on the Stacks blockchain.
;; Features include event CRUD operations, permission-based sharing, and decentralized synchronization.

;; ERROR CONSTANTS
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-CALENDAR-EVENT-NOT-FOUND (err u101))
(define-constant ERR-INVALID-TIME-RANGE (err u102))
(define-constant ERR-INVALID-INPUT-DATA (err u103))

;; DATA STRUCTURES

;; Primary storage for calendar events with comprehensive metadata
(define-map calendar-events
  { calendar-event-identifier: uint }
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
)

;; Track the total number of events created by each user
(define-map user-calendar-statistics
  { calendar-user: principal }
  { total-events-created: uint }
)

;; Granular permission system for shared calendar events
(define-map calendar-event-access-control
  { calendar-event-identifier: uint, authorized-user: principal }
  { 
    has-view-permission: bool,
    has-edit-permission: bool,
    has-delete-permission: bool
  }
)

;; Global counter for generating unique event identifiers
(define-data-var next-calendar-event-id uint u1)

;; UTILITY FUNCTIONS

;; Generate unique event ID and increment counter for thread safety
(define-private (generate-next-event-identifier)
  (let ((current-event-id (var-get next-calendar-event-id)))
    (var-set next-calendar-event-id (+ current-event-id u1))
    current-event-id
  )
)

;; Retrieve current blockchain timestamp
(define-private (get-blockchain-timestamp)
  (default-to u0 (get-block-info? time u0))
)

;; Verify that a calendar event exists in storage
(define-private (calendar-event-exists (calendar-event-identifier uint))
  (match (map-get? calendar-events { calendar-event-identifier: calendar-event-identifier })
    event-data true
    false
  )
)

;; Comprehensive permission validation system
(define-private (user-has-calendar-permission 
  (calendar-event-identifier uint) 
  (requesting-user principal) 
  (required-permission-type (string-ascii 10)))
  (if (not (calendar-event-exists calendar-event-identifier))
    false
    (match (map-get? calendar-events { calendar-event-identifier: calendar-event-identifier })
      calendar-event-data 
        (if (is-eq (get event-owner calendar-event-data) requesting-user)
          true  ;; Event owner has all permissions by default
          (match (map-get? calendar-event-access-control 
                   { calendar-event-identifier: calendar-event-identifier, authorized-user: requesting-user })
            user-permissions 
              (if (is-eq required-permission-type "view")
                (get has-view-permission user-permissions)
                (if (is-eq required-permission-type "edit")
                  (get has-edit-permission user-permissions)
                  (if (is-eq required-permission-type "delete")
                    (get has-delete-permission user-permissions)
                    false
                  )
                )
              )
            false
          )
        )
      false
    )
  )
)

;; Validate string input to ensure it's not empty
(define-private (is-valid-string-input (input-string (string-utf8 500)))
  (< u0 (len input-string))
)

;; Validate that recipient is different from sender
(define-private (is-valid-sharing-recipient (recipient-user principal))
  (not (is-eq recipient-user tx-sender))
)

;; PUBLIC FUNCTIONS

;; Create a new calendar event with comprehensive validation
(define-public (create-calendar-event
  (event-title (string-utf8 100))
  (event-description (string-utf8 500))
  (scheduled-start-time uint)
  (scheduled-end-time uint)
  (event-location (string-utf8 100))
  (is-publicly-visible bool)
)
  (let ((event-creator tx-sender)
        (new-event-id (generate-next-event-identifier))
        (current-timestamp (get-blockchain-timestamp)))
    
    ;; Comprehensive input validation
    (asserts! (is-valid-string-input event-title) ERR-INVALID-INPUT-DATA)
    (asserts! (is-valid-string-input event-description) ERR-INVALID-INPUT-DATA)
    (asserts! (is-valid-string-input event-location) ERR-INVALID-INPUT-DATA)
    (asserts! (< scheduled-start-time scheduled-end-time) ERR-INVALID-TIME-RANGE)
    
    ;; Store the new calendar event
    (map-set calendar-events
      { calendar-event-identifier: new-event-id }
      {
        event-owner: event-creator,
        event-title: event-title,
        event-description: event-description,
        scheduled-start-time: scheduled-start-time,
        scheduled-end-time: scheduled-end-time,
        event-location: event-location,
        is-publicly-visible: is-publicly-visible,
        last-modification-timestamp: current-timestamp
      }
    )
    
    ;; Update user's event creation statistics
    (let ((user-stats (default-to { total-events-created: u0 } 
                        (map-get? user-calendar-statistics { calendar-user: event-creator }))))
      (map-set user-calendar-statistics
        { calendar-user: event-creator }
        { total-events-created: (+ (get total-events-created user-stats) u1) })
    )
    
    ;; Return the newly created event identifier
    (ok new-event-id)
  )
)

;; Retrieve calendar event details with validation
(define-read-only (get-calendar-event-details (calendar-event-identifier uint))
  (match (map-get? calendar-events { calendar-event-identifier: calendar-event-identifier })
    calendar-event-data (ok calendar-event-data)
    ERR-CALENDAR-EVENT-NOT-FOUND
  )
)

;; Update existing calendar event with comprehensive validation
(define-public (update-calendar-event
  (calendar-event-identifier uint)
  (updated-event-title (string-utf8 100))
  (updated-event-description (string-utf8 500))
  (updated-start-time uint)
  (updated-end-time uint)
  (updated-event-location (string-utf8 100))
  (updated-visibility bool)
)
  (let ((requesting-user tx-sender)
        (modification-timestamp (get-blockchain-timestamp)))
    
    ;; Validate all input parameters
    (asserts! (is-valid-string-input updated-event-title) ERR-INVALID-INPUT-DATA)
    (asserts! (is-valid-string-input updated-event-description) ERR-INVALID-INPUT-DATA)
    (asserts! (is-valid-string-input updated-event-location) ERR-INVALID-INPUT-DATA)
    (asserts! (< updated-start-time updated-end-time) ERR-INVALID-TIME-RANGE)
    
    ;; Verify event exists
    (asserts! (calendar-event-exists calendar-event-identifier) ERR-CALENDAR-EVENT-NOT-FOUND)
    
    ;; Check user permissions
    (asserts! (user-has-calendar-permission calendar-event-identifier requesting-user "edit") 
              ERR-UNAUTHORIZED-ACCESS)
    
    ;; Retrieve existing event data and preserve ownership
    (match (map-get? calendar-events { calendar-event-identifier: calendar-event-identifier })
      existing-event-data
        (begin
          ;; Update the calendar event while preserving owner
          (map-set calendar-events
            { calendar-event-identifier: calendar-event-identifier }
            {
              event-owner: (get event-owner existing-event-data),
              event-title: updated-event-title,
              event-description: updated-event-description,
              scheduled-start-time: updated-start-time,
              scheduled-end-time: updated-end-time,
              event-location: updated-event-location,
              is-publicly-visible: updated-visibility,
              last-modification-timestamp: modification-timestamp
            }
          )
          (ok true)
        )
      ERR-CALENDAR-EVENT-NOT-FOUND
    )
  )
)

;; Delete calendar event with proper authorization
(define-public (delete-calendar-event (calendar-event-identifier uint))
  (let ((requesting-user tx-sender))
    
    ;; Verify event exists
    (asserts! (calendar-event-exists calendar-event-identifier) ERR-CALENDAR-EVENT-NOT-FOUND)
    
    ;; Check deletion permissions
    (asserts! (user-has-calendar-permission calendar-event-identifier requesting-user "delete") 
              ERR-UNAUTHORIZED-ACCESS)
    
    ;; Retrieve event data before deletion
    (match (map-get? calendar-events { calendar-event-identifier: calendar-event-identifier })
      calendar-event-data
        (begin
          ;; Remove event from storage
          (map-delete calendar-events { calendar-event-identifier: calendar-event-identifier })
          
          ;; Update creator's statistics if user is the owner
          (if (is-eq (get event-owner calendar-event-data) requesting-user)
            (let ((user-stats (default-to { total-events-created: u0 } 
                                (map-get? user-calendar-statistics { calendar-user: requesting-user }))))
              (map-set user-calendar-statistics
                { calendar-user: requesting-user }
                { total-events-created: (- (get total-events-created user-stats) u1) })
            )
            true
          )
          
          (ok true)
        )
      ERR-CALENDAR-EVENT-NOT-FOUND
    )
  )
)

;; Share calendar event with granular permission control
(define-public (share-calendar-event-with-permissions
  (calendar-event-identifier uint)
  (recipient-user principal)
  (grant-view-access bool)
  (grant-edit-access bool)
  (grant-delete-access bool)
)
  (let ((event-owner tx-sender))
    
    ;; Validate recipient user
    (asserts! (is-valid-sharing-recipient recipient-user) ERR-INVALID-INPUT-DATA)
    
    ;; Verify event exists
    (asserts! (calendar-event-exists calendar-event-identifier) ERR-CALENDAR-EVENT-NOT-FOUND)
    
    ;; Verify ownership permissions
    (match (map-get? calendar-events { calendar-event-identifier: calendar-event-identifier })
      calendar-event-data
        (begin
          (asserts! (is-eq (get event-owner calendar-event-data) event-owner) ERR-UNAUTHORIZED-ACCESS)
          
          ;; Grant specified permissions to recipient
          (ok (map-set calendar-event-access-control
            { calendar-event-identifier: calendar-event-identifier, authorized-user: recipient-user }
            { 
              has-view-permission: grant-view-access,
              has-edit-permission: grant-edit-access,
              has-delete-permission: grant-delete-access
            }
          ))
        )
      ERR-CALENDAR-EVENT-NOT-FOUND
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get user's calendar statistics
(define-read-only (get-user-calendar-statistics (target-user principal))
  (ok (default-to { total-events-created: u0 } 
        (map-get? user-calendar-statistics { calendar-user: target-user })))
)

;; Get specific user permissions for a calendar event
(define-read-only (get-calendar-event-permissions (calendar-event-identifier uint) (target-user principal))
  (if (not (calendar-event-exists calendar-event-identifier))
    ERR-CALENDAR-EVENT-NOT-FOUND
    (ok (default-to
      { has-view-permission: false, has-edit-permission: false, has-delete-permission: false }
      (map-get? calendar-event-access-control 
        { calendar-event-identifier: calendar-event-identifier, authorized-user: target-user })))
  )
)