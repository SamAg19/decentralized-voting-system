# Voting dApp - Complete Setup Guide

This guide walks you through setting up and running the complete Voting decentralized application with smart contracts and REST API backend.

## Project Overview

- **Smart Contract**: Solidity voting contract with OpenZeppelin's Ownable
- **Testing**: Comprehensive tests in Solidity 
- **Deployment**: Automated deployment scripts with address persistence
- **Backend API**: Node.js/Express REST API for contract interaction

## Prerequisites

- Node.js (v22+)
- npm

## Quick Start

### 1. Start Hardhat Local Network

Open a terminal and run:

```bash
npx hardhat node
```

**Keep this terminal running!** This starts a local Ethereum node with 20 test accounts.

### 2. Deploy the Smart Contract

In a new terminal:

```bash
npx hardhat run scripts/deploy-voting.ts --network localhost
```

This will:
- Deploy the Voting contract to your local network
- Save the contract address to `deployment.json`
- Display the contract address and owner

**Expected output:**
```
Starting Voting contract deployment...
Deploying with account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Account balance: 10000.0 ETH

Voting contract deployed!
Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Owner Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Network: localhost

Contract address saved to deployment.json
```

### 3. Configure Backend Environment

```bash
cd backend
cp .env.example .env
```

The default `.env` configuration works with Hardhat's local network:
```env
RPC_URL=http://127.0.0.1:8545
OWNER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
PORT=3000
NODE_ENV=development
```

### 4. Start the Backend Server

```bash
npm run dev
```

**Expected output:**
```
Voting API server running on port 3000
Health check: http://localhost:3000/health

Available endpoints:
  POST   http://localhost:3000/api/candidates
  GET    http://localhost:3000/api/candidates
  POST   http://localhost:3000/api/vote
  GET    http://localhost:3000/api/winner
```

## Testing the Complete System

### Test with cURL

#### 1. Check Backend Health
```bash
curl http://localhost:3000/health
```

#### 2. Add Candidates (Owner Only)
```bash
curl -X POST http://localhost:3000/api/candidates/add \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'

curl -X POST http://localhost:3000/api/candidates/add \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob"}'

curl -X POST http://localhost:3000/api/candidates/add \
  -H "Content-Type: application/json" \
  -d '{"name": "Charlie"}'
```

#### 3. View All Candidates
```bash
curl http://localhost:3000/api/candidates
```

#### 4. Cast Votes

Use different Hardhat test account private keys:

```bash
# Vote from Account #1 (for Alice)
curl -X POST http://localhost:3000/api/vote \
  -H "Content-Type: application/json" \
  -d '{
    "voterPrivateKey": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    "candidateIndex": 0
  }'

# Vote from Account #2 (for Bob)
curl -X POST http://localhost:3000/api/vote \
  -H "Content-Type: application/json" \
  -d '{
    "voterPrivateKey": "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
    "candidateIndex": 1
  }'

# Vote from Account #3 (for Alice)
curl -X POST http://localhost:3000/api/vote \
  -H "Content-Type: application/json" \
  -d '{
    "voterPrivateKey": "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
    "candidateIndex": 0
  }'
```

#### 5. Get Winner
```bash
curl http://localhost:3000/api/winner
```

