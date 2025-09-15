
# Front-Running / Sandwich Attacks `dex`

- **Simple Sandwich Attack** – Attacker places buy before and sell after a victim’s trade to profit.
- **MEV Extraction via Sandwiching** – Miner or bot extracts max value by reordering transactions.
- **Lack of Slippage Checks** – Victims suffer large losses due to missing slippage limits.
- **Unprotected Token Approvals** – Approvals front-run to drain tokens.
- **Gas Price Manipulation** – Attacker uses high gas to prioritize transactions in the mempool.
- **Batch Trades Vulnerable to Sandwich** – Multiple trades bundled, attacker exploits combined effect.
- **Failed Deadline Enforcement** – Transaction deadlines ignored, allowing stale trades.
- **No Front-Running Mitigation in AMMs** – AMMs without protection against sandwiching.
- **Flash Loan Sandwich Attacks** – Use flash loans to execute large sandwich attacks profitably.
- **Repeated Sandwiching on Same User** – Victim targeted multiple times in a short span.
- **Oracle Price Impact by Sandwich** – Attacker sandwiches to manipulate oracle prices indirectly.
- **Order-Flow Manipulation in DEX Aggregators** – Aggregators reorder trades to profit attackers.
- **No Time-Weighted Average Price (TWAP) Safeguards** – TWAP oracles easily manipulated by sandwich.
- **Pending Transaction Leak** – Leak of pending tx data enables front-running.
- **Unprotected Limit Orders** – Limit orders executed in attacker’s favor due to front-running.
- **Fee Manipulation by Sandwichers** – Front-run fees extracted by attackers.
- **DEX Router Vulnerabilities** – Router contract susceptible to order manipulation.
- **Slippage Refund Bugs** – Incorrect refunds allow attacker profit.
- **Unintended Reentrancy via Sandwich** – Sandwiching triggers reentrancy bugs.
- **Insufficient Transaction Ordering Controls** – Protocols don’t control order of user transactions.

# Oracle Manipulation Attack Vectors `lending` `dex`

- **Only One Source** – Oracle `relies` on a `single DEX`; attacker manipulates that market.
- **Low Liquidity Pool** – When a pool has `low liquidity`, even `small trades` can move the price a lot. 
- **Flash Loan Price Pump** – Attacker uses a `flash loan` to `pump price` in one transaction, then exploits it. 

## TWAP Skewing – Attacker pushes price over `multiple blocks` to change the `time-weighted average price`.

### `How to Check`

- Check if the protocol uses a `TWAP` (time-weighted average price) oracle or calculates average prices over time.
- Look for variables like `priceWindow`, `priceHistory`, or arrays storing past prices.
- See if the TWAP period is **too short**, allowing quick manipulation within the window.
- Check how often the TWAP updates — if updates are infrequent or manual, price can be skewed.
- Review if the protocol **validates price changes** between blocks or sets bounds on acceptable price moves.
- Ensure that **flash loans or rapid trades** can’t easily push the TWAP unfairly.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Stale Oracle Read – Protocol uses an `old oracle price` before it updates to the true price. 

### `How to Check`

- Look for oracle price calls that **don’t verify how recent the price is**.
- Check if the contract reads `lastUpdateTime` or `updatedAt` timestamps from the oracle.
- See if there is **no require or check** ensuring the price age is within an acceptable limit.
- Look for missing fallback or error handling when the oracle price is stale.
- Verify if the protocol trusts cached prices for too long without refresh.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`


## Missing Oracle Check – Protocol `does not check` if the oracle price is `recent or fresh`.

### `How to Spot`

- Look for oracle price fetch calls without verifying `timestamp` or `age` of the price.
- Check if contract reads price but **does not check `lastUpdated` or `lastUpdateTime`** from the oracle.
- Search for missing validation like:  
  ```solidity
  require(block.timestamp - oracle.lastUpdateTime() < maxAllowedDelay, "Stale price");
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## No Price Bounds** – Protocol accepts `extreme or invalid prices` without limits.

### `How to Check`

