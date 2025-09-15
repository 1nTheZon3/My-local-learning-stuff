
## 🧱 2. Mark Known Entry Points [HOW-TO-ORGANIZE-MD-FILE-PER-CONTEST]

From the bug report:

- Borrower triggers `downsideProtected += ...`  
- CDS depositor later withdraws, triggering issue


## FUNCTIONS & SUGESTIONS

**`deposit` - (adds collateral or lends)**  
  **Understand:** how funds enter (ERC20 `transferFrom`)  
  **Then check:** accounting updates, access control, event logs  

**`withdraw`**
  **Understand:** how user share is calculated  
  **Then check:** state updated before transfer, limits enforced, rounding

**`borrow`**        
 **Understand:** how borrow amount is calculated (LTV, collateral factor)  
  **Then check:** overflow risks, max borrow check, correct debt accounting

**`repay`**          
  **Understand:** debt reduction logic  
  **Then check:** interest paid first? underflows? ERC20 transfer result checked?

**`liquidate`**          
   **Understand:** how `target is selected` and `how much can be repaid`  
   **Then check:** price `oracle` used? `closeFactor` respected? `seized collateral` fair?
   **Understand:** when liquidation is allowed (`healthFactor < 1`)  
   **Then check:** price oracle, `closeFactor`, correct collateral seized

**`redeem` - convert protocol tokens back to underlying**
   **Understand:** 1:1 or `exchangeRate` based  
   **Then check:** rounding issues, manipulation of rate, fee logic
   **Understand:** 1:1 conversion or based on exchangeRate?  
   **Then check:** accurate math? any `rounding` losses?

**`flashLoan`** 
  **Understand:** how repayment + fee is verified  
  **Then check:** reentrancy guards, external call protection
   **Understand:** how `repayment + fees` are checked  
   **Then check:** `reentrancy` guard? `external call` safety?

💵 Price & Oracle
------------------
`priceOracle`          - contract providing token prices
`getAssetPrice`        - fetches token price
`priceFeed`            - external feed (e.g., Chainlink)
`fetchPrice`           - internal or adapter logic to get price

`priceOracle` / `getAssetPrice`  
   Understand: where price comes from  
   Then check: stale data? wrong decimals? spoofable source?

`priceFeed`, `fetchPrice`  
   Understand: if Chainlink, TWAP, or custom logic  
   Then check: what fallback logic exists if feed fails?

⚠️ Risk Parameters
-------------------
`collateralFactor`     - % of supplied asset usable as collateral
`maxLTV`               - max allowed loan-to-value ratio
`closeFactor`          - max % of debt liquidatable in one call

`healthFactor`     
   Understand: formula (collateral / borrow * thresholds)  
   Then check: precision? manipulation via price oracle?

`liquidationThreshold`, `collateralFactor`, `maxLTV`, `closeFactor`  
   Understand: control borrow and liquidation limits  
   Then check: are values too generous? are they enforced consistently?

📊 State & Balances
--------------------
`totalBorrows`        - total amount borrowed in the protocol
`totalSupply`         - total supplied assets
`totalReserves`       - protocol-owned reserves (not withdrawable)
`userBorrowAmount`    - how much a user has borrowed
`userCollateral`      - collateral posted by the user
`liquidity`           - available capital for borrowing
`balanceOf`           - user's token balance

`totalBorrows` / `totalSupply`  
   Understand: how global values are tracked  
   Then check: do per-user changes affect them correctly?

`totalReserves`       - protocol-owned reserves (not withdrawable)  
   Understand: how reserves accumulate (via fees?)  
   Then check: is it protected from draining?

`userBorrowAmount` / `userCollateral`  
   Understand: what units are stored (raw? normalized?)  
   Then check: are they synced after operations?

`liquidity`           - available capital for borrowing  
   Understand: supply - borrowed  
   Then check: does it match actual balance?

`balanceOf`           - user's token balance  
   Understand: ERC20 balance or internal accounting?  
   Then check: does it match actual entitlements?

🛠️ Utilities & Helpers
------------------------
`update`               - generic update (e.g., interest, indexes)
`configure`            - sets risk parameters
`rebalance`            - adjusts collateral/debt ratios
`snapshot`             - stores current state for later use
`init` / `initialize`  - sets up contract (especially proxy pattern)

`init`, `initialize`  
   Understand: proxy setup function  
   Then check: is it protected by `initializer` modifier? callable only once?

   `snapshot`  
   Understand: saves state at a moment  
   Then check: used for voting or redemption? can it be skipped?

   `rebalance`  
   Understand: moves collateral or debt to maintain health  
   Then check: can it be abused to shift losses?


## 📈 Interest & Indexes

- `accrueInterest` – updates interest over time  
  **Understand:** is it auto or manual?  
  **Then check:** skipped updates, overflow, fair distribution

- `interestRate` – borrow/supply rate  
  **Understand:** fixed, dynamic, or manipulated?  
  **Then check:** external config, rate jumps, high LTV exploitation

- `utilizationRate` – borrowed / available ratio  
  **Understand:** affects dynamic rates  
  **Then check:** division-by-zero, wrong base values

- `borrowIndex`, `supplyIndex` – interest accumulation trackers  
  **Understand:** used to compute user's accrued debt/rewards  
  **Then check:** updated consistently? any drift?

`updateInterest`      - manually trigger interest update  
   Understand: who can call it?  
   Then check: any impact if skipped or spammed?

- `exchangeRate` – how much underlying per protocol token  
  **Understand:** affects withdrawals, mint/burn logic  
  **Then check:** any manipulation window? is it live or stale?
   
   Interest accrual updates these key values:
`totalBorrows` - total amount owed by all borrowers (grows with interest)
`totalReserves` - protocol's cut of the interest earned


