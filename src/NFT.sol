// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19; // to be modified .8.10 -> .8.19 new line

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    constructor() ERC721("Cookies", "COOKIES") Ownable(msg.sender) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
