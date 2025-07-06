;; Rare Book Library Consortium Contract

;; Constants
(define-constant CHIEF_LIBRARIAN tx-sender)
(define-constant ERR_UNAUTHORIZED_SCHOLAR (err u1200))
(define-constant ERR_INSUFFICIENT_FOLIOS (err u1201))
(define-constant ERR_MANUSCRIPT_NOT_FOUND (err u1202))
(define-constant ERR_INVALID_AMOUNT (err u1203))
(define-constant ERR_EXHIBITION_NOT_FOUND (err u1204))
(define-constant ERR_ALREADY_VOTED (err u1205))

;; Data Variables
(define-data-var next-manuscript-id uint u1)
(define-data-var next-exhibition-id uint u1)

;; Manuscript Structure
(define-map rare-manuscripts 
  { manuscript-id: uint }
  {
    book-title: (string-ascii 100),
    total-folios: uint,
    folio-value: uint,
    exhibition-fees: uint,
    head-curator: principal,
    is-archived: bool
  }
)

;; Folio Ownership
(define-map scholar-folios
  { manuscript-id: uint, scholar: principal }
  { folios: uint }
)

;; Exhibition Proposals
(define-map book-exhibitions
  { exhibition-id: uint }
  {
    manuscript-id: uint,
    exhibition-title: (string-ascii 100),
    curatorial-notes: (string-ascii 500),
    organizer: principal,
    favor-votes: uint,
    against-votes: uint,
    exhibition-deadline: uint,
    displayed: bool
  }
)

;; Voting Records
(define-map exhibition-votes
  { exhibition-id: uint, voter: principal }
  { voted: bool, favors: bool }
)

;; Fee Distribution Tracking
(define-map fee-claims
  { manuscript-id: uint, scholar: principal, period: uint }
  { claimed: bool }
)

;; Manuscript Acquisition
(define-public (acquire-manuscript 
  (book-title (string-ascii 100))
  (total-folios uint)
  (folio-value uint)
  (exhibition-fees uint)
  (head-curator principal))
  (let ((manuscript-id (var-get next-manuscript-id)))
    (asserts! (is-eq tx-sender CHIEF_LIBRARIAN) ERR_UNAUTHORIZED_SCHOLAR)
    (asserts! (> total-folios u0) ERR_INVALID_AMOUNT)
    (asserts! (> folio-value u0) ERR_INVALID_AMOUNT)
    
    (map-set rare-manuscripts
      { manuscript-id: manuscript-id }
      {
        book-title: book-title,
        total-folios: total-folios,
        folio-value: folio-value,
        exhibition-fees: exhibition-fees,
        head-curator: head-curator,
        is-archived: true
      }
    )
    
    (var-set next-manuscript-id (+ manuscript-id u1))
    (ok manuscript-id)
  )
)

