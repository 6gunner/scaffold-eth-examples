//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721URIStorage, ERC721Enumerable {
    using Counters for Counters.Counter;
    // 自增的tokenId;
    Counters.Counter private _tokenIds;

    //   constructor(bytes32[] memory assetsForSale) ERC721("KYToken", "KYT") {
    //     for(uint256 i=0;i<assetsForSale.length;i++){
    //       forSale[assetsForSale[i]] = true;
    //     }
    //   }

    constructor() ERC721("KYToken", "KYT") {}

    //this marks an item in IPFS as "forsale"
    // mapping (bytes32 => bool) public forSale;
    //this lets you look up a token by the uri (assuming there is only one of each uri for now)
    // 通过uri来找tokenId;
    mapping(bytes32 => uint256) public uriToTokenId;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
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

    function mintItem(string memory uri) public returns (uint256) {
        bytes32 uriHash = keccak256(abi.encodePacked(uri));

        //make sure they are only minting something that is marked "forsale"
        // require(forSale[uriHash],"NOT FOR SALE");
        // forSale[uriHash]=false;

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);
        _setTokenURI(id, uri);

        uriToTokenId[uriHash] = id;

        return id;
    }
}
