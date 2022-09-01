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
    address public w0;
    address public tokenOwner;
    address public w1;
    address public w2;
    address public w3;
    address public w4;
    address public w5;
    address public w6; 
    address public w7;
    uint public constant decimalVal = 1e18;

    uint256 public swapTokensAtAmount = 1000_000_000 * decimalVal;

    bool public swapEnabled;

    uint256 constant initialSupply = 100_000_000_000 * decimalVal;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    bool public allowTransfer;

    mapping(address => bool) public isFromWhiteList;
    mapping(address => bool) public isToWhiteList;
    mapping(address => bool) public noProcessList;
    address private canStopAntibotMeasures;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded, bool isFrom);

    event NoProcessList(address indexed account, bool noProcess);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

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

        // initialze varables
        gasForProcessing = 300000;
        rewardFee = 6;
        blackholeFee = 1;
        liquidityFee = 3;
        swapTokensAtAmount = 1000_000_000 * decimalVal;

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
        //setFeeWhiteList(_uniswapV2Pair, true, true);
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
        address _w1,
        address _w2,
        address _w3,
        address _w4,
        address _w0,
        address _w5,
        address _w6,
        address _w7) public onlyOwner {
        require(_w1 != address(0), "_w1 is not the zero address");
        require(_w2 != address(0), "_w2 is not the zero address");
        require(_w3 != address(0), "_w2 is not the zero address");
        require(_w4 != address(0), "_w4 is not the zero address");
        require(_w0 != address(0), "_w0 is not the zero address");
        require(_w5 != address(0), "_w5 is not the zero address");
        require(_w6 != address(0), "_w6 is not the zero address");
        require(_w7 != address(0), "_w7 is not the zero address");

        w1 = _w1;
        w2 = _w2;
        w3 = _w3;
        w4 = _w4;
        w0 = _w0;
        w5 = _w5;
        w6 = _w6;
        w7 = _w7;
        dividendTracker.excludeFromDividends(address(w1));
        dividendTracker.excludeFromDividends(address(w2));
        dividendTracker.excludeFromDividends(address(w3));
        dividendTracker.excludeFromDividends(address(w4));
        dividendTracker.excludeFromDividends(address(w0));
        dividendTracker.excludeFromDividends(address(w5));
        dividendTracker.excludeFromDividends(address(w6));
        dividendTracker.excludeFromDividends(address(w7));
    }

    receive() external payable {}

    function release() public onlyOwner {
        transfer(w1,(initialSupply.mul(15).div(100))); 
        transfer(w2,(initialSupply.mul(25).div(100))); 
        transfer(w3,(initialSupply.mul(15).div(100)));
        transfer(w4,(initialSupply.mul(2).div(100)));
        transfer(w0,(initialSupply.mul(3).div(100))); 
        transfer(w5,(initialSupply.mul(9).div(100)));
        transfer(w6,(initialSupply.mul(16).div(100)));
        transfer(w7,(initialSupply.mul(15).div(100)));
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
        require(rewardFee + blackholeFee + liquidityFee <= 10, "INVALID_FEE_RATIO");
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

    function setW0(address w) external onlyOwner{
        require(w != address(0), "w is not the zero address");
        w0 = payable(w);
    }

    function setW1Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w1 = w;
    }

    function setW2Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w2 = w;
    }

    function setW3Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w3 = w;
    }

    function setW4Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w4 = w;
    }

    function setW5Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w5 = w;
    }

    function setW6Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w6 = w;
    }

    function setW7Address(address w) public onlyOwner {
        require(w != address(0), "w is not the zero address");
        w7 = w;
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
        require (_checkFreezeAmount(from, amount), "Not enough available balance");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
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