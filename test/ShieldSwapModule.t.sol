// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ShieldSwapModule} from "../src/ShieldSwapModule.sol";
import {DemoToken} from "../src/DemoToken.sol";
import {MockRouter} from "../src/MockRouter.sol";
import {Safe} from "../lib/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "../lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Enum} from "../lib/safe-smart-account/contracts/libraries/Enum.sol";

contract ShieldSwapModuleTest is Test {
    Safe safe;
    ShieldSwapModule module;
    DemoToken usdc;
    DemoToken wbtc;
    MockRouter router;

    address owner = makeAddr("owner");
    address agent = makeAddr("agent");

    uint256 constant MAX_IN = 1_000e6;

    // 18 WBTC minimum untuk setiap 1,000 USDC.
    // Karena kedua token demo memakai 6 decimals:
    // 18_000 * 1,000e6 / 1e6 = 18e6.
    uint256 constant MIN_OUT_PER_MILLION = 18_000;

    function setUp() public {
        // Deploy Safe
        Safe singleton = new Safe();
        SafeProxyFactory factory = new SafeProxyFactory();

        address[] memory owners = new address[](1);
        owners[0] = owner;

        bytes memory init = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            1,
            address(0),
            bytes(""),
            address(0),
            address(0),
            0,
            address(0)
        );

        safe = Safe(
            payable(
                address(
                    factory.createProxyWithNonce(
                        address(singleton),
                        init,
                        1
                    )
                )
            )
        );

        // Deploy demo tokens
        usdc = new DemoToken("USDC", 6);
        wbtc = new DemoToken("WBTC", 6);

        // Deploy mock router
        router = new MockRouter();

        // Deploy SHIELD swap module
        module = new ShieldSwapModule(address(safe));

        // Fund Safe with 10,000 USDC
        usdc.mint(address(safe), 10_000e6);

        // Enable SHIELD module pada Safe
        _exec(
            address(safe),
            abi.encodeWithSignature(
                "enableModule(address)",
                address(module)
            )
        );

        // Set deterministic SHIELD policy
        _exec(
            address(module),
            abi.encodeWithSelector(
                ShieldSwapModule.setPolicy.selector,
                agent,
                address(router),
                address(usdc),
                address(wbtc),
                MAX_IN,
                MIN_OUT_PER_MILLION,
                block.timestamp + 1 days
            )
        );
    }

    function _exec(address to, bytes memory data) internal {
        bytes memory sig = abi.encodePacked(
            bytes32(uint256(uint160(owner))),
            bytes32(0),
            uint8(1)
        );

        vm.prank(owner);

        safe.execTransaction(
            to,
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sig
        );
    }

    function test_SwapSucceedsWhenOutputMeetsMinimum() public {
        // 1,000 USDC -> 20 WBTC
        // Policy minimum = 18 WBTC
        router.setRate(20_000);

        vm.prank(agent);
        module.swap(1_000e6);

        assertEq(
            wbtc.balanceOf(address(safe)),
            20e6
        );

        assertEq(
            usdc.balanceOf(address(safe)),
            9_000e6
        );

        // Approval harus dikembalikan menjadi 0.
        assertEq(
            usdc.allowance(address(safe), address(router)),
            0
        );
    }

    function test_RevertWhen_OutputTooLow() public {
        // Router sengaja memberikan hanya 17 WBTC.
        // Policy membutuhkan minimal 18 WBTC.
        router.setRate(17_000);

        // Router sengaja mengabaikan minOut.
        router.setHonor(false);

        vm.prank(agent);

        vm.expectRevert(
            ShieldSwapModule.OutputTooLow.selector
        );

        module.swap(1_000e6);

        // Karena transaksi revert, seluruh state harus rollback.
        assertEq(
            usdc.balanceOf(address(safe)),
            10_000e6
        );

        assertEq(
            wbtc.balanceOf(address(safe)),
            0
        );

        assertEq(
            usdc.allowance(address(safe), address(router)),
            0
        );
    }

    function test_RevertWhen_AmountTooHigh() public {
        router.setRate(20_000);

        vm.prank(agent);

        vm.expectRevert(
            ShieldSwapModule.AmountTooHigh.selector
        );

        module.swap(1_001e6);
    }

    function test_RevertWhen_NotAgent() public {
        router.setRate(20_000);

        address stranger = makeAddr("stranger");

        vm.prank(stranger);

        vm.expectRevert(
            ShieldSwapModule.NotAgent.selector
        );

        module.swap(1_000e6);
    }

    function test_RevertWhen_Expired() public {
        router.setRate(20_000);

        vm.warp(block.timestamp + 2 days);

        vm.prank(agent);

        vm.expectRevert(
            ShieldSwapModule.Expired.selector
        );

        module.swap(1_000e6);
    }

    function test_AgentCannotChangeRouterPolicy() public {
        vm.prank(agent);

        vm.expectRevert(
            ShieldSwapModule.NotSafe.selector
        );

        module.setPolicy(
            agent,
            address(0x1234),
            address(usdc),
            address(wbtc),
            MAX_IN,
            MIN_OUT_PER_MILLION,
            block.timestamp + 1 days
        );
    }
}
