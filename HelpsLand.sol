// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LandStorageUri.sol";
import "./HelpsFarmCalculate.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 import "./IhelpsGameToken.sol";

 /// @custom:security-contact info@helpseed.org
contract HelpsLand is ERC721, ERC721Enumerable,HelpSeedLandStorage, Pausable, Ownable, ERC721Burnable, ReentrancyGuard, HelpsFarmCalculate{
    using Counters for Counters.Counter;
     using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    IhelpsGameToken internal IHGT;

    constructor() ERC721("Help Seed Land", "HELPSLAND") HelpsFarmCalculate(10) {}

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
    bool exits;
  }
 
  mapping(uint256 => Land) internal lands;
  mapping(address => uint256[]) internal ownerLandIds;
  mapping(address => mapping(uint256 => uint256)) internal ownerLandIndex;
  mapping(bytes15 => uint256) internal hexLand;
  mapping(bytes15 => bool) internal soldExits;
  mapping(address => WhiteList) internal whiteLists;
  mapping(uint256 => address) internal landSaleToken;

   event SoldLand(address indexed user, uint256 indexed tokenId, bytes15 hexId, bytes2 flag);


  /**
  * @dev User Mint Land.
  **/
  function mintLand(bytes15 _hexId, address to, bytes2 _flag) internal whenNotPaused(){
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment(); // 0
    lands[tokenId] = Land(tokenId, _hexId, _flag, address(this), to, 0, false);
    hexLand[_hexId] = tokenId;
    soldExits[_hexId] = true;
    ownerLandIds[to].push(tokenId);
    ownerLandIndex[to][tokenId] = ownerLandIds[to].length -1;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _hexId, _flag);
    emit SoldLand(to, tokenId, _hexId, _flag);

  }

  /**
  * @dev Owner Mint Land.
  **/
  function mintLandOwner(bytes15 hexId, address to, bytes2 flag) external onlyOwner {
    require(soldExits[hexId] == false, "Sold");
    mintLand(hexId, to, flag);

  }

  /**
  * @dev Owner Mint Multi Land.
  **/
 function mintLandMultiOwner(address[] memory to, bytes15[] memory hexId,  bytes2[] memory flag) external onlyOwner {
    for (uint256 i = 0; i < hexId.length; i++) {
      require(soldExits[hexId[i]] == false, "Sold");
      mintLand(hexId[i], to[i], flag[i]);
    }
  }

  /**
  * @dev Returns Land of HexId.
  **/ 
  function getHexLand(bytes15 _hexId) public view returns(Land memory) {
    require(_exists(hexLand[_hexId]), "Don't Have Land.");
    return lands[hexLand[_hexId]];
  }

   /**
  * @dev Returns Land of TokenId.
  **/ 
  function getLand(uint256 _tokenId) public view returns(Land memory) {
    require(_exists(_tokenId), "Don't Have Land.");
    return lands[_tokenId];
  }
  
     /**
  * @dev Returns Land of Sale Token.
  **/ 
  function getLandSaleToken(uint256 _tokenId) public view returns(address) {
    require(lands[_tokenId].forSale == true, "Dont Have Sale Token.");
    return landSaleToken[_tokenId];
  }

 /**
  * @dev Returns User Loop Lands.
  **/ 

  function getLands(address user, uint offset, uint limit) public view returns (Land[] memory , uint nextOffset, uint total) {
    require(user != address(0));
    require(balanceOf(user) > 0, "You Don't Have Land.");  
        uint totalUserLands = ownerLandIds[user].length;
        if(limit == 0) {
            limit = 1;
        }
        
        if (limit > totalUserLands- offset) {
            limit = totalUserLands - offset;
        }

        Land[] memory values = new Land[] (limit);
        for (uint i = 0; i < limit; i++) {
            values[i] = lands[ownerLandIds[user][offset + i]];
        }

        return (values, offset + limit, totalUserLands);
    }


function removeOwnerLandsIds(address owner, uint256 tokenId) public{ 
     for(uint i=ownerLandIndex[owner][tokenId]; i < ownerLandIds[owner].length -1; i++){  
       ownerLandIds[owner][i] = ownerLandIds[owner][i+1];
     }
    ownerLandIds[owner].pop();
}

  /**
  * @dev Emergency Owner Change Flag. Politicy Etc.
  **/  

  function landChangeFlag(uint256 tokenId, bytes2 flag) external onlyOwner {
    lands[tokenId].flag = flag;
  }

  /**
  * @dev Emergency Owner Change Hex. Hex Id Problem Etc.
  **/  
  function landChangeHex(uint256 tokenId, bytes15 land) external onlyOwner {
    require(soldExits[land] == false, "Sold Not Change");
    lands[tokenId].hexId = land;
    hexLand[land] = tokenId;
  }


  /**
  * @dev Set White List Address.
  **/
  function setWhitelistAddress(address[] memory user, uint256[] memory amount) public onlyOwner {
     for (uint256 i = 0; i < user.length; i++) {
       require(whiteLists[user[i]].exits == false, "Already User");
        whiteLists[user[i]] = WhiteList(amount[i], true);
    }
  }


  /**
  * @dev Set IHGT Address (INTERFACE HELPS GAME MULTI TOKEN )
  **/
  function updateIhgt(address _ihgt) public onlyOwner{
   IHGT = IhelpsGameToken(_ihgt);  
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
        require(lands[tokenId].forSale == false, "Land for Sale is not transferable");
        super._beforeTokenTransfer(from, to, tokenId);
       lands[tokenId].prevOwner = from;
       lands[tokenId].currentOwner = to;
       if(from != address(0)){ ownerLandIds[to].push(tokenId); removeOwnerLandsIds(from, tokenId);}
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
