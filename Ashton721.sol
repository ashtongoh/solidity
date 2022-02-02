// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IStorage {
    function getBack() external view returns (string memory);
    function getOutline() external view returns (string memory);
    function getFore(uint256 _index) external view returns (string memory);
    function getShading(uint256 _index) external view returns (string memory);
}

contract Ashton721 is ERC721Enumerable, ReentrancyGuard, Ownable, Pausable {

    using Strings for uint256; // This is so that uint256 can call up functions from the Strings library

    using Counters for Counters.Counter;
    //Counters.Counter private _tokenIds;

    uint256 public numClaimed = 0;

    address storageContract;

    // Gotta change this to something more "random"
    string private ra1='A';
    string private ra2='C';

    string[] private z = [
        '<svg width="100%" height="100%" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        '"<image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> </svg>'
    ];

    struct Alphabet {
        uint8 fore;
        uint8 shading;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function genChar(uint256 tokenId) internal view returns (Alphabet memory){
        
        Alphabet memory alphabet;

        alphabet.fore = uint8(random(string(abi.encodePacked(ra1,tokenId.toString()))) % 8);
        alphabet.shading = uint8(random(string(abi.encodePacked(ra2,tokenId.toString()))) % 8);

        return alphabet;
    }
 
    function genPNG(Alphabet memory alphabet) internal view returns (string memory) {

        string memory back_layer = IStorage(storageContract).getBack();
        string memory outline_layer = IStorage(storageContract).getOutline();
        string memory fore_layer = IStorage(storageContract).getFore(alphabet.fore);
        string memory shading_layer = IStorage(storageContract).getShading(alphabet.shading);

        string memory output = string(abi.encodePacked(z[0],z[1],back_layer,z[2]));
        output = string(abi.encodePacked(output,outline_layer,z[3],fore_layer,z[4],shading_layer,z[5]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory){
        require(_exists(tokenId), "TokenID does not exist");

        Alphabet memory alphabet = genChar(tokenId);

        string memory json = string(abi.encodePacked('{"name": "Ashton NFT #', tokenId.toString(), '",'));

        json = string(abi.encodePacked(json, '"description": "This is a NFT of the first initial of my name!",'));

        json = string(abi.encodePacked(json,
                '"attributes": [{"trait_type": "Foreground Colour", "value": "', uint256(alphabet.fore).toString(), 
                '"},',
                '{"trait_type": "Shading Colour", "value": "', uint256(alphabet.shading).toString(),
                '"}'));

        json = Base64.encode(bytes(string(abi.encodePacked(json, '],"image_data": "data:image/svg+xml;base64,', Base64.encode(bytes(genPNG(alphabet))),'"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
        
    }

    // Public mint
   function claim() public nonReentrant whenNotPaused{

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _safeMint(_msgSender(), tokenId);
        numClaimed += 1;
    }

    function burnToken(uint256 tokenId) public nonReentrant whenNotPaused{
        _burn(tokenId);
    }

    function pauseContract() public nonReentrant onlyOwner {
        _pause();
    }

    function unpauseContract() public nonReentrant onlyOwner {
        _unpause();
    }
    
    constructor() ERC721("Test", "Ash") Ownable() {
        storageContract = 0xA94F70BB8E7894fdF7fbfccFDc56231bD9Ab78F2;
    }
}
