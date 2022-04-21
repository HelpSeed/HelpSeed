// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}



abstract contract HelpSeedLandStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs

    struct ULand {
     bytes2 flag;
     bytes15 hexId;
    }

    mapping(uint256 => ULand) private _landTokenUris;
    mapping(uint256 => string) private _tokenURIs;



      function get(uint256 tokenId) internal view returns (string memory) {
       string memory svg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512' style='enable-background:new 0 0 512 512' width='350' height='350' xml:space='preserve'><path style='fill:#173b57' d='M80 0h352c44.184 0 80 35.816 80 80v352c0 44.184-35.816 80-80 80H80c-44.184 0-80-35.816-80-80V80C0 35.816 35.816 0 80 0z'/><path style='fill:#c37a86' d='m112.2 173.408 143.8-82.6 143.8 82.6v165.184l-143.8 82.6-143.8-82.6z'/><text font-family='Helvetica, sans-serif' style='font-size:20px;text-transform: uppercase;font-weight:800;fill:#ffff' x='25%' y='265'>",abi.encodePacked(_landTokenUris[tokenId].hexId),"~",abi.encodePacked(_landTokenUris[tokenId].country),"</text><g/><g/><g/><g/><g/><g/><g/><g/><g/><g/><g/><g/><g/><g/><g/><text font-family='Helvetica, sans-serif' x='18%' y='480' style='font-size:25px;font-weight:800;fill:white'>METAVERSE HELPSLAND</text></svg>"));
       string memory json=Base64.encode(bytes(string(abi.encodePacked('{"name": "HelpSeed Metaverse Land ', _landTokenUris[tokenId].hexId, '",','"description":"HelpSeed Metaverse Land Game Nft Item",','"image": "',svg, '",','"attributes":[{"trait_type":"Hex Id", "value":"', abi.encodePacked(_landTokenUris[tokenId].hexId), '"}'',{"trait_type":"Flag", "value":"', abi.encodePacked(_landTokenUris[tokenId].flag), '"}',']}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    } 
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "LANDSTORAGEURI: URI query for nonexistent token");
        return get(tokenId);
          
              }

    function _setTokenURI(uint256 tokenId, bytes15 hexId, bytes2 flag) internal virtual {
        require(_exists(tokenId), "LANDSTORAGEURI: URI set of nonexistent token");
       ULand memory uland = _landTokenUris[tokenId];
       uland.hexId = hexId;
       uland.flag = flag;
       _landTokenUris[tokenId] = uland;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

}
