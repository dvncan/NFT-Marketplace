// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19; // to be modified .8.10 -> .8.19 new line

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

// 0x4f5559D56FD6eba0DF026626fD8Dccb7B6603FdA
contract Vesting {
    IERC721 public contractAddress;
    IERC20 public rewardToken;
    address public owner;
    uint256 public startTime;
    mapping(uint256 => bool) public userHasNotClaimed;
    uint256 public tokensPerNFT;

    event UserNOMNOM(uint256 tokenId, address user);
    event vestCreated();
    modifier onlyOwner() {
        require(msg.sender == owner, "You do not own the contract");
        _;
    }

    constructor(address nftAddress) {
        owner = msg.sender;
        contractAddress = IERC721(nftAddress);
        startTime = block.timestamp;
    }

    function startVest(
        uint256 totalVestAmount,
        address rewardTokenAddress
    ) public onlyOwner {
        setRewardToken(totalVestAmount, rewardTokenAddress); //admin functions and transfers
        emit vestCreated();
    }

    function setTokenMemory(uint256[] calldata claimedTokens) public onlyOwner {
        for (uint i = 0; i < claimedTokens.length; i++) {
            userHasNotClaimed[claimedTokens[i]] = true;
        }
    }

    function setRewardToken(
        uint256 totalVestAmount,
        address rewardTokenAddress
    ) internal {
        rewardToken = IERC20(rewardTokenAddress);
        uint256 userBalance = rewardToken.balanceOf(msg.sender);
        require(userBalance >= totalVestAmount, "Balance insufficient");

        tokensPerNFT = 1050000000000000000000;
        rewardToken.transferFrom(msg.sender, address(this), totalVestAmount);
        _checkPayment(address(this), 0, totalVestAmount);
    }

    function endVest() public onlyOwner {
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function snack(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimToken(tokenIds[i]);
        }
    }

    function claimToken(uint256 tokenId) internal {
        require(
            block.timestamp <= startTime + 1814400,
            "Claiming period is over"
        );

        // get user balance before transfer
        uint256 userBalance = rewardToken.balanceOf(msg.sender);
        // token id exists
        require(tokenId <= 10000, "token id invalid");
        // msg.sender is the owner of the token claiming
        require(
            msg.sender == contractAddress.ownerOf(tokenId),
            "You do not own the token"
        );
        // claim only happens once
        require(
            userHasNotClaimed[tokenId] == true,
            "Tokens have already been claimed"
        );
        // sufficient balance
        require(
            rewardToken.balanceOf(address(this)) > 0,
            "Contract is out of cookies"
        );
        userHasNotClaimed[tokenId] = false;
        require(
            rewardToken.transfer(msg.sender, tokensPerNFT),
            "Reward token transfer failure"
        );
        _checkPayment(msg.sender, userBalance, tokensPerNFT);
        // check mapping value hasPersonClaimed
        // false = true
        emit UserNOMNOM(tokenId, msg.sender);
    }

    function _checkPayment(
        address receiver,
        uint256 balanceBefore,
        uint256 transferAmount
    ) internal view {
        uint256 balanceAfter = rewardToken.balanceOf(receiver);
        require(
            balanceAfter >= balanceBefore + transferAmount,
            "User balance is to low"
        );
    }

    function updateStartTime(uint256 newTime) public onlyOwner {
        startTime = newTime;
    }
}
