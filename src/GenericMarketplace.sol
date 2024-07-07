// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract GenericMarketplace is ReentrancyGuard {
    using SafeERC20 for IERC20;
    enum Status {
        INACTIVE,
        ACTIVE
    }
    enum Type {
        NONE,
        ERC721,
        ERC1155,
        ERC20,
        native
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    struct tokenIds {
        uint256[] ids;
        mapping(uint256 => bool) holding;
        mapping(uint256 => bool) transferred;
        uint32 index;
    }

    struct AcceptedTokens {
        address owner;
        address contractAddress;
        Status status;
        Type tokenType;
        tokenIds ids;
        string tokenName;
        uint256 totalSupply;
    }
    address public owner;

    mapping(address => Status) public tokenStatus;
    mapping(address => AcceptedTokens) private tokens;
    mapping(Type => function(address, uint256) internal)
        public purchaseTokenFunctions;

    error TokenAlreadyExists();
    error InvalidTokenType();
    error TotalSupplyMustBeGreaterThanZero();
    error PaymentInvalid();
    error InsufficientBalance();
    error TokenNotForSale();
    error TokenDoesNotExist();
    error TokenIDInvalid();
    error TokenNotOwnedBySender();
    error TokenOwnedByContract();

    event CollectionNowAccepted(
        address indexed contractAddress,
        string collectionName,
        uint256 totalSupply
    );

    event PurchaseTokenAccepted(
        address indexed contractAddress,
        string collectionName,
        uint256 totalSupply
    );

    constructor() {
        owner = msg.sender;
        purchaseTokenFunctions[Type.ERC721] = this.tokenERC721;
        purchaseTokenFunctions[Type.ERC1155] = this.tokenERC1155;
        purchaseTokenFunctions[Type.ERC20] = this.tokenERC20;
        purchaseTokenFunctions[Type.native] = this.tokenNative;
    }

    function addTokenToMarket(
        address _contractAddress,
        Type _tokenType,
        string memory _collectionName,
        uint256 _totalSupply,
        uint256[] calldata _tokenIds,
        uint256 numberOfTokens
    ) public onlyOwner {
        if (tokens[_contractAddress].status == Status.ACTIVE)
            revert TokenAlreadyExists();
        if (
            _tokenType != Type.ERC721 ||
            _tokenType != Type.ERC1155 ||
            _tokenType != Type.ERC20 ||
            _tokenType != Type.native
        ) revert InvalidTokenType();
        if (_totalSupply < 1) revert TotalSupplyMustBeGreaterThanZero();
        require(
            _tokenType == Type.ERC721 ||
                _tokenType == Type.ERC1155 ||
                _tokenType == Type.ERC20 ||
                _tokenType == Type.native,
            "Invalid token type"
        );
        if (tokenStatus[_contractAddress] == Status.INACTIVE) {
            AcceptedTokens storage local = tokens[_contractAddress];
            local.owner = msg.sender;
            local.contractAddress = _contractAddress;
            local.status = Status.ACTIVE;
            local.tokenType = _tokenType;
            local.tokenName = _collectionName;
            local.totalSupply = _totalSupply;
            tokenStatus[_contractAddress] == Status.ACTIVE;
        }
        // local.ids.ids = _tokenIds;

        if (_tokenType == Type.ERC721 || _tokenType == Type.ERC1155) {
            if (_tokenIds.length < 1) revert TokenIDInvalid();
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (local.ids.holding[_tokenIds[i]])
                    revert TokenOwnedByContract();
                local.ids.ids.push(_tokenIds[i]);
                local.ids.holding[_tokenIds[i]] = true;
                local.ids.index++;
            }
        } else if (_tokenType == Type.ERC20 || _tokenType == Type.native) {
            local.ids.index = numberOfTokens;
        }
        purchaseTokenFunctions[_tokenType](_contractAddress, numberOfTokens);
    }

    fucntion userPlace

    function tokenERC721(
        address contractAddress,
        uint256 numberOfTokens
    ) internal {
        IERC721 nft = IERC721(contractAddress);
        if (nft.balanceOf(msg.sender) < 1) revert InsufficientBalance();
        for (
            uint256 j = tokens[contractAddress].ids.index - numberOfTokens - 1;
            j > tokens[contractAddress].ids.index;
            j++
        ) {
            if (tokens[contractAddress].ids.holding[j])
                revert TokenNotOwnedBySender();
            nft.safeTransferFrom(
                msg.sender,
                address(this),
                tokens[contractAddress].ids.ids[j],
                ""
            );
        }
        emit CollectionNowAccepted(
            tokens[contractAddress].contractAddress,
            tokens[contractAddress].tokenName,
            tokens[contractAddress].totalSupply
        );
    }
    function tokenERC1155(
        address contractAddress,
        uint256 numberOfTokens
    ) internal {
        emit CollectionNowAccepted(
            tokens[contractAddress].contractAddress,
            tokens[contractAddress].tokenName,
            tokens[contractAddress].totalSupply
        );
    }
    function tokenERC20(
        address contractAddress,
        uint256 numberOfTokens
    ) internal {
        emit PurchaseTokenAccepted(
            tokens[contractAddress].contractAddress,
            tokens[contractAddress].tokenName,
            tokens[contractAddress].totalSupply
        );
    }

    function tokenNative(
        address contractAddress,
        uint256 numberOfTokens
    ) internal {
        if (contractAddress != address(0)) revert TokenNotOwnedBySender();
        emit PurchaseTokenAccepted(
            tokens[contractAddress].contractAddress,
            tokens[contractAddress].tokenName,
            tokens[contractAddress].totalSupply
        );
    }
}
