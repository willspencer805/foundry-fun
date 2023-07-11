pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // anything included before the broadcast starts is not a "real" tx
        HelperConfig helperConfig = new HelperConfig();
        (address priceFeedAddress) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeedAddress);
        vm.stopBroadcast();
        return fundMe;
    }
}