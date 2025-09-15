# Pool Contract - Core Functions Summary

`//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`
### `deposit`(address `asset`, uint256 `amount`, address `onBehalfOf`, uint16 `referralCode`) external  
Allows depositing an asset into the pool.

- **Reads:**  
  - `_reserves`  
  - `_reservesList`  
  - `_usersConfig[onBehalfOf]`  
- **Internal calls:**  
  - `SupplyLogic.executeSupply(...)`  
- **Reverts on:**  
- **External calls:**  
- **Chain:** 
- `executeSupply`  -> `validateSupply` ->  `validateAutomaticUseAsCollateral` -> `updateState`  -> `updateInterestRates`   -> `setUsingAsCollateral` -> `safeTransferFrom`   -> `mint`
- 

`//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`
####  Function: `executeSupply`

- **Reads:**  
  - `_reserves`  
  - `_reservesList`  
  - `_usersConfig[onBehalfOf]`  
- **Internal calls:**  
  - `ValidationLogic.validateSupply(...)`  
  - `ValidationLogic.validateAutomaticUseAsCollateral(...)`  
  - `reserve.updateState(...)`  
  - `reserve.updateInterestRates(...)`  
  - `userConfig.setUsingAsCollateral(...)`  
- **External calls:**  
  - `IERC20(params.asset).safeTransferFrom(msg.sender, reserveCache.aTokenAddress, params.amount)`  
  - `IAToken(reserveCache.aTokenAddress).mint(msg.sender, params.onBehalfOf, params.amount, reserveCache.nextLiquidityIndex)`  
- **Reverts on:**  
  - Validation failures  
  - TransferFrom failure  
  - Mint failure 





`//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`
`//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////`
### `Withdraw`


### initReserve(address asset, address aTokenAddress, address stableDebtAddress, address variableDebtAddress, address interestRateStrategyAddress) external onlyPoolConfigurator  
Initializes a new reserve in the pool.

- **Modifiers:** `onlyPoolConfigurator` (restricted access)  
- **Reads:**  
  - `_reserves`  
  - `_reservesCount`  
  - `MAX_NUMBER_RESERVES`  
  - `_reservesList`  
- **Writes:**  
- **Internal calls:**  
  - `PoolLogic.executeInitReserve(...)` with reserve parameters and current state  
- **Reverts on:**  
- **External calls:**  

---

### dropReserve(address asset) external onlyPoolConfigurator  
Removes a reserve from the pool.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
  - `_reserves`  
  - `_reservesList`  
- **Writes:**  
- **Internal calls:**  
  - `PoolLogic.executeDropReserve(...)`  
- **Reverts on:**  
- **External calls:**  

---

### setReserveInterestRateStrategyAddress(address asset, address strategyAddress) external onlyPoolConfigurator  
Updates the interest rate strategy for a reserve.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
  - `_reserves`  
  - `_reservesList`  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:** Uses require statements to ensure validity  
- **External calls:**  

---

### setConfiguration(address asset, DataTypes.ReserveConfigurationMap memory configuration) external onlyPoolConfigurator  
Sets the configuration parameters for a reserve.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
  - `_reserves`  
  - `_reservesList`  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:** Validity checks with require  
- **External calls:**  

---

### updateBridgeProtocolFee(uint256 fee) external onlyPoolConfigurator  
Updates the protocol fee taken from bridging operations.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:**  
- **External calls:**  

---

### updateFlashloanPremiums(uint128 premiumTotal, uint128 premiumToProtocol) external onlyPoolConfigurator  
Updates flashloan premium fees.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:**  
- **External calls:**  

---

### configureEModeCategory(uint8 id, DataTypes.EModeCategory memory category) external onlyPoolConfigurator  
Configures an E-Mode category.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:** Validity require checks  
- **External calls:**  

---

### getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory)  
Returns data for a specific E-Mode category.

- **Reads:**  
  - `_eModeCategories`  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:**  
- **External calls:**  

---

### setUserEMode(uint8 categoryId) external  
Sets the E-Mode category for the calling user.

- **Reads:**  
  - `_reservesCount`  
  - `_reservesList`  
  - `_eModeCategories`  
  - `_usersEModeCategory`  
  - `_usersConfig[msg.sender]`  
  - Oracle from `ADDRESSES_PROVIDER.getPriceOracle()`  
- **Internal calls:**  
  - `EModeLogic.executeSetUserEMode(...)`  
- **Reverts on:**  
- **External calls:**  

---

### getUserEMode(address user) external view returns (uint8)  
Returns the E-Mode category of a user.

- **Reads:**  
  - `_usersEModeCategory`  
- **Writes:**  
- **Internal calls:**  
- **Reverts on:**  
- **External calls:**  

