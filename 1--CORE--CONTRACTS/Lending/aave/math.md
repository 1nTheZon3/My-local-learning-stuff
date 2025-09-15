`WAD` = 10¹⁸ → used for tokens
`RAY` = 10²⁷ → used for rates / indices

## Debt growth with index
`storedDebt` = 100 DAI
`userIndex` = 1.0
`globalIndex` = 1.2

   `Currentdebt` = `storeddebt` × (`currentindex` / `index-at-last-update`)
    `121` =        `100` *       (`1.21`      /        `1.0`) 
➡️ Your loan grew with interest.
**////////////////////////////////////////////////////////////////////////**
    👉 Used in:
`borrowBalanceStored`() (Compound)
`getUserCurrentDebt`() (Aave style)
➡️ Anytime protocol needs your latest debt.

## Utilization rate (U)
`cash` = 400
`borrows` = 600
`reserves` = 0

   U = `totalBorrows` / (`cash` + `totalBorrows` - `reserves`)
   U =    `600`       / (`400` +       `600`        -     `0`) = 0.6 (60%)
➡️ 60% of pool is borrowed.
**////////////////////////////////////////////////////////////////////////**
👉 Used in:
`getUtilizationRate`() (Compound)
inside `calculateInterestRates`() (Aave)
➡️ Input for interest rate models.

## Borrow rate (r_b)
`baseRate` = 2%
`slope1` = 20%
`kink` = 80%
`U` = 60%

   r_b = `baseRate` + `slopes` * `U`
   r_b =     `2%` +     `20%` * `0.6` = 14%
   ➡️ Borrowers pay 14% APR.
**////////////////////////////////////////////////////////////////////////**
👉 Used in:
`getBorrowRate`() (Compound)
`calculateInterestRates`() (Aave)
➡️ Determines how expensive borrowing is.

## Supply rate (r_s)
`r_b` = `14%`
`U` = `60%`
`reserveFactor` = `10%`

   `r_s` = `r_b` * `U` *   (`1` - `reserveFactor`)
   `r_s` = `14%` * `0.6` * (`1` -      `0.1`) = `7.56%`
   ➡️ Lenders earn ~7.6% APR.
**////////////////////////////////////////////////////////////////////////**
👉 Used in:
`getSupplyRate`() (Compound)
`calculateInterestRates`() (Aave)
➡️ What depositors earn.

## Collateral factor (CF)
`collateral` = `$1000`
`CF` = `75%`

   maxBorrow = `collateralValue` * CF
   maxBorrow =      `1000` *      `0.75` = $750
   ➡️ You can borrow up to $750.
**////////////////////////////////////////////////////////////////////////**
👉 Used in:
`getAccountLiquidity`() (Compound)
`calculateUserAccountData`() (Aave)
➡️ Borrow limit check.

## Health factor (HF)
`collateralValue` = $1000
`CF` = 75%
`borrowValue` = $600

   HF = (`collateralValue` * `CF`) / `borrowValue`
   HF = (     `1000` *     `0.75`) /       `600`  = `1.25`
   ➡️ Safe (HF > 1).
**////////////////////////////////////////////////////////////////////////**
👉 Used in:
`getAccountLiquidity`() (Compound style, as “shortfall”)
`calculateHealthFactor`() (Aave)
➡️ Liquidation trigger check.

## Liquidation incentive (bonus)
`debtToRepay` = $100
`bonus` = 10%

`collateralSeized` = `debtToRepay` * (1 + bonus)
`collateralSeized` =     `100` *     (`1` + `0.1`) = `$110`
➡️ Liquidator repays 100, receives 110 collateral.
**////////////////////////////////////////////////////////////////////////**
👉 Used in:
`liquidateBorrow`() (Compound)
`liquidationCall`() (Aave)
➡️ How much collateral liquidator gets.