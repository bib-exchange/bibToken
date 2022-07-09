// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IterableMapping.sol";
import "./DividendPayingToken.sol";
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

contract BIBRewardToken is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public BUSD; //BUSD
    address public Router;
    //0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 bsc testnet
    //address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7) bsc mainnet
    // //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 bsc testnet router
        // //0x10ED43C718714eb63d5aA57B78B54704E256024E bsc mainnet router

    struct SellFee{
        uint16 rewardFee;
        uint16 blackholeFee;
        uint16 liquidityFee;
    }
    
    bool private swapping;

    SellFee public sellFee;
    
    TokenDividendTracker public dividendTracker;//分红对象
    address public liquidityWallet;          //流动性钱包
    address public tokenOwner;
    address public devAddr;
    address public ecologyAddr;
    address public privateSaleAddr;
    address public idoieoAddr;
    address public marketingAddr;
    address public nftminingAddr; 
    address public businessAddr;

    uint256 public maxSellTransactionAmount = 10000000000000 * (10 ** 18);              //最大卖出数量 1e 
    uint256 public swapTokensAtAmount = 1000000000 * (10**18);//可以兑换token数量

    uint16 private totalSellFee;
 
    bool public swapEnabled;

     uint public decimalVal = 1e18;
    uint256 public tokenAmount = 100000000000;

    uint256 initialSupply = decimalVal * tokenAmount;
 
    // use by default 300,000 gas to process auto-claiming dividends，默认使用300000 gas 处理自动申请分红
    uint256 public gasForProcessing = 300000;
    uint256 private launchDate;
 
    mapping (address => bool) private _isExcludedFromFees; //判断是否此账号需要手续费，true为不需要手续费
    mapping(address => bool) public isBlacklisted;//是否是黑名单,true表示这个地址是黑名单
    address private canStopAntibotMeasures;
    uint256 public antibotEndTime;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;//msg.sender加入索引参数
 
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);//监听更新分红跟踪事件
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);//监听更新周边路由事件
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
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
 
     modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    function initialize() initializer public {
    tokenOwner = msg.sender;
    __ERC20_init("BIBToken", "BIB");
    _mint(tokenOwner, initialSupply);
    __Pausable_init();
    __Ownable_init();
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
}

    constructor() {

        sellFee.rewardFee = 6;
        sellFee.blackholeFee = 1;
        sellFee.liquidityFee = 3;
        totalSellFee = 10;

        dividendTracker = new TokenDividendTracker();
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(Router);
         // Create a uniswap pair for this new token
         //createPair创建交易对 .该函数接受任意两个代币地址为参数，用来创建一个新的交易对合约并返回新合约的地址。
        //createPair的第一个地址是这个合约的地址，第二个地址是factory地址
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
 
        // exclude from receiving dividends 不在分红范围内的
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));//这个合约地址
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadAddress);                     //销毁地址
        dividendTracker.excludeFromDividends(address(devAddr));
        dividendTracker.excludeFromDividends(address(ecologyAddr));
        dividendTracker.excludeFromDividends(address(privateSaleAddr));
        dividendTracker.excludeFromDividends(address(idoieoAddr));
        dividendTracker.excludeFromDividends(address(liquidityWallet));
        dividendTracker.excludeFromDividends(address(marketingAddr));
        dividendTracker.excludeFromDividends(address(nftminingAddr));
        dividendTracker.excludeFromDividends(address(businessAddr));
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        swapEnabled = true;
    }
 
    receive() external payable {}

    function release() public onlyOwner {

    transfer(devAddr,(initialSupply.mul(15).div(100))); // Send 15% of tokens to dev wallet 10,000,000,000 bibtoken
    transfer(ecologyAddr,(initialSupply.mul(23).div(100))); // Send 23% of tokens to ecology wallet 10,000,000,000 bibtoken
    transfer(privateSaleAddr,(initialSupply.mul(15).div(100)));
    transfer(idoieoAddr,(initialSupply.mul(5).div(100)));// Send 15% of tokens to foundation wallet 15,000,000,00 bibtoken
    transfer(liquidityWallet,(initialSupply.mul(3).div(100))); // Send 5% of tokens to ido wallet 5,000,000,000 bibtoken
    transfer(marketingAddr,(initialSupply.mul(8).div(100)));// Send 3% of tokens to tournaments wallet 35,000,000,000 bibtoken
    transfer(nftminingAddr,(initialSupply.mul(16).div(100)));
    transfer(businessAddr,(initialSupply.mul(15).div(100)));// Send 16% of tokens to nftmining wallet 4,000,000,000 bibtoken

}
    
 
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Token: The dividend tracker already has that address");
 
        TokenDividendTracker newDividendTracker = TokenDividendTracker(payable(newAddress));
 
        require(newDividendTracker.owner() == address(this), "Token: The new dividend tracker must be owned by the Token token contract");
 
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
 
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
 
        dividendTracker = newDividendTracker;
    }
 
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(!isContract(newAddress), "newAddress is contract address");
        require(newAddress != address(uniswapV2Router), "Token: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function isContract(address addr) public returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
  }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Token: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
 
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
 
    //流动性是否可用
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

    function setSellFee(uint16 rewardfee, uint16 blackhole, uint16 liquidity) external onlyOwner {
        sellFee.rewardFee = rewardfee;
        sellFee.blackholeFee = blackhole;
        sellFee.liquidityFee = liquidity;
    
        totalSellFee = rewardfee + blackhole + liquidity;
    }
 
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
 
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }
 
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }
 
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
 
    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }
 
    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
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
        require(tx.origin == msg.sender);//add 
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
 
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function launch() external onlyOwner {
        launchDate = block.timestamp;
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
    
 
    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require (!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted address");

        //前三秒强先交易被视为机器人，然后拉黑
        if (from != owner() && to != owner() && (block.timestamp <= antibotEndTime || antibotEndTime == 0)) {
            require (to == canStopAntibotMeasures, "Timerr: Bots can't stop antibot measures");
            if (antibotEndTime == 0)
                antibotEndTime = block.timestamp + 3;
        }
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Check max wallet，接收钱包余额超过了最大的钱包数量
        if (from != owner() && to != uniswapV2Pair)
            require (balanceOf(to) + amount <= maxSellTransactionAmount, " Receiver's wallet balance exceeds the max wallet amount");

        uint256 contractTokenBalance = balanceOf(address(this));//获取该代币余额
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;//是否可以交易

        if(swapEnabled && !swapping && from != uniswapV2Pair && canSwap) {
            //精度提升
            contractTokenBalance = swapTokensAtAmount;
            uint16 totalFee = totalSellFee;

            uint256 swapTokens = contractTokenBalance.mul(
                sellFee.liquidityFee).mul(decimals()).div(totalFee).div(decimals());
            swapAndLiquify(swapTokens);
 
            uint256 sellTokens = contractTokenBalance.mul(
                sellFee.rewardFee).mul(decimals()).div(totalFee).div(decimals());
            swapAndSendDividends(sellTokens);
 
        }
 
        bool takeFee = true;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        if(takeFee) {
        	uint256 fees = amount.mul(totalSellFee).mul(decimals()).div(100).div(decimals());
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).mul(decimals()).div(100).div(decimals());
        	}
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }
 
        super._transfer(from, to, amount);// 转账msg.sender到合约地址，手续费用的币
 
        //该功能能够捕获仅在调用内部产生的异常，调用回滚（revert）了，不想终止交易的执行。//直接revert,require
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {revert();}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {revert();}
 
        if(!swapping) {
            uint256 gas = gasForProcessing;
 
            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                require(tx.origin == msg.sender);
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } 
            catch {
                revert();
            }
        }
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable滑点
            0, // slippage is unavoidable
            liquidityWallet,//流动性钱包地址
            block.timestamp
        );

    }
    
    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        // split the contract balance into halves,把该合约的余额平分，分成一半
        uint256 half = tokens.mul(decimals()).div(2).div(decimals());
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;//address(this)??

        // swap tokens for BUSD
        swapTokensForEth(half); // <- this breaks the BUSD -> HATE swap when swap+liquify is triggered

        // how much BUSD did we just swap into?
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
        path[2] = BUSD;

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
        require (account != uniswapV2Pair && blacklist);
        isBlacklisted[account] = blacklist;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
    super._beforeTokenTransfer(from, to, amount);
    }


    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForBusd(tokens);
        uint256 dividends = IERC20(BUSD).balanceOf(address(this));
        bool success = IERC20(BUSD).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeBUSDDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}
 
