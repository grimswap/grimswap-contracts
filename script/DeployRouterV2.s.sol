// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {GrimSwapRouterV2} from "../src/zk/GrimSwapRouterV2.sol";

interface IGrimPoolMultiToken {
    function releaseForSwap(uint256 amount) external;
    function releaseTokenForSwap(address token, uint256 amount) external;
    function setAuthorizedRouter(address router, bool authorized) external;
}

interface IPoolSwapTest {
    struct TestSettings {
        bool takeClaims;
        bool settleUsingBurn;
    }
}

contract DeployRouterV2 is Script {
    // Existing contracts on Unichain Sepolia
    address constant GRIM_POOL_MULTI_TOKEN = 0x6777cfe2A72669dA5a8087181e42CA3dB29e7710;
    address constant SWAP_ROUTER = 0x9140a78c1A137c7fF1c151EC8231272aF78a99A4;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy GrimSwapRouterV2
        GrimSwapRouterV2 router = new GrimSwapRouterV2(
            IGrimPoolMultiToken(GRIM_POOL_MULTI_TOKEN),
            IPoolSwapTest(SWAP_ROUTER)
        );
        console.log("GrimSwapRouterV2 deployed at:", address(router));

        // Authorize the new router on GrimPoolMultiToken
        IGrimPoolMultiToken(GRIM_POOL_MULTI_TOKEN).setAuthorizedRouter(address(router), true);
        console.log("Authorized router on GrimPoolMultiToken");

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("GrimSwapRouterV2:", address(router));
    }
}
