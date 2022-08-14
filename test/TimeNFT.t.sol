// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "../src/TimeNFT.sol";

contract NFTTest is Test {
    // Target contract
    TimeNFT public nftContract;

    // Actors
    address owner;
    address ZERO_ADDRESS = address(0);
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        owner = address(this);
        nftContract = new TimeNFT();
    }

    function testOwnerMint() public {
        vm.prank(owner);
        nftContract.mint(owner, "", "");
        uint256 tokenBalance1 = nftContract.balanceOf(owner);
        assertEq(tokenBalance1, 1);
    }

    function testFailNotOwnerMint() public {
        vm.prank(user1);
        nftContract.mint(user1, "", "");
    }

    function testSettimezone() public {
        vm.prank(owner);
        nftContract.mint(user1, "daytime", "night");
        vm.warp(0); //Default is JST(+0900). current time is daytime(9:00)!
        string memory tokenURIValue = nftContract.tokenURI(0);
        assertEq(tokenURIValue, "ipfs://daytime");
        vm.prank(user1);
        nftContract.settimezone(0, 0); //UTC(+0000). current time is night(1:00)!
        tokenURIValue = nftContract.tokenURI(0);
        assertEq(tokenURIValue, "ipfs://night");
    }

    function testFailNotTokenOwnerSettimezone() public {
        vm.prank(owner);
        nftContract.mint(user1, "", "");
        uint256 tokenBalance1 = nftContract.balanceOf(user1);
        assertEq(tokenBalance1, 1);
        nftContract.settimezone(0, 0);
    }

    function testTokenURI() public {
        vm.prank(owner);
        nftContract.mint(owner, "daytime", "night");
        vm.warp(39599); //Default is JST(+0900). current time is daytime(19:59)!
        string memory tokenURIValue = nftContract.tokenURI(0);
        assertEq(tokenURIValue, "ipfs://daytime");
        vm.warp(39600); //Default is JST(+0900). current time is night(20:00)!
        tokenURIValue = nftContract.tokenURI(0);
        assertEq(tokenURIValue, "ipfs://night");
        vm.warp(82799); //Default is JST(+0900). current time is night(7:59)!
        tokenURIValue = nftContract.tokenURI(0);
        assertEq(tokenURIValue, "ipfs://night");
        vm.warp(82800); //Default is JST(+0900). current time is daytime(8:00)!
        tokenURIValue = nftContract.tokenURI(0);
        assertEq(tokenURIValue, "ipfs://daytime");
    }

    function testGetRaribleV2Royalties() public {
        vm.prank(owner);
        nftContract.mint(user1, "", "");
        LibPart.Part[] memory royaltyValue =
            nftContract.getRaribleV2Royalties(0);
        assertEq(royaltyValue[0].value, 1000);
        assertEq(royaltyValue[0].account, owner);
    }

    function testSetDefaultPercentageBasisPoints() public {
        vm.prank(owner);
        nftContract.setDefaultPercentageBasisPoints(3000);
        LibPart.Part[] memory royaltyValue =
            nftContract.getRaribleV2Royalties(0);
        assertEq(royaltyValue[0].value, 3000);
        assertEq(royaltyValue[0].account, owner);
    }

    function testRoyaltyInfo() public {
        vm.prank(owner);
        nftContract.mint(user1, "", "");
        (address receiver, uint256 royaltyAmount) =
            nftContract.royaltyInfo(0, 100);
        assertEq(receiver, owner);
        assertEq(royaltyAmount, 10);
    }

    function testSupportsInterface() public {
        bool boolSupportInterface = nftContract.supportsInterface(0x2a55205a); //IERC2981
        assertEq(boolSupportInterface, true);
        boolSupportInterface = nftContract.supportsInterface(0xcad96cca); //LibRoyaltiesV2
        assertEq(boolSupportInterface, true);
    }
}
