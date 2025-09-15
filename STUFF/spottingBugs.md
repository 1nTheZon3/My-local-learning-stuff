🔁 Reentrancy	Has clear keywords (call, transfer, external), signs, and mitigation patterns
📤 Access Control	Easy to map with onlyOwner, admin, governance, and dangerous setters
🧾 Unchecked External Calls	Flags like call(), delegatecall, send, etc. — needs clear permission or checks
🥩 Slippage / Invariant Violations	Common in AMMs and swaps — track reserves, price impact, balance changes
🧠 Storage Collisions (Proxy)	Detectable by layout mismatch, delegatecall, storage slot confusion
🔐 Logic Flaws / Trust Assumptions	Seen in vaults, reward splitters — often traceable by naming and flow
🧨 Improper Initialization	initialize() missing checks, can be attacked if rerun
🗳 Governance Abuse	Dangerous if propose(), execute(), setParam() are loosely protected
🪞 Vault Accounting Drift	Includes pricePerShare, totalAssets, debtIndex — often manipulatable
🛠 Unsafe Upgrades / Init	Related to UUPS proxies, unprotected upgrades, storage layout

# Ask for every function borrow/deposit/flashloan/ and for other protocols DEXS swap etc for markdown file
Quick audit tips:
Validation must ensure liquidation conditions are met to prevent wrongful liquidations.

Liquidation bonus rewards liquidators — watch this value carefully for possible abuse.

Oracle prices are critical — manipulation here can break liquidation fairness.


# `🔎 ORACLE MANIPULATION ``///////////////////////////////////////////////////////////////////////////////////////////////////`


### ✅ What It Means
> Attacker `feeds` fake price to the protocol  
> → `inflates` or deflates asset value  
> → drains money or avoids liquidation  

---
## 🚩 Oracle Keywords Cheat Sheet (for grep / ctrl+F)

| **🔑 Keyword**               | **🧠 What It Indicates**                                         |
|-----------------------------|--------------------------------------------------------------------|
| `getAssetPrice`             | 📡 Pulls price from oracle — **check source & trust**              |
| `latestAnswer`              | 🧾 Chainlink price fetch — **spot value, instant read**            |
| `latestRoundData`           | ⌛ Chainlink + **timestamp info** — check for **stale prices**     |
| `pricePerShare`             | 🪞 Vault-based pricing — **can be manipulated**                    |
| `getPrice`                  | 📊 General price fetch — **check logic, math, and exposure**       |
| `oracle`                    | 🔌 Address/interface — **trace what it's pointing to**             |
| `twap`                      | ⏳ TWAP logic — **check for flashloan risks**                      |
| `update`, `setOracle`       | 🛠 Admin actions — **verify access control**                        |
| `consult`                   | 🧮 Uniswap TWAP call — **vulnerable to flashloan spikes**          |
| `scale`, `decimals`         | ⚖️ Scaling math — **check for unit mismatch bugs**                 |
| `precision`                 | 🎯 Custom scaler — **must match token decimals properly**          |                         

 
## 🚩 Bug Signs Cheat Sheet

| **🔍 Sign**                | **🚨 What It Means**                                   |
|---------------------------|--------------------------------------------------------|
| `latestAnswer()`          | 🧾 Chainlink **spot price used directly**              |
| `pricePerShare`           | 🪞 **Vault/Liquidity manipulation possible**           |
| `setOracle()`             | 🛑 **Access control risk** — check `onlyOwner`, etc.    |
| `twap.update()`           | ⚡️ Flashloan might **affect TWAP**                     |
| `decimals()`              | ⚖️ Scaling error — wrong units (e.g. `1e6` vs `1e18`)   |

---

