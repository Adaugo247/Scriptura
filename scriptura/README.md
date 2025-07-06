# 📜 Scriptura: Rare Book Library Consortium

**Scriptura** is a Clarity smart contract that enables decentralized, fractional ownership of rare manuscripts and automates the distribution of exhibition revenues among stakeholders. It facilitates collaborative manuscript acquisition, democratic exhibition proposals, and equitable reward systems for scholarly contributors.

---

## 🚀 Features

- **Manuscript Tokenization**: Digitally represent rare manuscripts as folios (fractional units).
- **Folio Sponsorship**: Scholars can purchase folios to own a share of valuable manuscripts.
- **Exhibition Proposals**: Folio holders can propose exhibitions, including curatorial notes and voting periods.
- **Decentralized Voting**: Folio-weighted voting to approve or reject exhibition proposals.
- **Revenue Sharing**: Exhibition fees are distributed proportionally among folio holders.
- **Claim Tracking**: Prevents double claims using unique `manuscript + scholar + period` identifiers.

---

## 🏗️ Data Structures

- **rare-manuscripts**: Metadata for each manuscript.
- **scholar-folios**: Tracks folio ownership per scholar per manuscript.
- **book-exhibitions**: Exhibition proposals with voting details.
- **exhibition-votes**: Prevents double voting and tracks preferences.
- **fee-claims**: Tracks if a scholar has claimed fees for a manuscript in a period.

---

## 📖 Public Functions

### 🪶 Manuscript Functions
- `acquire-manuscript`: Adds a new manuscript to the consortium.
- `sponsor-folios`: Allows scholars to purchase folios in a manuscript.

### 💰 Fee Distribution
- `distribute-fees`: Authorizes head curator to initiate a fee distribution period.
- `claim-fees`: Scholars claim their share of exhibition revenue.

### 🗳️ Exhibition Governance
- `create-exhibition`: Propose a new manuscript exhibition.
- `vote-exhibition`: Vote for or against an exhibition (weighted by folio ownership).

---

## 🔍 Read-Only Functions

- `get-manuscript`: Retrieve metadata for a specific manuscript.
- `get-folio-balance`: Check folio balance of a scholar.
- `get-exhibition`: Fetch an exhibition's metadata.
- `calculate-fee-share`: Estimate the fee a scholar can claim for a manuscript.

---

## 📛 Error Codes

| Code | Description |
|------|-------------|
| `u1200` | Unauthorized action by non-scholar |
| `u1201` | Scholar has insufficient folios |
| `u1202` | Manuscript not found |
| `u1203` | Invalid amount (e.g., folio count or fee) |
| `u1204` | Exhibition not found |
| `u1205` | Scholar has already voted on this proposal |

---

## 👤 Roles

- **Chief Librarian**: Only this role (contract deployer) can onboard new manuscripts.
- **Head Curator**: Responsible for distributing exhibition fees.
- **Scholars**: Stakeholders who own folios and participate in governance.

---

## 🧪 Example Workflow

1. **Manuscript Onboarding**: Chief Librarian adds a manuscript using `acquire-manuscript`.
2. **Folio Sponsorship**: Scholars buy folios with `sponsor-folios`.
3. **Proposal Creation**: A scholar proposes an exhibition with `create-exhibition`.
4. **Voting Period**: Scholars vote using `vote-exhibition`.
5. **Fee Distribution**: Head Curator calls `distribute-fees` for a given period.
6. **Claim Earnings**: Scholars claim their revenue via `claim-fees`.
