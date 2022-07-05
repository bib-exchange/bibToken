pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract BIBTokenNew is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    uint public decimalVal = 1e18;
    uint256 public tokenAmount = 100000000000;

    uint256 initialSupply = decimalVal * tokenAmount;

    address public tokenOwner;
    address public devAddr;
    address public ecologyAddr;
    address public privateSaleAddr;
    address public idoieoAddr;
    address public liquidityAddr;
    address public marketingAddr;
    address public nftminingAddr; 
    address public businessAddr;

    /// @custom:oz-upgrades-unsafe-allow constructor
 function initialize() initializer public {
    tokenOwner = msg.sender;
    __ERC20_init("BIBToken", "BIB");
    _mint(tokenOwner, initialSupply);
    __Pausable_init();
    __Ownable_init();
    // Epoch time: 8.15.2022 at 00:00:00 GMT time
    // uint64 private _startingTime = 1660492800;
}


 function initAddress(
        address _devAddr,
        address _ecologyAddr,
        address _privateSaleAddr,
        address _idoieoAddr,
        address _liquidityAddr,
        address _marketingAddr,
        address _nftminingAddr,
        address _businessAddr) public onlyOwner {
        require(_devAddr != address(0), "_dev is not the zero address");
        require(_ecologyAddr != address(0), "_ecology is not the zero address");
        require(_privateSaleAddr != address(0), "_privateSale is not the zero address");
        require(_idoieoAddr != address(0), "_idoieoAddr is not the zero address");
        require(_liquidityAddr != address(0), "_liquidity is not the zero address");
        require(_marketingAddr != address(0), "_marketing is not the zero address");
        require(_nftminingAddr != address(0), "_nftmining is not the zero address");
        require(_businessAddr != address(0), "_business is not the zero address");

        devAddr = _devAddr;
        ecologyAddr = _ecologyAddr;
        privateSaleAddr = _privateSaleAddr;
        idoieoAddr = _idoieoAddr;
        liquidityAddr = _liquidityAddr;
        marketingAddr = _marketingAddr;
        nftminingAddr = _nftminingAddr;
        businessAddr = _businessAddr;
}


function release() public onlyOwner {

    transfer(devAddr,(initialSupply.mul(15).mul(decimalVal).div(100).div(decimalVal))); // Send 15% of tokens to dev wallet 10,000,000,000 bibtoken
    transfer(ecologyAddr,(initialSupply.mul(23).mul(decimalVal).div(100).div(decimalVal))); // Send 23% of tokens to ecology wallet 10,000,000,000 bibtoken
    transfer(privateSaleAddr,(initialSupply.mul(15).mul(decimalVal).div(100).div(decimalVal)));
    transfer(idoieoAddr,(initialSupply.mul(5).mul(decimalVal).div(100).div(decimalVal)));// Send 15% of tokens to foundation wallet 15,000,000,00 bibtoken
    transfer(liquidityAddr,(initialSupply.mul(3).mul(decimalVal).div(100).div(decimalVal))); // Send 5% of tokens to ido wallet 5,000,000,000 bibtoken
    transfer(marketingAddr,(initialSupply.mul(8).mul(decimalVal).div(100).div(decimalVal)));// Send 3% of tokens to tournaments wallet 35,000,000,000 bibtoken
    transfer(nftminingAddr,(initialSupply.mul(16).mul(decimalVal).div(100).div(decimalVal)));
    transfer(businessAddr,(initialSupply.mul(15).mul(decimalVal).div(100).div(decimalVal)));// Send 16% of tokens to nftmining wallet 4,000,000,000 bibtoken

}

 function setDevAddress(address dev) public onlyOwner {
     require(dev != address(0), "_dev is not the zero address");
         devAddr = dev;
    }
    function setEcologyAddress(address ecology) public onlyOwner {
        require(ecology != address(0), "ecology is not the zero address");
         ecologyAddr = ecology;
    }
    function setPrivateSaleAddress(address privateSale) public onlyOwner {
         require(privateSale != address(0), "privateSale is not the zero address");
         privateSaleAddr = privateSale;
    }

    function setIdoAddress(address idoieo) public onlyOwner {
        require(idoieo != address(0), "idoieo is not the zero address");
        idoieoAddr = idoieo;
    }

    function setMarketingAddress(address marketing) public onlyOwner {
        require(marketing != address(0), "marketing is not the zero address");
        marketingAddr = marketing;
    }

    function setNftReserveAddress(address nftmining) public onlyOwner {
        require(nftmining != address(0), "nftmining is not the zero address");
        nftminingAddr = nftmining;
    }

    function setBusinessAddress(address business) public onlyOwner {
        require(business != address(0), "business is not the zero address");
        businessAddr = business;
    }

    function setLiquidityAddress(address liquidity) public onlyOwner {
        require(liquidity != address(0), "liquidity is not the zero address");
        liquidityAddr = liquidity;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