| **Variable**                        | **Type**                   | **Purpose**                             |
|------------------------------------|----------------------------|-----------------------------------------|
| `ContractName.oracle`              | `address`                  | **price feed contract used**            |
| `ContractName.priceFeed`           | `AggregatorV3Interface`    | **Chainlink feed**                      |
| `ContractName.pricePerShare`       | `uint256`                  | **current token share price**           |
| `ContractName.oracleDecimals`      | `uint8`                    | **precision for scaling**               |
---
## 🔎 Oracle Targets – Where to Look

| **🔍 Location / Pattern**         | **🧠 Why It Matters**                                           |
|----------------------------------|----------------------------------------------------------------|
| `setOracle`, `setPriceFeed`      | 🛑 Might allow price override — **check access control**        |
| `/oracle/` folder                | 📦 Look for **custom oracle logic**                            |
| `pricePerShare`, `getPrice`      | 🧮 Internal price logic — **often manipulable**                |
| Tests with: `oracle`, `price`    | 🔬 Look for how **oracle is used/tested**                      |
| Tests with: `manipulate`         | 🧪 Might **simulate attack or price injection**                |
| Tests with: `flashloan`          | ⚡️ Can reveal **TWAP or vault manipulation**  

## 🧠 Oracle Logic Red Flags

| **🔑 Keyword / Pattern**         | **🚨 Suggestion / What to Check**                                  |
|----------------------------------|---------------------------------------------------------------------|
| `setOracle`, `updatePrice`       | 🛑 Can *anyone* call it? Check for `onlyOwner`, `onlyAdmin`, etc.   |
| `twap.update()`, `consult`       | ⚠️ Can **flashloans skew TWAP**? Check timing and sync logic        |
| `pricePerShare`                  | 🪞 Vault price based on assets? **Manipulatable via flash loan**    |
| `latestAnswer()`                 | ⌛ Is price **stale or manipulated**? Check how recent the round is |
| `oracleDecimals`                 | 🧮 Are scaling units handled safely? Look for **unit mismatches**   |
| `getReserves()`                  | 🧊 Uses **live LP reserves**? Prone to **flash loan abuse**         |
| `AggregatorV3Interface`          | 🔌 Chainlink used? Confirm it’s the **real feed**, not a mock       |
| `setPriceFeed()`                 | 🛠️ Can devs **swap feeds post-deploy**? Must be **restricted**      |
| `MockV3Aggregator`               | 🎭 Used **in prod**? Big 🚨 — **mocks should be test-only**         |
| `customOracle`, `oracleLib`      | 🔍 Custom logic? **Audit it deeply** — might lack protections       |
---



---
## 📁 Bonus Lookups — Where to Search for Oracle Code & Clues

| **What**                     | **Examples / Suggestions**                                                  |
|------------------------------|-----------------------------------------------------------------------------|
| 🔍 **Folders to Search**     | `/oracle/`, `/mock/`, `/utils/price/`, `/test/oracle/`, `/feeds/`, `/libs/` |
| 💬 **Comment Clues**         | `// update price`, `// fetch oracle`, `// get TWAP`, `// sync reserves`, `// scale price` |
| 🛠 **Slither Tool**          | `slither . --detect-incorrect-units` → flags wrong scaling/decimals        |
| 🛠 **Foundry cast**          | `cast call <contract> "latestAnswer()"` → check live price from oracle      |
| 🛠 **Foundry decode**        | `cast calldata "setOracle(address)"` → simulate unauthorized calls          |
| 🧪 **Test grep keywords**    | `grep -Ri oracle test/`, `grep manipulate`, `grep -Ri pricePerShare`        |
| 📎 **Docs / Comments**       | Look for “price source”, “oracle config”, “TWAP period”, “mock feed”        |
| 📄 **Config files**          | `hardhat.config.js`, `deploy/oracle.js`, `.env` for feed addresses         |

### 🐛 Bug Pattern: Fake Price Feed
> LP token price can be `flash pumped`  
> `→` `borrow more` than real `value`  
> `→` withdraw and leave protocol `undercollateralized`  

`Example`:

function getPrice() external view returns (uint256) {
    return IUniswapV2Pair(lp).getReserves();  // 🐛 TWAP not used
}



  ## ✅ Audit Moves

