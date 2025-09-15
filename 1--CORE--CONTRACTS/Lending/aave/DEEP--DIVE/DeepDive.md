# Aave Core Contracts Overview

## Pool
- Main user entry point for core actions:  
  - `deposit()`  
  - `borrow()`  
  - `repay()`  
  - `withdraw()`  

## PoolConfigurator
- Admin-only functions to configure protocol parameters:  
  - Risk parameters (e.g., LTV, liquidation thresholds)  
  - Reserves management (enable/disable assets)  

## aTokens
- Interest-bearing tokens representing user deposits:  
  - Rebasing balance to reflect yield  
  - Transferable and tradable deposit receipts  

## DebtTokens
- Track user debt positions:  
  - Stable and variable rate debts  
  - Manage borrow allowances and delegation  

## ReserveLogic
- Core accounting for reserves:  
  - Update liquidity indices  
  - Calculate interest and fees  

## ValidationLogic
- Safety checks and validations:  
  - Borrow limits  
  - Liquidation conditions  
  - Collateral usage  

## PriceOracle
- Provides asset price feeds:  
  - Used for health factor and liquidation calculations  
  - Supports fallback oracles for reliability  