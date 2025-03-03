;; MapNest Contract v1.1
;; Enhanced with security features and events

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-invalid-coordinates (err u105))
(define-constant err-invalid-category (err u106))

;; Points for different actions
(define-constant points-add-poi u100)
(define-constant points-add-review u10)
(define-constant points-verified-contribution u50)

;; Contract version
(define-data-var contract-version (string-utf8 10) "1.1.0")

;; Data structures
(define-map POIs
  { poi-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    latitude: int,
    longitude: int,
    category: (string-utf8 50),
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
    timestamp: uint,
    edited: bool
  }
)

(define-map Verifiers principal bool)

(define-map UserRewards
  { user: principal }
  { 
    points: uint,
    reputation: uint,
    verified-contributions: uint
  }
)

;; Data vars
(define-data-var poi-counter uint u0)

;; Events
(define-public (print-poi-added-event (poi-id uint) (creator principal))
  (ok (print { type: "poi-added", poi-id: poi-id, creator: creator })))

(define-public (print-review-added-event (poi-id uint) (reviewer principal))
  (ok (print { type: "review-added", poi-id: poi-id, reviewer: reviewer })))

;; Private functions
(define-private (validate-coordinates (latitude int) (longitude int))
  (and
    (and (>= latitude -90000000) (<= latitude 90000000))
    (and (>= longitude -180000000) (<= longitude 180000000))
  )
)

(define-private (add-points (user principal) (points uint))
  (let ((current-rewards (default-to { points: u0, reputation: u0, verified-contributions: u0 } 
        (map-get? UserRewards { user: user }))))
    (map-set UserRewards
      { user: user }
      (merge current-rewards { points: (+ points (get points current-rewards)) })
    )
  )
)

;; Enhanced public functions
(define-public (add-poi (name (string-utf8 100)) 
                    (description (string-utf8 500))
                    (latitude int)
                    (longitude int)
                    (category (string-utf8 50)))
  (begin
    (asserts! (validate-coordinates latitude longitude) (err err-invalid-coordinates))
    (let ((poi-id (+ (var-get poi-counter) u1)))
      (map-insert POIs
        { poi-id: poi-id }
        {
          name: name,
          description: description,
          latitude: latitude,
          longitude: longitude,
          category: category,
          creator: tx-sender,
          verified: false,
          rating: u0,
          review-count: u0,
          total-rating: u0
        }
      )
      (var-set poi-counter poi-id)
      (add-points tx-sender points-add-poi)
      (try! (print-poi-added-event poi-id tx-sender))
      (ok poi-id)))
)

;; Read-only functions
(define-read-only (get-poi (poi-id uint))
  (map-get? POIs { poi-id: poi-id })
)

(define-read-only (get-user-rewards (user principal))
  (map-get? UserRewards { user: user })
)

;; ... [Previous functions remain unchanged]
