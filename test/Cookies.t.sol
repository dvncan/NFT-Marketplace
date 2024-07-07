// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import {Cookies} from "../src/Cookies.sol";
import {Vesting} from "../src/Vesting.sol";
import {NFT} from "../src/NFT.sol";

contract TestCookies is Test {
    Cookies public cookiesCoin;
    Vesting public vest;
    NFT nft;

    function setUp() public {
        cookiesCoin = new Cookies();
        nft = new NFT();
        vest = new Vesting(address(nft));
        cookiesCoin.approve(address(vest), 100 * 1_000_000_000 ether);
        vest.startVest(105_000_000 ether, address(cookiesCoin));
        assertEq(
            cookiesCoin.balanceOf(address(this)),
            105_000_000 ether,
            "Start function failure"
        );

        nft.mint(address(this), 1);
        nft.mint(address(this), 2);
        nft.mint(address(this), 3);
        nft.mint(address(this), 4);
        nft.mint(address(this), 5);
    }

    function testTransfer() public {
        cookiesCoin.transfer(
            0xf3e4D421E826a03848254095455ce818Ace25AF6,
            210 ether
        );
        assertEq(
            cookiesCoin.balanceOf(address(this)),
            (210_000_000 - 210) * 1 ether,
            "invalid balance"
        );
    }

    function testNewClaim() public {
        assertEq(
            cookiesCoin.balanceOf(address(this)),
            105000000000000000000000000,
            "Start function failure"
        );
        uint256[] memory unclaimedArray = new uint256[](3);
        unclaimedArray[0] = uint256(1);
        unclaimedArray[1] = uint256(2);
        unclaimedArray[2] = uint256(3);

        vest.setTokenMemory(unclaimedArray);

        // Create a new uint256[] memory array
        uint256[] memory claimedArray = new uint256[](2);

        // Convert each element and assign it to the new array

        claimedArray[0] = uint256(4);
        claimedArray[1] = uint256(5);

        // Now you can pass the convertedArray to the function
        vest.snack(unclaimedArray);

        assertEq(nft.ownerOf(1), address(this), "assertion issue");
        assertEq(
            cookiesCoin.balanceOf(address(this)),
            105003150000000000000000000,
            "Failure balance claim 1"
        );
    }

    function testFailClaim() public {
        // Create a new uint256[] memory array
        uint256[] memory claimedArray = new uint256[](2);

        // Convert each element and assign it to the new array

        claimedArray[0] = uint256(4);
        claimedArray[1] = uint256(5);
        vest.snack(claimedArray);
    }

    function testUpdateStartTime() public {
        vest.updateStartTime(10);
        assertEq(
            vest.startTime(),
            (1814400 + 10),
            "Assertion failure start time"
        );
    }
}
