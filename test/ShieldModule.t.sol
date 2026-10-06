// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ShieldModule} from "../src/ShieldModule.sol";
import {Safe} from "../lib/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "../lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Enum} from "../lib/safe-smart-account/contracts/libraries/Enum.sol";

contract MockUSDC {
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }
}

contract ShieldModuleTest is Test {
    Safe safe;
    ShieldModule module;
    MockUSDC usdc;

    address owner = makeAddr("owner");
    address agent = makeAddr("agent");
    address friend = makeAddr("friend");
    address stranger = makeAddr("stranger");

    function setUp() public {
        Safe singleton = new Safe();
        SafeProxyFactory factory = new SafeProxyFactory();

        address[] memory owners = new address[](1);
        owners[0] = owner;
        bytes memory init = abi.encodeWithSelector(
            Safe.setup.selector,
            owners, 1, address(0), bytes(""), address(0), address(0), 0, address(0)
        );
        safe = Safe(payable(address(factory.createProxyWithNonce(address(singleton), init, 1))));

        usdc = new MockUSDC();
        usdc.mint(address(safe), 10_000e6);

        module = new ShieldModule(address(safe));

        _exec(address(safe), abi.encodeWithSignature("enableModule(address)", address(module)));
        _exec(address(module), abi.encodeWithSelector(
            ShieldModule.setPolicy.selector, agent, address(usdc), 500e6, block.timestamp + 1 days
        ));
        _exec(address(module), abi.encodeWithSelector(ShieldModule.setRecipient.selector, friend, true));
    }

    function _exec(address to, bytes memory data) internal {
        bytes memory sig = abi.encodePacked(bytes32(uint256(uint160(owner))), bytes32(0), uint8(1));
        vm.prank(owner);
        safe.execTransaction(to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sig);
    }

    function test_AllowedTransferWorks() public {
        vm.prank(agent);
        module.transferToken(friend, 400e6);
        assertEq(usdc.balanceOf(friend), 400e6);
        assertEq(usdc.balanceOf(address(safe)), 9_600e6);
    }

    function test_RevertWhen_AmountTooHigh() public {
        vm.prank(agent);
        vm.expectRevert(ShieldModule.AmountTooHigh.selector);
        module.transferToken(friend, 600e6);
    }

    function test_RevertWhen_RecipientNotAllowed() public {
        vm.prank(agent);
        vm.expectRevert(ShieldModule.RecipientNotAllowed.selector);
        module.transferToken(stranger, 100e6);
    }

    function test_RevertWhen_NotAgent() public {
        vm.prank(stranger);
        vm.expectRevert(ShieldModule.NotAgent.selector);
        module.transferToken(friend, 100e6);
    }

    function test_RevertWhen_Expired() public {
        vm.warp(block.timestamp + 2 days);
        vm.prank(agent);
        vm.expectRevert(ShieldModule.Expired.selector);
        module.transferToken(friend, 100e6);
    }

    function test_AgentCannotChangePolicy() public {
        vm.prank(agent);
        vm.expectRevert(ShieldModule.NotSafe.selector);
        module.setPolicy(agent, address(usdc), 999_999e6, block.timestamp + 365 days);
    }

    function test_AgentCannotBypassModule() public {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", agent, 5_000e6);
        vm.prank(agent);
        vm.expectRevert();
        safe.execTransactionFromModule(address(usdc), 0, data, Enum.Operation.Call);
        assertEq(usdc.balanceOf(agent), 0);
    }
}
