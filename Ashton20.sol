pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract AshtonToken is ERC20Capped {

    // require(MAX_SUPPLY > TOKENS_SOLD + numberOfTokensToBeMinted, "Insufficient supply");


    constructor() ERC20("AshtonToken", "ASH") ERC20Capped(1000000){
        _mint(msg.sender, 10000); // Setting initial supply to 10k tokens
    }

    function claimToken(uint256 amount) public {

        _mint(msg.sender, amount);
    }
}