;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-item-not-found (err u102))
(define-constant err-already-purchased (err u103))
(define-constant err-not-seller (err u104))
(define-constant err-not-buyer (err u105))

;; Define data structures
(define-map products
  { product-id: uint }
  {
    seller: principal,
    name: (string-ascii 50),
    description: (string-utf8 500),
    price: uint,
    available: bool
  }
)

(define-map purchases
  { product-id: uint }
  {
    buyer: principal,
    status: (string-ascii 20),
    dispute: bool
  }
)

;; Product counter
(define-data-var product-counter uint u0)

;; List a new product
(define-public (list-product (name (string-ascii 50)) (description (string-utf8 500)) (price uint))
  (let ((product-id (var-get product-counter)))
    (if (> price u0)
      (begin
        (map-set products
          { product-id: product-id }
          {
            seller: tx-sender,
            name: name,
            description: description,
            price: price,
            available: true
          }
        )
        (var-set product-counter (+ product-id u1))
        (ok product-id)
      )
      err-invalid-price
    )
  )
)

;; Get product details
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

;; Get purchase details
(define-read-only (get-purchase (product-id uint))
  (map-get? purchases { product-id: product-id })
)

;; Purchase a product
(define-public (purchase-product (product-id uint))
  (let ((product (unwrap! (map-get? products { product-id: product-id }) err-item-not-found)))
    (if (get available product)
      (let ((price (get price product))
            (seller (get seller product)))
        (match (stx-transfer? price tx-sender seller)
          success (begin
            (map-set purchases
              { product-id: product-id }
              {
                buyer: tx-sender,
                status: "pending",
                dispute: false
              }
            )
            (map-set products
              { product-id: product-id }
              (merge product { available: false })
            )
            (ok true)
          )
          error (err error))
      )
      err-already-purchased
    )
  )
)

;; Confirm delivery
(define-public (confirm-delivery (product-id uint))
  (let ((purchase (unwrap! (map-get? purchases { product-id: product-id }) err-item-not-found)))
    (if (is-eq (get buyer purchase) tx-sender)
      (begin
        (map-set purchases
          { product-id: product-id }
          (merge purchase { status: "completed" })
        )
        (ok true)
      )
      err-not-buyer
    )
  )
)
