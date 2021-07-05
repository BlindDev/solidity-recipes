// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
We create a token with the DOG symbol and the name is Dogie. We can then mint as many DOGs as we want with the createCollectible function, 
which stores us a new tokenId every time we do so. All we need to do is pass a tokenURI, 
which is just any URL/URI that points to something in the metadata JSON format of:
{
  "name": "Name",    
  "description": "Description",    
  "image": "URI",    
  "attributes": []
}
This is nice, but let’s level up. If you want a walkthrough of the simple NFT, check this video.
 */
contract SimpleCollectible is ERC721 {
  uint256 public tokenCounter;
  constructor () public ERC721 ("Dogie", "DOG"){
    tokenCounter = 0;
  }
  function createCollectible(string memory tokenURI) public returns (uint256) {
    uint256 newItemId = tokenCounter;
    _safeMint(msg.sender, newItemId);
    _setTokenURI(newItemId, tokenURI);
    tokenCounter = tokenCounter + 1;
    return newItemId;
  }
}