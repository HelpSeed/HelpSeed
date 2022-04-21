// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HelpsLand.sol"; 
contract HelpsGame is HelpsLand, ReentrancyGuard {
    IHelps internal helps = IHelps(0x36b6974113a4f1Afed868C4057d0195D0589d957); // Help Seed Testnet Interface

}
