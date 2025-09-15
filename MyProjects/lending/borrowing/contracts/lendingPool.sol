// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LendingPool
 * @dev Core lending protocol contract handling deposits, withdrawals, borrowing, and repayments
 * @notice This is a minimal implementation for educational purposes
 */
contract LendingPool is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    // Asset information
    struct AssetInfo {
        uint256 totalDeposits;      // Total amount deposited by all users
        uint256 totalBorrows;       // Total amount borrowed by all users
        uint256 liquidationRatio;   // Ratio below which liquidation can occur (e.g., 80%)
        uint256 borrowRatio;        // Maximum ratio users can borrow (e.g., 75%)
        bool isActive;              // Whether this asset is active for lending/borrowing
    }

    // User position information
    struct UserPosition {
        uint256 deposited;          // Amount user has deposited
        uint256 borrowed;           // Amount user has borrowed
        uint256 lastUpdateTime;     // Last time interest was calculated
    }

    // Asset token address => AssetInfo
    mapping(address => AssetInfo) public assetInfo;
    // User address => Asset token address => UserPosition
    mapping(address => mapping(address => UserPosition)) public userPositions;
    // Supported assets list
    address[] public supportedAssets;
    
    // Simple interest rate: 5% APR = 500 basis points
    uint256 public constant INTEREST_RATE_BASIS_POINTS = 500;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 * 24 * 60 * 60;

    // ============ Events ============

    event AssetAdded(address indexed asset, uint256 liquidationRatio, uint256 borrowRatio);
    event Deposited(address indexed user, address indexed asset, uint256 amount);
    event Withdrawn(address indexed user, address indexed asset, uint256 amount);
    event Borrowed(address indexed user, address indexed asset, uint256 amount);
    event Repaid(address indexed user, address indexed asset, uint256 amount);
    event Liquidated(address indexed liquidator, address indexed borrower, address indexed asset, uint256 amount);

    // ============ Modifiers ============

    modifier onlyActiveAsset(address asset) {
        require(assetInfo[asset].isActive, "Asset not active");
        _;
    }
    modifier updateInterest(address user, address asset) {
        _updateUserInterest(user, asset);
        _;
    }

    // ============ Constructor ============

    constructor() {
        // Initialize with owner
    }

    // ============ Admin Functions ============
    function addAsset(
        address asset,
        uint256 liquidationRatio,
        uint256 borrowRatio
     ) external onlyOwner {
        require(asset != address(0), "Invalid asset address");
        require(liquidationRatio > 0 && liquidationRatio <= BASIS_POINTS, "Invalid liquidation ratio");
        require(borrowRatio > 0 && borrowRatio < liquidationRatio, "Invalid borrow ratio");
        require(!assetInfo[asset].isActive, "Asset already added");

        assetInfo[asset] = AssetInfo({
            totalDeposits: 0,
            totalBorrows: 0,
            liquidationRatio: liquidationRatio,
            borrowRatio: borrowRatio,
            isActive: true
        });

        supportedAssets.push(asset);
        emit AssetAdded(asset, liquidationRatio, borrowRatio);
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ Core Functions ============


    function deposit(address asset, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyActiveAsset(asset) 
        updateInterest(msg.sender, asset)
     {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens from user to contract
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Update state
        assetInfo[asset].totalDeposits += amount;
        userPositions[msg.sender][asset].deposited += amount;
        userPositions[msg.sender][asset].lastUpdateTime = block.timestamp;

        emit Deposited(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyActiveAsset(asset) 
        updateInterest(msg.sender, asset)
     {
        require(amount > 0, "Amount must be greater than 0");
        require(userPositions[msg.sender][asset].deposited >= amount, "Insufficient deposit balance");

        // Check if withdrawal would make user undercollateralized
        require(_canWithdraw(msg.sender, asset, amount), "Withdrawal would make position undercollateralized");

        // Update state
        assetInfo[asset].totalDeposits -= amount;
        userPositions[msg.sender][asset].deposited -= amount;
        userPositions[msg.sender][asset].lastUpdateTime = block.timestamp;

        // Transfer tokens to user
        IERC20(asset).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, asset, amount);
    }

    function borrow(address asset, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyActiveAsset(asset) 
        updateInterest(msg.sender, asset)
     {
        require(amount > 0, "Amount must be greater than 0");
        require(assetInfo[asset].totalDeposits >= assetInfo[asset].totalBorrows + amount, "Insufficient liquidity");

        // Check if user can borrow this amount
        require(_canBorrow(msg.sender, asset, amount), "Insufficient collateral");

        // Update state
        assetInfo[asset].totalBorrows += amount;
        userPositions[msg.sender][asset].borrowed += amount;
        userPositions[msg.sender][asset].lastUpdateTime = block.timestamp;

        // Transfer tokens to user
        IERC20(asset).safeTransfer(msg.sender, amount);

        emit Borrowed(msg.sender, asset, amount);
    }

    function repay(address asset, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyActiveAsset(asset) 
        updateInterest(msg.sender, asset)
     {
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 userBorrowed = userPositions[msg.sender][asset].borrowed;
        require(userBorrowed > 0, "No debt to repay");

        // Calculate actual repayment amount (can't repay more than owed)
        uint256 repayAmount = amount > userBorrowed ? userBorrowed : amount;

        // Transfer tokens from user to contract
        IERC20(asset).safeTransferFrom(msg.sender, address(this), repayAmount);

        // Update state
        assetInfo[asset].totalBorrows -= repayAmount;
        userPositions[msg.sender][asset].borrowed -= repayAmount;
        userPositions[msg.sender][asset].lastUpdateTime = block.timestamp;

        emit Repaid(msg.sender, asset, repayAmount);
    }

    function liquidate(address borrower, address asset, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyActiveAsset(asset) 
        updateInterest(borrower, asset)
     {
        require(amount > 0, "Amount must be greater than 0");
        require(borrower != msg.sender, "Cannot liquidate yourself");
        
        // Check if position is liquidatable
        require(_canLiquidate(borrower, asset), "Position not liquidatable");

        uint256 userBorrowed = userPositions[borrower][asset].borrowed;
        require(userBorrowed > 0, "No debt to liquidate");

        // Calculate liquidation amount (can't liquidate more than borrowed)
        uint256 liquidationAmount = amount > userBorrowed ? userBorrowed : amount;

        // Transfer repayment from liquidator to contract
        IERC20(asset).safeTransferFrom(msg.sender, address(this), liquidationAmount);

        // Calculate collateral to seize (1:1 ratio for simplicity)
        uint256 collateralToSeize = liquidationAmount;
        require(userPositions[borrower][asset].deposited >= collateralToSeize, "Insufficient collateral");

        // Update borrower's position
        assetInfo[asset].totalBorrows -= liquidationAmount;
        userPositions[borrower][asset].borrowed -= liquidationAmount;
        userPositions[borrower][asset].deposited -= collateralToSeize;
        userPositions[borrower][asset].lastUpdateTime = block.timestamp;

        // Update total deposits
        assetInfo[asset].totalDeposits -= collateralToSeize;

        // Transfer collateral to liquidator
        IERC20(asset).safeTransfer(msg.sender, collateralToSeize);

        emit Liquidated(msg.sender, borrower, asset, liquidationAmount);
    }

    // ============ Internal Functions ============

    function _updateUserInterest(address user, address asset) internal {
        UserPosition storage position = userPositions[user][asset];
        
        if (position.lastUpdateTime == 0) {
            position.lastUpdateTime = block.timestamp;
            return;
        }

        uint256 timeDelta = block.timestamp - position.lastUpdateTime;
        if (timeDelta > 0 && position.borrowed > 0) {
            // Calculate simple interest: borrowed * rate * time / (BASIS_POINTS * SECONDS_PER_YEAR)
            uint256 interestAccrued = (position.borrowed * INTEREST_RATE_BASIS_POINTS * timeDelta) / 
                                    (BASIS_POINTS * SECONDS_PER_YEAR);
            
            position.borrowed += interestAccrued;
            assetInfo[asset].totalBorrows += interestAccrued;
        }

        position.lastUpdateTime = block.timestamp;
    }

    function _canWithdraw(address user, address asset, uint256 amount) internal view returns (bool) {
        UserPosition memory position = userPositions[user][asset];
        
        if (position.borrowed == 0) {
            return true; // No debt, can withdraw anything
        }

        uint256 remainingDeposit = position.deposited - amount;
        uint256 maxBorrow = (remainingDeposit * assetInfo[asset].borrowRatio) / BASIS_POINTS;
        
        return position.borrowed <= maxBorrow;
    }

    function _canBorrow(address user, address asset, uint256 amount) internal view returns (bool) {
        UserPosition memory position = userPositions[user][asset];
        
        uint256 maxBorrow = (position.deposited * assetInfo[asset].borrowRatio) / BASIS_POINTS;
        
        return position.borrowed + amount <= maxBorrow;
    }

    function _canLiquidate(address borrower, address asset) internal view returns (bool) {
        UserPosition memory position = userPositions[borrower][asset];
        
        if (position.borrowed == 0) {
            return false; // No debt to liquidate
        }

        uint256 maxBorrow = (position.deposited * assetInfo[asset].liquidationRatio) / BASIS_POINTS;
        
        return position.borrowed > maxBorrow;
    }

    // ============ View Functions ============

    function getUserPosition(address user, address asset) 
        external 
        view 
        returns (
            uint256 deposited,
            uint256 borrowed,
            bool canBorrow,
            bool canLiquidate
        ) 
     {
        UserPosition memory position = userPositions[user][asset];
        
        // Calculate current borrowed amount with interest
        uint256 currentBorrowed = position.borrowed;
        if (position.lastUpdateTime > 0 && position.borrowed > 0) {
            uint256 timeDelta = block.timestamp - position.lastUpdateTime;
            uint256 interestAccrued = (position.borrowed * INTEREST_RATE_BASIS_POINTS * timeDelta) / 
                                    (BASIS_POINTS * SECONDS_PER_YEAR);
            currentBorrowed += interestAccrued;
        }

        deposited = position.deposited;
        borrowed = currentBorrowed;
        canBorrow = _canBorrow(user, asset, 0);
        canLiquidate = _canLiquidate(user, asset);
    }
    function getAssetStats(address asset) 
        external 
        view 
        returns (
            uint256 totalDeposits,
            uint256 totalBorrows,
            uint256 utilizationRate
        ) 
     {
        AssetInfo memory info = assetInfo[asset];
        totalDeposits = info.totalDeposits;
        totalBorrows = info.totalBorrows;
        utilizationRate = totalDeposits > 0 ? (totalBorrows * BASIS_POINTS) / totalDeposits : 0;
    }
    function getSupportedAssets(
     ) external view returns (address[] memory) {

        return supportedAssets;
    }
}