// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe(); 
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD() , 5e18);
    }

    function testOwnerIsMsgSender()  public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() external {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testFundFailsWitoutEnoughEth() external {
        vm.expectRevert();// Next line should revert
        fundMe.fund();
    }

    function testFundUpdatedFundedDatastructe() external {
        vm.prank(USER); // Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 fundedAmount = fundMe.getAddressToAmountFunded(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER); // Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
    modifier funded {
        vm.prank(USER); // Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); 
        vm.prank(USER); // This cheat code is not expected to be reverted
        fundMe.withdraw();
    }
    
    function testWithdrawWithASingleFunder() public funded{
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);

    }

       function testWithdrawWithFromMultipleFunders() public funded{
        // Arrange
        uint160 funders = 10;
        uint160 startingFundersIndex = 1;

        for (uint160 i = startingFundersIndex; i < funders; i++) {
            hoax(address(i), SEND_VALUE );
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}