- [ ] Grep for keywords like `getPrice`, `latestAnswer`, `setOracle`
- [ ] Check access control on `setOracle`, `updatePrice`
- [ ] Test if price can be manipulated via flash loan or LP sync
- [ ] Verify all scaling logic: `decimals()`, `1e18`, `scaleFactor`
- [ ] See if LP tokens or vaults can be inflated via `pricePerShare`

 

 

# 🧮 `INCORRECT MATH/ROUNDING` `/////////////////////////////////////////////////////////////////////////////////////////////////`


### ✅ What It Means
> Protocol assumes correct math or scaling  
> → but rounding, overflow, or unit mismatch  
> → leads to loss, inflation, or unfair behavior

---

##  
## 🚩 Math Keywords Cheat Sheet (for grep / ctrl+F)

| **🔑 Keyword**               | **🧠 What It Indicates**                                             |
|-----------------------------|----------------------------------------------------------------------|
| `decimals`                  | ⚖️ Unit scaling — check all token and oracle math                    |
| `precision`                 | 🎯 Custom scaler — must match `decimals()` properly                  |
| `mulDiv`, `mulWad`, `divWad`| 🔬 Fixed-point helpers — check rounding direction                    |
| `percentMul`, `rayDiv`      | 🧮 Aave-style math helpers — need precision awareness                |
| `1e18`, `10**`, `WAD`, `RAY`| 🧯 Hardcoded scalers — check that they match asset units             |
| `rounding`, `SafeCast`      | 🛟 Rounding mode or type conversion — possible silent bugs           |
| `scaledBalance`             | 📉 Scaled balances — track index multipliers carefully                |
| `toInt256`, `toUint128`     | 💥 Truncation or overflow risks — check ranges                       |
| `unchecked {}`              | 🚫 Overflow disabled — verify bounds manually                        |

---

## 🚩 Bug Signs Cheat Sheet

| **🔍 Sign**                | **🚨 What It Means**                                                |
|---------------------------|---------------------------------------------------------------------|
| Hardcoded `1e18`, `1e6`   | ⚖️ Unit mismatch likely — especially in ERC20 math                  |
| `div()` before `mul()`    | 🧨 Order matters — rounding down early causes precision loss        |
| Custom `precision` var    | 🎯 Make sure it's used consistently across all math                 |
| `scaled + index` mismatch | 📉 Indexed balance drift — often seen in lending protocols          |
| Silent `toUintXX()` cast  | 💥 Might truncate unexpectedly — check max values                   |
| `totalSupply * price`     | 🧾 Vault calc — wrong order or units leads to over/under valuation   |

---

| **Variable**                        | **Type**               | **Purpose**                                      |
|------------------------------------|------------------------|--------------------------------------------------|
| `ContractName.decimals`            | `uint8`                | ⚖️ Native token precision                         |
| `ContractName.precision`           | `uint256`              | 🎯 Custom math scaler (e.g., 1e18 or 1e27)        |
| `ContractName.pricePerShare`       | `uint256`              | 🪞 Price of each share — prone to rounding        |
| `ContractName.index`               | `uint256`              | 📈 Interest or yield index (used for scaling)     |
| `ContractName.scaledBalanceOf`     | `mapping`              | 📉 Indexed balances — multiply by index later     |
| `ContractName.ratio`               | `uint256`              | 📊 Exchange rate, often precision-sensitive       |

---

## 🔎 Math Targets – Where to Look

| **🔍 Location / Pattern**         | **🧠 Why It Matters**                                                  |
|----------------------------------|------------------------------------------------------------------------|
| `div(mul())` vs `mul(div())`     | 🧨 Check order of operations — rounding happens fast                    |
| `pricePerShare`, `getPrice()`    | 💸 Vault/asset math — needs consistent scaling                         |
| Lending `index` logic            | 📈 Used to scale debt/supply — errors lead to value drift               |
| Token `decimals()` reads         | ⚖️ Mixing 6/8/18 decimals? Look for bad conversions                     |
| External price feeds             | 🧾 If `1e8`, but internal math expects `1e18`, math is wrong            |
| `_calculateAmount`, `_scale()`   | 🧮 Check custom math helper functions                                   |