;; Purchase Manuscript Folios
(define-public (sponsor-folios (manuscript-id uint) (folio-amount uint))
  (let (
    (manuscript (unwrap! (map-get? rare-manuscripts { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    (total-cost (* folio-amount (get folio-value manuscript)))
    (current-folios (default-to u0 (get folios (map-get? scholar-folios { manuscript-id: manuscript-id, scholar: tx-sender }))))
  )
    (asserts! (get is-archived manuscript) ERR_MANUSCRIPT_NOT_FOUND)
    (asserts! (> folio-amount u0) ERR_INVALID_AMOUNT)
    
    (map-set scholar-folios
      { manuscript-id: manuscript-id, scholar: tx-sender }
      { folios: (+ current-folios folio-amount) }
    )
    
    (ok folio-amount)
  )
)

;; Distribute Exhibition Fees
(define-public (distribute-fees (manuscript-id uint) (period uint))
  (let (
    (manuscript (unwrap! (map-get? rare-manuscripts { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    (exhibition-fees (get exhibition-fees manuscript))
    (total-folios (get total-folios manuscript))
  )
    (asserts! (is-eq tx-sender (get head-curator manuscript)) ERR_UNAUTHORIZED_SCHOLAR)
    (asserts! (get is-archived manuscript) ERR_MANUSCRIPT_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Fee Share
(define-public (claim-fees (manuscript-id uint) (period uint))
  (let (
    (manuscript (unwrap! (map-get? rare-manuscripts { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    (folio-balance (default-to u0 (get folios (map-get? scholar-folios { manuscript-id: manuscript-id, scholar: tx-sender }))))
    (already-claimed (default-to false (get claimed (map-get? fee-claims { manuscript-id: manuscript-id, scholar: tx-sender, period: period }))))
    (exhibition-fees (get exhibition-fees manuscript))
    (total-folios (get total-folios manuscript))
    (fee-share (/ (* exhibition-fees folio-balance) total-folios))
  )
    (asserts! (> folio-balance u0) ERR_INSUFFICIENT_FOLIOS)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_SCHOLAR)
    
    (map-set fee-claims
      { manuscript-id: manuscript-id, scholar: tx-sender, period: period }
      { claimed: true }
    )
    
    (ok fee-share)
  )
)

;; Create Exhibition Proposal
(define-public (create-exhibition 
  (manuscript-id uint)
  (exhibition-title (string-ascii 100))
  (curatorial-notes (string-ascii 500))
  (voting-period uint))
  (let (
    (exhibition-id (var-get next-exhibition-id))
    (folio-balance (default-to u0 (get folios (map-get? scholar-folios { manuscript-id: manuscript-id, scholar: tx-sender }))))
    (exhibition-deadline (+ block-height voting-period))
  )
    (asserts! (> folio-balance u0) ERR_UNAUTHORIZED_SCHOLAR)
    
    (map-set book-exhibitions
      { exhibition-id: exhibition-id }
      {
        manuscript-id: manuscript-id,
        exhibition-title: exhibition-title,
        curatorial-notes: curatorial-notes,
        organizer: tx-sender,
        favor-votes: u0,
        against-votes: u0,
        exhibition-deadline: exhibition-deadline,
        displayed: false
      }
    )
    
    (var-set next-exhibition-id (+ exhibition-id u1))
    (ok exhibition-id)
  )
)

;; Vote on Exhibition
(define-public (vote-exhibition (exhibition-id uint) (favors bool))
  (let (
    (exhibition (unwrap! (map-get? book-exhibitions { exhibition-id: exhibition-id }) ERR_EXHIBITION_NOT_FOUND))
    (manuscript-id (get manuscript-id exhibition))
    (folio-balance (default-to u0 (get folios (map-get? scholar-folios { manuscript-id: manuscript-id, scholar: tx-sender }))))
    (already-voted (default-to false (get voted (map-get? exhibition-votes { exhibition-id: exhibition-id, voter: tx-sender }))))
    (current-favor (get favor-votes exhibition))
    (current-against (get against-votes exhibition))
  )
    (asserts! (> folio-balance u0) ERR_UNAUTHORIZED_SCHOLAR)
    (asserts! (<= block-height (get exhibition-deadline exhibition)) ERR_UNAUTHORIZED_SCHOLAR)
    (asserts! (not already-voted) ERR_ALREADY_VOTED)
    
    (map-set exhibition-votes
      { exhibition-id: exhibition-id, voter: tx-sender }
      { voted: true, favors: favors }
    )
    
    (if favors
      (map-set book-exhibitions
        { exhibition-id: exhibition-id }
        (merge exhibition { favor-votes: (+ current-favor folio-balance) })
      )
      (map-set book-exhibitions
        { exhibition-id: exhibition-id }
        (merge exhibition { against-votes: (+ current-against folio-balance) })
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manuscript (manuscript-id uint))
  (map-get? rare-manuscripts { manuscript-id: manuscript-id })
)

(define-read-only (get-folio-balance (manuscript-id uint) (scholar principal))
  (default-to u0 (get folios (map-get? scholar-folios { manuscript-id: manuscript-id, scholar: scholar })))
)

(define-read-only (get-exhibition (exhibition-id uint))
  (map-get? book-exhibitions { exhibition-id: exhibition-id })
)

(define-read-only (calculate-fee-share (manuscript-id uint) (scholar principal))
  (let (
    (manuscript (unwrap! (map-get? rare-manuscripts { manuscript-id: manuscript-id }) ERR_MANUSCRIPT_NOT_FOUND))
    (folio-balance (default-to u0 (get folios (map-get? scholar-folios { manuscript-id: manuscript-id, scholar: scholar }))))
    (exhibition-fees (get exhibition-fees manuscript))
    (total-folios (get total-folios manuscript))
  )
    (if (> folio-balance u0)
      (ok (/ (* exhibition-fees folio-balance) total-folios))
      (ok u0)
    )
  )
)