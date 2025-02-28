// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISuperchainTokenBridge } from '@interop-lib/interfaces/ISuperchainTokenBridge.sol';
import { IL2ToL2CrossDomainMessenger } from '@interop-lib/interfaces/IL2ToL2CrossDomainMessenger.sol';
import { CrossDomainMessageLib } from '@interop-lib/libraries/CrossDomainMessageLib.sol';
import { Ownable } from '@solady/auth/Ownable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IUniswapV2Router {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}
contract SuperSwapper is Ownable {
  address public uniswapV2Router;
  ISuperchainTokenBridge public constant bridge =
    ISuperchainTokenBridge(0x4200000000000000000000000000000000000028);
  IL2ToL2CrossDomainMessenger public constant messenger =
    IL2ToL2CrossDomainMessenger(0x4200000000000000000000000000000000000023);

  address public SUPERTOKEN9000;
  address public constant SUPERWETH = 0x4200000000000000000000000000000000000024;

  mapping(address => mapping(address => uint256)) public failedSwaps;

  // supported chainIds
  uint256[] public supportedChainIds;

  constructor(address owner_) Ownable() {
    _initializeOwner(owner_);
    IERC20(SUPERWETH).approve(address(bridge), type(uint256).max);

    supportedChainIds.push(10);
    supportedChainIds.push(8453);
    supportedChainIds.push(34443);
    supportedChainIds.push(130);
  }

  function setSuperToken9000(address superToken9000_) external onlyOwner {
    SUPERTOKEN9000 = superToken9000_;
    IERC20(superToken9000_).approve(address(bridge), type(uint256).max);
  }

  function setUniswapV2Router(address uniswapV2Router_) external onlyOwner {
    uniswapV2Router = uniswapV2Router_;
  }

  function getFailedSwaps(address user, address tokenIn) external view returns (uint256) {
    return failedSwaps[user][tokenIn];
  }

  function initiateSwap(
    address tokenIn,
    uint256[] memory amounts,
    uint256[] memory chainIds
  ) external {
    require(amounts.length == chainIds.length, 'Invalid input');
    require(amounts.length > 0, 'Invalid input');

    uint256 totalAmount = 0;
    for (uint256 i = 0; i < amounts.length; i++) {
      totalAmount += amounts[i];
    }

    IERC20(tokenIn).transferFrom(msg.sender, address(this), totalAmount);

    for (uint256 i = 0; i < amounts.length; i++) {
      uint256 amount = amounts[i];
      uint256 chainId = chainIds[i];

      if (chainId == block.chainid) {
        (address tokenOut, uint256 amountOut) = _executeSwap(tokenIn, amount);
        if (amountOut > 0) {
          IERC20(tokenOut).transfer(msg.sender, amountOut);
        } else {
          failedSwaps[msg.sender][tokenIn] += amount;
        }
      } else {
        bridge.sendERC20(tokenIn, address(this), amount, chainId);
        //   emit SwapInitiated(tokenIn, amount, chainId);
        messenger.sendMessage(
          chainId,
          address(this),
          abi.encodeWithSelector(
            SuperSwapper.relaySwap.selector,
            block.chainid,
            msg.sender,
            tokenIn,
            amount
          )
        );
      }
    }
  }
  function relaySwap(
    uint256 sourceChainId,
    address receiver,
    address tokenIn,
    uint256 amountIn
  ) external {
    CrossDomainMessageLib.requireCrossDomainCallback();
    (address tokenOut, uint256 amountOut) = _executeSwap(tokenIn, amountIn);

    if (amountOut > 0) {
      bridge.sendERC20(tokenOut, receiver, amountOut, sourceChainId);
    } else {
      failedSwaps[receiver][tokenIn] += amountIn;
    }
  }

  function _executeSwap(
    address tokenIn,
    uint256 amountIn
  ) internal returns (address tokenOut, uint256 amountOut) {
    IERC20(tokenIn).approve(address(uniswapV2Router), amountIn);

    tokenOut = tokenIn == SUPERTOKEN9000 ? SUPERWETH : SUPERTOKEN9000;
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;

    try
      IUniswapV2Router(uniswapV2Router).swapExactTokensForTokens(
        amountIn,
        0,
        path,
        address(this),
        block.timestamp + 1000
      )
    returns (uint256[] memory amounts) {
      amountOut = amounts[1];
    } catch (bytes memory reason) {}
  }

  function withdraw(address tokenIn) external {
    require(tokenIn == SUPERTOKEN9000 || tokenIn == SUPERWETH, 'Invalid token');

    uint256 amount = failedSwaps[msg.sender][tokenIn];

    if (amount > 0) {
      failedSwaps[msg.sender][tokenIn] = 0;
      IERC20(tokenIn).transfer(msg.sender, amount);
    }

    for (uint256 i = 0; i < supportedChainIds.length; i++) {
      uint256 chainId = supportedChainIds[i];
      if (chainId == block.chainid) {
        continue;
      }
      messenger.sendMessage(
        chainId,
        address(this),
        abi.encodeWithSelector(
          SuperSwapper.crossChainWithdraw.selector,
          block.chainid,
          msg.sender,
          tokenIn
        )
      );
    }
  }

  function crossChainWithdraw(uint256 chainId, address receiver, address tokenIn) external {
    CrossDomainMessageLib.requireCrossDomainCallback();
    uint256 amount = failedSwaps[receiver][tokenIn];
    require(amount > 0, 'No failed swaps');

    failedSwaps[receiver][tokenIn] = 0;

    bridge.sendERC20(tokenIn, receiver, amount, chainId);
  }
}
