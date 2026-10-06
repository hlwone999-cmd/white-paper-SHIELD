// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {Enum} from "../lib/safe-smart-account/contracts/libraries/Enum.sol";
import {ShieldModule} from "../src/ShieldModule.sol";
import "./ShieldModule.t.sol";

contract DemoTest is ShieldModuleTest {
    function _why(bytes4 s) internal pure returns (string memory) {
        if (s == ShieldModule.AmountTooHigh.selector) return "amount above per-transaction limit";
        if (s == ShieldModule.RecipientNotAllowed.selector) return "recipient not on allowlist";
        if (s == ShieldModule.NotAgent.selector) return "caller is not the authorized agent";
        if (s == ShieldModule.Expired.selector) return "session expired";
        return "rejected";
    }

    function _try(string memory label, address caller, address to, uint256 amt) internal {
        vm.prank(caller);
        try module.transferToken(to, amt) {
            console.log("  ALLOW:", label);
        } catch (bytes memory r) {
            console.log("  BLOCK:", label);
            console.log("         reason:", _why(bytes4(r)));
        }
    }

    function test_Demo() public {
        console.log("");
        console.log("=== SHIELD DEMO: AI agent controlling a Safe with 10,000 USDC ===");
        console.log("Policy: max 500 USDC per tx | approved recipient only | 24h session");
        console.log("");

        _try("Agent sends 400 USDC to approved address", agent, friend, 400e6);
        _try("Agent sends 600 USDC (over the limit)", agent, friend, 600e6);
        _try("Agent sends 100 USDC to unknown address", agent, stranger, 100e6);
        _try("Someone else calls the module", stranger, friend, 100e6);

        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", agent, 5_000e6);
        vm.prank(agent);
        try safe.execTransactionFromModule(address(usdc), 0, data, Enum.Operation.Call) returns (bool) {
            console.log("  ALLOW: Agent bypasses SHIELD and calls the Safe directly");
        } catch {
            console.log("  BLOCK: Agent bypasses SHIELD and calls the Safe directly");
            console.log("         reason: Safe only accepts calls from enabled modules");
        }

        vm.warp(block.timestamp + 2 days);
        _try("Agent tries again after the session expired", agent, friend, 100e6);

        console.log("");
        console.log("Safe balance (USDC):", usdc.balanceOf(address(safe)) / 1e6);
        console.log("Agent balance (USDC):", usdc.balanceOf(agent) / 1e6);
    }
}