---

## 🧠 Math Logic Red Flags

| **🔑 Keyword / Pattern**         | **🚨 Suggestion / What to Check**                                  |
|----------------------------------|---------------------------------------------------------------------|
| `price * totalSupply`           | 📏 Are both values scaled to the same unit?                         |
| `div()` early in formula        | 🔻 Check for underflow or premature rounding                        |
| `toUint128()`, `toInt256()`     | 💥 Make sure values fit target size                                 |
| `unchecked {}`                  | 🚫 No overflow protection — verify limits manually                  |
| `scaledBalance`, `index`        | 🧮 Confirm math matches between store/load                          |
| `updateIndex()`                 | ⚠️ Wrong update order can inflate or deflate balances               |
| `decimals = token.decimals()`   | ⚖️ Is this stored and used consistently in math?                    |
| `customPrecision`               | 🎯 Check consistency with tokens/oracles                            |

---

## 📁 Bonus Lookups — Where to Search for Math Bugs

| **What**                     | **Examples / Suggestions**                                                  |
|------------------------------|-----------------------------------------------------------------------------|
| 🔍 **Folders to Search**     | `/math/`, `/libs/`, `/utils/`, `/vaults/`, `/tokens/`                      |
| 💬 **Comment Clues**         | `// scale amount`, `// convert units`, `// apply index`, `// precision loss` |
| 🛠 **Slither Tool**          | `slither . --detect-incorrect-units` → finds mismatched math                |
| 🛠 **Foundry**               | Use `cast call` to simulate and observe `pricePerShare`, `getScaledBalance()` |
| 🧪 **Test grep keywords**    | `grep -Ri decimals`, `grep -Ri precision`, `grep scale`, `grep index`       |
| 📎 **Docs / Comments**       | Look for “precision”, “WAD/RAY”, “math lib”, “rounding mode”                |
| 📄 **Common Libraries**      | `WadRayMath`, `SafeCast`, `FixedPointMathLib`, `SafeMath`  

# `⚖️ DECIMAL / PRECISION BUGS` `///////////////////////////////////////////////////////////////////////////////////////////////`

### ✅ What It Means
> Tokens and feeds use different decimals  
> → math is mismatched (e.g. 6 vs 18 decimals)  
> → leads to wrong prices, rounding errors, or loss of funds

---

##  
## 🚩 Decimal Keywords Cheat Sheet (for grep / ctrl+F)

| **🔑 Keyword**                | **🧠 What It Indicates**                                                  |
|------------------------------|---------------------------------------------------------------------------|
| `decimals()`                 | ⚖️ Token or oracle precision — must be handled correctly                  |
| `10**`, `1e6`, `1e18`        | 💥 Hardcoded scalers — check if they match token decimals                 |
| `scale`, `unscale`, `convertDecimals` | 🔁 Unit adjustment — often source of bugs                            |
| `precision`, `BASE_UNIT`     | 🎯 Custom scaler — make sure it’s used consistently                      |
| `mulWad`, `divWad`           | 🧮 Wad (1e18) math helpers — may break with 6-decimal tokens              |
| `SafeCast`, `toUint128()`    | 🧯 Downcasting — might hide silent rounding errors                        |
| `AggregatorV3Interface`      | 📡 Chainlink feeds — often return 8 decimals (not 18!)                    |
| `amount / 1e18`, `amount * 1e6`| ⚠️ Scaling math — mismatch if asset uses different precision            |

---

## 🚩 Bug Signs Cheat Sheet

