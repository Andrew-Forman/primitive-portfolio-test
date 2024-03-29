// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "portfolio/interfaces/IPortfolio.sol";
import "portfolio/interfaces/IERC20.sol";
import "solmate/tokens/ERC1155.sol";

contract DeallocateExample is ERC1155TokenReceiver {
    IPortfolio public portfolio;
    address public asset;
    address public quote;

    constructor(address portfolio_, address asset_, address quote_) {
        portfolio = IPortfolio(portfolio_);
        asset = asset_;
        quote = quote_;
    }

    function deallocate() external {
        // Assuming we want to allocate into the pool `4294967297`:
        uint64 poolId = 4294967297;

        // Let's check how many tokens we have.
        uint256 assetBalance = IERC20(asset).balanceOf(address(this));
        uint256 quoteBalance = IERC20(quote).balanceOf(address(this));

        // Now we check the maximum amount of liquidity we can get from our
        // current token balances.
        uint128 maxLiquidity =
            portfolio.getMaxLiquidity(poolId, assetBalance, quoteBalance);

        // Let's use this liquidity amount to get some more precise deltas.
        (uint128 deltaAsset, uint128 deltaQuote) =
            portfolio.getLiquidityDeltas(poolId, int128(maxLiquidity));

        // We allow the portfolio contract to move our tokens.
        IERC20(asset).approve(address(portfolio), deltaAsset);
        IERC20(quote).approve(address(portfolio), deltaQuote);

        // Finally, we call the `allocate` function.
        portfolio.allocate(
            false, address(this), poolId, maxLiquidity, deltaAsset, deltaQuote
        );

        // We can use the `balanceOf` function to check how much liquidity we
        // currently own.
        uint256 balance =
            ERC1155(address(portfolio)).balanceOf(address(this), poolId);

        // To avoid being sandwiched, we can check the minimum amount of
        // tokens that we can expect from our liquidity balance.
        // Note: Don't forget the "-" sign since we're deallocating!
        (uint128 minDeltaAsset, uint128 minDeltaQuote) =
            portfolio.getLiquidityDeltas(poolId, -int128(uint128(balance)));

        // We can now deallocate our liquidity:
        portfolio.deallocate(
            false, poolId, uint128(balance), minDeltaAsset, minDeltaQuote
        );
    }
}
