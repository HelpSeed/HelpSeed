// SPDX-License-Identifier: MIT

/***
* HELPSEED METAVERSE NFT LAND FARM CONTRACT
* PLAY TO EARN GAME
***/

pragma solidity ^0.8.2;
import "./HelpsFarm.sol";
import "./HelpsRef.sol";
import "./HelpsLand.sol"; 

contract HelpsGame is HelpsLand, HelpsFarm, HelpsRef {

 event Buy(address indexed from, address to, uint256 tokenId, uint256 price);
 event Sell(address indexed user, uint256 tokenId, uint256 price, address fToken);
 event WateringSeeds(address indexed user, uint256 earn);
 event CancelSale(address indexed user, uint256 indexed tokenId);

  /**
  * @dev User Buy Land.
  **/
 function buy(uint256 _tokenId, bytes2 flag) public nonReentrant{
     Land memory land = lands[_tokenId];
  require(ownerOf(_tokenId) != _msgSender());
  require(land.forSale == true, "Not open for sale");
  address _fToken = landSaleToken[_tokenId];
  uint256 _landSalePrice = IHGT.landSalePriceToken(_fToken, land.salePrice);
  require(IHGT.UFT(_fToken).balanceOf(_msgSender()) >= _landSalePrice, "Insufficient balance.");
    IHGT.UFT(_fToken).transferFrom(_msgSender(), land.currentOwner, _landSalePrice*900/1000); // %90 CurrentOWner
    IHGT.UFT(_fToken).transferFrom(_msgSender(), owner(), _landSalePrice*100/1000); // %10 Provider Fee
    land.forSale = false;
    land.flag = flag;
    land.salePrice = 0;
    land.prevOwner = land.currentOwner;
    land.currentOwner = _msgSender();
    _setTokenURI(_tokenId, land.hexId, flag);
    lands[_tokenId] = land;
     _transfer(land.prevOwner, _msgSender(), _tokenId);
    emit Buy(land.prevOwner, _msgSender(), _tokenId, land.salePrice);
  }


  /**
  * @dev User Sell Land.
  **/
  function sell(uint256 _tokenId, uint256 price, address fToken) public nonReentrant {
    require(ownerOf(_tokenId) == _msgSender(), "You do not own this land.");
    require(price > IHGT.landPrice(), "Price too Low.");
    Land memory land = lands[_tokenId];
    require(land.forSale == false, "Already.");
    land.forSale = true;
    land.salePrice = price;
    _approve(address(this), _tokenId);
    lands[_tokenId]= land;
    landSaleToken[_tokenId] = fToken;
    emit Sell(_msgSender(), _tokenId, price, fToken);
  }
 
  /**
  * @dev Cancel Sale Land.
  **/
  function cancelSale(uint256 _tokenId) public nonReentrant {
    require(ownerOf(_tokenId) == _msgSender(), "You do not own this land.");
    Land memory land = lands[_tokenId];
    require(land.forSale == true, "Already.");
    land.forSale = false;
    land.salePrice = 0;
    lands[_tokenId]= land;
    emit CancelSale(_msgSender(), _tokenId);
  }

  /**
  * @dev User First Buy Land (Multi Token).
  **/
  function buyLand(bytes15 hexId, bytes2 flag,  address ref, address _fToken) public nonReentrant whenNotPaused(){
    require(soldExits[hexId] == false, "This Land Sold.");
    uint256 _landPriceToken = IHGT.landPriceToken(_fToken);
    require(IHGT.UFT(_fToken).balanceOf(_msgSender()) >=  _landPriceToken, "Insufficient balance.");
    IHGT.UFT(_fToken).transferFrom(_msgSender(), owner(), _landPriceToken);
    // In the first land sale, the money goes to the Contract owner owner().
    mintLand(hexId, _msgSender(), flag);
    if(refExits[_msgSender()] == false){
       _setRef(ref); 
      IHGT.UFT(IHGT.defaultToken()).transfer(ref, getRefenceReward());
        }
  }
  
  /**
  * @dev User Watering Seeds.
  **/
  function watering() public nonReentrant whenNotPaused() {
    require(balanceOf(_msgSender()) > 0, "You Don't Have Land.");
    address _fToken = IHGT.defaultToken(); // Default HelpSeed 
    uint256 reward = wateringSeeds(_fToken);
    IHGT.UFT(_fToken).transfer(_msgSender(), reward);
    emit WateringSeeds(_msgSender(), reward);
  }

  /**
  * @dev Whitelist Buy Land (Free).
  **/
 function whiteBuyLand(bytes15 hexId, bytes2 flag) public nonReentrant{
  require(soldExits[hexId] == false,"Sold");
  require(whiteLists[_msgSender()].exits == true, "YDNWHITELIST");
    mintLand(hexId, _msgSender(), flag);
    if(balanceOf(_msgSender()) >= whiteLists[_msgSender()].freeAmount){
        delete whiteLists[_msgSender()];
    }
  }

 /**
  * @dev returns Check in Whitelist
  **/
  function isWhiteList(address user) public view returns(bool){
   return whiteLists[user].exits;
  }

  

}
