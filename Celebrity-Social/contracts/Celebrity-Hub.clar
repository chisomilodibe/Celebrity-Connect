;; StarConnect Hub - Premium Celebrity Engagement Platform

;; A comprehensive blockchain-based platform that enables verified celebrities 
;; to monetize their brand through exclusive content creation, personalized 
;; fan interactions, and premium digital experiences. Fans can purchase 
;; exclusive content, request custom messages/videos, and build meaningful 
;; connections with their favorite stars while ensuring secure, transparent 
;; transactions and fair revenue distribution.
;;
;; Core Features:
;; - Celebrity verification and profile management
;; - Monetized exclusive content distribution  
;; - Custom interaction requests (messages, videos, digital autographs)
;; - Social following system with engagement tracking
;; - Automated revenue sharing with platform sustainability
;; - Comprehensive analytics and earnings management

;; SYSTEM CONSTANTS & ERROR DEFINITIONS

(define-constant PLATFORM_ADMINISTRATOR tx-sender)
(define-constant UNAUTHORIZED_ACCESS_ERROR (err u100))
(define-constant RESOURCE_NOT_FOUND_ERROR (err u101))
(define-constant DUPLICATE_RESOURCE_ERROR (err u102))
(define-constant INSUFFICIENT_BALANCE_ERROR (err u103))
(define-constant INVALID_AMOUNT_ERROR (err u104))
(define-constant INVALID_INPUT_PARAMETERS_ERROR (err u105))
(define-constant CONTENT_UNAVAILABLE_ERROR (err u106))
(define-constant DUPLICATE_PURCHASE_ERROR (err u107))
(define-constant SELF_INTERACTION_PROHIBITED_ERROR (err u108))

;; Revenue sharing configuration (500 basis points = 5%)
(define-constant PLATFORM_REVENUE_SHARE_BASIS_POINTS u500)
(define-constant TOTAL_BASIS_POINTS u10000)

;; Input validation constants
(define-constant MAX_NAME_LENGTH u50)
(define-constant MAX_BIO_LENGTH u500)
(define-constant MAX_URL_LENGTH u200)
(define-constant MAX_TITLE_LENGTH u100)
(define-constant MAX_DESCRIPTION_LENGTH u500)
(define-constant MAX_CONTENT_TYPE_LENGTH u20)
(define-constant MAX_MESSAGE_LENGTH u500)
(define-constant MAX_STATUS_LENGTH u25)

;; PLATFORM STATE VARIABLES


(define-data-var platform-revenue-recipient principal PLATFORM_ADMINISTRATOR)
(define-data-var registered-celebrities-count uint u0)
(define-data-var published-content-items-count uint u0)
(define-data-var completed-interactions-count uint u0)

;; CORE DATA STRUCTURES

;; Celebrity professional profiles with verification status
(define-map verified-celebrity-profiles
    { celebrity-wallet-address: principal }
    {
        display-name: (string-ascii 50),
        professional-biography: (string-utf8 500),
        profile-image-url: (string-ascii 200),
        verification-status: bool,
        total-lifetime-earnings: uint,
        published-content-count: uint,
        fulfilled-interactions-count: uint,
        platform-registration-block: uint
    }
)

;; Premium content catalog with pricing and metadata
(define-map premium-content-catalog
    { unique-content-identifier: uint }
    {
        content-creator-address: principal,
        content-title: (string-utf8 100),
        content-description: (string-utf8 500),
        media-content-type: (string-ascii 20),
        access-price-microSTX: uint,
        content-storage-url: (string-ascii 200),
        publication-timestamp: uint,
        total-purchase-count: uint,
        content-availability-status: bool
    }
)

;; Fan purchase records for content access tracking
(define-map fan-content-access-records
    { purchasing-fan-address: principal, purchased-content-id: uint }
    {
        purchase-completion-timestamp: uint,
        transaction-amount-paid: uint
    }
)

;; Custom interaction requests between fans and celebrities
(define-map personalized-interaction-requests
    { interaction-request-identifier: uint }
    {
        target-celebrity-address: principal,
        requesting-fan-address: principal,
        interaction-service-type: (string-ascii 20),
        fan-request-content: (string-utf8 500),
        celebrity-response-content: (optional (string-utf8 500)),
        service-price-microSTX: uint,
        request-fulfillment-status: (string-ascii 25),
        initial-request-timestamp: uint,
        completion-timestamp: (optional uint)
    }
)

