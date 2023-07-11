
pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant FUNDING_AMOUNT = 0.1 ether;
    uint256 constant START_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BALANCE);
    }

    function testMiniumDollarIsFive() external {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() external {
        console.log(fundMe.getOwner());
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() external {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFail() external {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundDataStructure() external {
        vm.prank(USER); // next tx is being sent by user
        fundMe.fund{value: FUNDING_AMOUNT}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, FUNDING_AMOUNT);
    }

    function testAddsFunderToFunderArray() external {
        vm.prank(USER);
        fundMe.fund{value: FUNDING_AMOUNT}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: FUNDING_AMOUNT}();
        _;
    }

    function testOnlyOwnerCanWithdraw() external funded {
        vm.prank(USER); 
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() external funded {
        // Arrange
        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(owner);
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        
        // Assert
        uint256 endingOwnerBalance = owner.balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() external funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), FUNDING_AMOUNT);
            fundMe.fund{value: FUNDING_AMOUNT}();
        }

        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.txGasPrice(GAS_PRICE);
        vm.prank(owner);
        fundMe.withdraw();

        uint256 endingOwnerBalance = owner.balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFundersCheaper() external funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), FUNDING_AMOUNT);
            fundMe.fund{value: FUNDING_AMOUNT}();
        }

        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.txGasPrice(GAS_PRICE);
        vm.prank(owner);
        fundMe.cheaperWithdraw();

        uint256 endingOwnerBalance = owner.balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
}