🧪 Testing & Audit Targets      **`WHAT IT MEANS BY TARGETS`?** 
---------------------------
`emit`                 - logs events (Deposit, Withdraw, Liquidate, etc.)
`require`              - safety checks in logic
`revert`               - error on failed condition
`mapping(address =>`   - tracks per-user data
`external` / `public`  - externally callable functions (entrypoints)

`emit`, `require`, `revert`  
   Understand: where checks fail or succeed  
   Then check: are logs informative? do all safety checks exist?

`mapping(address =>`, `external`, `public`  
   Understand: where user state is stored and exposed  
   Then check: are inputs sanitized? access checked?

# 🧠 Ctrl+F Helpers  

### 🔑 Important Variables  
These control money, ratios, or protocol state:
- `debt`, `collateral`, `value`, `amount`, `balance`
- `total*`, `cumulative*`, `normalized*`, `pending*`
- `last*`, `prev*`, `current*`
- `price`, `strike`, `rate`, `ratio`, `index`

> Tip: Use `=`, `+=`, `-=` to find where they **change**

**`VUNRABILITY TRACE `**

### 📉 Accounting Bugs  
- `cumulative*`, `normalized*`, `rate`, `index`, `value`

### 🔁 Reentrancy / External Calls  
- `transfer`, `call`, `external`, `nonReentrant`

### 💰 Price Manipulation  
- `price`, `oracle`, `TWAP`, `update`


### 🔢 `cumulativeValue`  
  **Look for:**  
  - Written (`=`, `+=`, `-=`)  
  - Read in conditions/calculations  
  - Returned or passed to functions  

  **Then check:**  
  - Can it go negative?  
  - Does it reset or drift?  
  - Is it always updated before used?

where it’s:  
   - ✅ Written (`=`, `+=`, `-=`)  
   - ✅ Read/used in logic  
   - ✅ Returned from or passed to functions  
   - Follow value movement → spot inconsistencies  

### 🔁 `transfer`, `call`, `send` `IERC20(`
 
  **Check:**  
  - State updated **before** external call  
  - `nonReentrant` or guard exists  
  - Fallback call risks

    - Who sends/receives?  
  - Is fee logic safe?  
  - `transferFrom` return value checked?

    **Watch for:**  
  - Missing access checks  
  - Transfers to attacker-controlled addresses  
  - Locked funds

 -  Who can send? Who receives?  
   - ✅ Fee logic  
   - ✅ Missing access checks  
   - 🚨 Transfers to attacker-controlled addresses  
   - 🧊 Funds locked forever  


### 🧮 `*`, `/`, `%`  
  **Check:**  
  - Division-by-zero  
  - Rounding issues (e.g., `x / y * z`)  
  - Overflow before division

2. Validate:  
   - ❓ Division-by-zero  
   - ⚠️ Rounding issues (`x / y * z`?)  
   - 💥 Overflow before division  

### 📦 `mapping`, `.push`, `delete`, `index++`  
  **Check:**  
  - Mappings and arrays stay in sync  
  - Unused indices or stale data  
  - Structs partially deleted?

    - Are structs/mappings in sync?  
    - Is anything **left behind**?  
    - Are indices reused or misaligned?  

### 🕵️ `public`, `external`  
  **Check:**  
  - Entry points with no access checks  
  - Logic trusting user input or state too much  
  - Abuse via repeated calls

  -  Map user-facing functions  
   - Can they be abused repeatedly?  
   - Are permissions enforced?  
   - Do they trust inputs blindly?  

### 🧱 `deposit`, `withdraw`  
  **Understand:**  
  - Where funds go (`transferFrom`)?  
  - How state is updated?  

  **Then check:**  
  - Accurate share calculation?  
  - Front-running possible?  
  - Is user state cleaned on withdrawal?


  


**`//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`**
  # 📌 Lending Protocol Math Cheat Sheet

| **Formula** | **Meaning** | **Audit Notes** | **Mini Example** |
|-------------|-------------|-----------------|------------------|
| `U = borrows / liquidity` | Utilization rate | Denominator must include reserves | `100 / (200+100) = 0.33` |
| `borrowRate = base + (slope * U)` | Interest rate model (linear) | Check scaling (1e18) | `0.02 + 0.1 * 0.5 = 0.07` |
| `supplyRate = borrowRate * U * (1 - rf)` | Lender APY | Reserve factor cut must be correct | `0.07 * 0.5 * 0.9` |
| `ΔIndex = IR * Δt / YEAR` | Index growth over time | Use correct time units | `0.05 * 86400 / 31536000` |
| `newDebtIndex = oldIndex * (1 + ΔIndex)` | Compound debt index | Multiply before dividing | `1e18 * (1 + 0.001)` |
| `userDebt = shares * index / 1e18` | Convert debt shares → value | Precision loss if divide first | `100 * 1.001e18 / 1e18` |
| `collateralValue = amount * price * scale` | Collateral valuation | Check oracle decimals | `100 * 2e18 / 1e8` |
| `healthFactor = collatValue * LTV / debt` | Risk metric | Must handle rounding edge cases | `200 * 0.8 / 150` |
| `seizeAmount = repay * bonus * price` | Collateral seized in liquidation | Bonus too high = griefing | `100 * 1.1 * 2` |
| `badDebt = totalBorrows - totalCollateralValue` | Uncovered debt | Must be socialized | Missing → insolvency hole |



## Practical tips for auditing flows

Start with fund-holding contracts → mark every incoming/outgoing token
Trace every function that modifies storage related to value
Always check funds before and after a transaction — this is what attackers exploit
Draw a mini diagram on the side: user → router → pair → balances, so you always know “where money lives”