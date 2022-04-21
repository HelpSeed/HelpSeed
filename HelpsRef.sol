// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;


import "./HelpsGame.sol";

abstract contract HelpsRef is HelpsGame{
 
 uint256 private referenceReward;


  mapping(address => address[]) private refs;
  mapping(address => address) private refUser;
  mapping(address => bool) private refExits;

 
 function setReferenceReward(uint256 v) public onlyOwner {
    require(v > 0, "Don't Set Zero");
    referenceReward = v * 10 ** 18;
  }

  function getRefenceReward() internal view returns(uint256) {
      return referenceReward;
  }

  function _checkRef(address a) internal view returns(bool) {
    return refExits[a];
  }

 
  function _setRef(address from) private {
    require(_msgSender() != from, "False");
    require(_checkRef(from) == false, "False");
    refs[from].push(_msgSender());
    refExits[_msgSender()] = true;
    helps.transfer(from, getRefenceReward());
  }

  function checkAndSetRef(address ref) internal {
    _setRef(ref);
  }

 function getRefs(address user) public view returns(address[] memory) {
    return refs[user];
  }

 

}
