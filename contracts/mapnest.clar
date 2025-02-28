;; MapNest Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rating (err u104))

;; Points for different actions
(define-constant points-add-poi u100)
(define-constant points-add-review u10)

;; Data structures
(define-map POIs
  { poi-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    latitude: int,
    longitude: int,
    creator: principal,
    verified: bool,
    rating: uint,
    review-count: uint,
    total-rating: uint
  }
)

(define-map Reviews
  { poi-id: uint, reviewer: principal }
  {
    rating: uint,
    comment: (string-utf8 500),
    timestamp: uint
  }
)

(define-map Verifiers principal bool)

(define-map UserRewards
  { user: principal }
  { points: uint }
)

;; Data vars
(define-data-var poi-counter uint u0)

;; Private functions
(define-private (add-points (user principal) (points uint))
  (let ((current-points (default-to { points: u0 } (map-get? UserRewards { user: user }))))
    (map-set UserRewards
      { user: user }
      { points: (+ points (get points current-points)) }
    )
  )
)

(define-private (update-poi-rating (poi-id uint) (new-rating uint))
  (let (
    (poi (unwrap! (map-get? POIs { poi-id: poi-id }) (err err-not-found)))
    (new-total (+ (default-to u0 (get total-rating poi)) new-rating))
    (new-count (+ (default-to u0 (get review-count poi)) u1))
  )
    (map-set POIs
      { poi-id: poi-id }
      (merge poi {
        total-rating: new-total,
        review-count: new-count,
        rating: (/ new-total new-count)
      })
    )
  )
)

;; Public functions
(define-public (add-poi (name (string-utf8 100)) 
                    (description (string-utf8 500))
                    (latitude int)
                    (longitude int))
  (let ((poi-id (+ (var-get poi-counter) u1)))
    (map-insert POIs
      { poi-id: poi-id }
      {
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
        creator: tx-sender,
        verified: false,
        rating: u0,
        review-count: u0,
        total-rating: u0
      }
    )
    (var-set poi-counter poi-id)
    (add-points tx-sender points-add-poi)
    (ok poi-id))
)

(define-public (add-review (poi-id uint) 
                       (rating uint)
                       (comment (string-utf8 500)))
  (begin
    (asserts! (and (>= rating u1) (<= rating u5)) (err err-invalid-rating))
    (let ((poi (unwrap! (map-get? POIs { poi-id: poi-id }) (err err-not-found))))
      (map-set Reviews
        { poi-id: poi-id, reviewer: tx-sender }
        {
          rating: rating,
          comment: comment,
          timestamp: block-height
        }
      )
      (try! (update-poi-rating poi-id rating))
      (add-points tx-sender points-add-review)
      (ok true))
  )
)

(define-public (claim-rewards)
  (let ((user-rewards (default-to { points: u0 } (map-get? UserRewards { user: tx-sender }))))
    (map-set UserRewards
      { user: tx-sender }
      { points: u0 }
    )
    (ok (get points user-rewards)))
)

(define-public (verify-poi (poi-id uint))
  (let ((is-verifier (default-to false (map-get? Verifiers tx-sender))))
    (asserts! is-verifier (err err-unauthorized))
    (map-set POIs
      { poi-id: poi-id }
      (merge (unwrap! (map-get? POIs { poi-id: poi-id }) (err err-not-found))
            { verified: true })
    )
    (ok true))
)

(define-public (add-verifier (address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (map-set Verifiers address true)
    (ok true))
)
