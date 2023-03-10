// SPDX-License-Identifier: MIT

import "./access/AccessControl.sol";

pragma solidity ^0.8.0;

contract Event is AccessControl {
    bytes32 public venue;
}

