```solidity
contract ABCD
```

### `executesupply()` 
`updateState -->`
 `validateSupply -->`
 `updateInterestRates -->`

### `liquidationCall`(address `collateralAsset`, address `debtAsset`, address `user`, uint256 `debtToCover`, bool `receiveAToken`) external
Allows liquidating an undercollateralized position when health factor < 1.

***Reads***

`_reserves`
`_reservesList`
`_usersConfig`
`_eModeCategories`


***Internal calls***
LiquidationLogic.`executeLiquidationCall`(...)


***Reverts on***
- Health factor not below threshold
- Reserve inactive/paused
- Price oracle sentinel check failed
- Collateral cannot be liquidated


**External calls**
`executeLiquidationCall` → `validateLiquidationCall` → `_calculateDebt` → `_burnDebtTokens` → `_liquidateATokens` 
OR 
`_burnCollateralATokens` → `updateState` → `updateInterestRates` → `safeTransferFrom` → `handleRepayment`




### `executeLiquidationCall` -  - Main liquidation entry point
asd


#### MATH
```solidity
// Example: User borrows 1000 USDC at 5% stable rate
// If user had 500 USDC debt at 4%, new rate = weighted average
newUserRate = (oldDebt * oldRate + newDebt * newRate) / totalDebt
newUserRate = (500 * 4% + 1000 * 5%) / 1500 = 4.67% 
```

#### `VARS`
vars.`healthFactor` - User's collateral health (must be < 1)
vars.`userVariableDebt` - User's current variable debt amount
vars.`userTotalDebt` - User's total debt (same as variable in V3)
vars.`actualDebtToLiquidate` - Final debt amount to repay
vars.`actualCollateralToLiquidate` - Collateral amount to seize
vars.`liquidationBonus` - Bonus percentage for liquidator
vars.`liquidationProtocolFeeAmount` - Fee for protocol treasury
vars.`collateralAToken` - aToken contract for collateral
vars.`debtReserveCache` - Cached debt reserve data

 
### `_calculateDebt` - Determine liquidatable debt amount
Calculate how much debt can be liquidated based on health factor and close factor rules
VARS USED:

`userVariableDebt` - User's current variable debt balance
`userTotalDebt` - Total debt (variable only in V3)
`closeFactor` - 50% if HF > 0.95, 100% if HF < 0.95
`maxLiquidatableDebt` - Maximum debt allowed to liquidate
`actualDebtToLiquidate` - Min of requested vs max allowed


### `_getConfigurationData` - Get price sources and liquidation config
Determine price oracles and liquidation bonus based on efficiency mode settings
VARS USED:

`collateralAToken` - aToken contract for collateral asset
`liquidationBonus` - Percentage bonus for liquidators
`collateralPriceSource` - Oracle address for collateral pricing
`debtPriceSource` - Oracle address for debt pricing
`eModePriceSource` - Custom oracle for efficiency mode

### `_calculateAvailableCollateralToLiquidate` - Calculate collateral amounts
Determine actual collateral to seize and protocol fees based on debt amount and prices
VARS USED:

`collateralPrice` - Current price of collateral asset
`debtPrice` - Current price of debt asset
`liquidationBonus` - Bonus percentage for liquidator
`baseCollateral` - Base collateral value before bonus
`bonusCollateral` - Additional collateral from liquidation bonus
`totalCollateralToLiquidate` - Final collateral amount to transfer

### `_liquidateATokens` - Transfer collateral to liquidator
Execute collateral transfer and handle aToken conversion if requested

VARS

`liquidatorPreviousATokenBalance` - Liquidator's aToken balance before
`actualCollateralToLiquidate` - Amount of collateral to transfer
`receiveAToken` - Whether liquidator wants aTokens or underlying

### `_burnDebtTokens` - Burn liquidated debt
Burn debt tokens that liquidator has repaid and update user's debt state
VARS USED:

`userVariableDebt` - User's current debt balance
`actualDebtToLiquidate` - Amount of debt being repaid
`scaledDebtToLiquidate` - Debt amount adjusted for interest index


### `calculateUserAccountData` - Calculate health factor
Calculate user's total collateral, debt, and health factor for liquidation eligibility
VARS USED:

`totalCollateralInBaseCurrency` - User's total collateral value
`totalDebtInBaseCurrency` - User's total debt value
`currentLiquidationThreshold` - Weighted liquidation threshold
`healthFactor` - Collateral / (Debt * Liquidation Threshold)

### `validateLiquidationCall` - Validate liquidation rules
Check if liquidation is allowed based on protocol rules and user state
VARS USED:

`healthFactor` - Must be < 1 for liquidation
`totalDebt` - User must have debt to liquidate
`debtReserveCache`.reserveConfiguration - Asset must allow liquidation
`priceOracleSentinel` - Oracle must be active

