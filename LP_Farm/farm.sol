
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/farm.sol

pragma solidity ^0.8.0;


//import "hardhat/console.sol";


interface IAshtonCoin {
    function mint(address to, uint256 amount) external;
}

interface IAshtonNFT {
    function claim() external;
}

contract TokenFarm is Ownable {

    struct User {
        uint256[3] stakingBalance;
        bool[3] isStaking;
        uint256[3] startTime;
        uint256[3] rewardBalance;
    }

    // Default value is 10
    uint256 rewardDivisor = 10;

    // Store the address of the LP tokens
    mapping(uint256 => IERC20) private addressMapping;

    // Maps user address to user object (struct)
    mapping(address => User) addrToUser;

    // This is to store the block rewards for each token
    mapping(uint256 => uint256) private tokenRewardMapping;

    // Rewards: ERC20 and ERC721
    address ashtonCoinAddress;
    address ashtonNFTAddress;

    constructor(){
        tokenRewardMapping[0] = 50; // LP Token 1
        tokenRewardMapping[1] = 30; // LP Token 2
        tokenRewardMapping[2] = 20; // LP Token 3
    }

    function stake(uint256 amount, uint256 index) public {
         // Get address of particular LP token
        IERC20 thisLPToken = addressMapping[index];

        require(amount > 0 && thisLPToken.balanceOf(msg.sender) >= amount, "You cannot stake zero tokens");
    
        User memory thisUser;
        thisUser = addrToUser[msg.sender];
        
        //If the user is already staking, take the current rewards and store it inside rewardBalance
        if(thisUser.isStaking[index] == true){
            uint256 rewards = calculateRewards(msg.sender, index);
            thisUser.rewardBalance[index] += rewards;
            //console.log("Old rewards transferred:", rewards);
        }

        // Transfer LP tokens to this contract to stake/add liquidity
        thisLPToken.transferFrom(msg.sender, address(this), amount);

        // Stores the amount staked in the user's mapping
        thisUser.stakingBalance[index] += amount;
        
        // Start at current block number
        thisUser.startTime[index] = block.number;
        
        // Set user's staking status in the mapping to true
        thisUser.isStaking[index] = true;

        // Assign thisUser back to mapping to update values
        addrToUser[msg.sender] = thisUser;

        //console.log("Amount Staked:", amount);
    }

    function unstake(uint256 amount, uint256 index) public {
    
        User memory thisUser;
        thisUser = addrToUser[msg.sender];
        
        require(thisUser.isStaking[index] = true && thisUser.stakingBalance[index] >= amount, "Nothing to unstake");

        // Get address of particular LP token
        IERC20 thisLPToken = addressMapping[index]; 

        // Make sure to calculate rewards and take rewards out first
        // Get rewards from current stake
        uint256 rewards = calculateRewards(msg.sender, index);
        thisUser.rewardBalance[index] += rewards;

        // Transfer LP tokens from contract to recipient (msg.sender)
        thisLPToken.transfer(msg.sender, amount);

        // Unstake set amount from the user's mapping
        thisUser.stakingBalance[index] -= amount;

        // Set current block number as start time
        thisUser.startTime[index] = block.number;

        // If user's balance becomes 0, change staking status to false
        if(thisUser.stakingBalance[index] == 0){
            thisUser.isStaking[index] = false;
        }

        // Assign thisUser back to mapping to update values
        addrToUser[msg.sender] = thisUser;

        //console.log("Amount unstaked:", amount);
    }

    function withdrawRewards(uint256 index) public {
        // This withdraws all rewards

        // Put require function here for users that dont exist in the mapping
        //require(addrToUser[msg.sender].isStaking[index], "You are not currently staking!");
        uint256 rewards = calculateRewards(msg.sender, index);
        User memory thisUser;
        thisUser = addrToUser[msg.sender];

        require(rewards > 0 || thisUser.rewardBalance[index] > 0, "Nothing to withdraw");
            
        if(thisUser.rewardBalance[index] != 0){
            uint256 oldBalance = thisUser.rewardBalance[index];
            thisUser.rewardBalance[index] = 0;
            rewards += oldBalance;
        }

        // Extra NFT reward
        uint256 currentBlock = block.number;
        uint256 startingBlock = addrToUser[msg.sender].startTime[index];

        if((currentBlock - startingBlock) >= 5 ){
            IAshtonNFT(ashtonNFTAddress).claim();
        }

        // Normal reward: Ashton coin
        IAshtonCoin(ashtonCoinAddress).mint(msg.sender, rewards);

        thisUser.startTime[index] = block.number;

        // Assign thisUser back to mapping to update values
        addrToUser[msg.sender] = thisUser;

        //console.log("Rewards withdrawn:", rewards);
    }

    function calculateRewards(address user, uint256 index) internal view returns(uint256) {
        
        // Example of reward rate
        // By default, user gets a reward for every 10 tokens staked
        // Reward rate can be changed by changing the rewardDivisor
        uint256 thisUserRate = addrToUser[user].stakingBalance[index] / rewardDivisor;
        uint256 currentBlock = block.number;
        uint256 startingBlock = addrToUser[user].startTime[index];
        uint256 reward = (currentBlock - startingBlock) * tokenRewardMapping[index] * thisUserRate;

        return reward;
    }

    function checkStaked(uint256 _index) public view returns (uint256){
        return addrToUser[msg.sender].stakingBalance[_index];
    }

    // Check reward balance
    function checkRewards(uint256 _index) public view returns (uint256){
        return addrToUser[msg.sender].rewardBalance[_index];
    }

    // Check rolling rewards
    function checkCurrentRollingRewards(uint256 _index) public view returns (uint256){
        return calculateRewards(msg.sender, _index);
    }

    function setRewardDivisor(uint256 _value) public onlyOwner{
        rewardDivisor = _value;
    }

    function setAshTokenAddress(address _address) public onlyOwner{
       ashtonCoinAddress = _address;
    }

    function setAshNFTAddress(address _address) public onlyOwner{
       ashtonNFTAddress = _address;
    }

    function setLPTokensAddresses(IERC20 _address1, IERC20 _address2, IERC20 _address3) public onlyOwner{
        addressMapping[0] = _address1;
        addressMapping[1] = _address2;
        addressMapping[2] = _address3;
    }

}