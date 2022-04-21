// SPDX-License-Identifier: MIT

/***
* HELPSEED METAVERSE NFT LAND FARM CONTRACT
* PLAY TO EARN GAME
* You can read the Function Descriptions of this Smart Contract in detail at docs.helpseed.org.
***/

pragma solidity ^0.8.2;
import "./HelpsFarm.sol";
import "./HelpsRef.sol";
import "./HelpsLand.sol"; 

contract HelpsLandGame is HelpsLand, HelpsFarm, HelpsRef {

 event Buy(address indexed from, address to, uint256 tokenId, uint256 price);
 event Sell(address indexed user, uint256 tokenId, uint256 price);
 event WateringSeeds(address indexed user, uint256 earn);


  function buy(uint256 _tokenId, bytes2 flag) public nonReentrant {
    require(_msgSender() != address(0));
    require(_exists(_tokenId), "Don't Have Land");
    require(helps.allowance(_msgSender(), address(this)) >= lands[_tokenId].salePrice, "Insufficient allowance.");
    require(helps.balanceOf(_msgSender()) >= lands[_tokenId].salePrice, "Insufficient balance.");
    require(_msgSender() != lands[_tokenId].currentOwner);
    require(lands[_tokenId].forSale == true, "Not open for sale");  
    helps.transferFrom(_msgSender(), lands[_tokenId].currentOwner, lands[_tokenId].salePrice);
    _transfer(lands[_tokenId].currentOwner, _msgSender(), _tokenId);
    activatedSaleCounts[lands[_tokenId].currentOwner]--;
    _updateLand(_tokenId, false, flag, lands[_tokenId].currentOwner, (), 0);
    _setTokenURI(_tokenId, lands[_tokenId].hexId, flag);
    emit Buy(lands[_tokenId].prevOwner, _msgSender(), _tokenId, lands[_tokenId].salePrice);
  }


  function sell(uint256 _tokenId, uint256 price) public nonReentrant {
    require(_msgSender() != address(0));
    require(_exists(_tokenId), "Don't Have Land");
    require(ownerOf(_tokenId) == _msgSender(), "You do not own this land.");
    require(safeFarmMethodTwo(_msgSender(),activatedSaleCounts[_msgSender()], balanceOf(_msgSender())) == true, "Your Land is equal to the Amount of Land for Sale.");
    require(lands[_tokenId].forSale == false, "Already.");
    lands[_tokenId].price = price*10**18;
    activatedSaleCounts[_msgSender()]++;
    _approve(address(this), _tokenId);
    emit Sell(_msgSender(), _tokenId, price);
  }

  

  function updateSale(uint256 _tokenId, uint256 price, bool forSale) public  {
    require(_msgSender() != address(0));
    require(_exists(_tokenId), "Don't Have Land");
    require(ownerOf(_tokenId) == _msgSender(), "You do not own this land.");
    _updateLand(_tokenId, forSale, lands[_tokenId].flag, lands[_tokenId].currentOwner, _msgSender(), price*10**18);
    forSale == true ? activatedSaleCounts[_msgSender()]++ : activatedSaleCounts[_msgSender()]--;
  }

  
  function checkSoldLand(bytes15 hexId) internal view returns(bool) {
    return soldExits[hexId];
  }

 function buyLand(bytes15 hexId, bytes2 flag, address ref) public nonReentrant {
    require(_msgSender() != address(0));
    require(checkSoldLand(hexId) == false, "This Land Sold.");
    require(helps.allowance(_msgSender(), address(this)) >= getLandPrice(), "Insufficient allowance.");
    require(helps.balanceOf(_msgSender()) >= getLandPrice(), "Insufficient balance.");
    helps.transferFrom(_msgSender(), address(this), getLandPrice());
    mintLand(hexId, _msgSender(), flag);
    if(_checkRef(_msgSender()) == false){ checkAndSetRef(ref); }
  }
  

 function freeBuyLand(bytes15 hexId, bytes2 flag) public nonReentrant whenNotPaused(){
  require(_msgSender() != address(0));
  require(checkSoldLand(hexId) == false,"Sold");
  require(balanceOf(_msgSender())+1 <= whiteLists[_msgSender()].freeAmount, "Free Land Complete");
  require(whiteLists[_msgSender()].exits == true, "YDNWHITELIST");
  mintLand(hexId, _msgSender(), flag);
    if(farms[_msgSender()].status == false){
      farms[_msgSender()].endTime = whiteLists[_msgSender].freeTime;
      farms[_msgSender()].nextWateringTime = block.timestamp;
      farms[_msgSender()].status = true;
     }
  }


  function unlockFarm() public  nonReentrant{
  require(_msgSender() != address(0));
  require(balanceOf(_msgSender()) > 0, "You Don't Have Land.");   
  require(safeFarmMethodTwo(_msgSender(),activatedSaleCounts[_msgSender()], balanceOf(_msgSender())) == true, "Your Land is equal to the Amount of Land for Sale.");
  require(helps.allowance(_msgSender(), address(this)) >= getUnlockFarmPrice(), "Insufficient allowance.");
  require(helps.balanceOf(_msgSender()) >= getUnlockFarmPrice(), "Insufficient balance.");
    checkFarmExpireTime(_msgSender());
    helps.transferFrom(_msgSender(), address(this), _calculateUnlockFarmPrice(balanceOf(_msgSender())));
    _unlockFarm(_msgSender());
  }

 function wateringSeeds() public nonReentrant whenNotPaused() {
    require(_msgSender() != address(0));
  require(balanceOf(_msgSender()) > 0, "You Don't Have Land.");   
    uint256 winned = _wateringSeeds(balanceOf(_msgSender()), getLandPrice());
    helps.transfer(_msgSender(), winned);
    emit WateringSeeds(_msgSender(), winned);
  }


}
