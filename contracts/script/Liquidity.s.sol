// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from 'forge-std/Script.sol';
import 'forge-std/console.sol';
interface IERC20 {
  function transfer(address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

// WETH interface
interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
  function balanceOf(address account) external view returns (uint256);
}

// Uniswap V2 interfaces
interface IUniswapV2Router02 {
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function getAmountsOut(
    uint amountIn,
    address[] calldata path
  ) external view returns (uint[] memory amounts);

  function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Liquidity is Script {
  string[] private rpcUrls = [
    'http://localhost:9545',
    'http://localhost:9546',
    'http://localhost:9547',
    'http://localhost:9548'
  ];

  // Uniswap V2 Factory on Ethereum mainnet
  mapping(uint256 => address) public uniswapV2Factories;
  mapping(uint256 => address) public uniswapV2Routers;
  mapping(uint256 => address) public wethAddresses;

  // Replace these with your actual token addresses
  address public tokenA;

  // Liquidity amounts

  mapping(uint256 => uint256) public amountA;
  mapping(uint256 => uint256) public amountB;

  // Swap amounts
  uint256 public swapAmountIn = 1 * 10 ** 18; // Only 0.01 token to swap (0.001% of pool)
  uint256 public slippageTolerance = 95; // 95% slippage tolerance for testing
  bool public performSwap = false; // Flag to determine if we should perform a swap
  bool public swapTokenAForTokenB = true; // Direction of swap (true = A→B, false = B→A)

  // Flag to determine if we should get WETH first
  bool public getWethFirst = true;

  function run() public {
    uniswapV2Factories[10] = 0x0c3c1c532F1e39EdF36BE9Fe0bE1410313E074Bf;
    uniswapV2Factories[8453] = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    uniswapV2Factories[34443] = 0x50fD14F0eba5A678c1eBC16bDd3794f09362a95C;
    uniswapV2Factories[130] = 0x1F98400000000000000000000000000000000002;
    uniswapV2Routers[10] = 0x4A7b5Da61326A6379179b40d00F57E5bbDC962c2;
    uniswapV2Routers[8453] = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    uniswapV2Routers[34443] = 0x28108b86bb717A3557fb5d4A05A9249333dd7c96;
    uniswapV2Routers[130] = 0x284F11109359a7e1306C3e447ef14D38400063FF;
    wethAddresses[10] = 0x4200000000000000000000000000000000000024; // OP Mainnet WETH
    wethAddresses[8453] = 0x4200000000000000000000000000000000000024; // Base WETH
    wethAddresses[34443] = 0x4200000000000000000000000000000000000024; // Mode WETH
    wethAddresses[130] = 0x4200000000000000000000000000000000000024; // Unichain WETH

    amountA[10] = 12000 * 10 ** 18; // 10000 tokens with 18 decimals on OP
    amountB[10] = 12 * 10 ** 18; // 10 WETH or equivalent on OP

    amountA[8453] = 20000 * 10 ** 18; // 10000 tokens with 18 decimals on BASE
    amountB[8453] = 20 * 10 ** 18; // 10 WETH or equivalent on BASE

    amountA[130] = 10000 * 10 ** 18; // 10000 tokens with 18 decimals on UNICHAIN
    amountB[130] = 10 * 10 ** 18; // 10 WETH or equivalent on UNICHAIN

    amountA[34443] = 11000 * 10 ** 18; // 10000 tokens with 18 decimals on MODE
    amountB[34443] = 10 * 10 ** 18; // 10 WETH or equivalent on MODE

    tokenA = vm.envAddress('SUPERTOKEN9000_ADDRESS');

    for (uint256 i = 0; i < rpcUrls.length; i++) {
      string memory rpcUrl = rpcUrls[i];

      console.log('--------------------------------');
      console.log('Starting script for chainId:', block.chainid);
      vm.createSelectFork(rpcUrl);
      address ROUTER = uniswapV2Routers[block.chainid];
      address FACTORY = uniswapV2Factories[block.chainid];
      address WETH = wethAddresses[block.chainid];
      address tokenB = WETH; // Use WETH as tokenB

      vm.startBroadcast();

      // Get WETH first if needed
      if (getWethFirst) {
        console.log('Getting WETH by wrapping ETH');
        IWETH(WETH).deposit{ value: amountB[block.chainid] }();
        console.log('WETH Balance after wrapping:', IERC20(WETH).balanceOf(msg.sender));
      }

      // Approve tokens to router
      IERC20(tokenA).approve(ROUTER, amountA[block.chainid] + swapAmountIn);
      IERC20(tokenB).approve(ROUTER, amountB[block.chainid] + swapAmountIn);

      // Check if pair exists
      address pair = IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);
      if (pair == address(0)) {
        console.log('Creating new pair for', tokenA, 'and', tokenB);
        pair = IUniswapV2Factory(FACTORY).createPair(tokenA, tokenB);
      }

      // Calculate minimum amounts (usually a percentage of desired amounts, e.g., 95%)
      uint amountAMin = (amountA[block.chainid] * 95) / 100;
      uint amountBMin = (amountB[block.chainid] * 95) / 100;

      console.log('Balance of tokenA:', IERC20(tokenA).balanceOf(msg.sender));
      console.log('Balance of tokenB:', IERC20(tokenB).balanceOf(msg.sender));

      console.log('Adding liquidity for pair:', pair);
      console.log('Token A:', tokenA, 'Amount:', amountA[block.chainid]);
      console.log('Token B:', tokenB, 'Amount:', amountB[block.chainid]);

      // deploying more capital steady lads
      (uint amountAAdded, uint amountBAdded, uint liquidity) = IUniswapV2Router02(ROUTER)
        .addLiquidity(
          tokenA,
          tokenB,
          amountA[block.chainid],
          amountB[block.chainid],
          amountAMin,
          amountBMin,
          msg.sender, // LP tokens will be sent to the contract
          block.timestamp + 15 minutes // Deadline: 15 minutes from now
        );

      console.log('Liquidity added successfully:');
      console.log('Token A added:', amountAAdded);
      console.log('Token B added:', amountBAdded);
      console.log('LP tokens received:', liquidity);

      // Perform token swap if enabled
      if (performSwap) {
        console.log('Performing token swap...');

        // Check if we have enough token balance for the swap
        if (swapTokenAForTokenB) {
          uint256 tokenABalance = IERC20(tokenA).balanceOf(msg.sender);
          console.log('Available tokenA balance for swap:', tokenABalance);
          if (tokenABalance < swapAmountIn) {
            console.log('Not enough tokenA balance for swap. Skipping swap.');
            vm.stopBroadcast();
            continue;
          }
        } else {
          uint256 tokenBBalance = IERC20(tokenB).balanceOf(msg.sender);
          console.log('Available tokenB balance for swap:', tokenBBalance);
          if (tokenBBalance < swapAmountIn) {
            console.log('Not enough tokenB balance for swap. Skipping swap.');
            vm.stopBroadcast();
            continue;
          }
        }

        // Set up the swap path
        address[] memory path = new address[](2);

        if (swapTokenAForTokenB) {
          // Swap tokenA for tokenB
          path[0] = tokenA;
          path[1] = tokenB;

          console.log('Swapping %s tokenA for tokenB', swapAmountIn);

          // Get expected output amount from router
          uint[] memory expectedAmounts;
          try IUniswapV2Router02(ROUTER).getAmountsOut(swapAmountIn, path) returns (
            uint[] memory amounts
          ) {
            expectedAmounts = amounts;
            console.log('Expected output of tokenB:', expectedAmounts[1]);
          } catch {
            console.log('Failed to get expected amounts. Using default calculation.');
            expectedAmounts = new uint[](2);
            expectedAmounts[0] = swapAmountIn;
            expectedAmounts[1] = (swapAmountIn * 9) / 10000; // Conservative estimate
          }

          // Calculate minimum output amount based on slippage tolerance
          uint amountOutMin = (expectedAmounts[1] * (100 - slippageTolerance)) / 100;
          console.log('Minimum output amount (tokenB):', amountOutMin);

          // Execute the swap with minimal slippage protection
          uint[] memory amounts = IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
            swapAmountIn,
            1, // Use minimal slippage protection
            path,
            msg.sender,
            block.timestamp + 15 minutes
          );

          console.log('Swap executed successfully:');
          console.log('Input amount of tokenA:', amounts[0]);
          console.log('Output amount of tokenB:', amounts[1]);
        } else {
          // Swap tokenB for tokenA
          path[0] = tokenB;
          path[1] = tokenA;

          console.log('Swapping %s tokenB for tokenA', swapAmountIn);

          // Get expected output amount from router
          uint[] memory expectedAmounts;
          try IUniswapV2Router02(ROUTER).getAmountsOut(swapAmountIn, path) returns (
            uint[] memory amounts
          ) {
            expectedAmounts = amounts;
            console.log('Expected output of tokenA:', expectedAmounts[1]);
          } catch {
            console.log('Failed to get expected amounts. Using default calculation.');
            expectedAmounts = new uint[](2);
            expectedAmounts[0] = swapAmountIn;
            expectedAmounts[1] = (swapAmountIn * 9) / 10; // Conservative estimate
          }

          // Calculate minimum output amount based on slippage tolerance
          uint amountOutMin = (expectedAmounts[1] * (100 - slippageTolerance)) / 100;
          console.log('Minimum output amount (tokenA):', amountOutMin);

          // Execute the swap with minimal slippage protection
          uint[] memory amounts = IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
            swapAmountIn,
            1, // Use minimal slippage protection
            path,
            msg.sender,
            block.timestamp + 15 minutes
          );

          console.log('Swap executed successfully:');
          console.log('Input amount of tokenB:', amounts[0]);
          console.log('Output amount of tokenA:', amounts[1]);
        }

        // Log updated balances after swap
        console.log('Updated balance of tokenA:', IERC20(tokenA).balanceOf(msg.sender));
        console.log('Updated balance of tokenB:', IERC20(tokenB).balanceOf(msg.sender));
      }

      vm.stopBroadcast();
    }
  }
}