contract TokenDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
 
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
 
    mapping (address => bool) public excludedFromDividends;
 
    mapping (address => uint256) public lastClaimTimes;
 
    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;
 
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
 
    constructor() DividendPayingToken("Token_Dividend_Tracker", "Token_Dividend_Tracker") {
        claimWait = 1 hours;
        minimumTokenBalanceForDividends = 1e5 * (10**9); //must hold 10000 tokens
    }
 
    function _transfer(address, address, uint256) internal pure override {
        require(false, "Token_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() public pure override {
        require(false, "Token_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Token contract.");
    }
 
    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
 
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
 
        emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Token_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Token_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }
 
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
 
 
 
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
 
        index = tokenHoldersMap.getIndexOfKey(account);
 
        iterationsUntilProcessed = -1;
 
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
 
 
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
 
 
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
 
        lastClaimTime = lastClaimTimes[account];
 
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
 
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
 
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (address(0), -1, -1, 0, 0, 0, 0, 0);
        }
 
        address account = tokenHoldersMap.getKeyAtIndex(index);
 
        return getAccount(account);
    }
 
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
 
        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
 
        processAccount(account, true);
    }
 
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
 
        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }
 
        uint256 _lastProcessedIndex = lastProcessedIndex;
 
        uint256 gasUsed = 0;
 
        uint256 gasLeft = gasleft();
 
        uint256 iterations = 0;
        uint256 claims = 0;
 
        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;
 
            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }
 
            address account = tokenHoldersMap.keys[_lastProcessedIndex];
 
            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }
 
            iterations++;
 
            uint256 newGasLeft = gasleft();
 
            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
 
            gasLeft = newGasLeft;
        }
 
        lastProcessedIndex = _lastProcessedIndex;
 
        return (iterations, claims, lastProcessedIndex);
    }
 
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
 
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
 
        return false;
    }
}
