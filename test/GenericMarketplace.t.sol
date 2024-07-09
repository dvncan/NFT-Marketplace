// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {GenericMarketplace} from "../src/Modules/GenericMarketplace.sol";
// import {Vesting} from "../src/Vesting.sol";
import {NFT} from "../src/NFT.sol";
import {Cookies} from "../src/Cookies.sol";

enum Type {
    NONE,
    ERC721,
    ERC1155,
    ERC20,
    native
}

contract TestGenericMarketplace is Test {
    GenericMarketplace public gm;
    NFT nft;
    Cookies cook;
    address me = 0xee2A7789515115d1F49b01AB38b502E5d5034Fd3;

    // function setup() public {}

    function testAddNFT() public {
        // vm.startBroadcast();
        vm.startPrank(0xee2A7789515115d1F49b01AB38b502E5d5034Fd3);
        gm = new GenericMarketplace();

        nft = new NFT();

        nft.mint(me, 1000);
        nft.mint(me, 2000);
        nft.mint(me, 3000);

        uint256[] memory value = new uint256[](3);
        value[0] = 1000;
        value[1] = 2000;
        value[2] = 3000;
        nft.setApprovalForAll(address(gm), true);
        gm.addTokenToMarket(
            address(nft),
            GenericMarketplace.Type.ERC721,
            "test",
            3,
            value,
            3
        );
        vm.stopPrank();
        // vm.stopBroadcast();
    }

    function testAddERC20() public {
        // vm.startBroadcast();
        address me = 0xee2A7789515115d1F49b01AB38b502E5d5034Fd3;
        vm.startPrank(me);
        gm = new GenericMarketplace();

        cook = new Cookies();
        uint256[] memory value;
        gm.addTokenToMarket(
            address(cook),
            GenericMarketplace.Type.ERC20,
            "testerc",
            3_000 ether,
            value,
            3_000 ether
        );
        vm.stopPrank();
        // vm.stopBroadcast();
    }
}
