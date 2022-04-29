// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;

import "./HelpsLand.sol";


/**
* @dev This Contract was written for the Farm System of the HelpsLand Game. 
* The methods in this contract cover the Farm System.
**/

  contract HelpsFarm is HelpsLand {


address private _poolAddress; // Earn Pool;


constructor(){
 _poolAddress = address(this); // this Contract is Pool;
}
 
   struct Farm {
    uint256 totalMint; // Farm Total Earn
    uint256 nextWateringTime; // Farm Next Watering Time 
    uint256 endTime; // Farm End Time
    bool status; // Farm Status 
  }

  mapping(address => Farm) private farms;

 event UnlockFarm(address indexed user);
 event LockFarm(address indexed user);


  /**
  * @dev Returns Number of Tokens in the Pool
  **/
  function getPoolBalanceToken() public view returns(uint256){
    return IERC20(IHGT.defaultToken()).balanceOf(address(_poolAddress));
    }


  /**
  * @dev Returns Address the Pool
  **/
  function getPoolAddress()  public view returns(address){
    return _poolAddress;
  }

  /**
  * @dev User Set Lock Farm
  **/
  function _lockFarm(address user) private {
    farms[user].status = false;
   }


  /**
  * @dev User Farm Expiry Detection
  **/
  function expireDetect(uint256 endTime) internal {
    if (endTime <= block.timestamp) {
      _lockFarm(_msgSender());
      emit LockFarm(_msgSender());
    }
  }


  /**
  * @dev User Set Unlock Farm
  **/
   function unlock(address user) private {
     farms[user].status = true;
     farms[user].nextWateringTime = block.timestamp;
     farms[user].endTime = block.timestamp + 30 days;
   }
   

  /**
  * @dev User Farm End Time Control
  **/
  function checkFarmExpireTime(address user) internal {
    require(farms[user].endTime <= block.timestamp, "Until time");
    // If the Farm Duration Time has passed, it will be unlocked again.
    unlock(user);
    emit UnlockFarm(user);
  }

  /**
  * @dev User Returns Farm Data
  **/
  function getFarm(address user) public view returns(Farm memory) {
   require(user != address(0));
    return farms[user];
  }

  /**
  * @dev User Unlock Farm Action.
  **/
  function _unlockFarm() public nonReentrant{
    require(_msgSender() != address(0));
  require(balanceOf(_msgSender()) > 0, "You Don't Have Land.");   
  address _fToken = IHGT.defaultToken();
   uint256 _unlockFarmPriceToken =  calculateUnlockFarmPrice(balanceOf(_msgSender()), IHGT.unlockFarmPriceToken(_fToken));
  require(IHGT.UFT(_fToken).balanceOf(_msgSender()) >= _unlockFarmPriceToken, "Insufficient balance.");
  checkFarmExpireTime(_msgSender());
  IHGT.UFT(_fToken).transferFrom(_msgSender(), owner(), _unlockFarmPriceToken);
  }
  
  /**
  * @dev User Watering Seeds Action.
  **/
   function wateringSeeds(address fToken) internal returns(uint256) {
     require(_msgSender() != address(0));
     uint256 landsCount = balanceOf(_msgSender());
    require(landsCount > 0, "You Don't Have Land.");   
    Farm memory farm = farms[_msgSender()];
    require(farm.status == true, "Farm Mode Disable");
    expireDetect(farm.endTime);
    require(farm.nextWateringTime < block.timestamp, "Until Time");
    uint256 earnAmount = calculateDailyEarn(landsCount, IHGT.landPriceToken(fToken), getPoolBalanceToken());
    require(earnAmount > 0, "Failed Earn Amount");
    farm.nextWateringTime = block.timestamp + 1 days;
    farm.totalMint += earnAmount;
    farms[_msgSender()] = farm;
    return earnAmount;

}

 


  }
