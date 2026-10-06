# SHIELD — Experimental Validation

## On-Chain Outcome Policy Enforcement

*Project:* SHIELD  
*Version:* 1.0  
*Status:* Research / Pre-MVP  
*Network:* Local Anvil  
*Chain ID:* 31337

---

## 1. Purpose

This experiment evaluates whether SHIELD can enforce deterministic
economic constraints on transactions initiated by an autonomous agent.

The key research question is:

> Can an autonomous agent execute a permitted transaction while being
> prevented from producing an explicitly prohibited economic outcome?

The experiment focuses on token swaps executed through a Safe smart
account.

---

## 2. Research Hypothesis

Authorization alone does not guarantee that a transaction produces an
acceptable economic outcome.

SHIELD therefore introduces an additional policy layer that evaluates
transaction conditions and enforces deterministic constraints on-chain.

The prototype specifically tests a minimum-output constraint.

---

## 3. Experimental Environment

The experiment uses:

- Foundry
- Anvil local Ethereum network
- Safe smart account
- Solidity smart contracts
- Demo ERC-20 tokens
- Mock swap router
- SHIELD Swap Module

The prototype is intentionally simplified and is not intended for
production use.

---

## 4. Policy

The Safe owner configures the following policy:

| Parameter | Value |
|---|---|
| Agent | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 |
| Router | 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 |
| Token In | USDC |
| Token Out | WBTC |
| Maximum Input | 1,000 USDC |
| Minimum Output Rate | 18,000 WBTC units / 1,000,000 USDC units |
| Expiry | 24 hours |
| Policy modification | Safe only |

The agent is therefore authorized to execute swaps within these
constraints but cannot modify the policy itself.

---

## 5. On-Chain Enforcement

The enforcement mechanism is implemented in:

```text
src/ShieldSwapModule.sol
The enforcement mechanism is implemented in:

The module performs the following checks:

1. Verify that the caller is the authorized agent.
2. Verify that the policy has not expired.
3. Verify that the input amount does not exceed the configured maximum.
4. Calculate the required minimum output.
5. Execute the swap through the Safe.
6. Measure the Safe's token balance before execution.
7. Measure the Safe's token balance after execution.
8. Revert if the received amount is below the required minimum.

The important property is that the enforcement occurs inside the transaction execution path rather than relying solely on an off-chain server.


---

6. Automated Verification

The swap module tests include:

test/ShieldSwapModule.t.sol

The test suite verifies:

- Successful swap when output satisfies the policy.
- Rejection when input exceeds the maximum.
- Rejection when the session has expired.
- Rejection when the caller is not the authorized agent.
- Rejection when received output is below the policy minimum.

Observed result:

5 passed; 0 failed; 0 skipped


---

7. B4.1 — Valid Swap

The router was configured with an output rate satisfying the policy.

The agent executed:

1,000 USDC → 20 WBTC

The configured minimum was:

18 WBTC

Therefore:

20 WBTC >= 18 WBTC

The transaction succeeded.

The Safe balance changed from:

USDC: 10,000
WBTC: 0

to:

USDC: 9,000
WBTC: 20

This demonstrates successful execution of a transaction that satisfies the configured outcome constraint.


---

8. B4.2 — Router-Level Slippage Rejection

The router was then configured with an output rate of:

17 WBTC

while SHIELD required:

18 WBTC

The router was still configured to honor the minimum-output parameter.

As a result, the router itself rejected the swap.

This case demonstrates that protocol-native slippage protection can reject an invalid transaction, but it is not by itself evidence of SHIELD's post-execution enforcement.


---

9. B4.3 — Adversarial Router

The stronger adversarial test disabled the router's own minimum-output enforcement.

The router was configured to:

Output rate = 17 WBTC
Honor minOut = false

SHIELD still required:

Minimum output = 18 WBTC

The router therefore attempted to produce:

17 WBTC

despite the configured minimum.

SHIELD calculated the Safe's token balance delta and detected:

received = 17 WBTC
required = 18 WBTC

The module then reverted with:

OutputTooLow

This demonstrates that SHIELD's own post-execution balance check can reject an output that violates the policy even when the underlying router ignores the minimum-output parameter.


---

10. Atomic State Preservation

Following the adversarial execution attempt, the Safe balances remained unchanged.

Observed state:

Safe USDC: 8,000
Safe WBTC: 40

These were the balances immediately before the failed adversarial attempt.

Therefore the attempted invalid swap did not partially execute.

This demonstrates the atomic nature of the enforcement mechanism: when the policy check fails, the transaction reverts and the state change is not committed.


---

11. Policy Escalation Test

The agent attempted to modify the policy directly using:

setPolicy(...)

The transaction was rejected with:

NotSafe

The policy configuration function contains:

modifier onlySafe() {
    if (msg.sender != address(safe)) revert NotSafe();
    _;
}

Therefore the autonomous agent cannot simply increase its own limits or remove the minimum-output constraint.


---

12. Evidence Chain

The experimental evidence follows this chain:

Policy
   ↓
Smart Contract Enforcement
   ↓
Automated Tests
   ↓
On-Chain Execution
   ↓
Adversarial Execution
   ↓
Revert
   ↓
State Verification

The strongest evidence is the combination of:

1. Adversarial router configuration.
2. SHIELD OutputTooLow rejection.
3. Unchanged Safe balances.

Together these demonstrate that the outcome constraint is enforced inside the transaction execution path.


---

13. Reproducibility

The experiment can be reproduced using the Foundry project contained in this repository.

Build:

forge build

Run tests:

forge test

Format:

forge fmt

Start local chain:

anvil

Deployment scripts are available under:

script/


---

14. Limitations

This experiment does not establish that SHIELD solves arbitrary economic intent verification.

The prototype currently uses deterministic constraints.

It does not provide:

- General portfolio drawdown verification.
- Arbitrary natural-language intent enforcement.
- Protection against all MEV strategies.
- Protection against compromised approved protocols.
- Protection against every oracle manipulation scenario.
- Production-grade contract security.
- Mainnet security guarantees.

The mock token and router are intentionally simplified for controlled experimentation.

The contracts have not been audited.


---

15. Research Interpretation

The experiment provides evidence for a narrower claim:

> A smart-account module can enforce a deterministic transaction outcome constraint on-chain, including rejecting an output that violates the configured minimum even when the underlying router does not enforce that minimum itself.



This supports the SHIELD research thesis that transaction authorization and transaction outcome enforcement can be treated as separate security layers.

It does not prove that arbitrary economic outcomes can be enforced generically.


---

16. Conclusion

The B4 experiment demonstrates a working prototype of outcome-aware on-chain enforcement.

A permitted agent transaction can be executed when it satisfies the policy, while an adversarial transaction that produces an insufficient output is reverted by the SHIELD module.

The experiment therefore provides a reproducible technical basis for further research into deterministic outcome policies for autonomous on-chain agents.


---

17. Contract Addresses

Component	Address

Safe	0x8154Db6A7BC97A4aF62c7fF19073554CF5C4aB26
SHIELD Module	0x0165878A594ca255338adfa4d48449f69242Eb8F
USDC	0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
WBTC	0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
Mock Router	0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
Agent	0x70997970C51812dc3A010C7d01b50e0d17dc79C8



---

18. Disclaimer

This repository contains an experimental research prototype.

It has not undergone a professional security audit and must not be used to protect real funds.

The local network, demo tokens, and mock router are intended solely for research and reproducibility.
