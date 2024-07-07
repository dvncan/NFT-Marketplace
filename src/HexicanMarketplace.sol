// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract HexicanMarketPlace is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function pause() public whenNotPaused onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public whenPaused onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    IERC721 hexicanContract; // 0x9a8C5DA383f3B6a4d07Fb9fDEF3ac54044e5e6bE

    struct Offer {
        bool isForSale;
        uint hexicanIndex;
        address seller;
        uint minValue; // in ether
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint hexicanIndex;
        address bidder;
        uint value;
    }

    // A record of phunks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint => Offer) public hexicanOfferedForSale;

    // A record of the highest phunk bid
    mapping(uint => Bid) public hexicanBids;

    // A record of pending ETH withdrawls by address
    mapping(address => uint) public pendingWithdrawals;

    event HexicanOffered(
        uint indexed hexicanIndex,
        uint minValue,
        address indexed toAddress
    );
    event HexicanBidEntered(
        uint indexed hexicanIndex,
        uint value,
        address indexed fromAddress
    );
    event HexicanBidWithdrawn(
        uint indexed hexicanIndex,
        uint value,
        address indexed fromAddress
    );
    event HexicanBought(
        uint indexed hexicanIndex,
        uint value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event HexicanNoLongerForSale(uint indexed hexicanIndex);

    /* Initializes contract with an instance of CryptoPhunks contract, and sets deployer as owner */
    function startContract(
        address initialHexicanAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(initialHexicanAddress != )
        IERC721(initialHexicanAddress).balanceOf(address(this));
        hexicanContract = IERC721(initialHexicanAddress);
    }

    /* Returns the CryptoPhunks contract address currently being used */
    function hexicanAddress() public view returns (address) {
        return address(hexicanContract);
    }

    /* Allows the owner of the contract to set a new CryptoPhunks contract address */
    function setHexicanContract(
        address newHexicanAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        hexicanContract = IERC721(newHexicanAddress);
    }

    /* Allows the owner of a CryptoPhunks to stop offering it for sale */
    function hexicanNoLongerForSale(uint hexicanIndex) public nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        if (hexicanContract.ownerOf(hexicanIndex) != msg.sender)
            revert("you are not the owner of this token");
        hexicanOfferedForSale[hexicanIndex] = Offer(
            false,
            hexicanIndex,
            msg.sender,
            0,
            address(0x0)
        );
        emit HexicanNoLongerForSale(hexicanIndex);
    }

    /* Allows a CryptoPhunk owner to offer it for sale */
    function offerHexicanForSale(
        uint hexicanIndex,
        uint minSalePriceInWei
    ) public whenNotPaused nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        if (hexicanContract.ownerOf(hexicanIndex) != msg.sender)
            revert("you are not the owner of this token");
        hexicanOfferedForSale[hexicanIndex] = Offer(
            true,
            hexicanIndex,
            msg.sender,
            minSalePriceInWei,
            address(0x0)
        );
        emit HexicanOffered(hexicanIndex, minSalePriceInWei, address(0x0));
    }

    /* Allows a CryptoPhunk owner to offer it for sale to a specific address */
    function offerHexicanForSaleToAddress(
        uint hexicanIndex,
        uint minSalePriceInWei,
        address toAddress
    ) public whenNotPaused nonReentrant {
        if (hexicanIndex <= 10000) revert();
        if (hexicanContract.ownerOf(hexicanIndex) != msg.sender)
            revert("you are not the owner of this token");
        hexicanOfferedForSale[hexicanIndex] = Offer(
            true,
            hexicanIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        emit HexicanOffered(hexicanIndex, minSalePriceInWei, toAddress);
    }

    /* Allows users to buy a Cryptohexican offered for sale */
    function buyhexican(
        uint hexicanIndex
    ) public payable whenNotPaused nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        Offer memory offer = hexicanOfferedForSale[hexicanIndex];
        if (!offer.isForSale) revert("hexican is not for sale"); // phunk not actually for sale
        if (offer.onlySellTo != address(0x0) && offer.onlySellTo != msg.sender)
            revert();
        if (msg.value != offer.minValue) revert("not enough ether"); // Didn't send enough ETH
        address seller = offer.seller;
        if (seller == msg.sender) revert("seller == msg.sender");
        if (seller != hexicanContract.ownerOf(hexicanIndex))
            revert("seller no longer owner of hexican"); // Seller no longer owner of phunk

        hexicanOfferedForSale[hexicanIndex] = Offer(
            false,
            hexicanIndex,
            msg.sender,
            0,
            address(0x0)
        );
        hexicanContract.safeTransferFrom(seller, msg.sender, hexicanIndex);
        pendingWithdrawals[seller] += msg.value;
        emit HexicanBought(hexicanIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = hexicanBids[hexicanIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            hexicanBids[hexicanIndex] = Bid(
                false,
                hexicanIndex,
                address(0x0),
                0
            );
        }
    }

    /* Allows users to retrieve ETH from sales */
    function withdraw() public nonReentrant {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /* Allows users to enter bids for any CryptoHexican */
    function enterBidForHexican(
        uint hexicanIndex
    ) public payable whenNotPaused nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        if (hexicanContract.ownerOf(hexicanIndex) == msg.sender)
            revert("you already own this hexican");
        if (msg.value == 0) revert("cannot enter bid of zero");
        Bid memory existing = hexicanBids[hexicanIndex];
        if (msg.value <= existing.value) revert("your bid is too low");
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        hexicanBids[hexicanIndex] = Bid(
            true,
            hexicanIndex,
            msg.sender,
            msg.value
        );
        emit HexicanBidEntered(hexicanIndex, msg.value, msg.sender);
    }

    /* Allows CryptoPhunk owners to accept bids for their Phunks */
    function acceptBidForHexican(
        uint hexicanIndex,
        uint minPrice
    ) public whenNotPaused nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        if (hexicanContract.ownerOf(hexicanIndex) != msg.sender)
            revert("you do not own this token");
        address seller = msg.sender;
        Bid memory bid = hexicanBids[hexicanIndex];
        if (bid.value == 0) revert("cannot enter bid of zero");
        if (bid.value < minPrice) revert("your bid is too low");

        address bidder = bid.bidder;
        if (seller == bidder) revert("you already own this token");
        hexicanOfferedForSale[hexicanIndex] = Offer(
            false,
            hexicanIndex,
            bidder,
            0,
            address(0x0)
        );
        uint amount = bid.value;
        hexicanBids[hexicanIndex] = Bid(false, hexicanIndex, address(0x0), 0);
        hexicanContract.safeTransferFrom(msg.sender, bidder, hexicanIndex);
        pendingWithdrawals[seller] += amount;
        emit HexicanBought(hexicanIndex, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForHexican(uint hexicanIndex) public nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        Bid memory bid = hexicanBids[hexicanIndex];
        if (bid.bidder != msg.sender)
            revert("the bidder is not message sender");
        emit HexicanBidWithdrawn(hexicanIndex, bid.value, msg.sender);
        uint amount = bid.value;
        hexicanBids[hexicanIndex] = Bid(false, hexicanIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

    function acceptBidForHexicanAndWithdraw(
        uint hexicanIndex,
        uint minPrice
    ) public whenNotPaused nonReentrant {
        if (hexicanIndex <= 10000) revert("token index not valid");
        if (hexicanContract.ownerOf(hexicanIndex) != msg.sender)
            revert("you do not own this token");
        address seller = msg.sender;
        Bid memory bid = hexicanBids[hexicanIndex];
        if (bid.value == 0) revert("cannot enter bid of zero");
        if (bid.value < minPrice) revert("your bid is too low");

        address bidder = bid.bidder;
        if (seller == bidder) revert("you already own this token");
        hexicanOfferedForSale[hexicanIndex] = Offer(
            false,
            hexicanIndex,
            bidder,
            0,
            address(0x0)
        );
        uint amount = bid.value;
        hexicanBids[hexicanIndex] = Bid(false, hexicanIndex, address(0x0), 0);
        hexicanContract.safeTransferFrom(msg.sender, bidder, hexicanIndex);
        pendingWithdrawals[seller] += amount;
        payable(address(this)).transfer(pendingWithdrawals[seller]);
        emit HexicanBought(hexicanIndex, bid.value, seller, bidder);
    }
}