| **🔍 Sign**                      | **🚨 What It Means**                                                  |
|----------------------------------|----------------------------------------------------------------------|
| Using `1e18` for 6-dec token     | ⚖️ Overestimating amount by 1 million fold                           |
| Comparing two values with diff scale | 🎭 False equality or inequality — could allow bypasses          |
| Mixing `decimals()` with hardcoded scaler | ❌ Math breaks if token changes decimals                       |
| `SafeCast` after decimal math    | 🧯 May silently drop non-zero values (lossy cast)                    |
| Oracle + Token math without scale | 📡 Feed might be 1e8, token is 1e18 — leads to wrong pricing        |

---

| **Variable**                         | **Type**               | **Purpose**                                                   |
|-------------------------------------|------------------------|---------------------------------------------------------------|
| `ContractName.tokenDecimals`        | `uint8`                | ⚖️ Underlying token precision                                 |
| `ContractName.oracleDecimals`       | `uint8`                | 📡 Price feed precision (e.g. 8)                              |
| `ContractName.precision`            | `uint256`              | 🎯 Custom base unit (e.g. `1e18`)                             |
| `ContractName.amountScaled`         | `uint256`              | 🔁 Scaled up/down token value                                 |
| `ContractName.BASE_UNIT`           | `uint256`              | 🧮 Reference unit for math (e.g., `10 ** tokenDecimals`)       |
| `ContractName.WAD`, `RAY`           | `uint256`              | 🧪 Aave-style fixed-point scalers (WAD = 1e18, RAY = 1e27)    |

---

## 🔎 Decimal Targets – Where to Look

| **🔍 Location / Pattern**           | **🧠 Why It Matters**                                                  |
|------------------------------------|------------------------------------------------------------------------|
| `decimals()` usage                 | ⚠️ Mixing different sources? Normalize values before math              |
| Oracle price × token amount        | 🧾 Need to scale either price or amount to match                       |
| `pricePerShare` with `1e18`        | 🪞 Vaults often assume 18 decimals — might be wrong for 6-dec tokens   |
| `amount / BASE_UNIT`              | ⚖️ Division might cause rounding or truncation                         |
| Aave-style helpers (`mulWad`)     | 🧮 Assumes WAD (1e18) — doesn’t work with USDC (6 decimals)            |
| Token mint/burn with scaler       | 🎯 Confirm token units match internal calculations                     |

---

## 🧠 Decimal Logic Red Flags

| **🔑 Keyword / Pattern**           | **🚨 Suggestion / What to Check**                                    |
|------------------------------------|----------------------------------------------------------------------|
| Hardcoded `1e18`                   | ❌ Dangerous unless all tokens/oracles are 18 decimals                |
| Oracle returns 8-dec value         | 📉 Needs upscaling to match token math                               |
| `precision` defined but unused     | 🎯 Declared intent, but no actual scaling in logic                   |
| Downcasting after math             | 🧯 Rounding may zero out small values                                |
| Missing `decimals()` normalization| ⚠️ Math might silently over/underflow due to unit mismatch           |

---

## 📁 Bonus Lookups — Where to Search for Decimal Bugs

| **What**                     | **Examples / Suggestions**                                                    |
|------------------------------|-------------------------------------------------------------------------------|
| 🔍 **Folders to Search**     | `/math/`, `/vaults/`, `/tokens/`, `/price/`, `/oracle/`, `/utils/`           |
| 💬 **Comment Clues**         | `// scale to 1e18`, `// normalize units`, `// convert decimals`, `// price math` |
| 🛠 **Slither Tool**          | `slither . --detect-incorrect-units` → detects decimal mismatches             |
| 🛠 **Foundry cast**          | Use `cast call <token> "decimals()"` or price feed to compare assumptions     |
| 🧪 **Test grep keywords**    | `grep -Ri decimals`, `grep -Ri 1e18`, `grep BASE_UNIT`, `grep -Ri precision`  |
| 📎 **Docs / Comments**       | Look for “all math uses 18 decimals”, “fixed-point scaling”, “token precision”|
| 📄 **Attack Examples**       | YAM (rebase + 1e18 math bug), Cover protocol (price mis-scaling)              |

