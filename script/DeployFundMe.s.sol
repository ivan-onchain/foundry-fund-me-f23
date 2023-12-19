// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    constructor() {
        
    }
    FundMe fundMe;
    function run() external returns(FundMe){
        // Before vm.startBroadcast() -> not a real tx
        HelperConfig helperConfig = new HelperConfig();
        address usdEthPriceFeed = helperConfig.activeNetworkConfig();
        // After vm.startBroadcast() -> real tx
        vm.startBroadcast();
        fundMe = new FundMe(usdEthPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}