---

### resetIsolationModeTotalDebt(address asset) external onlyPoolConfigurator  
Resets total debt under isolation mode for a given asset.

- **Modifiers:** `onlyPoolConfigurator`  
- **Reads:**  
  - `_reserves`  
- **Writes:**  
- **Internal calls:**  
  - `PoolLogic.executeResetIsolationModeTotalDebt(...)`  
- **Reverts on:**  
- **External calls:**  

---

### rescueTokens(address token, address to, uint256 amount) external onlyPoolAdmin  
Allows admin to rescue tokens mistakenly sent to the pool.

- **Modifiers:** `onlyPoolAdmin`  
- **Reads:**  
- **Writes:**  
- **Internal calls:**  
  - `PoolLogic.executeRescueTokens(...)`  
- **Reverts on:**  
- **External calls:**  

---


---

### Modifiers Summary

| Modifier         | Description                 | Access Control                |
|------------------|-----------------------------|------------------------------|
| `initializer()`  | Prevents reinitialization   | Internal                     |
| `onlyPoolConfigurator()` | Restricts to configurator role | Internal                     |
| `onlyPoolAdmin()` | Restricts to admin role     | Internal                     |
| `onlyBridge()`    | Restricts to bridge role    | Internal                     |

---

*Notes:*  
- Functions mostly protected by role-based access controls (`onlyPoolConfigurator`, `onlyPoolAdmin`).  
- Core logic is delegated to external logic libraries (`PoolLogic`, `SupplyLogic`, `EModeLogic`) to keep code modular.  
- Safety checks (e.g., require) are used before applying critical changes.  
- Rescue and configuration functions help maintain pool health and flexibility.  

### flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external  
Executes a simple flash loan.

- **Reads:**  
  - `_flashLoanPremiumTotal`  
  - `_flashLoanPremiumToProtocol`  
  - `_reserves[asset]`  
- **Writes:** None  
- **Internal calls:**  
  - `FlashLoanLogic.executeFlashLoanSimple(...)` with structured params  
- **Access control:** Public/external  
- **Reverts on:** Flash loan preconditions/failures inside logic

---

### mintToTreasury(address[] calldata assets) external  
Mints accrued fees to the treasury for given assets.

- **Reads:**  
  - `_reserves`  
- **Writes:** None  
- **Internal calls:**  
  - `PoolLogic.executeMintToTreasury(...)`  
- **Access control:** External, likely restricted by modifiers (not shown here)  
- **Reverts on:** Logic internal errors

---

### getReserveData(address asset) external view returns (ReserveData)  
Returns reserve data for the given asset.

- **Reads:**  
  - `_reserves[asset]`  
- **Writes:** None  
- **Internal calls:** None  
- **Access control:** View function (read-only)

---

### getUserAccountData(address user) external view returns (UserAccountData)  
Returns comprehensive user data including collateral, debt, and health factor.

- **Reads:**  
  - `_usersConfig[user]`  
  - `_reservesCount`  
  - `_usersEModeCategory[user]`  
  - Oracle from `ADDRESSES_PROVIDER.getPriceOracle()`  
- **Internal calls:**  
  - `PoolLogic.executeGetUserAccountData(...)`  
- **Access control:** View function

---

### getConfiguration(address asset) external view returns (ReserveConfigurationMap)  
Returns the configuration of a reserve.

- **Reads:**  
  - `_reserves[asset]`  
- **Writes:** None  
- **Access control:** View

---

### getUserConfiguration(address user) external view returns (UserConfigurationMap)  
Returns the configuration of a user’s account.

- **Reads:**  
  - `_usersConfig[user]`  
- **Writes:** None  
- **Access control:** View

---

### getReserveNormalizedIncome(address asset) external view returns (uint256)  
Returns the normalized income of a reserve (index reflecting interest accrued).

- **Reads:**  
  - `_reserves[asset]`  
- **Access control:** View

---

### getReserveNormalizedDebt(address asset) external view returns (uint256)  
Returns the normalized variable debt of a reserve.

- **Reads:**  
  - `_reserves[asset]`  
- **Access control:** View

---

### getReservesList() external view returns (address[])  
Returns the list of all reserve assets currently in the pool.

- **Reads:**  
  - `_reservesCount`  
  - `_reservesList`  
- **Writes:** None  
- **Access control:** View

---

### getReserveAddressById(uint16 id) external view returns (address)  
Returns the reserve asset address by its ID.

- **Reads:**  
  - `_reservesList[id]`  
- **Access control:** View

---

### finalizeTransfer(address asset, address from, address to, uint256 amount, uint256 balanceFromBefore, uint256 balanceToBefore, int256 balanceToAfter) external  
Finalizes the transfer of tokens between users, updating accounting and validating.

