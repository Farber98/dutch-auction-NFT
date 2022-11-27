// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MyNFT.sol";
import "forge-std/console.sol";

contract DutchAuction {
    IERC721 public immutable nft;
    uint256 public immutable nftId;
    address payable public immutable seller;
    uint private constant DURATION = 7 days;
    uint32 public immutable startAt;
    uint32 public immutable endAt;
    uint256 public immutable startingPrice;
    uint256 public immutable discountRate;

    event Start();
    event Buy(address buyer, uint256 price);
    event Close();

    constructor(
        address _nft,
        uint256 _nftId,
        uint256 _startingPrice,
        uint256 _discountRate,
    ) {
        require(_startingPrice >= _discountRate * DURATION, "last price must be higher than starting price.")
        seller = payable(msg.sender);
        startAt = block.timestamp;
        endAt = block.timestamp + DURATION;
        nft = IERC721(_nft);
        nftId = _nftId;
        startingPrice = _startingPrice;
        discountRate = _discountRate;

        emit Start();

        // Transfers NFT to SC.
        nft.transferFrom(seller, address(this), nftId);
    }

    function getPrice() public view returns (uint) {
        uint32 timeElapsed = uint32(block.timestamp) - startAt;
        return startingPrice - timeElapsed * discountRate;
    }
    
    function buy() external payable {
        uint price = getPrice();

        require(msg.value >= price, "not enough ETH sent.");
        
        emit End(msg.sender, price);

        if (msg.value - price > 0){
            // Returns exceeding sent eth to buyer.
            payable(msg.sender).transfer(msg.value - price);
        }

        // Transfers NFT from SC to buyer.
        nft.transferFrom(address(this), msg.sender, nftId);

        // Transfers funds from SC to seller and destroys SC.
        selfdestruct(seller);
    }
    
    function close() external payable {
        require(msg.sender == seller, "Only seller.");
        require(uint32(block.timestamp) >= endAt, "Auction not ended.");
        emit Close();

        // If auction finished, seller can close it getting back the NFT.
        nft.transferFrom(address(this), seller, nftId);
        
        // Transfers funds from SC to seller and destroys SC.
        selfdestruct(seller);
    }
}
