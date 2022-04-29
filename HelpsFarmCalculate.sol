import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;


  /**
   * @dev created for HelpSeed Game Calculations. In this contract,
   * there are methods that make Simple calculations such as Daily Earnings, Token to Usd, Usd to Token.
   */

  contract HelpsFarmCalculate is Ownable{
   
    using SafeMath for uint256;
    uint256 internal _perc; // % Daily Earn %.

  constructor(uint256 perc){
  _perc = perc;
  }
  /**
   * @dev Set Daily Earn % Value.
   */
  function setPerc(uint256 eperc) public onlyOwner{
    // Minimum Limit %0.01 
    require(eperc > 0, "Minimum 1");
    _perc = eperc;
  }

  /**
   * @dev Returns Daily Earn % Value.
   */
  function getPerc() public view returns(uint256){
    return _perc;
  }


  /**
  * @dev Decimal Cleaning
  **/
  function fromWei(uint256 amount) internal pure returns(uint256) {
      return amount / 1e18;
    }

  /**
  * @dev Decimal Convert 18-8
  **/
  function convertDecimals(int a) internal pure returns (uint256) {
    return uint256(a)* (10**(18-8));
  }

  /**
  * @dev Calculate Usd <(SWAP)> Token
  **/
  function calculateUsdtoToken(uint256 amountUsd, uint256 tokenPriceUsd) internal pure returns(uint256){ 
    require(tokenPriceUsd > 0 && amountUsd > 0, "Invalid Number");
    uint256 minRequiredUSD = amountUsd*10**18; 
    return (minRequiredUSD*10**18)/tokenPriceUsd; 
  }

  /**
  * @dev Calculate Token <(SWAP)> Usd
  **/
  function calculateTokentoUsd(uint256 tokenAmount, uint256 tokenPriceUsd) internal pure returns(uint256){ 
    require(tokenPriceUsd > 0 && tokenAmount > 0, "Invalid Number");
    uint256 minRequiredUSD = (fromWei(tokenAmount))*tokenPriceUsd; 
    return (minRequiredUSD) / 1; 
  }


  /**
  * @dev Calculate Unlock Farm Price
  **/
  function calculateUnlockFarmPrice(uint256 landsCount, uint256 unlockFarmPriceToken) public pure returns(uint256){ 
    return landsCount* unlockFarmPriceToken;
  }

  /**
  * @dev Calculate Daily Earn Token Amount
  **/
  function calculateDailyEarn(uint256 landsCount, uint256 landPriceToken, uint256 pool) internal view returns(uint256){
          uint256 _balance = (landsCount * landPriceToken) * _perc / 1000;
          uint256 _poolEarn = pool * 1 / 1000;
          return (_balance + _poolEarn);
  } 
}
