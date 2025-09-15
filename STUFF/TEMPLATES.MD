### `GUIDE`
- `Ctrl + P` → Type file name directly  
  _Example: `CDS.sol`_

- `Ctrl + Shift + O` → Jump to functions in the file  
  _Acts like a Table of Contents_

- `Ctrl + F` → Search in current file  
  _Try: `downsideProtected` or `calculateWithdrawAmount`_

- `Ctrl + Shift + F` → Search across whole repo  
  _Great for jumping to var/func definitions_

## `moneyflow`

| Step | Action               | Pool | Shrs | Rate     | Debt | Coll | LP  | Price | Notes                             |
|------|----------------------|------|------|----------|------|------|-----|--------|-----------------------------------|
| 1    | Alice `deposits` 1000  | 1000 | 1000 | 1e36     | 0    | 0    | 0   | $1.00  | Initial deposit                   |
| 2    | Bob borrows 500      | 1000 | 1000 | 1e36     | 500  | 1000 | 0   | $1.00  | Borrow against 1000 collateral   |
| 3    | Interest accrues     | 1050 | 1000 | 1.05e36  | 500  | 1000 | 0   | $1.00  | Lenders earn, protocol earns 50  |
| 4    | LP adds 500/500 AMM  | 1050 | 1000 | 1.05e36  | 500  | 1000 | 100 | $1.00  | LP adds liquidity to AMM         |
| 5    | Oracle drops price   | 1050 | 1000 | 1.05e36  | 500  | 1000 | 100 | $0.60  | Undercollateral alert triggered  |
| 6    | Liquidation triggered| 1050 | 1000 | 1.05e36  | 0    | 0    | 100 | $0.60  | Bob's position liquidated        |
| 7    | Alice withdraws 950  | 100  | 50   | 1.05e36  | 0    | 0    | 100 | $0.60  | Withdraw post-liquidation        |
| 8    | ⚠️ Rate bug (zero debt)| 100 | 50   | 1.05e36  | 0    | 0    | 100 | $0.60  | Rate not updating if no debt     |
| 9    | Fee revenue summary  | -    | -    | -        | -    | -    | -   | -      | Protocol earned 50 interest      |
| 10   | Sec. recommendation  | -    | -    | -        | -    | -    | -   | -      | Add buffer vs oracle manipulation|

## `FUNCTION-SUMMARY` 
slither . --print function-summary

for every function
output  like this one:
i will paste the functions in a sec

 **`FunctionName(ParameterTypes)`**
visibility; 1-liner description 
- **Reads:** `.var2.var1.`
- **Writes:** `.var1.var2.`
- **Internal calls:**
  - Contract.function()
- **Reverts on:** Error1(), Error2(), ...
- **External calls:**
  - - Contract.function() / Interface.method()


## 🔸 `FUNCTION-CHAIN`

slither . --print function-summary

- `buyLoan` → `_calculateInterest` → `getPoolId` → `_updatePoolBalance` → `transfer`
- `repay` → `getLoanDebt` → `_calculateInterest` → `transferFrom`
- `deposit` → `updatePoolState` → `mint`  
- `withdraw` → `burn` → `transfer`
- `deposit()` → calls `Staking.updateFor(address)` → which calls `update()`  
- `withdraw()` → calls `Staking.updateFor(address)` → which calls `update()`  
- `claim()` → calls `Staking.updateFor(address)` → which calls `update()`  
- `updateFor(address)` → calls `update()`  

## `VARIABLES`
slither . --print variable-order
give me a minimal example of storage variables

- Staking.owner - `address` - Contract owner address  
- Staking.balance - `uint256` - Total staked balance  
- Staking.index - `uint256` - Global index for rewards calculation  
- Staking.supplyIndex - `mapping(address => uint256)` - Mapping of user address to index  
- Staking.balances - `mapping(address => uint256)` - Mapping of user address to staked amount  
- Staking.claimable - `mapping(address => uint256)` - Mapping of user address to claimable rewards


















  ##


  ##

  