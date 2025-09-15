

# `LENDING-FOCUS`

## 📐 Collateral & Borrowing
| Formula / Concept                          | What it means                                     |
|--------------------------------------------|---------------------------------------------------|
| Collateral Value = deposits * price        | How much the collateral is worth in USD/ETH terms |
| Borrow Power = Collateral Value * LTV      | Max borrowable amount                             |
| Health Factor = (Collateral * LTV) / Debt  | Safety ratio; <1 → liquidation                   |
| Liquidation Threshold                      | Ratio where liquidation can happen                |

- Check if price uses a manipulable oracle.
- Verify math is scaled correctly (decimals, 1e18 vs 1e6).
- Ensure health factor cannot be bypassed.

## 📉 Interest & Debt
| Formula / Concept                            | What it means                                     |
|----------------------------------------------|---------------------------------------------------|
| Interest Accrued = `debt * rate * time`      | How much extra borrower owes                      |
| Utilization = `borrows / (cash + borrows)`   | Borrowed % of pool                                |
| Rate Model = `baseRate + slope*utilization`  | Dynamic interest calculation                      |
| `Debt Index / Borrow Index`                  | Scaling factor for accrued interest               |

- Check if time units (seconds vs blocks) are consistent.
- Look for rounding errors in interest accrual.
- Ensure debt index always updates before user actions.

## 💸 Rewards / Shares
| Formula / Concept                             | What it means                                     |
|-----------------------------------------------|---------------------------------------------------|
| Shares = deposit * (totalShares / totalAssets)| User’s ownership of pool                          |
| Assets = shares * (totalAssets / totalShares) | Convert back to real assets                       |
| Rewards per Share = rewards / totalShares     | Distribution formula                              |
| Accrued Rewards = userShares * rewardsPerShare| What user earns                                   |

- Check division order → must avoid rounding away user funds.
- Ensure shares/asset conversion is consistent both ways.
- Watch for dust tokens (leftover due to rounding).
 
## 🛑 Math Attack Scenarios
| Attack Scenario                            | Example                                           |
|--------------------------------------------|---------------------------------------------------|
| Rounding Exploit                           | Attacker deposits/withdraws tiny amounts to steal |
| Overflow / Underflow                       | Rare after 0.8, but possible in `unchecked`       |
| Mispriced Collateral                       | Oracle returns 0 or fake high price               |
| Infinite Mint                              | Bug in shares formula lets attacker mint extra    |
| Skewed Utilization                         | Flashloan inflates utilization → rate manipulation|

## 🕵️ Auditor Math Checklist    
| Check                                      | Why it matters                                    |
|--------------------------------------------|---------------------------------------------------|
| Is LTV correctly applied?                  | Wrong LTV → over-borrow possible                  |
| Does Health Factor < 1 trigger liquidation?| Safety mechanism must work reliably               |
| Are decimals consistent?                   | Tokens use 6, 8, 18 decimals                      |
| Are interest & indexes updated timely?     | Delayed update = accounting drift                 |
| Are rewards capped or bounded?             | Prevents infinite reward bug                      |
| Is division done last (after multiply)?    | Prevents precision loss                           |


#

## ➗ Basic Math Risks
| Risk / Pattern                             | What to check                                     |
|--------------------------------------------|---------------------------------------------------|
| Overflow / Underflow (pre-Solidity 0.8)    | Missing SafeMath or `unchecked`                   |
| Division Rounding                          | Results truncated (floor division)                |
| Multiplication Before Division             | Precision loss                                    |
| Wrong Order of Operations                  | Must do `(a * b) / c`, not `a * (b / c)`          |

## 🏦 Accounting Math
| Risk / Pattern                             | What to check                                     |
|--------------------------------------------|---------------------------------------------------|
| totalSupply vs sum(balances)               | Do they match?                                    |
| Shares vs Assets                           | Conversion formula correct?                       |
| Rewards per Share                          | Precision scaling (`1e18` style multipliers)      |
| Accrual Updates                            | Interest / rewards updated before usage           |
| Off-by-One Errors                          | Indexing in arrays, loops                        |


## 📉 Financial Math 
| Risk / Pattern                             | What to check                                     |
|--------------------------------------------|---------------------------------------------------|
| Slippage Calculation                       | Is slippage properly enforced?                    |
| Fee Deduction                              | Fee taken before or after transfer?               |
| Rounding Exploits                          | User repeats actions to gain leftover dust        |
| Interest Formula                           | Compounding or simple? Correct math?              |
| Price Calculation                          | From oracle/AMM — manipulation possible?          |

## 🛠 Auditor Math Checklist
| Question / Check                           | Why it matters                                    |
|--------------------------------------------|---------------------------------------------------|
| Are math operations inside `unchecked`?    | Could overflow / underflow silently               |
| Is precision scaling consistent?           | 1e6 vs 1e18 mismatches cause big losses           |
| Are division results floored?              | Floor division may unfairly favor someone         |
| Does total = sum(balances)?                | Accounting mismatch leads to fund loss            |
| Are rewards/fees bounded?                  | Infinite growth → inflation / drain               |
| Is math gas-efficient but safe?            | Some optimizations remove checks                  |