- Look for missing or weak **require/assert** statements limiting acceptable price ranges.
- Check if the contract enforces **min and max price limits** before using oracle data.
- Look for variables like `maxPrice`, `minPrice`, `priceCap`, or `priceFloor`.
- See if there’s **no sanity checks** against absurdly high or low prices.
- Verify if price input is used directly without validation.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Manipulated LP Reserves – Attacker changes `token balances` in an AMM pool to `distort price`. 

### `How to Check`

- Check how the protocol **reads price from AMM pools**—does it rely directly on **reserves** like `reserve0`, `reserve1`?
- Look for calls to functions like `getReserves()` on Uniswap-like pairs.
- Verify if there are **no safeguards** against flash loan attacks manipulating reserves within a tx.
- Check if the protocol uses **TWAP or other averaging** instead of instant reserve snapshots.
- Review if **price calculations use token balances without validation or limits**.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Custom Token with Fake Price** – Attacker creates a `fake token and pool`, manipulates its price, and uses it.

### `How to Check`

- Check if the protocol **accepts prices from unknown or unverified tokens**.
- Look for **no whitelist or verification** on tokens used as collateral or price feeds.
- Verify if the protocol **allows creating new pools or tokens without restrictions**.
- Look for **no validation on token contracts** (e.g., missing interface checks).
- Review if the protocol trusts **on-chain price from any token pair** without safeguards.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Delayed Oracle Updates** – Attacker exploits the `time gap` between real price change and `oracle update`. 

### `How to Check`

- Check how often the oracle price is **updated or pushed** on-chain (e.g., per block, manual updates).
- **Look for timestamps** or `lastUpdateTime` variables indicating oracle freshness.
- Does the contract use **manual oracle updates** or rely on keepers/agents to push prices?
- Is there a **long delay between price updates** that can be exploited?
- Look for **no fallback or secondary oracle** if the main oracle is stale.
- Check if the protocol **relies on latest oracle price without validation of freshness**.
- Check for use of **block timestamps** or other time indicators vulnerable to miner manipulation.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Price Pull Before Deposit** – Attacker manipulates price `before depositing` to mint more tokens. 

### `How to Check`

- Does the contract fetch the oracle price `at deposit time` without prior validation?
- **Look for functions** like `deposit()`, `mint()`, or `stake()` where price is read right before minting.
- Check if **price is fetched right before user balance or shares are updated**.
- Is there **no delay or TWAP** to smooth price fluctuations before deposits?
- Are there no checks preventing **price manipulation in the same transaction** before deposit?
- Check if the contract uses **cached or stored price** from previous blocks instead of current price.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Flash Loan Sandwiching** – Attacker `pushes price` in `tx1`, uses protocol in `tx2`, then `reverts price` in `tx3`.

(`tx1`), they quickly `buy` or `sell` to `push` the `price` `up` or `down`.
(`tx2`), they use the protocol to take advantage of the changed price (like borrowing or liquidating).
(`tx3`), they reverse their first trade to restore the price back, making a profit from the temporary price change.

### `How to Check` 

