;; MapNest Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

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
    review-count: uint
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

;; Add POI
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
        review-count: u0
      }
    )
    (var-set poi-counter poi-id)
    (ok poi-id))
)

;; Add review
(define-public (add-review (poi-id uint) 
                         (rating uint)
                         (comment (string-utf8 500)))
  (let ((poi (unwrap! (map-get? POIs { poi-id: poi-id }) (err err-not-found))))
    (map-set Reviews
      { poi-id: poi-id, reviewer: tx-sender }
      {
        rating: rating,
        comment: comment,
        timestamp: block-height
      }
    )
    (ok true))
)

;; Verify POI
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

;; Add verifier
(define-public (add-verifier (address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (map-set Verifiers address true)
    (ok true))
)
