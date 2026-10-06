// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Safe} from "../lib/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "../lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Enum} from "../lib/safe-smart-account/contracts/libraries/Enum.sol";
import {DemoToken} from "../src/DemoToken.sol";
import {MockRouter} from "../src/MockRouter.sol";
import {ShieldSwapModule} from "../src/ShieldSwapModule.sol";

contract DeploySwap is Script {
    function run() external {
        uint256 ownerPk = vm.envUint("OWNER_PK");
        address owner = vm.addr(ownerPk);
        address agent = vm.envAddress("AGENT");

        vm.startBroadcast(ownerPk);

        // Safe
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

        Safe safe = Safe(
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

        // Demo tokens
        DemoToken usdc = new DemoToken("USDC", 6);
        DemoToken wbtc = new DemoToken("WBTC", 6);

        // Mock router
        MockRouter router = new MockRouter();

        // SHIELD swap module
        ShieldSwapModule module = new ShieldSwapModule(address(safe));

        // Fund Safe
        usdc.mint(address(safe), 10_000e6);

        // Router rate:
        // 1,000 USDC -> 20 WBTC
        router.setRate(20_000);

        // Enable SHIELD module
        _exec(
            safe,
            owner,
            address(safe),
            abi.encodeWithSignature(
                "enableModule(address)",
                address(module)
            )
        );

        // Policy:
        // max 1,000 USDC per swap
        // minimum 18 WBTC per 1,000 USDC
        // expires in 24 hours
        _exec(
            safe,
            owner,
            address(module),
            abi.encodeWithSelector(
                ShieldSwapModule.setPolicy.selector,
                agent,
                address(router),
                address(usdc),
                address(wbtc),
                1_000e6,
                18_000,
                block.timestamp + 1 days
            )
        );

        vm.stopBroadcast();

        console.log("=== SHIELD SWAP DEPLOYMENT ===");
        console.log("OWNER  =", owner);
        console.log("AGENT  =", agent);
        console.log("SAFE   =", address(safe));
        console.log("MODULE =", address(module));
        console.log("USDC   =", address(usdc));
        console.log("WBTC   =", address(wbtc));
        console.log("ROUTER =", address(router));
    }

    function _exec(
        Safe safe,
        address owner,
        address to,
        bytes memory data
    ) internal {
        bytes memory sig = abi.encodePacked(
            bytes32(uint256(uint160(owner))),
            bytes32(0),
            uint8(1)
        );

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
}
