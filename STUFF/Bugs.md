#

## `gas-check`
always perform the `gas check first`, and only `update/reserve` funds after it passes to avoid locking user assets.

## `proxy`

**For new protocols**: Make sure the `pause` function `blocks` every `new operation`, `not` just the `old` ones.

## `safeTransferFrom` 
```solidity
// safeTransferFrom requires the sender (address(this)) to have approved the admin — but the contract itself can’t approve anyone.
// So the call always reverts → admin can’t withdraw fees.
    function transferFee() external onlyRole(DEFAULT_ADMIN_ROLE) {
        ...
        token.safeTransferFrom(address(this), msg.sender, feeToTransfer); // @audit should use safeTransfer
        ...
    }
```

## `fees`
**1**
- Fee checks ignore extra required fees, letting transactions fail and lock user funds.
only checks `msg_value < enough_fee` but ignores the additional TON needed to complete the transaction, allowing partial execution to fail and lock user funds. 

**2**
The origination fee is applied after checking collateralization, which can create undercollateralized borrow positions immediately after borrowing.

```solidity

// In the VisibilityCredits contract, the PARTNER_FEE and PARTNER_REFERRER_BONUS are incorrectly set to 250 ppm, which represents 0.025%. However, as per the comment in the contract, these values should be set to 0.25%. This misconfiguration will result in the partner and referrer receiving a less bonus from the total cost of the bought credits than intended.

uint16 public constant PARTNER_FEE = 250; 
// 0.25% bonus for the partner/marketing agency 
// if linked to a referrer (deduced from protocol fee)
uint16 public constant PARTNER_REFERRER_BONUS = 250; 
// 0.25% bonus for the referrer 
// if linked to a partner (deduced from protocol fee)

// Recommendations
// Update the values of PARTNER_FEE and PARTNER_REFERRER_BONUS to 2500 ppm (0.25%) to match the intended values.
```


## `accounting`

- Concurrent supply transactions can bypass the maximum token supply check if pending supplies aren’t accounted for, allowing the total supply to exceed the intended cap.”

## `deposit()`

## `borrow()`

## `withdraw()`

## `redeem()`

### when-having-redeemCap [per-day] [broken]
Instead of resetting at a fixed time, `you always look back exactly 24h from now.`
`Total redeemed in the last 24h must be ≤ cap`

### missing slippage protection 
```solidity
///It's recommended to add a _minExpectedAmount parameter to the redeem function.
   function redeem(
        uint256 _amount,
        address _receiver,
        address _withdrawalTokenAddress
    ) public whenNotPaused onlyAllowedProviders {
        IERC20(ISSUE_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), _amount);
        usrRedemptionExtension.redeem(_amount, _receiver, _withdrawalTokenAddress);
​
        emit Redeemed(msg.sender, _receiver, _amount, _withdrawalTokenAddress);
    }
```

## `repay()`

## `liquidate()`

# `claimrewards()`

## [H-01] `claimReward()` can DOS by iterating predictions blocking funds

Impact: High (funds can become permanently locked due to gas exhaustion).
Likelihood: Medium (spamming is realistic because fee is small and fixed).

**Issue**
- `predictions`-ARRAY-UNBOUNDED
- USR-CAN-SPAM-1000-PREDICTIONS-PER-ROUND [FEE-5(USDC)]
- `claimReward()`-LOOP-OVER-FULL-ARRAY [EXCEEDS-BLOCK-GAS-LIMIT] [DoS-REWARD-CLAIMING->FUNDS-STUCK]

**`Attack Scenario`**
- ATTACKER-`predict`-10,000(USDC)
- INSTED-OF-ONE-TX // 2,000-`predict`-5USDC-EACH
- `claimReward()`-LOOP-OVER-FULL-ARRAY→GAS-TOO-HIGH→N0-ONE-CAN-CLAIM.

**`Recommendation`**
SET-`MAX-PREDICTION`-PER-ROUND-PER-USER
///////////////////////////////////////
Alternatively, replace the unbounded array with mappings:
Track total bullish/bearish stakes.
Track per-user amount directly.
This removes the need to loop over all predictions.
### `predict` 
```solidity
function predict(uint256 marketId, bool isBullish) external roundActive(marketId) {
        uint256 roundId = currentRoundId[marketId];
        Round memory round = marketRounds[marketId][roundId];
​
        // Predictions close 1 hour before round ends to prevent last-minute manipulation
        require(block.timestamp < round.startTime + 23 hours, "Prediction closed (last hour)");
​
        // Transfer 5 USDC fee from user to contract
        require(IERC20(markets[marketId].token).transferFrom(
            msg.sender,
            address(this),
            PREDICTION_FEE
        ), "Payment failed");
​
        // Store the prediction
        predictions[marketId][roundId].push(Prediction({
            user: msg.sender,
            isBullish: isBullish,
            amount: PREDICTION_FEE 
        }));
        emit PredictionMade(marketId, roundId, msg.sender, isBullish, PREDICTION_FEE);
    }
 ```
 WHEN CLAIMREWARDS IS CALLED ENTIRE PREDICTION ARRAY IS CHECKED
