# SHIELD

## Outcome Policy Infrastructure for Autonomous On-Chain Agents

SHIELD explores an outcome policy layer for autonomous on-chain agents.

The core thesis is that authorization alone does not guarantee a desired
economic outcome. SHIELD investigates deterministic transaction policies,
pre-execution analysis, simulation, and on-chain enforcement.

> Let agents act. Define what they can change.

---

## Repository Status

*Research / Pre-MVP*

This repository contains the SHIELD prototype, technical research,
experimental validation, and whitepaper materials.

---

## Current Prototype

The current prototype demonstrates an on-chain enforcement mechanism for
agent-controlled token swaps through a Safe smart account.

The prototype tests:

- Maximum token input
- Allowed router
- Allowed token pair
- Agent authorization
- Policy expiry
- Minimum output requirement
- Post-execution balance verification
- Atomic transaction revert
- Prevention of agent policy escalation

### Core enforcement contract

```text
src/ShieldSwapModule.sol

The module is designed so that the agent cannot directly modify the policy. Policy configuration is restricted to the Safe.

For swap execution, the module:

1. Validates the agent.
2. Validates policy expiry.
3. Validates maximum input amount.
4. Calculates the required minimum output.
5. Executes the swap through the Safe.
6. Checks the Safe's token balance before and after execution.
7. Reverts if the received amount is below the policy requirement.


---

Experimental Validation

The B4 experimental validation demonstrates:

Valid execution

A compliant swap is executed successfully when the output satisfies the configured minimum.

Adversarial execution

The mock router can be configured to:

- return an output below the required minimum, and
- ignore the router-level minimum-output parameter.

In this case SHIELD detects the insufficient output using the Safe's balance delta and reverts the transaction.

The Safe's balances remain unchanged after the failed execution, demonstrating atomic state preservation.


---

Project Structure

shield-demo/
├── src/
│   ├── DemoToken.sol
│   ├── MockRouter.sol
│   ├── ShieldModule.sol
│   └── ShieldSwapModule.sol
│
├── test/
│   ├── Demo.t.sol
│   ├── ShieldModule.t.sol
│   └── ShieldSwapModule.t.sol
│
├── script/
│   ├── Deploy.s.sol
│   └── DeploySwap.s.sol
│
├── docs/
│   └── ...
│
├── evidence/
│   └── ...
│
├── whitepaper/
│   ├── SHIELD-Whitepaper-EN-v1.0.pdf
│   └── SHIELD-Whitepaper-ID-v1.0.pdf
│
└── foundry.toml


---

Build

forge build

Test

forge test

Format

forge fmt

Run Local Ethereum Node

anvil

Deploy

Deployment scripts are located in:

script/

The prototype is intended for local/test environments and is not production-ready or audited.


---

Research Focus

SHIELD investigates:

- Deterministic transaction policies
- Transaction simulation
- Contract risk intelligence
- Outcome-aware constraints
- On-chain enforcement
- Smart-account integration
- Autonomous agent security

The current prototype intentionally focuses on deterministic, testable constraints rather than arbitrary natural-language outcome verification.


---

Whitepaper

- English — SHIELD Whitepaper v1.0
- Bahasa Indonesia — SHIELD Whitepaper v1.0


---

Important Disclaimer

This repository contains a research prototype.

The contracts have not undergone a production security audit and should not be used to protect real funds.

The mock token and router are intentionally simplified for experimental validation.


---

SHIELD

Let agents act. Define what they can change.