- Does the contract fetch oracle price `multiple times within one transaction`**`?
- **Look for function names** like `getPrice()`, `latestAnswer()`, `getLatestPrice()`

- Is the protocol using only `spot price` without TWAP or averaging?
- **Look for function names** like `getPrice()`, `latestAnswer()`, `getLatestPrice()`
- **Check variables** like `price`, `spotPrice`, `currentPrice`
- **Absence of functions** like `getTWAP()`, `getAveragePrice()`, `getMedianPrice()`, `aggregatePrice()`

- Are there **no restrictions or detection** for flash loan usage?
- **Search for** `flashLoan()`, `flashLoanGuard()`, `onFlashLoan()`, or modifiers related to flash loans

- Does the contract allow `multi-step operations in one tx`**` (e.g., borrow + liquidate)?
- Are price-dependent actions based on `current oracle price`**` inside the same transaction?

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Single Oracles Without Min/Max Aggregation** – No `fallback or aggregation` if one oracle source is wrong or malicious.

### `How to check`
- Is price fetched from only `one oracle source` or `multiple`?  
- Does the code `combine prices` (`average`, `median`, `min/max`)?  
- Is there any `time-weighted average (TWAP)` logic?  
- Is there a `fallback oracle` if the main oracle fails?  
- Are `extreme prices filtered` or `bounded` before use?
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Manipulated Vault Shares** – Oracle tracks `vault share price` which can be `flash loaned` and manipulated.

### `How to Check`

- Check if the oracle price depends on **vault share value or pricePerShare**.
- Look for calls to vault functions like `pricePerShare()`, `totalAssets()`, or `totalSupply()`.
- Verify if **flash loans or rapid deposit/withdraw actions** can manipulate vault shares in one transaction.
- Check if the protocol uses **TWAP or delayed averaging** to smooth vault share prices.
- Review whether the protocol **validates share price changes before accepting them**.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Multi-DEX Oracle Drift** – Attacker manipulates price across `multiple DEXes` used by oracle.

### `How to Check`
- Check if the oracle aggregates prices from **multiple DEX sources** (e.g., Uniswap, SushiSwap).
- Look for functions like `getPriceFromDEX()`, `aggregatePrices()`, or arrays of price feeds.
- Verify if the aggregation uses **median, min/max, or weighted averages** to reduce manipulation risk.
- Check for **no fallback or sanity checks** if one DEX price is outlier or manipulated.
- Review if the protocol **fails to handle inconsistent or delayed price feeds** from different DEXes.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Improper Decimals Handling** – Oracle misreads price due to `wrong token decimals`.

### `How to Check`

- Check if the oracle or protocol correctly **reads and adjusts token decimals** (usually 18, 6, or others).
- Look for missing **decimal conversion or scaling** when reading prices or reserves.
- Verify if token decimals are fetched via `decimals()` and applied properly.
- Look for calculations that **mix tokens with different decimals** without normalization.
- Check for hardcoded decimal assumptions that may break with tokens using unusual decimals.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Inverted Price Feeds** – Oracle reads `tokenB/tokenA` but protocol expects `tokenA/tokenB`. ✅

### `How to Check`

- Check the order of tokens used in oracle price calls, e.g., `getPrice(tokenA, tokenB)` vs `getPrice(tokenB, tokenA)`.
- Verify if the protocol expects price in one direction but oracle returns the inverse.
- Look for missing **price inversion or reciprocal calculation** like `1 / price`.
- Check if the contract properly handles **token order when querying price feeds or pools**.
- Review documentation or code comments clarifying token pairs and price direction.
`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Infrequent Oracle Pushing** – Oracle price is `pushed manually or delayed`, causing stale data.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Re-entrancy in Oracle Callbacks** – Oracle update triggers a `callback`, attacker `reenters` during update.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Two-Step Price Manipulation** – Attacker manipulates oracle price in one block, then exploits it in the next before reset.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Mirror Pool Manipulation** – Attacker creates `two pools (A-B and B-A)` and confuses price references.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Fake Token Pairs** – Attacker uses `fake tokens` with no oracle validation and manipulates mint/burn logic.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Scaling Bug in Oracle Math** – Oracle fails to `scale large numbers` correctly causing overflow or underflow.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Laggy Chainlink Feeds** – Chainlink price updates are too `slow` to reflect high volatility.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Oracle-Initiated Actions** – Oracle triggers protocol actions (e.g., rebases, interest), attacker manipulates timing.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Paused Feed Fallback** – Primary oracle is `paused`; fallback oracle (e.g., DEX) can be manipulated.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Selective Price Read** – Attacker front-runs which `DEX the oracle samples` if not randomized.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Flash Loaned Collateral Boost** – Attacker inflates oracle price, deposits collateral, borrows, then reverts price.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`

## Unverified Oracle Contracts** – Protocol uses oracles with `no source code verified`, hiding attacker logic.

`////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`


# Logic Errors in Interest or Fee Calculations `lending/borrowing`

