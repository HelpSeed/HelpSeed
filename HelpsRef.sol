// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;


import "./HelpsLand.sol";

 contract HelpsRef is  HelpsLand{
 
 uint256 private referenceReward;

 


  mapping(address => address[]) private refs;
  mapping(address => address) private refUser;
  mapping(address => bool) internal refExits;

 
 /**
 * @dev Set Reference Reward Token Amount
 **/
 function setReferenceReward(uint256 v) public onlyOwner {
    require(v > 0, "Don't Set Zero");
    referenceReward = v * 10 ** 18;
  }

 /**
 * @dev Returns Reference Reward Token Amount
 **/
  function getRefenceReward() internal view returns(uint256) {
      return referenceReward;
  }

  /**
  * @dev Set Reference Address And Send Reward Amount.
  **/
  function _setRef(address from) internal {
    require(_msgSender() != from, "False");
    refs[from].push(_msgSender());
    refExits[_msgSender()] = true;
  }


  /**
  * @dev Returns User Reference Address.
  **/
 function getRefs(address user) public view returns(address[] memory) {
    return refs[user];
  }

 

}
