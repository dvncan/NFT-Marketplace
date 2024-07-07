// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19; // to be modified .8.10 -> .8.19 new line

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Cookies is ERC20 {
    constructor() ERC20("Cookies", "COOKIES") {
        _mint(msg.sender, 210_000_000 * 1 ether);
    }
}