- **Incorrect Interest Accrual Timing** – Interest calculated before updating principal, causing over- or under-accumulation.
- **Using Integer Division Without Rounding** – Truncation causes systematic loss or gain over time.
- **Misplaced Fee Deduction** – Deducting fees before interest causes incorrect final balances.
- **Not Updating State After Fee Payment** – Fees are transferred but internal accounting not updated, causing mismatch.
- **Interest Rate Overflow** – Multiplying large principal by rate causes overflow if unchecked.
- **Compound Interest Miscalculation** – Using simple interest formulas where compounding is needed, or vice versa.
- **Wrong Basis Points Conversion** – Confusing basis points (`bps`) and percentages leads to wrong fee rates.
- **Ignoring Fee Cap or Max Limits** – `Fees grow beyond` intended `limits` due to `missing checks`.
- **Incorrect Handling of Grace Periods** – Interest continues accruing during grace period when it should pause.
- **Double Counting Fees in Multi-Token Protocols** – Charging fees multiple times due to separate token handling bugs.
- **Incorrect Principal Update Order** – Principal updated after interest calculation, causing stale bases.
- **Ignoring Accrued Interest in Repayments** – Repayments reduce principal but skip settling accrued interest first.
- **Using Block Timestamp for Interest Periods** – Vulnerable to miner manipulation causing inconsistent interest accrual.
- **Fee Calculation Based on Outdated State** – Fees computed before state changes cause wrong fee amounts.
- **Fixed-Point Precision Loss** – Loss of precision in decimal math leads to gradual drifts.
- **Misaligned Interest Rate Units** – Mixing annual vs per-block rates without proper conversion.
- **Unbounded Interest Growth** – No maximum cap on interest causes runaway debt.
- **Improper Penalty Interest Trigger** – Penalties applied incorrectly or too aggressively.
- **Fee Transfer Failures Ignored** – Protocol assumes fee transfers succeed without checks, breaking accounting.
- **Inconsistent Fee Logic Across Functions** – Different functions calculate or apply fees differently, causing state divergence.


# Liquidation Manipulation (Borrower or Liquidator Abuse) `lending`

- **Price Oracle Manipulation** – Attacker skews `oracle price` to trigger unfair liquidation or avoid it.
- **Liquidation Incentive Exploit** – Liquidator repeatedly liquidates `small amounts` to extract excess rewards.
- **Partial Liquidation Abuse** – Borrower repays just enough to reset liquidation status repeatedly.
- **Flash Loan Liquidation Attack** – Use `flash loan` to trigger liquidation cheaply and profit from rewards.
- **Debt Reentrancy During Liquidation** – Reenter liquidation function to drain collateral multiple times.
- **Delayed Liquidation Attack** – Borrower delays liquidation timing to maximize profit or avoid penalties.
- **Collateral Swap Abuse** – Swap collateral assets during liquidation to confuse accounting.
- **Liquidator Front-Running** – Liquidator front-runs other liquidators to grab better prices or rewards.
- **Underpriced Collateral Purchase** – Liquidator buys collateral below fair market value due to bugs.
- **Incorrect Health Factor Calculation** – Protocol miscalculates borrower risk, causing wrongful liquidations.
- **Multiple Liquidations in One Tx** – Liquidator triggers multiple liquidations exploiting state updates.
- **Liquidation Delay Exploit** – Attacker manipulates timing between `price updates` and liquidation checks.
- **Oracle Delay with Liquidation** – Use `oracle update lag` to liquidate unfairly or avoid liquidation.
- **Liquidation Refund Bug** – Protocol refunds too much collateral or debt on liquidation.
- **Incorrect Collateral Valuation** – Protocol undervalues collateral, letting attacker liquidate cheaply.
- **Debt Token Reentrancy** – Reenter liquidation to drain more debt tokens or collateral.
- **Liquidation Fee Bypass** – Attacker avoids paying liquidation fees by exploiting logic bugs.
- **Incorrect Partial Liquidation Logic** – Liquidation leaves borrower undercollateralized or liquidatable.
- **Liquidator Role Abuse** – Malicious liquidator changes roles or permissions to skip checks.
- **Flash Loan Collateral Cycling** – Use `flash loan` to swap collateral repeatedly to manipulate liquidation state.

# Access Control Flaws (Missing/Incorrect Modifiers)