;; Celebrity financial tracking and withdrawal management
(define-map celebrity-financial-accounts
    { celebrity-account-holder: principal }
    {
        lifetime-total-earned: uint,
        current-withdrawable-balance: uint,
        cumulative-withdrawn-amount: uint
    }
)

;; Service pricing configuration per celebrity
(define-map celebrity-service-pricing-tiers
    { service-provider-address: principal }
    {
        personal-message-price: uint,
        custom-video-price: uint,
        digital-autograph-price: uint
    }
)

;; Fan-celebrity social connection tracking
(define-map fan-celebrity-following-relationships
    { follower-fan-address: principal, followed-celebrity-address: principal }
    {
        relationship-established-timestamp: uint
    }
)

;; INPUT VALIDATION FUNCTIONS

;; Validate string inputs for safety
(define-private (validate-string-ascii-input (input (string-ascii 200)) (max-length uint))
    (and (> (len input) u0) (<= (len input) max-length))
)

(define-private (validate-string-utf8-input (input (string-utf8 500)) (max-length uint))
    (and (> (len input) u0) (<= (len input) max-length))
)

;; Validate content type values
(define-private (validate-content-type (content-type (string-ascii 20)))
    (or (is-eq content-type "premium-video")
        (or (is-eq content-type "exclusive-audio")
            (or (is-eq content-type "digital-artwork")
                (is-eq content-type "written-content"))))
)

;; Validate interaction service types
(define-private (validate-interaction-type (service-type (string-ascii 20)))
    (or (is-eq service-type "personal-message")
        (or (is-eq service-type "custom-video")
            (is-eq service-type "digital-autograph")))
)

;; Validate uint inputs
(define-private (validate-positive-uint (value uint))
    (> value u0)
)

;; Validate content identifier exists
(define-private (validate-content-identifier (content-id uint))
    (and (> content-id u0) 
         (<= content-id (var-get published-content-items-count)))
)

;; Validate interaction identifier exists  
(define-private (validate-interaction-identifier (interaction-id uint))
    (and (> interaction-id u0) 
         (<= interaction-id (var-get completed-interactions-count)))
)

;; INTERNAL UTILITY FUNCTIONS

;; Verify platform administrator privileges
(define-private (verify-administrator-access)
    (is-eq tx-sender PLATFORM_ADMINISTRATOR)
)

;; Check celebrity registration status in platform
(define-private (validate-celebrity-registration-status (celebrity-address principal))
    (is-some (map-get? verified-celebrity-profiles { celebrity-wallet-address: celebrity-address }))
)

;; Calculate platform revenue share from transaction amount
(define-private (compute-platform-revenue-portion (transaction-total-amount uint))
    (/ (* transaction-total-amount PLATFORM_REVENUE_SHARE_BASIS_POINTS) TOTAL_BASIS_POINTS)
)

;; Calculate celebrity net earnings after platform fees
(define-private (compute-celebrity-net-earnings (gross-transaction-amount uint))
    (- gross-transaction-amount (compute-platform-revenue-portion gross-transaction-amount))
)

;; Update celebrity financial account with new earnings
(define-private (process-celebrity-earnings-update (celebrity-address principal) (earnings-amount uint))
    (let (
        (existing-financial-record (default-to 
            { lifetime-total-earned: u0, current-withdrawable-balance: u0, cumulative-withdrawn-amount: u0 }
            (map-get? celebrity-financial-accounts { celebrity-account-holder: celebrity-address })
        ))
        (net-celebrity-earnings (compute-celebrity-net-earnings earnings-amount))
    )
        (map-set celebrity-financial-accounts
            { celebrity-account-holder: celebrity-address }
            {
                lifetime-total-earned: (+ (get lifetime-total-earned existing-financial-record) net-celebrity-earnings),
                current-withdrawable-balance: (+ (get current-withdrawable-balance existing-financial-record) net-celebrity-earnings),
                cumulative-withdrawn-amount: (get cumulative-withdrawn-amount existing-financial-record)
            }
        )
    )
)

;; CELEBRITY ONBOARDING & PROFILE MANAGEMENT

