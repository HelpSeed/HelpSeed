// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

  interface IhelpsGameToken {
 function UFT(address f) external view returns(IERC20);
 function defaultToken() external view returns(address);
 function landPrice() external view returns(uint256);
 function unlockFarmPrice() external view returns(uint256);
 function landPriceToken(address a) external view returns(uint256);
 function unlockFarmPriceToken(address a) external view returns(uint256);
 function tokenPrice(address a) external view returns(uint256);
 function getPoolBalanceToken(address _fToken) external view returns(uint256);
 function landSalePriceToken(address a, uint256 amount) external view returns(uint256);

}
