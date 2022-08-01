// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/ITokenDividendTracker.sol";
import "../interface/FreezeTokenInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BIBToken is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    mapping(address => bool) public admin;

    IUniswapV2Router02 public uniswapV2Router;
    FreezeTokenInterface public freezeToken;
    address public uniswapV2Pair;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public rewardToken; //rewardToken
    address public router;

    uint public rewardFee = 6;
    uint public blackholeFee = 1;
    uint public liquidityFee = 3;

    bool private swapping;

    ITokenDividendTracker public dividendTracker;
    address public liquidityWallet;
    address public tokenOwner;
    address public devAddr;
    address public ecologyAddr;
    address public privateSaleAddr;
    address public idoieoAddr;
    address public marketingAddr;
    address public nftminingAddr; 
    address public businessAddr;
    uint public decimalVal = 1e18;

    uint256 public maxSellTransactionAmount = 10_000_000_000_000 * decimalVal;
    uint256 public swapTokensAtAmount = 1000_000_000 * decimalVal;

    bool public swapEnabled;

    uint256 initialSupply = 100_000_000_000 * decimalVal;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    bool public allowTransfer;

    mapping(address => bool) public isFromWhiteList;
    mapping(address => bool) public isToWhiteList;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public noProcessList;
    address private canStopAntibotMeasures;
    uint256 public antibotEndTime;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded, bool isFrom);

    event NoProcessList(address indexed account, bool noProcess);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapTokensAtAmountUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    function initialize(
        address _dividendTracker, 
        address _router,
        address _rewardToken
        ) initializer public {
        tokenOwner = msg.sender;
        __ERC20_init("BIBToken", "BIB");
        _mint(tokenOwner, initialSupply);
        __Pausable_init();
        __Ownable_init();

        require(address(0) != _rewardToken, "INVLID_REWARD_TOKEN");
        require(address(0) != _dividendTracker, "INVLID_DIVIDENTTRACKER");
        require(address(0) != _router, "INVLID_ROUTER");
        
        rewardToken = _rewardToken;
        dividendTracker = ITokenDividendTracker(_dividendTracker);
        require(dividendTracker.controller() == address(this), "Token: The new dividend tracker must be owned by the Token token contract");

        router = _router;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadAddress);

        // exclude from paying fees or having max transaction amount
        setFeeWhiteList(owner(), true, true);
        setFeeWhiteList(address(this), true, true);
        setFeeWhiteList(_uniswapV2Pair, true, true);
        setFeeWhiteList(deadAddress, true, false);

        swapEnabled = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function initAddress(
        address _devAddr,
        address _ecologyAddr,
        address _privateSaleAddr,
        address _idoieoAddr,
        address _liquidityWallet,
        address _marketingAddr,
        address _nftminingAddr,
        address _businessAddr) public onlyOwner {
        require(_devAddr != address(0), "_dev is not the zero address");
        require(_ecologyAddr != address(0), "_ecology is not the zero address");
        require(_privateSaleAddr != address(0), "_privateSale is not the zero address");
        require(_idoieoAddr != address(0), "_idoieoAddr is not the zero address");
        require(_liquidityWallet != address(0), "_liquidity is not the zero address");
        require(_marketingAddr != address(0), "_marketing is not the zero address");
        require(_nftminingAddr != address(0), "_nftmining is not the zero address");
        require(_businessAddr != address(0), "_business is not the zero address");

        devAddr = _devAddr;
        ecologyAddr = _ecologyAddr;
        privateSaleAddr = _privateSaleAddr;
        idoieoAddr = _idoieoAddr;
        liquidityWallet = _liquidityWallet;
        marketingAddr = _marketingAddr;
        nftminingAddr = _nftminingAddr;
        businessAddr = _businessAddr;
        dividendTracker.excludeFromDividends(address(devAddr));
        dividendTracker.excludeFromDividends(address(ecologyAddr));
        dividendTracker.excludeFromDividends(address(privateSaleAddr));
        dividendTracker.excludeFromDividends(address(idoieoAddr));
        dividendTracker.excludeFromDividends(address(liquidityWallet));
        dividendTracker.excludeFromDividends(address(marketingAddr));
        dividendTracker.excludeFromDividends(address(nftminingAddr));
        dividendTracker.excludeFromDividends(address(businessAddr));
    }

    receive() external payable {}

    function release() public onlyOwner {
        // Send 15% of tokens to dev wallet 10,000,000,000 bibtoken
        transfer(devAddr,(initialSupply.mul(15).div(100))); 
        // Send 23% of tokens to ecology wallet 10,000,000,000 bibtoken
        transfer(ecologyAddr,(initialSupply.mul(23).div(100))); 
        transfer(privateSaleAddr,(initialSupply.mul(15).div(100)));
        // Send 15% of tokens to foundation wallet 15,000,000,00 bibtoken
        transfer(idoieoAddr,(initialSupply.mul(5).div(100)));
        // Send 5% of tokens to ido wallet 5,000,000,000 bibtoken
        transfer(liquidityWallet,(initialSupply.mul(3).div(100))); 
        // Send 3% of tokens to tournaments wallet 35,000,000,000 bibtoken
        transfer(marketingAddr,(initialSupply.mul(8).div(100)));
        transfer(nftminingAddr,(initialSupply.mul(16).div(100)));
        // Send 16% of tokens to nftmining wallet 4,000,000,000 bibtoken
        transfer(businessAddr,(initialSupply.mul(15).div(100)));
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Token: The dividend tracker already has that address");
        ITokenDividendTracker newDividendTracker = ITokenDividendTracker(payable(newAddress));
        require(newDividendTracker.controller() == address(this), "Token: The new dividend tracker must be owned by the Token token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function addExcludeFromDividends(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            dividendTracker.excludeFromDividends(addrs[i]);
        }
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(!isContract(newAddress), "newAddress is contract address");
        require(newAddress != address(uniswapV2Router), "Token: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function setFeeWhiteList(address account, bool excluded, bool isFrom) public onlyOwner {
        if (isFrom) {
            require(isFromWhiteList[account] != excluded, "Token: Account is already the value of 'excluded'");
            isFromWhiteList[account] = excluded;
        } else {
            require(isToWhiteList[account] != excluded, "Token: Account is already the value of 'excluded'");
            isToWhiteList[account] = excluded;
        }
        emit ExcludeFromFees(account, excluded, isFrom);
    }

    function setMultipleWhiteList(address[] calldata accounts, bool excluded, bool isFrom) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            setFeeWhiteList(accounts[i], excluded, isFrom);
        }
    }

    function setNoProcessList(address account, bool noProcess) public onlyOwner {
        require(noProcessList[account] != noProcess, "Token: Account is already the value of 'noProcess'");
        noProcessList[account] = noProcess;
        emit NoProcessList(account, noProcess);
    }

    function setMultipleNoProcessList(address[] calldata accounts, bool noProcess) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            setNoProcessList(accounts[i], noProcess);
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Token: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Token: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue != gasForProcessing, "Token: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateSwapTokensAtAmount(uint256 newValue) public onlyOwner {
        require(newValue != swapTokensAtAmount, "Token: Cannot update swapTokensAtAmount to same value");
        emit SwapTokensAtAmountUpdated(newValue, swapTokensAtAmount);
        swapTokensAtAmount = newValue;
    }

    function setSellFee(uint16 _rewardfee, uint16 _blackhole, uint16 _liquidity) external onlyOwner {
        rewardFee = _rewardfee;
        blackholeFee = _blackhole;
        liquidityFee = _liquidity;
        require(rewardFee + blackholeFee + liquidityFee > 1, "INVALID_FEE_RATIO");
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getAccountDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
    (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setLiquidityWallet(address liquidity) external onlyOwner{
        require(liquidity != address(0), "liquidity is not the zero address");
        liquidityWallet = payable(liquidity);
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

    function setFreezeTokenAddress(address _freezeToken) public onlyOwner {
        require(_freezeToken != address(0), "_freezeToken is not the zero address");
        freezeToken = FreezeTokenInterface(_freezeToken);
    }

    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }

    function setAllowTransfer(bool value) external onlyOwner{
        allowTransfer = value;
    }

    function _checkFreezeAmount(address account, uint256 transferAmount) internal view returns(bool) {
        if (address(freezeToken) == address(0)) {
            return true;
        }
        uint256 freezeAmount = freezeToken.getFreezeAmount(account);
        return balanceOf(account) - freezeAmount >= transferAmount;
    }

    function _transfer(
    address from,
    address to,
    uint256 amount
    ) internal override {
        require(allowTransfer, "ERC20: unable to transfer");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require (!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted address");
        require (_checkFreezeAmount(from, amount), "Not enough available balance");

        // forbiden bot
        if (from != owner() && to != owner() && (block.timestamp <= antibotEndTime || antibotEndTime == 0)) {
            require (to == canStopAntibotMeasures, "Timerr: Bots can't stop antibot measures");
            if (antibotEndTime == 0)
                antibotEndTime = block.timestamp + 3;
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Check max wallet
        if (from != owner() && to != uniswapV2Pair){
            require (balanceOf(to) + amount <= maxSellTransactionAmount, " Receiver's wallet balance exceeds the max wallet amount");
        }

        // check if have sufficient balance
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(swapEnabled && !swapping && !noProcessList[to] && canSwap) {
            swapping = true;
            contractTokenBalance = swapTokensAtAmount;

            // part goes to liquadation pool
            uint256 swapTokens = contractTokenBalance.mul(
                liquidityFee).div(liquidityFee.add(rewardFee));
            swapAndLiquify(swapTokens);

            // part gose to dividens pool
            swapAndSendDividends(contractTokenBalance.sub(swapTokens));

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(isFromWhiteList[from] || isToWhiteList[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(liquidityFee.add(rewardFee)).div(100);
            uint256 burned = amount.mul(blackholeFee).div(100);
            amount = amount.sub(fees).sub(burned);
            super._transfer(from, deadAddress, burned);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping && !noProcessList[to]) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } 
            catch {}
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 tokens) private{
        // split the contract balance into halves,
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;//address(this)??

        // swap tokens for rewardToken
        swapTokensForEth(half); // <- this breaks the rewardToken -> HATE swap when swap+liquify is triggered

        // how much rewardToken did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForBusd(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = rewardToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function setAntiBotStopAddress (address account) external onlyOwner {
        require (account != address(0));
        canStopAntibotMeasures = account;
    }

    function blacklistAddress (address account, bool blacklist) external onlyOwner {
        require (isBlacklisted[account] != blacklist);
        require (account != uniswapV2Pair);
        isBlacklisted[account] = blacklist;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForBusd(tokens);
        uint256 dividends = IERC20(rewardToken).balanceOf(address(this));
        bool success = IERC20(rewardToken).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}