## 3️⃣ Keywords / Patterns to Search in Code

| Keyword / Pattern                          | What it indicates                                  |
|--------------------------------------------|---------------------------------------------------|
| `reserve`, `balance`, `shares`, `debt`     | Stores token or debt amounts                      |
| `transfer`, `transferFrom`, `safeTransfer` | Outgoing token movement                           |
| `payable`, `msg.value`, `receive`          | ETH can be received                               |
| `_mint`, `_burn`                           | LP tokens or debt shares updated                  |
| `getReserves`, `totalSupply`, `totalBorrows`| Read-only views of funds/state                   |
| `address(0)`                               | Check for uninitialized storage or burn address   |
| `approve`, `allowance`                     | Token spending rights (who can move funds)        |
| `call{value: x}()`, `send`, `delegatecall` | ETH/token movement via low-level calls            |
| `selfdestruct`                             | Contract can delete itself and send all ETH       |
| `msg.sender`, `tx.origin`                  | Who triggered the call (important for auth/flow)  |
| `withdraw`, `claim`, `redeem`              | Outgoing withdrawals / exits of value             |
| `deposit`, `stake`, `supply`               | Incoming deposits / user funds entering           |
| `fee`, `interest`, `premium`               | Protocol earnings / deductions on transactions    |
| `collateral`, `liquidate`                  | Funds locked or seized in lending protocols       |
| `swap`, `exchange`, `trade`                | Token conversion, may move balances internally    |
| `vault`, `treasury`                        | Central place where funds are aggregated/stored   |
| `distribute`, `reward`, `airdrop`          | Outgoing distribution of tokens/ETH               |
| `rebase`, `adjustSupply`                   | Total token supply changes (affects balances)     |



## 🏦 Where Funds Sit
| Keyword / Pattern                          | What it indicates                                  |
|--------------------------------------------|---------------------------------------------------|
| `balanceOf`, `reserves`                    | Tokens held by contract or user                   |
| `shares`, `debt`, `collateral`             | Accounting for deposits or loans                  |
| `treasury`, `vault`                        | Central storage of pooled funds                   |
| `getReserves`, `totalSupply`, `totalBorrows`| State views of system balances                    |
| `mapping(address => uint)`                 | Tracks user balances internally                   |
| `address(0)`                               | Burn address (funds gone forever)                 |

## ⚠️ Red Flags / Dangerous Flows
| Keyword / Pattern                          | What it indicates                                  |
|--------------------------------------------|---------------------------------------------------|
| `call`, `delegatecall`, `staticcall`       | Low-level calls (check safety & return values)    |
| `selfdestruct`                             | Contract can delete itself and send funds out     |
| `tx.origin`                                | Bad auth pattern (phishable)                      |
| `unchecked { ... }`                        | Possible math errors or overflow/underflow        |
| External `transfer` before state update    | Reentrancy risk (check CEI pattern)               |
| `approve` without `0` reset                | ERC20 allowance double-spend issue                |

## 📝 Auditor Checklist (Funds)
| Question / Check                             | Why it matters                                    |
|----------------------------------------------|---------------------------------------------------|
| Where do funds `enter`?                      | Entry points must be validated/sanitized          |
| Where do funds `leave`?                      | Exit points must enforce permissions              |
| Who can `move` funds?                        | Role-based access (admin, owner, etc.)            |
| Can funds get `stuck`?                       | Check for no-withdraw scenarios                   |
| Can funds be `drained`?                      | Look at loops, reentrancy, external calls         |
| Is `accounting` consistent?                  | `totalSupply` matches sum of balances?            |
| Are `fees` transparent?                      | No hidden tax/stealth transfer logic              |
| What happens on `upgrade/selfdestruct`?      | Proxy or destruct draining risks                  |

## 🔄 Moneyflow Tracing Workflow
| Step                                       | What to do                                        |
|--------------------------------------------|---------------------------------------------------|
| 1. Identify entry points                   | Look for `deposit`, `payable`, `stake`            |
| 2. Trace storage                           | Where are balances stored? (`mapping`, `reserves`)|
| 3. Follow updates                          | Who updates them? (`_mint`, `_burn`, `shares`)    |
| 4. Identify exit points                    | Where funds can leave (`withdraw`, `transfer`)    |
| 5. Check permissions                       | Who is allowed to call those exits?               |
| 6. Look for external calls                 | Any `call`, `delegatecall`, `send`? Risks here    |
| 7. Verify accounting                       | Does `totalSupply` match balances?                |
| 8. Stress test scenarios                   | What if attacker calls multiple times / reenters? |

## 💡 Extra Auditor Tips
| Tip                                        | Why it matters                                    |
|--------------------------------------------|---------------------------------------------------|
| Always map “money in” vs “money out”       | Clear picture of flow                             |
| Draw balance flow diagrams                 | Helps visualize deposits → storage → exits        |
| Check events (`emit`)                      | They show when transfers happen                   |
| Compare `require` / `assert` to flow       | Make sure checks protect money                    |
| Check fallback/receive functions           | Hidden ETH flows often live here                  |
| Always ask “who benefits?”                 | Useful for spotting hidden fees or drains         |
| Search for owner-only functions            | Admins may have backdoors                        |
| Read constructor/init logic                | Funds can be set/trapped from start               |

## 🛑 Attack Scenarios (Money Drains)
| Attack Scenario                            | What to look for                                  |
|--------------------------------------------|---------------------------------------------------|
| Reentrancy                                 | External call before balances update (missing CEI)|
| Flashloan Drain                            | No slippage / price checks in swaps               |
| Approval Race                              | `approve` changed directly without 0 reset        |
| Infinite Mint / Burn                       | Bad `_mint` or `_burn` checks                     |
| Reward/Interest Inflation                  | Rewards not capped by supply or reserves          |
| Unbounded Loop with Transfers              | Gas griefing → funds locked if too many users     |
| Fee-on-Transfer Tokens                     | Balances reduced silently on transfer             |
| Malicious Token Callback                   | ERC777 hooks / reentering via `tokensReceived`    |
| Selfdestruct Drain                         | Contract can delete itself, send ETH elsewhere    |
| Oracle Manipulation                        | Price based on low-liquidity pool                 |

## 🔓 Attack Scenarios (Funds Stuck)
| Attack Scenario                            | What to look for                                  |
|--------------------------------------------|---------------------------------------------------|
| No Withdraw Function                       | Users can deposit but not withdraw                |
| Wrong Math in Shares                       | Shares don’t map 1:1 to deposited funds           |
| Only Owner Can Withdraw                    | Admin-only exit of funds                          |
| No Fallback for ETH                        | ETH sent directly gets stuck                      |
| Pausable Without Resume                    | Contract locked forever if `unpause` missing      |
| Rounding Errors                            | Tiny amounts stuck in contract                    |
| Transfer Fail Without Handling             | `require(transfer())` missing → funds trapped     |

## 🕵️ Attack Scenarios (Hidden Fees & Backdoors)
| Attack Scenario                            | What to look for                                  |
|--------------------------------------------|---------------------------------------------------|
| Hidden Transfer Tax                        | Transfers deduct % silently                       |
| Skim Function                              | Owner can sweep tokens from contract              |
| Upgradeable Proxy Abuse                    | Admin can replace logic with malicious one        |
| Emergency Withdraw Without Checks          | Admin can drain pool instantly                    |
| Whitelist / Blacklist Abuse                | Certain addresses get special treatment           |
| Hardcoded Owner                            | Single address has permanent control              |
| Unlimited Mint Authority                   | Owner can mint infinite tokens                    |







