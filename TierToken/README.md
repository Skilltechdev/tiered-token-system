# Tiered Vesting Token with Governance

A production-ready smart contract implementing a capped token with tiered vesting schedules and on-chain governance capabilities, built using the Clarity language.

This smart contract implements a sophisticated token system with the following key features:
- Maximum supply cap of 1 billion tokens
- Tiered vesting schedules with configurable parameters
- On-chain governance system with proposal and voting mechanisms
- Comprehensive security controls and error handling

### Key Features

#### Vesting System
- Multiple vesting tiers with different schedules
- Configurable cliff periods and vesting durations
- Linear vesting after cliff period
- Safe claiming mechanism
- Per-address vesting schedule tracking

#### Governance System
- Proposal creation with minimum token threshold
- Token-weighted voting
- Configurable proposal duration
- Protection against double voting
- Detailed vote tracking

## Technical Specifications

### Constants
```clarity
MAX-SUPPLY: u1000000000
DECIMALS: u6
PROPOSAL-DURATION: u144 (approximately 1 day in blocks)
MIN-PROPOSAL-THRESHOLD: u1000000
```

### Error Codes
```clarity
ERR-NOT-AUTHORIZED (u1001)
ERR-ALREADY-INITIALIZED (u1002)
ERR-NOT-INITIALIZED (u1003)
ERR-INVALID-AMOUNT (u1004)
ERR-MAX-SUPPLY-REACHED (u1005)
ERR-VESTING-LOCKED (u1006)
ERR-INVALID-PROPOSAL (u1007)
ERR-PROPOSAL-EXPIRED (u1008)
ERR-ALREADY-VOTED (u1009)
ERR-INSUFFICIENT-BALANCE (u1010)
```

## Installation

1. Install Clarinet
```bash
curl -sL https://deno.land/x/clarinet/install.sh | sh
```

2. Initialize a new project
```bash
clarinet new my-token-project
cd my-token-project
```

3. Copy the contract to your contracts directory
```bash
cp tiered-vesting-token.clar contracts/
```

## Usage

### Initializing the Contract

The contract must be initialized by the contract owner:
```clarity
(contract-call? .tiered-vesting-token initialize)
```

### Creating Vesting Schedules

Create a vesting schedule for a beneficiary:
```clarity
(contract-call? .tiered-vesting-token create-vesting-schedule
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; beneficiary
    u1000000                                      ;; amount
    block-height                                  ;; start-block
    u4320                                         ;; cliff-blocks (30 days)
    u51840                                        ;; duration-blocks (360 days)
    u1)                                           ;; tier
```

### Claiming Vested Tokens

Beneficiaries can claim their vested tokens:
```clarity
(contract-call? .tiered-vesting-token claim-vested-tokens)
```

### Governance Actions

Creating a proposal:
```clarity
(contract-call? .tiered-vesting-token create-proposal 
    "Update Fee Structure"
    "Proposal to reduce marketplace fees from 2% to 1.5%")
```

Casting a vote:
```clarity
(contract-call? .tiered-vesting-token cast-vote u1 true)  ;; Vote 'yes' on proposal 1
```

## Reading Contract State

### Query Vesting Schedule
```clarity
(contract-call? .tiered-vesting-token get-vesting-schedule 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Query Proposal Details
```clarity
(contract-call? .tiered-vesting-token get-proposal u1)
```

### Check Vote Status
```clarity
(contract-call? .tiered-vesting-token get-vote u1 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Security Considerations

1. Access Control
   - Only contract owner can initialize the contract
   - Only contract owner can create vesting schedules
   - Voting requires token holdings
   - Double-voting protection

2. Input Validation
   - Amount validation
   - Schedule parameter validation
   - Proposal duration checks
   - Vote eligibility verification

3. State Protection
   - Initialization protection
   - Safe arithmetic operations
   - Proposal expiration checks
   - Vesting schedule verification

## Testing

Run the test suite:
```bash
clarinet test
```

Example test cases are provided in the `tests` directory:
- Initialization tests
- Vesting schedule creation tests
- Token claiming tests
- Governance proposal tests
- Voting mechanism tests

## Deployment

1. Build the contract:
```bash
clarinet build
```

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

3. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request