// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {GenericMarketplace} from "./../src/GenericMarketplace.sol";
// import {Vesting} from "../src/Vesting.sol";
import {NFT} from "../src/NFT.sol";

contract TestCookies is Test {
    GenericMarketplace public GM;
    NFT nft;

    function setup() public {
        GM = new GenericMarketplace();
    }
}
