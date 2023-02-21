// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IEscrow.sol";
import "./IProduct.sol";

contract Product is IProduct,ERC721,ERC721Enumerable,Ownable {
    using SafeMath for uint256;
    // max supply
    uint256 public maxSupply = 140000; 

    // product's total sold
    mapping(uint256 => uint256) public prodTotalSold;

    // product's success sold
    mapping(uint256 => uint256) public prodSuccessSold;

    // product's success rate
    mapping(uint256 => uint8) public prodSuccessRate;

    // mint event
    event Mint(
        uint256 indexed productId
    );

    // update sold event
    event UpdateSold(
        uint256 indexed productId,
        bool indexed ifSuccess
    );

    // escrow contract address
    address payable public escrowAddress;

    constructor()  ERC721("Dejob Product", "PROD")  {

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,/* firstTokenId */
        uint256 batchSize
    )
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // function baseTokenURI() public pure returns (string memory) {
    //     return "https://savechives.com/rest/V1/vc/mod/id/";
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://savechives.com/rest/V1/vc/mod/id/";
    }



    function contractURI() public pure returns (string memory) {
        return "https://savechives.com/rest/V1/vc/mod/contract/info";
    }



    // set escrow contract address
    function setEscrow(address payable _escrow) public onlyOwner {
        IEscrow EscrowContract = IEscrow(_escrow);
        require(EscrowContract.getModAddress()==address(this),'Mod: wrong escrow contract address');
        escrowAddress = _escrow; 
    }

    // mint a new product
    function mint() public onlyOwner {
        uint256 tokenId                     = super.totalSupply().add(1);
        require(tokenId <= maxSupply, 'Mod: supply reach the max limit!');
        _safeMint(_msgSender(), tokenId);
        // set default product sold quantity
        prodTotalSold[tokenId]   =   0;  
        // emit mint event
        emit Mint(
            tokenId
        );
    }

    // get product's total supply
    function getMaxProdId() external view override returns(uint256) {
        return super.totalSupply();
    }

    // get product's owner
    function getProdOwner(uint256 prodId) external view override returns(address) {
        require(prodId <= super.totalSupply(),'PROD: illegal moderator ID!');
        return ownerOf(prodId);
    }

    // update product's sold score
    function updateProdScore(uint256 prodId, bool ifSuccess) external override returns(bool) {
        //Only Escrow contract can increase score
        require(escrowAddress == msg.sender,'Prod: only escrow contract can update product sold score');
        //total score add 1
        prodTotalSold[prodId] = prodTotalSold[prodId].add(1);
        if(ifSuccess) {
            // success score add 1
            prodSuccessSold[prodId] = prodSuccessSold[prodId].add(1);
        } else if(prodSuccessSold[prodId] > 0) {
            prodSuccessSold[prodId] = prodSuccessSold[prodId].sub(1);
        } else {
            // nothing changed
        }
        // recount mod success rate
        prodSuccessRate[prodId] = uint8(prodSuccessSold[prodId].mul(100).div(prodTotalSold[prodId]));
        // emit event
        emit UpdateSold(
            prodId,
            ifSuccess
        );
        return true;

    }

}