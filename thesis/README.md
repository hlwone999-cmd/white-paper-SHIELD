# SHIELD — Research Thesis

## Outcome Policy Enforcement for Autonomous On-Chain Agents

This directory contains the academic research documentation,
experimental validation, and thesis materials for SHIELD.

SHIELD investigates whether deterministic economic outcome constraints
can be enforced on-chain for autonomous agents operating through
smart accounts.

---

## Research Status

*Status:* Experimental Research / Pre-MVP

*Network:* Local Anvil

*Chain ID:* 31337

*Prototype:* Foundry + Solidity + Safe Smart Account

---

## Research Question

> Can an autonomous on-chain agent be permitted to execute a transaction
> while being prevented from producing a deterministic economic outcome
> that violates a user-defined policy?

---

## Core Hypothesis

Traditional authorization mechanisms determine whether an agent is
allowed to execute a transaction.

SHIELD investigates an additional security layer:

> authorization of the action + enforcement of the resulting economic
> outcome.

The prototype evaluates this concept using a deterministic minimum-output
constraint for token swaps.

---

## Thesis Documents

### English

SHIELD-Thesis-EN.pdf

### Bahasa Indonesia

SHIELD-Thesis-ID.pdf

The PDF documents will contain the complete academic treatment of the
research, methodology, experimental results, limitations, and
reproducibility information.

---

## Experimental Evidence

The thesis is supported by the experimental validation available in:

```text
../docs/SHIELD-Experimental-Validation.md
Additional screenshots and experimental evidence are stored in:
../evidence/B4-onchain-enforcement/
Prototype
The core enforcement mechanism is implemented in:
../src/ShieldSwapModule.sol
The automated tests are located in:
../test/ShieldSwapModule.t.sol
Main Experimental Finding
The strongest experimental case configures the mock router to:
Output = 17 WBTC
while the SHIELD policy requires:
Minimum = 18 WBTC
The router is additionally configured to ignore its own minimum-output parameter.
SHIELD independently detects the insufficient output and reverts the transaction with:
OutputTooLow
The Safe's balances remain unchanged after the failed execution.
This provides experimental evidence that a deterministic outcome constraint can be enforced inside the transaction execution path rather than relying solely on the underlying protocol's own slippage protection.
Reproducibility
The prototype can be built and tested using Foundry:
forge build
forge test
The experiment uses a local Anvil network and intentionally simplified demo contracts.
Limitations
This research does not claim that SHIELD can enforce arbitrary natural-language economic intent.
The current prototype is limited to deterministic constraints.
It does not establish protection against:
All MEV strategies
Compromised approved protocols
Oracle manipulation
Arbitrary portfolio drawdown
General economic intent
Production smart-contract vulnerabilities
The prototype has not been professionally audited.
Repository Structure
shield-demo/
├── src/          # SHIELD smart contracts
├── test/         # Automated tests
├── script/       # Deployment scripts
├── docs/         # Experimental validation
├── evidence/     # Experimental evidence
├── whitepaper/   # SHIELD whitepapers
└── thesis/       # Academic research and thesis
Disclaimer
This repository contains an experimental research prototype.
It is not production-ready and must not be used to protect real funds.
The local blockchain, demo tokens, and mock router are intended solely for research and reproducibility.