### `claimrewards()`
```solidity
function claimReward(uint256 marketId, uint256 roundId) external {
        
        Round memory round = marketRounds[marketId][roundId];
        require(round.ended, "Round not ended");
        require(!hasClaimed[marketId][roundId][msg.sender], "Already claimed");
​
        Prediction[] memory preds = predictions[marketId][roundId];
        
        // Determine winning direction (bullish if end price > start price)
        bool isBullWinning = round.endPrice > round.startPrice;
​
        // Calculate reward pool (total - 5% fee)
        uint256 totalPool = preds.length * PREDICTION_FEE; 
        uint256 fee = (totalPool * 5) / 100;
        uint256 rewardPool = totalPool - fee;
​
        // Calculate user's share of winning predictions
        uint256 totalWinningAmount = 0;
        uint256 userWinningAmount = 0;
​
        for (uint256 i = 0; i < preds.length; i++) {
            if (preds[i].isBullish == isBullWinning) {
                totalWinningAmount += preds[i].amount;
                if (preds[i].user == msg.sender) {
                    userWinningAmount += preds[i].amount;
                }
            } }
   
```

## `reservefactor`
`reservefactor` = % INTEREST-FOR-PROTOCOL NOT-LENDERS
- ADMIN-CAN-CHANGE-ANYTIME-VIA-`setCod3xReserveFactor().`
- INTEREST-RATES-NOT-UPDATED-IMMEDIATELY-AFTER-CHANGE
So:
Liquidity rate (what lenders earn) USES-OLD-`reservefactor`(stored in `currentLiquidityRate`).
But when `_mintToTreasury()` runs later, it takes the new reserve factor.
This mismatch means the treasury can take more than expected, leaving less for lenders.
→ `potential insolvency toward lenders.`

**`FIX`**
- When reserve factor changes → force a pool update first:
`pool.updateState();`

### `Example`
- Suppose utilization rate and borrow rate mean lenders should get 8% APY, treasury 2%.
- Admin changes reserve factor so treasury should now get 5%.
- But until updateState() is triggered, lenders still accrue as if they get 8%.
- Later, when debt indexes are updated, treasury suddenly mints more interest → lenders actually over-accrued → system imbalance.

### code
```solidity

// BasePiReserveRateStrategy.sol#L291-L299
function getLiquidityRate(
  uint256 currentVariableBorrowRate,
  uint256 utilizationRate,
  uint256 reserveFactor
) internal pure returns (uint256) {
  return currentVariableBorrowRate.rayMul(utilizationRate).percentMul(
    PercentageMath.PERCENTAGE_FACTOR - reserveFactor // <<<
  );
}

// It can be changed directly by the admin by calling setCod3xReserveFactor:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// LendingPoolConfigurator.sol#L443-L455
function setCod3xReserveFactor(address asset, bool reserveType, uint256 reserveFactor)
  external
  onlyPoolAdmin
{
  DataTypes.ReserveConfigurationMap memory currentConfig =
  pool.getConfiguration(asset, reserveType);
  currentConfig.setCod3xReserveFactor(reserveFactor);
  pool.setConfiguration(asset, reserveType, currentConfig.data);
  emit ReserveFactorChanged(asset, reserveType, reserveFactor);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// However, since calling this function does not update interest rates, this could lead to insolvency towards lenders in the case where the reserve factor is increased. Indeed, during the next accrual, the current liquidity rate will be applied to the liquidity index, and at the same time, the new reserve factor will be taken out of accrued borrow interest:

// ReserveLogic.sol#L284-L304
function _updateIndexes(
  DataTypes.ReserveData storage reserve,
  uint256 scaledVariableDebt,
  uint256 liquidityIndex,
  uint256 variableBorrowIndex,
  uint40 timestamp
) internal returns (uint256, uint256) {
  uint256 currentLiquidityRate = reserve.currentLiquidityRate;
  uint256 newLiquidityIndex = liquidityIndex;
  uint256 newVariableBorrowIndex = variableBorrowIndex;
​
  // Only cumulating if there is any income being produced.
  if (currentLiquidityRate != 0) {
    uint256 cumulatedLiquidityInterest =
      MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
    newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);
    require(newLiquidityIndex <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);
    reserve.liquidityIndex = uint128(newLiquidityIndex);
  }
  // ...
}
// MiniPoolReserveLogic.sol#L251-L269
function _mintToTreasury(
  DataTypes.MiniPoolReserveData storage reserve,
  uint256 scaledVariableDebt,
  uint256 previousVariableBorrowIndex,
  uint256 newLiquidityIndex,
  uint256 newVariableBorrowIndex,
  uint40
) internal {
  MintToTreasuryLocalVars memory vars;
  vars.cod3xReserveFactor = reserve.configuration.getCod3xReserveFactor(); // <<<
  vars.minipoolOwnerReserveFactor = reserve.configuration.getMinipoolOwnerReserveFactor();
  if (vars.cod3xReserveFactor == 0 && vars.minipoolOwnerReserveFactor == 0) {
    return;
  }
  // Calculate the last principal variable debt.
  vars.previousVariableDebt = scaledVariableDebt.rayMul(previousVariableBorrowIndex);
  // ...
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Recommendation
// The pool should be touched when updating reserve factors (Cod3x and MinipoolOwner):

// LendingPoolConfigurator.sol#L443-L455
function setCod3xReserveFactor(address asset, bool reserveType, uint256 reserveFactor)
  external
  onlyPoolAdmin
{
  //@audit please note that this function needs to be implemented, because there is no endpoint
  // which can be called with zero amount, !
  pool.updateState();
​
  DataTypes.ReserveConfigurationMap memory currentConfig =
    pool.getConfiguration(asset, reserveType);
  currentConfig.setCod3xReserveFactor(reserveFactor);
  pool.setConfiguration(asset, reserveType, currentConfig.data);
  emit ReserveFactorChanged(asset, reserveType, reserveFactor);
}

```

# `USG-TANGET`

##