;; Register new celebrity profile on platform
(define-public (register-celebrity-profile 
    (celebrity-display-name (string-ascii 50)) 
    (biography-content (string-utf8 500)) 
    (profile-image-link (string-ascii 200))
)
    (let (
        (registering-celebrity-address tx-sender)
    )
        (asserts! (not (validate-celebrity-registration-status registering-celebrity-address)) DUPLICATE_RESOURCE_ERROR)
        (asserts! (validate-string-ascii-input celebrity-display-name MAX_NAME_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-string-utf8-input biography-content MAX_BIO_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-string-ascii-input profile-image-link MAX_URL_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        
        (map-set verified-celebrity-profiles
            { celebrity-wallet-address: registering-celebrity-address }
            {
                display-name: celebrity-display-name,
                professional-biography: biography-content,
                profile-image-url: profile-image-link,
                verification-status: false,
                total-lifetime-earnings: u0,
                published-content-count: u0,
                fulfilled-interactions-count: u0,
                platform-registration-block: block-height
            }
        )
        
        (map-set celebrity-financial-accounts
            { celebrity-account-holder: registering-celebrity-address }
            {
                lifetime-total-earned: u0,
                current-withdrawable-balance: u0,
                cumulative-withdrawn-amount: u0
            }
        )
        
        (map-set celebrity-service-pricing-tiers
            { service-provider-address: registering-celebrity-address }
            {
                personal-message-price: u1000000, ;; Default: 1 STX
                custom-video-price: u5000000,     ;; Default: 5 STX  
                digital-autograph-price: u2000000 ;; Default: 2 STX
            }
        )
        
        (var-set registered-celebrities-count (+ (var-get registered-celebrities-count) u1))
        (ok true)
    )
)

;; Update existing celebrity profile information
(define-public (modify-celebrity-profile-details 
    (updated-display-name (string-ascii 50)) 
    (updated-biography (string-utf8 500)) 
    (updated-profile-image (string-ascii 200))
)
    (let (
        (updating-celebrity-address tx-sender)
        (existing-profile-data (unwrap! (map-get? verified-celebrity-profiles { celebrity-wallet-address: updating-celebrity-address }) RESOURCE_NOT_FOUND_ERROR))
    )
        (asserts! (validate-string-ascii-input updated-display-name MAX_NAME_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-string-utf8-input updated-biography MAX_BIO_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-string-ascii-input updated-profile-image MAX_URL_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        
        (map-set verified-celebrity-profiles
            { celebrity-wallet-address: updating-celebrity-address }
            (merge existing-profile-data {
                display-name: updated-display-name,
                professional-biography: updated-biography,
                profile-image-url: updated-profile-image
            })
        )
        (ok true)
    )
)

;; Configure celebrity service pricing structure
(define-public (configure-service-pricing-structure 
    (message-service-price uint) 
    (video-service-price uint) 
    (autograph-service-price uint)
)
    (let (
        (celebrity-service-provider tx-sender)
    )
        (asserts! (validate-celebrity-registration-status celebrity-service-provider) RESOURCE_NOT_FOUND_ERROR)
        (asserts! (validate-positive-uint message-service-price) INVALID_AMOUNT_ERROR)
        (asserts! (validate-positive-uint video-service-price) INVALID_AMOUNT_ERROR)
        (asserts! (validate-positive-uint autograph-service-price) INVALID_AMOUNT_ERROR)
        
        (map-set celebrity-service-pricing-tiers
            { service-provider-address: celebrity-service-provider }
            {
                personal-message-price: message-service-price,
                custom-video-price: video-service-price,
                digital-autograph-price: autograph-service-price
            }
        )
        (ok true)
    )
)

;; PREMIUM CONTENT CREATION & DISTRIBUTION

;; Publish new premium content for fan purchase
(define-public (publish-premium-content 
    (content-title-text (string-utf8 100)) 
    (content-description-text (string-utf8 500)) 
    (content-media-type (string-ascii 20))
    (content-access-price uint)
    (content-hosting-url (string-ascii 200))
)
    (let (
        (content-publishing-celebrity tx-sender)
        (new-content-unique-id (+ (var-get published-content-items-count) u1))
        (celebrity-current-profile (unwrap! (map-get? verified-celebrity-profiles { celebrity-wallet-address: content-publishing-celebrity }) UNAUTHORIZED_ACCESS_ERROR))
    )
        (asserts! (validate-string-utf8-input content-title-text MAX_TITLE_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-string-utf8-input content-description-text MAX_DESCRIPTION_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-content-type content-media-type) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-positive-uint content-access-price) INVALID_AMOUNT_ERROR)
        (asserts! (validate-string-ascii-input content-hosting-url MAX_URL_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        
        (map-set premium-content-catalog
            { unique-content-identifier: new-content-unique-id }
            {
                content-creator-address: content-publishing-celebrity,
                content-title: content-title-text,
                content-description: content-description-text,
                media-content-type: content-media-type,
                access-price-microSTX: content-access-price,
                content-storage-url: content-hosting-url,
                publication-timestamp: block-height,
                total-purchase-count: u0,
                content-availability-status: true
            }
        )
        
        (map-set verified-celebrity-profiles
            { celebrity-wallet-address: content-publishing-celebrity }
            (merge celebrity-current-profile {
                published-content-count: (+ (get published-content-count celebrity-current-profile) u1)
            })
        )
        
        (var-set published-content-items-count new-content-unique-id)
        (ok new-content-unique-id)
    )
)

;; Fan purchase access to premium celebrity content
(define-public (purchase-premium-content-access (target-content-identifier uint))
    (let (
        (purchasing-fan-address tx-sender)
        (selected-content-details (unwrap! (map-get? premium-content-catalog { unique-content-identifier: target-content-identifier }) RESOURCE_NOT_FOUND_ERROR))
        (content-creator-celebrity (get content-creator-address selected-content-details))
        (content-purchase-price (get access-price-microSTX selected-content-details))
        (calculated-platform-fee (compute-platform-revenue-portion content-purchase-price))
    )
        (asserts! (validate-content-identifier target-content-identifier) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (get content-availability-status selected-content-details) CONTENT_UNAVAILABLE_ERROR)
        (asserts! (not (is-eq purchasing-fan-address content-creator-celebrity)) SELF_INTERACTION_PROHIBITED_ERROR)
        (asserts! (is-none (map-get? fan-content-access-records { purchasing-fan-address: purchasing-fan-address, purchased-content-id: target-content-identifier })) DUPLICATE_PURCHASE_ERROR)
        
        ;; Execute payment transaction to platform contract
        (try! (stx-transfer? content-purchase-price purchasing-fan-address (as-contract tx-sender)))
        
        ;; Transfer platform revenue share to administrator
        (try! (as-contract (stx-transfer? calculated-platform-fee tx-sender (var-get platform-revenue-recipient))))
        
        ;; Update celebrity earnings account
        (process-celebrity-earnings-update content-creator-celebrity content-purchase-price)
        
        ;; Record fan purchase transaction
        (map-set fan-content-access-records
            { purchasing-fan-address: purchasing-fan-address, purchased-content-id: target-content-identifier }
            {
                purchase-completion-timestamp: block-height,
                transaction-amount-paid: content-purchase-price
            }
        )
        
        ;; Update content purchase statistics
        (map-set premium-content-catalog
            { unique-content-identifier: target-content-identifier }
            (merge selected-content-details {
                total-purchase-count: (+ (get total-purchase-count selected-content-details) u1)
            })
        )
        
        (ok true)
    )
)

;; PERSONALIZED INTERACTION SERVICES

;; Submit personalized interaction request to celebrity
(define-public (submit-personalized-interaction-request 
    (target-celebrity-wallet-address principal) 
    (requested-interaction-type (string-ascii 20))
    (fan-message-content (string-utf8 500))
)
    (let (
        (requesting-fan-address tx-sender)
        (new-interaction-request-id (+ (var-get completed-interactions-count) u1))
        (celebrity-pricing-structure (unwrap! (map-get? celebrity-service-pricing-tiers { service-provider-address: target-celebrity-wallet-address }) RESOURCE_NOT_FOUND_ERROR))
        (calculated-service-price (if (is-eq requested-interaction-type "personal-message")
                   (get personal-message-price celebrity-pricing-structure)
                   (if (is-eq requested-interaction-type "custom-video")
                       (get custom-video-price celebrity-pricing-structure)
                       (get digital-autograph-price celebrity-pricing-structure))))
        (calculated-platform-revenue (compute-platform-revenue-portion calculated-service-price))
    )
        (asserts! (validate-celebrity-registration-status target-celebrity-wallet-address) RESOURCE_NOT_FOUND_ERROR)
        (asserts! (not (is-eq requesting-fan-address target-celebrity-wallet-address)) SELF_INTERACTION_PROHIBITED_ERROR)
        (asserts! (validate-string-utf8-input fan-message-content MAX_MESSAGE_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-interaction-type requested-interaction-type) INVALID_INPUT_PARAMETERS_ERROR)
        
        ;; Process payment transaction
        (try! (stx-transfer? calculated-service-price requesting-fan-address (as-contract tx-sender)))
        
        ;; Transfer platform fee portion
        (try! (as-contract (stx-transfer? calculated-platform-revenue tx-sender (var-get platform-revenue-recipient))))
        
        ;; Update celebrity earnings balance
        (process-celebrity-earnings-update target-celebrity-wallet-address calculated-service-price)
        
        ;; Create interaction request record
        (map-set personalized-interaction-requests
            { interaction-request-identifier: new-interaction-request-id }
            {
                target-celebrity-address: target-celebrity-wallet-address,
                requesting-fan-address: requesting-fan-address,
                interaction-service-type: requested-interaction-type,
                fan-request-content: fan-message-content,
                celebrity-response-content: none,
                service-price-microSTX: calculated-service-price,
                request-fulfillment-status: "awaiting-response",
                initial-request-timestamp: block-height,
                completion-timestamp: none
            }
        )
        
        (var-set completed-interactions-count new-interaction-request-id)
        (ok new-interaction-request-id)
    )
)

;; Celebrity fulfillment of fan interaction request
(define-public (fulfill-interaction-request (interaction-identifier uint) (celebrity-response-message (string-utf8 500)))
    (let (
        (responding-celebrity-address tx-sender)
        (interaction-request-details (unwrap! (map-get? personalized-interaction-requests { interaction-request-identifier: interaction-identifier }) RESOURCE_NOT_FOUND_ERROR))
        (celebrity-current-profile (unwrap! (map-get? verified-celebrity-profiles { celebrity-wallet-address: responding-celebrity-address }) UNAUTHORIZED_ACCESS_ERROR))
    )
        (asserts! (validate-interaction-identifier interaction-identifier) INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (is-eq responding-celebrity-address (get target-celebrity-address interaction-request-details)) UNAUTHORIZED_ACCESS_ERROR)
        (asserts! (is-eq (get request-fulfillment-status interaction-request-details) "awaiting-response") INVALID_INPUT_PARAMETERS_ERROR)
        (asserts! (validate-string-utf8-input celebrity-response-message MAX_MESSAGE_LENGTH) INVALID_INPUT_PARAMETERS_ERROR)
        
        (map-set personalized-interaction-requests
            { interaction-request-identifier: interaction-identifier }
            (merge interaction-request-details {
                celebrity-response-content: (some celebrity-response-message),
                request-fulfillment-status: "successfully-completed",
                completion-timestamp: (some block-height)
            })
        )
        
        (map-set verified-celebrity-profiles
            { celebrity-wallet-address: responding-celebrity-address }
            (merge celebrity-current-profile {
                fulfilled-interactions-count: (+ (get fulfilled-interactions-count celebrity-current-profile) u1)
            })
        )
        
        (ok true)
    )
)

;; SOCIAL ENGAGEMENT FEATURES

;; Establish fan-celebrity following relationship
(define-public (establish-celebrity-following (target-celebrity-address principal))
    (let (
        (following-fan-address tx-sender)
    )
        (asserts! (validate-celebrity-registration-status target-celebrity-address) RESOURCE_NOT_FOUND_ERROR)
        (asserts! (not (is-eq following-fan-address target-celebrity-address)) SELF_INTERACTION_PROHIBITED_ERROR)
        (asserts! (is-none (map-get? fan-celebrity-following-relationships { follower-fan-address: following-fan-address, followed-celebrity-address: target-celebrity-address })) DUPLICATE_RESOURCE_ERROR)
        
        (map-set fan-celebrity-following-relationships
            { follower-fan-address: following-fan-address, followed-celebrity-address: target-celebrity-address }
            { relationship-established-timestamp: block-height }
        )
        (ok true)
    )
)

;; Remove fan-celebrity following relationship
(define-public (remove-celebrity-following (target-celebrity-address principal))
    (let (
        (unfollowing-fan-address tx-sender)
    )
        (asserts! (validate-celebrity-registration-status target-celebrity-address) RESOURCE_NOT_FOUND_ERROR)
        (asserts! (is-some (map-get? fan-celebrity-following-relationships { follower-fan-address: unfollowing-fan-address, followed-celebrity-address: target-celebrity-address })) RESOURCE_NOT_FOUND_ERROR)
        
        (map-delete fan-celebrity-following-relationships { follower-fan-address: unfollowing-fan-address, followed-celebrity-address: target-celebrity-address })
        (ok true)
    )
)

;; FINANCIAL MANAGEMENT SYSTEM

;; Celebrity earnings withdrawal functionality
(define-public (process-earnings-withdrawal (withdrawal-amount-microSTX uint))
    (let (
        (withdrawing-celebrity-address tx-sender)
        (celebrity-financial-data (unwrap! (map-get? celebrity-financial-accounts { celebrity-account-holder: withdrawing-celebrity-address }) RESOURCE_NOT_FOUND_ERROR))
        (available-withdrawal-balance (get current-withdrawable-balance celebrity-financial-data))
    )
        (asserts! (validate-celebrity-registration-status withdrawing-celebrity-address) UNAUTHORIZED_ACCESS_ERROR)
        (asserts! (validate-positive-uint withdrawal-amount-microSTX) INVALID_AMOUNT_ERROR)
        (asserts! (>= available-withdrawal-balance withdrawal-amount-microSTX) INSUFFICIENT_BALANCE_ERROR)
        
        ;; Transfer earnings to celebrity wallet
        (try! (as-contract (stx-transfer? withdrawal-amount-microSTX tx-sender withdrawing-celebrity-address)))
        
        ;; Update financial account records
        (map-set celebrity-financial-accounts
            { celebrity-account-holder: withdrawing-celebrity-address }
            {
                lifetime-total-earned: (get lifetime-total-earned celebrity-financial-data),
                current-withdrawable-balance: (- available-withdrawal-balance withdrawal-amount-microSTX),
                cumulative-withdrawn-amount: (+ (get cumulative-withdrawn-amount celebrity-financial-data) withdrawal-amount-microSTX)
            }
        )
        
        (ok true)
    )
)

;; ADMINISTRATIVE FUNCTIONS

;; Administrator celebrity verification process
(define-public (grant-celebrity-verification-status (celebrity-address-to-verify principal))
    (let (
        (celebrity-profile-data (unwrap! (map-get? verified-celebrity-profiles { celebrity-wallet-address: celebrity-address-to-verify }) RESOURCE_NOT_FOUND_ERROR))
    )
        (asserts! (verify-administrator-access) UNAUTHORIZED_ACCESS_ERROR)
        (asserts! (validate-celebrity-registration-status celebrity-address-to-verify) RESOURCE_NOT_FOUND_ERROR)
        
        (map-set verified-celebrity-profiles
            { celebrity-wallet-address: celebrity-address-to-verify }
            (merge celebrity-profile-data { verification-status: true })
        )
        (ok true)
    )
)

;; PUBLIC DATA ACCESS FUNCTIONS

(define-read-only (retrieve-celebrity-profile-data (celebrity-address principal))
    (map-get? verified-celebrity-profiles { celebrity-wallet-address: celebrity-address })
)

(define-read-only (retrieve-celebrity-pricing-information (celebrity-address principal))
    (map-get? celebrity-service-pricing-tiers { service-provider-address: celebrity-address })
)

(define-read-only (retrieve-celebrity-financial-summary (celebrity-address principal))
    (map-get? celebrity-financial-accounts { celebrity-account-holder: celebrity-address })
)

(define-read-only (retrieve-content-details (content-identifier uint))
    (map-get? premium-content-catalog { unique-content-identifier: content-identifier })
)

(define-read-only (retrieve-interaction-request-details (interaction-identifier uint))
    (map-get? personalized-interaction-requests { interaction-request-identifier: interaction-identifier })
)

(define-read-only (verify-fan-content-purchase-status (fan-address principal) (content-identifier uint))
    (is-some (map-get? fan-content-access-records { purchasing-fan-address: fan-address, purchased-content-id: content-identifier }))
)

(define-read-only (verify-fan-following-status (fan-address principal) (celebrity-address principal))
    (is-some (map-get? fan-celebrity-following-relationships { follower-fan-address: fan-address, followed-celebrity-address: celebrity-address }))
)

(define-read-only (retrieve-platform-analytics-summary)
    {
        total-registered-celebrities: (var-get registered-celebrities-count),
        total-published-content: (var-get published-content-items-count),
        total-completed-interactions: (var-get completed-interactions-count),
        platform-fee-percentage-basis-points: PLATFORM_REVENUE_SHARE_BASIS_POINTS
    }
)

(define-read-only (retrieve-platform-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)