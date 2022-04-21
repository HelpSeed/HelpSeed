// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;

import "./HelpsFarmCalculate.sol";
import "./HelpsGame.sol";

abstract contract HelpsFarm is  HelpsGame, HelpsFarmCalculate{
  using SafeMath for uint256;

uint256 private unlockFarmPrice;
  
   struct Farm {
    uint256 totalMint;
    uint256 nextWateringTime;
    uint256 endTime;
    bool status;
  }

  mapping(address => Farm) private farms;
  address private poolAddress; 
  
 event NewUnlockFarmPrice(uint256 price);
 event UnlockFarm(address indexed user);
 event LockFarm(address indexed user);


  function setUnlockFarmPrice(uint256 u) public onlyOwner {
    require(u > 0, "Don't Set Zero");
    unlockFarmPrice = u * 10 ** 18;
    emit NewUnlockFarmPrice(unlockFarmPrice);
  }

   function setPoolAddress(address p) public onlyOwner {
    poolAddress = p;
  }

  function getUnlockFarmPrice() public view returns(uint256){
  return unlockFarmPrice;
  }

 function getPoolBalance() public view returns(uint256){
  return helps.balanceOf(address(poolAddress)); // Pool Live Balance
  }

  function getPoolAddress()  public view returns(address){
    return poolAddress;
  }

  function _farm(address user) internal view returns(Farm memory){
  return farms[user];
  }
 
  function safeFarmMethodTwo(address from, uint256 activatedSaleCounts, uint256 balance) internal view returns(bool) {
    if (farms[from].status == true) {
      return activatedSaleCounts+1 == balance ? false : true;
    } else{
     return activatedSaleCounts == balance ? false : true;
    }
  }
 

  function _lockFarm(address user) private {
    farms[user].status = false;
   }

  function expireDetect(address user) internal {
    if (farms[user].endTime <= block.timestamp) {
      _lockFarm(user);
      emit LockFarm(user);
    }
  }

  function checkFarmExpireTime(address user) internal {
    require(farms[user].endTime <= block.timestamp, "Until time");
    _unlockFarm(user);
    emit UnlockFarm(user);
  }

    function _calculateUnlockFarmPrice(uint256 landsCount) internal view returns(uint256) {
    uint256 u = landsCount == 0 ? 1 : landsCount * unlockFarmPrice;
    return u;
  }

   function _unlockFarm(address user) internal {
     farms[user].status = true;
     farms[user].nextWateringTime = block.timestamp;
     farms[user].endTime = block.timestamp + 30 days;
   }

  function getFarm(address user) public view returns(Farm memory) {
   require(user != address(0));
    return farms[user];
  }


function _wateringSeeds(uint256 balance, uint256 landPrice ) internal returns(uint256) {
    require(farms[_msgSender()].status == true, "Farm Mode Disable");
    require(farms[_msgSender()].nextWateringTime < block.timestamp, "Until Time");
    expireDetect(_msgSender());
    uint256 earnAmount = calculateDailyEarn(balance, landPrice, getPoolBalance());
    farms[_msgSender()].nextWateringTime = block.timestamp + 1 days;
    farms[_msgSender()].totalMint += earnAmount;
    return earnAmount;
}

    function rescueBNBFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    function burnPool(uint _amount) public onlyOwner {
      helps.transfer(address(0x000000000000000000000000000000000000dEaD), _amount);
    }
}