# 💸 `LIQUIDATION MANIPULATION` `///////////////////////////////////////////////////////////////////////////////////////////`


### ✅ What It Means
> Attacker tricks protocol into thinking position is unsafe or safe  
> → forces unfair liquidation or avoids it  
> → drains collateral, steals discount, or avoids bad debt

---

##  
## 🚩 Liquidation Keywords Cheat Sheet (for grep / ctrl+F)

| **🔑 Keyword**                  | **🧠 What It Indicates**                                                  |
|--------------------------------|---------------------------------------------------------------------------|
| `healthFactor`, `hf`           | ❤️ Safety check — attacker can manipulate inputs                         |
| `liquidationThreshold`         | ⚠️ Threshold for when liquidation happens — track asset-specific values  |
| `liquidate`, `performLiquidation` | 🔨 Core liquidation logic — must validate all preconditions             |
| `getUserAccountData`           | 📊 Summary of collateral vs debt — key to liquidation logic              |
| `getAssetPrice`, `oracle`      | 🧾 Price fetch — **prime target for manipulation**                        |
| `discount`, `liquidationBonus` | 💰 Determines how much collateral is given to liquidator                 |
| `collateralBalance`, `debtBalance` | 🏦 Core state variables — check how they’re computed                   |
| `getLoanToValue`               | 📉 Can be manipulated via price/valuation tricks                         |
| `isLiquidatable`               | 🚨 Boolean check — might be bypassed or spoofed                          |

---

## 🚩 Bug Signs Cheat Sheet

| **🔍 Sign**                        | **🚨 What It Means**                                                    |
|-----------------------------------|-------------------------------------------------------------------------|
| `healthFactor` uses manipulable price | 💉 Oracle attack can trigger fake liquidation                          |
| `discount` applied without slippage | 🧨 Liquidator can extract more than they should                         |
| Vault-style `pricePerShare` used in HF | 🪞 Manipulatable price logic affects healthFactor                       |
| No check for close factor / max repay | 💰 Liquidator may repay full debt and take full collateral              |
| Underflow in collateral/debt accounting | 🧯 Might allow debt-free liquidation or overclaim                       |

---

| **Variable**                              | **Type**               | **Purpose**                                               |
|------------------------------------------|------------------------|-----------------------------------------------------------|
| `ContractName.healthFactor`              | `uint256`              | ❤️ User safety metric (collateral vs debt)                |
| `ContractName.liquidationThreshold`      | `uint256`              | ⚠️ Threshold below which liquidation becomes possible      |
| `ContractName.liquidationBonus`          | `uint256`              | 💰 Reward % for liquidator (discount on collateral)        |
| `ContractName.collateralBalance`         | `uint256`              | 🏦 Amount of collateral the user holds                     |
| `ContractName.debtBalance`               | `uint256`              | 💸 How much the user owes                                 |
| `ContractName.oracle`                    | `address`              | 📡 Where prices are fetched from — manipulatable           |
| `ContractName.closeFactor`               | `uint256`              | 🧾 Max % of debt liquidatable in one call                  |

---

## 🔎 Liquidation Targets – Where to Look

| **🔍 Location / Pattern**             | **🧠 Why It Matters**                                                |
|--------------------------------------|---------------------------------------------------------------------|
| `liquidate()`                        | 🔨 Core liquidation logic — check every conditional and math        |
| `healthFactor < 1e18`                | 🧮 Unsafe position trigger — depends on accurate price data         |
| `oracle.getAssetPrice()`             | 🧾 Price manipulation changes liquidation eligibility               |
| `discount`, `bonus` applied          | 💰 Might allow value extraction if applied before safety checks     |
| `repayDebt`, `seizeCollateral`       | 🏦 Actions during liquidation — watch for accounting drift          |
| `getUserAccountData()`               | 📊 May use flawed or manipulatable calculations                     |

