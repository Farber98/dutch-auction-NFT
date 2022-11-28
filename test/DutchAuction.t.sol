// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MyNFT.sol";
import "../src/DutchAuction.sol";

contract DutchAuctionTest is Test {
    MyNFT nft;
    DutchAuction auction;
    address seller = address(0x1);
    address buyer2 = address(0x2);
    uint256 nftId = 77;
    uint256 startingPrice = 10 ether;
    uint256 discountRate = 0.01 ether;
    uint32 duration = 60 seconds;

    function setUp() public {
        vm.startPrank(seller);
        nft = new MyNFT();
        auction = new DutchAuction(
            address(nft),
            nftId,
            startingPrice,
            discountRate,
            duration
        );
        nft.mint(seller, nftId);
        assertEq(nft.ownerOf(nftId), seller);
        assertEq(nft.balanceOf(seller), 1);
        nft.approve(address(auction), nftId);
        assertEq(nft.getApproved(77), address(auction));
        vm.stopPrank();
    }

    function testStartNotSeller() public {
        vm.expectRevert("Only seller.");
        auction.start();
        vm.stopPrank();
    }

    function testStartAlreadyStarted() public {
        vm.startPrank(seller);
        assertEq(auction.startAt(), uint32(0));
        assertEq(auction.endAt(), uint32(0));
        auction.start();
        assertEq(auction.startAt(), uint32(block.timestamp));
        assertEq(auction.endAt(), uint32(block.timestamp) + duration);
        vm.expectRevert("Already started.");
        auction.start();
        vm.stopPrank();
    }

    function testStartOk() public {
        vm.startPrank(seller);
        assertEq(auction.startAt(), uint32(0));
        assertEq(auction.endAt(), uint32(0));
        auction.start();
        assertEq(nft.ownerOf(nftId), address(auction));
        assertEq(auction.startAt(), uint32(block.timestamp));
        assertEq(auction.endAt(), uint32(block.timestamp) + duration);

        vm.stopPrank();
    }

    function testGetPrice() public {
        testStartOk();
        assertEq(auction.getPrice(), 10 ether);
    }

    function testBuyNotEnough() public {
        testStartOk();
        vm.startPrank(buyer2);
        vm.deal(buyer2, 2 ether);
        assertEq(buyer2.balance, 2 ether);
        vm.expectRevert("not enough ETH sent.");
        auction.buy{value: 1 ether}();
        vm.stopPrank();
    }

    function testBuyWithRefund() public {
        testStartOk();
        vm.startPrank(buyer2);
        vm.deal(buyer2, 20 ether);
        assertEq(buyer2.balance, 20 ether);
        assertEq(nft.ownerOf(nftId), address(auction));
        assertEq(seller.balance, 0 ether);
        auction.buy{value: 20 ether}();
        assertEq(nft.ownerOf(nftId), buyer2);
        assertEq(buyer2.balance, 10 ether);
        assertEq(seller.balance, 10 ether);
        vm.stopPrank();
    }

    function testBuyNoRefund() public {
        testStartOk();
        vm.startPrank(buyer2);
        vm.deal(buyer2, 10 ether);
        assertEq(buyer2.balance, 10 ether);
        assertEq(nft.ownerOf(nftId), address(auction));
        assertEq(seller.balance, 0 ether);
        auction.buy{value: 10 ether}();
        assertEq(nft.ownerOf(nftId), buyer2);
        assertEq(buyer2.balance, 0 ether);
        assertEq(seller.balance, 10 ether);
        vm.stopPrank();
    }

    function testCloseNotSeller() public {
        vm.expectRevert("Only seller.");
        auction.close();
    }

    function testCloseNotEnded() public {
        testStartOk();

        vm.startPrank(seller);
        vm.expectRevert("Auction not ended.");
        auction.close();
        vm.stopPrank();
    }

    function testCloseOk() public {
        testStartOk();
        vm.startPrank(seller);
        vm.warp(block.timestamp + 8 days);
        assertEq(nft.ownerOf(nftId), address(auction));
        auction.close();
        assertEq(nft.ownerOf(nftId), seller);
        vm.stopPrank();
    }
}
