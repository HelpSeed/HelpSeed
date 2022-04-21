// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LandStorageUri.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IHelps.sol";
/// @custom:security-contact info@helpseed.org
contract HelpsLand is ERC721, ERC721Enumerable,HelpSeedLandStorage, Pausable, Ownable, ERC721Burnable{
    using Counters for Counters.Counter;
     using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
  uint256 private landPrice;

    constructor() ERC721("Help Seed Land", "HELPSLAND") {}


  struct Land {
    uint256 tokenId;
    bytes15 hexId;
    bytes2 flag;
    address prevOwner;
    address currentOwner;
    uint256 salePrice;
    bool forSale;
  }

  struct WhiteList {
    uint256 freeAmount;
    uint256 freeTime;
    bool exits;
  }

  mapping(uint256 => Land) internal lands;
  mapping(bytes15 => Land) internal hexLand;
  mapping(bytes15 => bool) internal soldExits;
  mapping(address => uint256) internal activatedSaleCounts;
  mapping(address => WhiteList) internal whiteLists;

   event SoldLand(address indexed user, uint256 indexed tokenId, bytes15 hexId, bytes2 color);
  event NewLandPrice(uint256 price);

  
  function setLandPrice(uint256 l) public onlyOwner {
    require(l > 0, "Don't Set Zero");
    landPrice = l * 10 ** 18;
    emit NewLandPrice(landPrice);
  }

  function getLandPrice() public view returns(uint256){
  return landPrice;
  }
 

  function mintLand(bytes15 _hexId, address to, bytes2 _flag) internal whenNotPaused(){
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    lands[tokenId] = Land(tokenId, _hexId, _flag, address(this), to, 0 ,false);
    hexLand[_hexId] = lands[tokenId];
    soldExits[_hexId] = true;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _hexId, _flag);
    emit SoldLand(to, tokenId, _hexId, _flag);

  }

  
  function mintLandOwner(bytes15 hexId, address to, bytes2 flag) external onlyOwner {
    require(soldExits[hexId] == false, "Sold");
    mintLand(hexId, to, flag);

  }


 function mintLandMultiOwner(address[] memory to, bytes15[] memory hexId,  bytes2[] memory flag) external onlyOwner {
    for (uint256 i = 0; i < hexId.length; i++) {
      require(soldExits[hexId[i]] == false, "Sold");
      mintLand(hexId[i], to[i], flag[i]);
    }
  }

 
  function getHexLand(bytes15 _hexId) public view returns(Land memory) {
    require(soldExits[_hexId] == true, "Don't Have Land.");
    return hexLand[_hexId];
  }


  function _updateLand(uint256 tokenId, bool forSale, bytes2 flag,  address prevOwner, address currentOwner, uint256 salePrice ) internal {
    lands[tokenId].forSale = forSale;
    lands[tokenId].flag = flag;
    lands[tokenId].prevOwner = prevOwner;
    lands[tokenId].currentOwner = currentOwner;
    lands[tokenId].salePrice = salePrice;
    hexLand[lands[tokenId].hexId] = lands[tokenId];
  }


  
  function getLand(uint256 _tokenId) public view returns(Land memory) {
    require(_exists(_tokenId), "Don't Have Land.");
    return lands[_tokenId];
  }
  

    function getLands(address user, uint offset, uint limit) public view returns (Land[] memory , uint nextOffset, uint total) {
    require(user != address(0));
    require(balanceOf(user) > 0, "You Don't Have Land.");  
        uint totalUserLands = balanceOf(user);
        if(limit == 0) {
            limit = 1;
        }
        
        if (limit > totalUserLands- offset) {
            limit = totalUserLands - offset;
        }

        Land[] memory values = new Land[] (limit);
        for (uint i = 0; i < limit; i++) {
            values[i] = lands[offset + i];
        }

        return (values, offset + limit, totalUserLands);
    }

 
  function landChangeFlag(uint256 tokenId, bytes2 flag) external onlyOwner {
    lands[tokenId].flag = flag;
  }

  function landChangeHex(uint256 tokenId, bytes15 land) external onlyOwner {
    lands[tokenId].hexId = land;
  }


function setWhitelistAddress(address[] memory user, uint256[] memory amount, uint256[] memory time) public onlyOwner {
     for (uint256 i = 0; i < user.length; i++) {
       require(whiteLists[user[i]].exits == false, "Already User");
        whiteLists[user[i]] = WhiteList(amount[i], time[i], true);
    }
}


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, bytes15 hexId, bytes2 flag) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, hexId, flag);
    }
    


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, HelpSeedLandStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, HelpSeedLandStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     

  

}