---

## 🧠 Liquidation Logic Red Flags

| **🔑 Keyword / Pattern**           | **🚨 Suggestion / What to Check**                                    |
|------------------------------------|----------------------------------------------------------------------|
| `healthFactor` uses `pricePerShare` | 🪞 Vault value can be flashloaned → fake insolvency or solvency     |
| Oracle not TWAP protected          | ⚡ Can be flashloaned for single-block manipulation                  |
| No time buffer between updates     | ⌛ Allows attacker to manipulate and liquidate in same tx            |
| Liquidator receives too much       | 💸 Discount or fee may be miscalculated → overpayment                |
| User not undercollateralized       | ❌ Liquidation might still succeed due to logic flaw                 |
| Close factor not enforced          | 🚪 Liquidator might repay 100% debt instead of capped amount        |
| `SafeCast`, `uint128`, `toUint()`  | 💥 Type conversion bugs — rounding can affect liquidation math      |

---

## 📁 Bonus Lookups — Where to Search for Liquidation Code & Clues

| **What**                     | **Examples / Suggestions**                                                    |
|------------------------------|-------------------------------------------------------------------------------|
| 🔍 **Folders to Search**     | `/lending/`, `/liquidation/`, `/core/`, `/vaults/`, `/risk/`                 |
| 💬 **Comment Clues**         | `// liquidation`, `// health check`, `// bonus`, `// seize collateral`       |
| 🛠 **Slither Tool**          | `slither . --detect-uninitialized-state` → may find liquidation-related bugs |
| 🛠 **Foundry cast**          | `cast call <contract> "getUserAccountData(address)"` → get live HF info      |
| 🧪 **Test grep keywords**    | `grep -Ri liquidate`, `grep -Ri healthFactor`, `grep discount`, `grep bonus` |
| 📎 **Docs / Comments**       | Look for “when liquidation triggers”, “bonus %”, “repay vs seize logic”      |
| 📄 **Config files**          | `riskParams.json`, `assetConfig.js`, `liquidationThresholds.ts`             |

# ⚡️ `FLASHLOAN EXPLOITS` `///////////////////////////////////////////////////////////////////////////////////////////////////`

### ✅ What It Means
> Attacker borrows huge amount with no upfront capital  
> → manipulates state (price, index, balance) within 1 tx  
> → exploits logic assuming prices or balances are stable

---

##  
## 🚩 Flashloan Keywords Cheat Sheet (for grep / ctrl+F)

| **🔑 Keyword**               | **🧠 What It Indicates**                                                |
|-----------------------------|-------------------------------------------------------------------------|
| `flashLoan`, `flashloan`    | ⚡ Core entry point — check if logic is abused mid-execution            |
| `executeOperation`          | 🧪 Aave-style callback — contains attack surface                        |
| `twap`, `consult`           | ⏳ Time-weighted prices — may be corrupted in one tx                    |
| `getReserves`               | 💧 AMM state — can be desynced or spoofed via temporary manipulation    |
| `sync`, `skim`              | 🧼 AMM balance adjustments — attacker can abuse `sync()`                |
| `pricePerShare`             | 🪞 Vault math — flashloan can temporarily inflate/deflate               |
| `beforeWithdraw`, `afterDeposit` | 🎭 Hooks that may be triggered during flashloan cycles          |
| `updateIndex`, `accrue`     | ⏱ Internal accounting — might be skipped or misaligned                 |
| `borrow`, `repay`, `mint`   | 💰 State-changing ops often targeted during reentry/flash window        |

---

## 🚩 Bug Signs Cheat Sheet

| **🔍 Sign**                      | **🚨 What It Means**                                                   |
|----------------------------------|------------------------------------------------------------------------|
| Price changes mid-transaction    | 📉 Oracle/TWAP updates after manipulation                             |
| Balance or reserve used as price | 💧 AMM or vault pricing can be spoofed with temp liquidity            |
| Index updated post-action        | ⏱ Value scaling incorrect for early actions                          |
| No `block.timestamp` check       | 🧨 TWAP may use same block multiple times                             |
| Vault TVL read before sync       | 🪞 Stale `totalAssets` or `pricePerShare` enables incorrect minting   |

