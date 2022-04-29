// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./HelpsFarmCalculate.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
   * @dev created for HelpSeed Game Price And Token Management. In this contract,
   * there are methods that make add Token, Update Price, Set Land Price ... Etc
   */

  contract HelpsGameMultiTokens is Ownable, HelpsFarmCalculate{
     using Counters for Counters.Counter;

    address private _helpSeed; 
    Counters.Counter private _fTokenIdCounter;
    uint256 private _landPrice;
    uint256 private _unlockFarmPrice;

    constructor() HelpsFarmCalculate(1){
       _helpSeed = address(0x0A6e6D2F58d22E267Fdc9bfB295F0d43985FEBB4); // HelpSeed Token Contract Address
      _landPrice = 30; // First Buy Land Price 30$
      _unlockFarmPrice = 5; // One Land Unlock Farm Price = 5$ 
      addToken(_helpSeed, _helpSeed,"HelpSeed(Helps)",17610000000000); // Default is HelpSeed
    }


  
struct Ftoken {
   address aggregator; // ChainLink Aggreator Address
   address token; // Token Contract Address
   uint256 index; // Token Array in Index
   uint256 lastPrice;  // Token Price USD
   string name; // Token Name
   bool status; // Token Activate Status
}

address[] internal fTokenAddress; // Token Address Array
mapping(address => Ftoken) private fTokens; // Tokens

  event NewLandPrice(uint256 price);
 event NewUnlockFarmPrice(uint256 price);


  /**
  * @dev Add New Token.
  **/
  function addToken(address _aggretor, address _token, string memory _name, uint256 _price) public onlyOwner {
    require(fTokens[_token].token != _token, "Already Token");
    uint256 fTokenId = _fTokenIdCounter.current();
    _fTokenIdCounter.increment();
    fTokenAddress.push(_token);
    fTokens[_token] = Ftoken(_aggretor, _token, fTokenId, _price, _name, true);
  }


  /**
  * @dev Remove Token.
  **/
  function removeToken(address _token) public onlyOwner {
  require(fTokens[_token].status == false, "This Token is Active Not Remove");
  require(fTokens[_token].index < fTokenAddress.length, "Invalid Index");
  fTokenAddress[fTokens[_token].index] = fTokenAddress[fTokenAddress.length-1];
  fTokenAddress.pop();
  delete fTokens[_token];
  }  
  
  /**
  * @dev Returns Default Token.
  **/
  function defaultToken() public view returns(address){
     return _helpSeed;
  }

   /**
  * @dev Update Default Token.
  **/
  function updateDefaultToken(address _token) public onlyOwner{
     _helpSeed = _token;
  }

 /**
  * @dev Update Token Aggreator Address.
  **/
  function updateTokenAggregator(address _token, address _aggretor) public onlyOwner{
     fTokens[_token].aggregator = _aggretor;
  }


  /**
  * @dev Update Live Token Price.
  **/
  function updateLiveTokenPrice(address _token) public onlyOwner{
    uint256 cPrice = convertDecimals(getLatestPriceChainLink(fTokens[_token].aggregator)); 
    require(cPrice > 0, "Not Set Zero");
      if(cPrice != fTokens[_token].lastPrice){
         fTokens[_token].lastPrice = cPrice;
      }
    }


  /**
  * @dev Update Manual Token Price.
  **/
  function updateManualTokenPrice(address _token, uint256 _price) public onlyOwner{
    require(_price > 0, "Not Set Zero");
    require(_price != fTokens[_token].lastPrice,"Equal");
    fTokens[_token].lastPrice = _price;
  
    }


  /**
  * @dev Update Token Status.
  **/
  function updateTokenStatus(address _token, bool status) public onlyOwner{
    require(fTokens[_token].status =! status, "Not Set Zero");
     fTokens[_token].status = status;
  }


  /**
  * @dev Returns Token Price.
  **/
  function tokenPrice(address _token) public view returns(uint256){
    Ftoken memory fToken = fTokens[_token];
    if(fToken.token != defaultToken()){
  uint256 cPrice = convertDecimals(getLatestPriceChainLink(fToken.aggregator)); 
    return cPrice != fToken.lastPrice ? cPrice:fToken.lastPrice;
    }else{
      return fToken.lastPrice;
    }
  
  }


  /**
  * @dev Returns Activated Tokens.
  **/
  function getActivatedfTokens() public view returns(Ftoken[] memory){
  Ftoken[] memory _vtokens = new Ftoken[] (fTokenAddress.length);
  for (uint256 i = 0; i < fTokenAddress.length; i++) {
     if(fTokens[fTokenAddress[i]].status == true){
    _vtokens[i] = fTokens[fTokenAddress[i]];
     }
  }
  return _vtokens;
  }




  /**
  * @dev Returns ERC20 Interface And Switch Token.
  **/
  function UFT(address f) public view returns(IERC20){
  return fTokens[f].status == false || f == _helpSeed ?  IERC20(_helpSeed) : IERC20(f);
  }



  /**
  * @dev Set Land Price USD.
  **/
  function setLandPrice(uint256 l) public onlyOwner {
    require(l > 0, "Don't Set Zero");
    _landPrice = l;
    emit NewLandPrice(_landPrice);
  }

  /**
  * @dev Set Unlock Farm Price USD.
  **/
  function setUnlockFarmPrice(uint256 u) public onlyOwner {
    require(u > 0, "Don't Set Zero");
    _unlockFarmPrice = u;
    emit NewLandPrice(_unlockFarmPrice);
  }

 /**
  * @dev Returns User Land  Sale Price Token Amount.
  **/
 function landSalePriceToken(address a, uint256 salePrice) public view returns(uint256){
  return calculateUsdtoToken(salePrice, tokenPrice(a));
  }

  /**
  * @dev Returns Land Price Token Amount.
  **/
 function landPriceToken(address a) public view returns(uint256){
  return calculateUsdtoToken(_landPrice, tokenPrice(a));
  }

  /**
  * @dev Returns Unlock Farm Price Token Amount.
  **/
 function unlockFarmPriceToken(address a) public view returns(uint256){
  return calculateUsdtoToken(_unlockFarmPrice, tokenPrice(a));
  }

 /**
  * @dev Returns Land Price Usd.
  **/
   function landPrice() public view returns(uint256){
  return _landPrice;
  }

 /**
  * @dev Returns Unlock Farm Price Usd.
  **/
 function unlockFarmPrice() public view returns(uint256){
  return _unlockFarmPrice;
  }
 
  /**
  * @dev Returns Chainlik Token Live Price.
  **/
 function getLatestPriceChainLink(address _aggretor) internal view returns (int) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(_aggretor).latestRoundData();
    return price;
    }


 
}