- **Missing OnlyOwner Modifier** – Critical functions callable by anyone due to missing `ownership` checks.
- **Incorrect Role Assignment** – Users assigned `wrong roles` accidentally or maliciously.
- **Admin Privilege Escalation** – Users exploit bugs to gain `admin rights`.
- **Unprotected Initialization** – `initialize()` function callable multiple times, resetting `ownership`.
- **Missing Reentrancy Guard on Admin Functions** – Allows `reentrancy attacks` via privileged functions.
- **Lack of Pause/Unpause Restrictions** – Anyone can `pause` or `unpause` contract if not restricted.
- **Unrestricted Upgrades** – Proxy upgrades callable by `unauthorized users`.
- **Incorrect Modifier Logic** – Modifiers use `if` instead of `require`, skipping checks.
- **No Access Control on Emergency Withdraw** – Anyone can `drain funds` in emergencies.
- **Public Variables Allow State Changes** – Public setters or variables misused to change critical state.
- **Missing Access Control on Mint/Burn** – Token `minting` or `burning` callable by unauthorized users.
- **Delegatecall Abuse** – Delegatecall targets lack access checks, allowing `malicious code`.
- **Missing Multi-Sig for Critical Actions** – High-privilege actions require `single key` instead of multi-sig.
- **Unchecked External Calls in Admin Functions** – Admin functions call external contracts without checks.
- **Insecure Whitelist Management** – Anyone can add/remove addresses from `whitelist`.
- **Bypassing Access Control via Constructor** – Logic in constructor allows bypassing later checks.
- **Incorrect Access Control Inheritance** – Child contracts miss inherited access checks.
- **Unprotected Upgrade Admin Role Transfer** – Admin role can be transferred without proper validation.
- **Role Renouncement Bugs** – Users renounce roles unintentionally or maliciously.
- **Fallback Function Abuse** – Fallback function allows unauthorized access to `admin logic`.

# Arithmetic Bugs (Overflow/Underflow Despite SafeMath)

- **Incorrect Use of SafeMath Library** – Forgetting to use `SafeMath` in some functions.
- **Unsafe Custom Math Functions** – Writing own math without `overflow checks`.
- **Unchecked Multiplication Overflow** – Multiplying large numbers causing `overflow`.
- **Unchecked Subtraction Underflow** – Subtracting larger from smaller value without checks.
- **Mixing Signed and Unsigned Integers** – Causing unexpected behavior or `overflow`.
- **Improper Casting Between Types** – Casting larger uint to smaller causing `truncation`.
- **SafeMath Not Applied to Exponentiation** – `Overflow` in power operations.
- **Integer Division Truncation** – Losing precision leads to `rounding errors`.
- **Neglecting Overflow in Loops** – Loop counters `overflow` causing infinite loops or errors.
- **Unchecked Addition Overflow** – Adding large values without `overflow` protection.
- **Overflows in Timestamp Calculations** – Adding large durations to block `timestamps`.
- **Incorrect Handling of Decimals** – Multiplying/dividing tokens with different `decimals` causes miscalculations.
- **SafeMath Used Only in Critical Functions** – Other math operations left `unprotected`.
- **Neglecting Overflow in Array Indexing** – Overflowing indices can `corrupt data`.
- **Using Solidity <0.8 Without SafeMath** – Native `overflow` checks missing in older compilers.
- **SafeMath Disabled in Optimized Builds** – Compiler optimizations remove checks unexpectedly.
- **Unchecked Increment/Decrement** – Counters `overflow` or underflow without checks.
- **Incorrect SafeMath Version Used** – Using outdated or incompatible `SafeMath` library.
- **Unchecked Multiplication With Zero** – Special cases where multiplying by zero skips checks.
- **Logic Errors Due to Overflow Masks** – Masking bits instead of proper `overflow` handling.


# Unchecked Return Values (Missing require/assert on External Calls)

- **Missing require on ERC20 transfers** – Not checking `transfer()` success causes silent failures.
- **Ignoring return values of low-level calls** – `call()`, `delegatecall()` results unchecked.
- **Unverified external contract calls** – Assume external calls succeed without validation.
- **Unchecked ERC721 transfer results** – Failing to check `safeTransferFrom()` success.
- **Lack of revert on failed external calls** – Errors go unnoticed, corrupting state.
- **Unchecked return of approval calls** – `approve()` return ignored, allowing failed approvals.
- **Missing assert on critical callbacks** – External callbacks assumed always succeed.
- **Ignoring return of ETH transfers** – Using `send()` without require leads to lost ETH.
- **Unchecked low-level assembly calls** – Assembly calls lack result verification.
- **No error handling on oracle calls** – Price fetches without result checks.
- **Unchecked proxy delegatecall return** – Delegatecall results ignored, hiding failures.
- **Unvalidated contract creation return** – Deployment success not checked.
- **Unchecked batch calls** – Batched external calls missing success checks.
- **No require on external balance fetch** – Assume balance queries always succeed.
- **Unchecked library calls** – Library functions with external calls ignore return values.
- **Unchecked external mint calls** – Minting tokens externally without verifying success.
- **Unchecked return on external swap** – Swap success not checked, leading to bad trades.
- **Ignoring revert reasons from external calls** – Missing logs on failed calls.
- **Unchecked return on external approvals** – Approval failures ignored, causing security holes.
- **Missing require on external delegatecall** – Critical delegatecall failures unhandled.