- **Reads:**  
  - `_reserves`  
  - `_reservesCount`  
  - `_usersConfig`  
  - `_eModeCategories`  
  - Oracle from `ADDRESSES_PROVIDER.getPriceOracle()`  
  - `_usersEModeCategory[from]`  
- **Internal calls:**  
  - `SupplyLogic.executeFinalizeTransfer(...)`  
- **Access control:** External, likely restricted  
- **Reverts on:** Validation failures in internal logic

---

### Constants / Storage Variables of Note

| Variable                  | Description                                      |
|---------------------------|------------------------------------------------|
| `_maxStableRateBorrowSizePercent` | Max size percent for stable rate borrowing  |
| `_bridgeProtocolFee`       | Fee applied to bridge protocol operations      |
| `_flashLoanPremiumTotal`  | Total premium fee for flash loans                |
| `_flashLoanPremiumToProtocol` | Portion of flash loan fee going to protocol treasury |
| `MAX_NUMBER_RESERVES`     | Maximum number of reserves supported             |

---

### Summary Notes

- Flash loan logic is encapsulated in `FlashLoanLogic.executeFlashLoanSimple` using detailed parameter struct.  
- Treasury minting helps protocol accrue fees.  
- User and reserve data fetching functions are read-only and provide important state info for frontend and internal checks.  
- Transfer finalization involves updating user balances and validating with oracle and mode data.  
- Many internal calls delegate to specialized logic libraries, improving modularity and testability.  
- Access control mostly enforced via modifiers (not fully shown here) to protect sensitive state changes.  

---

---

### getUserAccountData(address user) external view returns (UserAccountData)  
- **Reads:**  
  - `_usersConfig[user]` (user's reserve usage config)  
  - `_reservesCount` (total reserves count)  
  - `_reservesList` (list of reserve addresses)  
  - `_eModeCategories` (eMode category configs)  
  - `_usersEModeCategory[user]` (user’s selected eMode)  
  - Oracle from `ADDRESSES_PROVIDER.getPriceOracle()`  
- **Internal calls:**  
  - `PoolLogic.executeGetUserAccountData(...)` with above data wrapped in a struct  
- **Writes:** None (view function)  

---

### getConfiguration(address asset) external view returns (ReserveConfigurationMap)  
- **Reads:**  
  - `_reserves[asset]` (reserve struct)  
- **Writes:** None  

---

### getUserConfiguration(address user) external view returns (UserConfigurationMap)  
- **Reads:**  
  - `_usersConfig[user]` (user’s reserve usage map)  
- **Writes:** None  

---

### getReserveNormalizedIncome(address asset) external view returns (uint256)  
- **Reads:**  
  - `_reserves[asset].getNormalizedIncome()` (interest index reflecting accrued interest)  
- **Writes:** None  

---

### getReserveNormalizedDebt(address asset) external view returns (uint256)  
- **Reads:**  
  - `_reserves[asset].getNormalizedDebt()` (normalized variable debt index)  
- **Writes:** None  

---

### getReservesList() external view returns (address[])  
- **Reads:**  
  - `_reservesCount`  
  - `_reservesList` (list of reserve asset addresses)  
- **Writes:** None  

---

### getReserveAddressById(uint16 id) external view returns (address)  
- **Reads:**  
  - `_reservesList[id]`  
- **Writes:** None  

---

### finalizeTransfer(address asset, address from, address to, uint256 amount, uint256 balanceFromBefore, uint256 balanceToBefore, int256 balanceToAfter) external  
- **Reads:**  
  - `_reserves`  
  - `_reservesCount`  
  - `_usersConfig`  
  - `_eModeCategories`  
  - Oracle from `ADDRESSES_PROVIDER.getPriceOracle()`  
  - `_usersEModeCategory[from]`  
- **Internal calls:**  
  - `SupplyLogic.executeFinalizeTransfer(...)` which updates balances and validates transfer rules  
- **Writes:** State updated inside `SupplyLogic` (balances, config)  
- **Access control:** Typically only called internally or via authorized contracts  

---

### Constants / Variables Used  
- `_maxStableRateBorrowSizePercent`  
- `_bridgeProtocolFee`  
- `_flashLoanPremiumTotal`  
- `_flashLoanPremiumToProtocol`  
- `MAX_NUMBER_RESERVES`  

---

**Summary:**  
- The getters mostly read reserve/user config and oracle data, then call specialized logic to compute or return data.  
- `finalizeTransfer` is a key state-changing function that adjusts balances and validates transfers.  
- Oracle price data and eMode categories are frequently used to calculate health factors and validate actions.  