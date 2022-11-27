// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MyNFT.sol";
import "forge-std/console.sol";

contract DutchAuction {
    IERC721 public immutable nft;
    uint256 public immutable nftId;
    address payable public immutable seller;
    uint32 public immutable duration;
    uint32 public startAt;
    uint32 public endAt;
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
        uint32 _duration
    ) {
        require(
            _startingPrice >= _discountRate * _duration,
            "Discount must be less than 100%."
        );
        seller = payable(msg.sender);
        nft = IERC721(_nft);
        nftId = _nftId;
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        duration = _duration;
    }

    function start() external {
        require(msg.sender == seller, "Not seller");
        require(startAt == uint32(0) && endAt == uint32(0), "Already started.");

        startAt = uint32(block.timestamp);
        endAt = uint32(block.timestamp) + duration;

        // Transfers NFT to SC.
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }

    function getPrice() public view returns (uint256) {
        uint32 timeElapsed = uint32(block.timestamp) - startAt;
        return startingPrice - timeElapsed * discountRate;
    }

    function buy() external payable {
        uint256 price = getPrice();

        require(msg.value >= price, "not enough ETH sent.");

        if (msg.value - price > 0) {
            // Returns exceeding sent eth to buyer.
            payable(msg.sender).transfer(msg.value - price);
        }

        // Transfers NFT from SC to buyer.
        nft.transferFrom(address(this), msg.sender, nftId);

        emit Buy(msg.sender, price);

        // Transfers funds from SC to seller and destroys SC.
        selfdestruct(seller);
    }

    function close() external payable {
        require(msg.sender == seller, "Only seller.");
        require(uint32(block.timestamp) >= endAt, "Auction not ended.");

        // If auction finished, seller can close it getting back the NFT.
        nft.transferFrom(address(this), seller, nftId);

        emit Close();

        // Transfers funds from SC to seller and destroys SC.
        selfdestruct(seller);
    }
}
