;; simple-eco-pool.clar

;; Data maps and variables
(define-map lender-balances principal u128) ;; Lender's deposited STX balance
(define-data-var total-liquidity u128 u0) ;; Total STX in pool
(define-data-var interest-rate u128 u5) ;; 5% interest (scaled by 100)
(define-data-var donation-rate u128 u1) ;; 1% donation on withdrawals
(define-data-var charity-principal principal 'SP000000000000000000002Q6VF78) ;; Charity address

;; Error codes
(define-constant err-invalid-amount (err u100))
(define-constant err-insufficient-balance (err u101))

;; Public function: Deposit STX into the pool
(define-public (deposit-stx (amount u128))
    (let ((caller contract-caller))
        (if (> amount u0)
            (begin
                (try! (stx-transfer? amount caller (as-contract tx-sender)))
                (map-set lender-balances caller
                    (+ (default-to u0 (map-get? lender-balances caller)) amount))
                (var-set total-liquidity (+ (var-get total-liquidity) amount))
                (ok amount))
            err-invalid-amount)))

;; Public function: Withdraw STX with interest and donation
(define-public (withdraw-stx (amount u128))
    (let ((caller contract-caller)
          (balance (default-to u0 (map-get? lender-balances caller))))
        (if (and (> balance u0) (>= balance amount))
            (let ((interest (/ (* balance (var-get interest-rate)) u100))
                  (donation (/ (* amount (var-get donation-rate)) u100)))
                (try! (as-contract (stx-transfer? donation tx-sender (var-get charity-principal))))
                (map-set lender-balances caller (- balance amount))
                (var-set total-liquidity (- (var-get total-liquidity) amount))
                (try! (as-contract (stx-transfer? (+ amount interest) tx-sender caller)))
                (ok {withdrawn: amount, donated: donation}))
            err-insufficient-balance)))

;; Read-only: Get user balance
(define-read-only (get-balance (user principal))
    (default-to u0 (map-get? lender-balances user)))