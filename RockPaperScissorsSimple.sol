// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    address owner; 

    event MoveMade(address player, uint256 amount, uint8 option, bool result);

    constructor() payable {
        owner = msg.sender;
    }

    function makeMove(uint8 _option) public payable returns (bool) {
        require(_option < 3, "Please select shape");
        require(msg.value > 0, "Please add your bet");
        require(msg.value * 2 <= address(this).balance, "Contract balance is insuffieient");
        // should be random number oracle
        bool result = block.timestamp * block.gaslimit % 3 == _option;
        emit MoveMade(msg.sender, msg.value, _option, result);
        
        if (result){
            payable(msg.sender).transfer(msg.value*2);
            return true;
        }

        return false;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}