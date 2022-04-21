// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;
interface IHelps {
  function transfer(address recipient, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
  function allowance(address _owner, address spender) external view returns(uint256);
 function setPresaleWallet(address user) external;
function removePresaleWallet(address user) external;
function getPresaleWalletStatus(address user) external view returns(bool);
}
