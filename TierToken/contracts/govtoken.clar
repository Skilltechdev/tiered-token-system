;; Production-Ready Tiered Vesting Token with Governance
;; Implements a capped token with tiered vesting schedules and governance capabilities

(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-SUPPLY u1000000000)
(define-constant DECIMALS u6)
(define-constant PROPOSAL-DURATION u144) ;; ~1 day in blocks
(define-constant MIN-PROPOSAL-THRESHOLD u1000000) ;; Minimum tokens to create proposal

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-ALREADY-INITIALIZED (err u1002))
(define-constant ERR-NOT-INITIALIZED (err u1003))
(define-constant ERR-INVALID-AMOUNT (err u1004))
(define-constant ERR-MAX-SUPPLY-REACHED (err u1005))
(define-constant ERR-VESTING-LOCKED (err u1006))
(define-constant ERR-INVALID-PROPOSAL (err u1007))
(define-constant ERR-PROPOSAL-EXPIRED (err u1008))
(define-constant ERR-ALREADY-VOTED (err u1009))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1010))

;; Define token
(define-fungible-token governed-token MAX-SUPPLY)

;; Contract state
(define-data-var contract-initialized bool false)
(define-data-var total-supply uint u0)

;; Vesting configuration
(define-map vesting-schedules
    principal
    {
        total-amount: uint,
        claimed-amount: uint,
        start-block: uint,
        cliff-blocks: uint,
        duration-blocks: uint,
        tier: uint
    })

;; Governance structures
(define-map proposals
    uint
    {
        creator: principal,
        title: (string-ascii 50),
        description: (string-utf8 500),
        start-block: uint,
        end-block: uint,
        for-votes: uint,
        against-votes: uint,
        executed: bool
    })

(define-map votes
    { proposal-id: uint, voter: principal }
    { amount: uint, support: bool })

(define-data-var proposal-count uint u0)

;; Initialization
(define-public (initialize)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (not (var-get contract-initialized)) ERR-ALREADY-INITIALIZED)
        (var-set contract-initialized true)
        (ok true)))

;; Vesting functions
(define-public (create-vesting-schedule 
    (beneficiary principal) 
    (amount uint)
    (start-block uint)
    (cliff-blocks uint)
    (duration-blocks uint)
    (tier uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (<= (+ (var-get total-supply) amount) MAX-SUPPLY) ERR-MAX-SUPPLY-REACHED)
        
        (map-set vesting-schedules
            beneficiary
            {
                total-amount: amount,
                claimed-amount: u0,
                start-block: start-block,
                cliff-blocks: cliff-blocks,
                duration-blocks: duration-blocks,
                tier: tier
            })
        
        (var-set total-supply (+ (var-get total-supply) amount))
        (ok true)))

(define-public (claim-vested-tokens)
    (let (
        (vesting-info (unwrap! (map-get? vesting-schedules tx-sender) ERR-NOT-AUTHORIZED))
        (claimable-amount (get-claimable-amount tx-sender))
    )
        (asserts! (> claimable-amount u0) ERR-INVALID-AMOUNT)
        (try! (ft-mint? governed-token claimable-amount tx-sender))
        
        (map-set vesting-schedules
            tx-sender
            (merge vesting-info { claimed-amount: (+ (get claimed-amount vesting-info) claimable-amount) }))
        
        (ok claimable-amount)))

;; Governance functions
(define-public (create-proposal (title (string-ascii 50)) (description (string-utf8 500)))
    (let (
        (proposer-balance (ft-get-balance governed-token tx-sender))
    )
        (asserts! (>= proposer-balance MIN-PROPOSAL-THRESHOLD) ERR-INSUFFICIENT-BALANCE)
        
        (map-set proposals
            (var-get proposal-count)
            {
                creator: tx-sender,
                title: title,
                description: description,
                start-block: block-height,
                end-block: (+ block-height PROPOSAL-DURATION),
                for-votes: u0,
                against-votes: u0,
                executed: false
            })
        
        (var-set proposal-count (+ (var-get proposal-count) u1))
        (ok (- (var-get proposal-count) u1))))

(define-public (cast-vote (proposal-id uint) (support bool))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) ERR-INVALID-PROPOSAL))
        (voter-balance (ft-get-balance governed-token tx-sender))
    )
        (asserts! (not (is-proposal-expired proposal)) ERR-PROPOSAL-EXPIRED)
        (asserts! (not (has-voted proposal-id tx-sender)) ERR-ALREADY-VOTED)
        (asserts! (> voter-balance u0) ERR-INSUFFICIENT-BALANCE)
        
        ;; Record vote
        (map-set votes
            { proposal-id: proposal-id, voter: tx-sender }
            { amount: voter-balance, support: support })
        
        ;; Update vote tallies
        (map-set proposals
            proposal-id
            (merge proposal {
                for-votes: (if support
                    (+ (get for-votes proposal) voter-balance)
                    (get for-votes proposal)),
                against-votes: (if support
                    (get against-votes proposal)
                    (+ (get against-votes proposal) voter-balance))
            }))
        
        (ok true)))

;; Private helper functions
(define-private (is-proposal-expired (proposal { creator: principal, title: (string-ascii 50), description: (string-utf8 500), start-block: uint, end-block: uint, for-votes: uint, against-votes: uint, executed: bool }))
    (> block-height (get end-block proposal)))

(define-private (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? votes { proposal-id: proposal-id, voter: voter })))

(define-private (get-claimable-amount (beneficiary principal))
    (let (
        (vesting-info (unwrap-panic (map-get? vesting-schedules beneficiary)))
        (total-amount (get total-amount vesting-info))
        (claimed-amount (get claimed-amount vesting-info))
        (start-block (get start-block vesting-info))
        (cliff-blocks (get cliff-blocks vesting-info))
        (duration-blocks (get duration-blocks vesting-info))
    )
        (if (< block-height (+ start-block cliff-blocks))
            u0
            (- (min
                total-amount
                (/ (* total-amount (- block-height start-block)) duration-blocks))
               claimed-amount))))

;; Read-only functions
(define-read-only (get-vesting-schedule (beneficiary principal))
    (map-get? vesting-schedules beneficiary))

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id))

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes { proposal-id: proposal-id, voter: voter }))

(define-read-only (get-balance (account principal))
    (ft-get-balance governed-token account))

(define-read-only (get-total-supply)
    (var-get total-supply))