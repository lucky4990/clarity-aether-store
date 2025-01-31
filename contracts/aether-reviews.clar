;; Review system contract
(define-map reviews
  { product-id: uint }
  {
    reviewer: principal,
    rating: uint,
    comment: (string-utf8 500),
    timestamp: uint
  }
)

(define-public (add-review (product-id uint) (rating uint) (comment (string-utf8 500)))
  (let ((purchase (unwrap! (contract-call? .aether-store get-purchase product-id) err-not-purchased)))
    (if (and (>= rating u1) (<= rating u5))
      (begin
        (map-set reviews
          { product-id: product-id }
          {
            reviewer: tx-sender,
            rating: rating,
            comment: comment,
            timestamp: block-height
          }
        )
        (ok true)
      )
      (err u106)
    )
  )
)