# Race Conditions / Transaction Ordering

- **Double Spend Due to Tx Ordering** – Attacker reorders `txs` to spend funds twice.
- **State Update Race** – Concurrent `txs` update state inconsistently.
- **Front-Running Race** – Attacker exploits `mempool` visibility to reorder trades.
- **Delayed State Visibility** – Oracles or contracts rely on `stale state` due to ordering.
- **Race on Withdrawal Limits** – Multiple withdrawals bypass limits if ordered badly.
- **Transaction Sandwich Race** – Attacker sandwiches victim’s `tx` to profit.
- **Race on Ownership Transfer** – Ownership changes lost due to concurrent `txs`.
- **Race in Token Minting** – Multiple mints cause inconsistent supply.
- **Race on Access Control Updates** – Role changes conflict if ordered improperly.
- **Race Condition in Liquidation** – Multiple liquidations interfere and cause errors.
- **Race on Reward Claiming** – Claim functions exploited by concurrent calls.
- **Race in Interest Calculation** – Interest miscalculated due to `tx ordering`.
- **Race on Fee Deduction** – Fees under- or over-charged due to race.
- **Race in Debt Accounting** – Debt balances corrupted by concurrent updates.
- **Race on Collateral Withdrawal** – Multiple withdrawals exceed collateral.
- **Race in Price Oracle Updates** – Oracle price updates race with state changes.
- **Race in Contract Upgrades** – Upgrade logic broken by concurrent calls.
- **Race on Deposit/Withdrawal Events** – Events fired in incorrect order.
- **Race in Governance Voting** – Votes overridden due to ordering.
- **Race Condition in Token Swaps** – Swap results inconsistent due to concurrent `txs`.

# Denial of Service (DoS) via Block Gas Limit or Locks

- **Unbounded Loop Over Gas Limit** – Loop over user data exceeds `gas`, blocking execution.
- **Gas Exhaustion in Refunds** – Refund logic uses too much `gas`, failing transactions.
- **DoS via Locked State Variable** – Contract locked indefinitely due to bad `state update`.
- **Denial via Full Queue or Array** – Arrays fill up, preventing further user actions.
- **DoS from Failed External Calls** – External call failures block progress without fallback.
- **DoS via Self-Destruct Called Improperly** – Contract destroyed by `unauthorized call`.
- **Gas Limit Hit on Batch Processing** – Processing batches exceeds `block gas`, halting.
- **DoS via Reentrancy Locks** – Improper locking blocks all future calls.
- **DoS by Blocking Admin Functions** – Admin functions frozen, stopping protocol upgrades.
- **DoS from Unchecked Exception** – Exception leaves contract in unusable state.
- **DoS by Withholding Funds** – Funds locked by design or bug, halting withdrawals.
- **DoS via Fallback Function Overload** – Fallback consumes all `gas`, blocking calls.
- **DoS by Front-Runner Blocking** – Attacker spam front-runs, congesting `mempool`.
- **DoS by Price Oracle Freeze** – Oracle feed freezes, halting dependent functions.
- **DoS via Incorrect Modifier Logic** – Modifiers prevent legitimate calls accidentally.
- **DoS via Gas Griefing** – Attacker forces high `gas costs` to prevent txs.
- **DoS via Storage Bloat** – Large storage use slows or blocks important calls.
- **DoS by Locking Upgrade Path** – Upgrade contract blocked, locking protocol forever.
- **DoS from Failed Delegatecall** – Delegatecall failure stops contract execution.
- **DoS via Paused Contract State** – Contract paused with no recovery path.