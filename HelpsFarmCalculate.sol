
// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;


abstract contract HelpsFarmCalculate {
    
 function perc(uint a, uint256 amount) internal pure returns(uint256) {
      uint p = a*10**18/10000*100;
      return fromWei(amount) * p / 100;
  }

  function fromWei(uint256 amount) internal pure returns(uint256) {
      return amount / 1e18;
  }

function toWei(uint256 amount) internal pure returns(uint256) {
      return amount*10**18;
  }


   function add(uint256 amount1 , uint256 amount2, uint256 p1, uint256 p2) internal pure returns(uint256){
  return perc(p1, amount1) + perc(p2, amount2);
  }

  function calculateDailyEarn(uint256 landsCount, uint256 landPrice, uint256 pool ) internal pure returns(uint256){
          uint256 _balance = landsCount * landPrice;
      if (landsCount <= 50) {

      return add(_balance, pool, 50, 1);// Daily %0.51

    } else if (landsCount > 50 && landsCount <= 500) {

       return add(_balance, pool, 67, 1); //  Daily %0.68

    } else if (landsCount > 500 && landsCount <= 2500) {

      return add(_balance, pool, 84, 1); // Daily %0.85

    } else if (landsCount > 2500 && landsCount <= 5000) {

     return add(_balance, pool, 100, 1); // Daily %1.01

    } else {
      return 0;
    }
  }
}