---

| **Variable**                           | **Type**               | **Purpose**                                                  |
|---------------------------------------|------------------------|--------------------------------------------------------------|
| `ContractName.flashLoan`              | `function`             | ⚡ Entry point for flashloan — attacker-controlled flow       |
| `ContractName.twap`                   | `contract` or `uint`   | ⏳ Time-weighted price tracking                              |
| `ContractName.pricePerShare`          | `uint256`              | 🪞 Vault price — used for mint/burn or value calc            |
| `ContractName.reserves`              | `uint112` or `uint256` | 💧 AMM liquidity — used for price or swap validation         |
| `ContractName.index`                  | `uint256`              | 📈 Scaling factor — must track yield/debt accurately         |
| `ContractName.lastUpdateTimestamp`    | `uint40` or `uint256`  | ⌛ Used to determine if TWAP or accrual is up-to-date        |

---

## 🔎 Flashloan Targets – Where to Look

| **🔍 Location / Pattern**           | **🧠 Why It Matters**                                                   |
|------------------------------------|--------------------------------------------------------------------------|
| `flashLoan()` body                 | 🧨 Can trigger mint/burn/borrow before system updates                    |
| `executeOperation()`              | ⚠️ Often lacks reentrancy protections                                    |
| `twap.consult()`, `twap.update()` | 🧪 TWAP may be skewed if attacker controls both update and read          |
| `getReserves()` usage             | 💧 Liquidity-based pricing or logic can be gamed                         |
| `pricePerShare` used for mint     | 🪞 Can be inflated temporarily to mint extra shares                      |
| `accrueInterest()`, `updateIndex()`| ⏱ If done after sensitive actions, may break accounting                 |

---

## 🧠 Flashloan Logic Red Flags

| **🔑 Keyword / Pattern**           | **🚨 Suggestion / What to Check**                                      |
|------------------------------------|------------------------------------------------------------------------|
| `flashLoan()` allows any asset     | ❌ Restrictable assets? Attack surface may be too broad                 |
| `twap.update()` same tx as read   | ⚠️ Check if update and consult happen in same transaction              |
| Oracle uses reserves directly      | 💧 May be manipulated mid-tx → incorrect valuation                     |
| Vault TVL not updated before mint | 🪞 Attacker can exploit stale price to mint more shares                 |
| Index updated post-logic          | ⏱ Value may be scaled incorrectly for action that already happened     |
| Hooks not reentrancy protected     | 🚪 Flashloan might reenter critical state-modifying function            |

---

## 📁 Bonus Lookups — Where to Search for Flashloan Code & Clues

| **What**                     | **Examples / Suggestions**                                                    |
|------------------------------|-------------------------------------------------------------------------------|
| 🔍 **Folders to Search**     | `/flashloan/`, `/test/`, `/vaults/`, `/amm/`, `/hooks/`, `/oracles/`         |
| 💬 **Comment Clues**         | `// flashloan logic`, `// update reserves`, `// sync TWAP`, `// rebalance`   |
| 🛠 **Slither Tool**          | `slither . --detect-reentrancy-eth` → flag mid-tx reentrancy during flashloan|
| 🛠 **Foundry cast**          | Use `cast send` to simulate `flashLoan()` behavior and state                 |
| 🧪 **Test grep keywords**    | `grep -Ri flashloan`, `grep twap`, `grep pricePerShare`, `grep getReserves`  |
| 📎 **Docs / Comments**       | Look for “TWAP window”, “flashloan allowed”, “rebalance”, “TVL accounting”   |
| 📄 **Attack Examples**       | Alpha Homora, Yearn Vault, Cheese Bank, ValueDefi, Harvest exploits          |