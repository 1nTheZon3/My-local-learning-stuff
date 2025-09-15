 **Uniswap V3 Variables** (Time-Weighted Observations)
UniswapV3Pool.`slot0` - struct - Stores key state: sqrtPriceX96, tick, feeProtocol, etc.
UniswapV3Pool.`observations` - mapping(uint256 => Observation) - Stores price/liq data points for TWAPs
UniswapV3Pool.`observationCardinality` - uint16 - Current number of stored observations
UniswapV3Pool.`observationCardinalityNext` - uint16 - Next desired number of observations (can grow)
UniswapV3Pool.`observationIndex` - uint16 - Index of the most recent observation

**tick-flip**
If liquidity is added at tick #5 → flip bit #5:
bitmap = 0010`1`000

**zero-to-one**
You are selling token0 to get token1.
`More token0 in the pool` → `token0 price goes down `
According to the AMM formula (x * y = k), this reduces the price of token0 in terms of token1.

## observation

🧸 `Imagine a notebook`
- Every time someone trades on Uniswap, the pool writes down the price in its notebook.
- Each line in the notebook = an observation.

📖 `What’s inside one line (observation)?`
- What time it was (block timestamp ⏰)
- What the price was (tick cumulative 📈)
- How much liquidity there was (liquidity cumulative 💧)
- So each “observation” = a snapshot of pool history.

🔄 `What about the confusing variables?`
`observationCardinality` → how many notebook pages are actually usable right now.
`observationCardinalityNext` → how many pages the notebook will grow to next time (bigger notebook → longer history).
`observationIndex` → which page we wrote on last.
`observations` → the whole notebook (all the pages).

📊 `Why do we care?`
Uniswap doesn’t want to trust just today’s price (could be manipulated).
So it looks at the notebook → average of prices across many pages (blocks).
That’s how it builds a TWAP (time-weighted average price) that’s safer.

**`TWAP`**
- Every few blocks, Uniswap writes down a snapshot = an observation (time + price + liquidity).
- Later, when someone asks: “What’s the average price over the last X seconds?” →
- Uniswap looks at two observations (start + end), subtracts them, and divides by the time difference.
- That calculation = the TWAP.