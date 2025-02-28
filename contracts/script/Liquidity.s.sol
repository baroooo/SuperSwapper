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

  function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Liquidity is Script {
  string[] private rpcUrls = ['http://localhost:9545', 'http://localhost:9546'];

  // Uniswap V2 Factory on Ethereum mainnet
  mapping(uint256 => address) public uniswapV2Factories;
  mapping(uint256 => address) public uniswapV2Routers;
  mapping(uint256 => address) public wethAddresses;

  // Replace these with your actual token addresses
  address public tokenA = 0xB53955FfEEeC4845CCc045e94b940DE62FB190AE; // Our SuperchainERC20 token

  // Liquidity amounts
  uint256 public amountA = 1000 * 10 ** 18; // 1000 tokens with 18 decimals
  uint256 public amountB = 1 * 10 ** 18; // 1 WETH or equivalent

  // Flag to determine if we should get WETH first
  bool public getWethFirst = true;

  function run() public {
    uniswapV2Factories[10] = 0x0c3c1c532F1e39EdF36BE9Fe0bE1410313E074Bf;
    uniswapV2Factories[8453] = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    uniswapV2Routers[10] = 0x4A7b5Da61326A6379179b40d00F57E5bbDC962c2;
    uniswapV2Routers[8453] = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    wethAddresses[10] = 0x4200000000000000000000000000000000000006; // OP Mainnet WETH
    wethAddresses[8453] = 0x4200000000000000000000000000000000000006; // Base WETH

    for (uint256 i = 0; i < rpcUrls.length; i++) {
      string memory rpcUrl = rpcUrls[i];

      vm.createSelectFork(rpcUrl);
      address ROUTER = uniswapV2Routers[block.chainid];
      address FACTORY = uniswapV2Factories[block.chainid];
      address WETH = wethAddresses[block.chainid];
      address tokenB = WETH; // Use WETH as tokenB

      vm.startBroadcast();

      // Get WETH first if needed
      if (getWethFirst) {
        console.log('Getting WETH by wrapping ETH');
        IWETH(WETH).deposit{ value: amountB }();
        console.log('WETH Balance after wrapping:', IERC20(WETH).balanceOf(address(this)));
      }

      // Approve tokens to router
      IERC20(tokenA).approve(ROUTER, amountA);
      IERC20(tokenB).approve(ROUTER, amountB);

      // Check if pair exists
      address pair = IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);
      if (pair == address(0)) {
        console.log('Creating new pair for', tokenA, 'and', tokenB);
        pair = IUniswapV2Factory(FACTORY).createPair(tokenA, tokenB);
      }

      // Calculate minimum amounts (usually a percentage of desired amounts, e.g., 95%)
      uint amountAMin = (amountA * 95) / 100;
      uint amountBMin = (amountB * 95) / 100;

      console.log('Balance of tokenA:', IERC20(tokenA).balanceOf(msg.sender));
      console.log('Balance of tokenB:', IERC20(tokenB).balanceOf(msg.sender));

      console.log('Adding liquidity for pair:', pair);
      console.log('Token A:', tokenA, 'Amount:', amountA);
      console.log('Token B:', tokenB, 'Amount:', amountB);

      // Add liquidity
      (uint amountAAdded, uint amountBAdded, uint liquidity) = IUniswapV2Router02(ROUTER)
        .addLiquidity(
          tokenA,
          tokenB,
          amountA,
          amountB,
          amountAMin,
          amountBMin,
          address(this), // LP tokens will be sent to the contract
          block.timestamp + 15 minutes // Deadline: 15 minutes from now
        );

      console.log('Liquidity added successfully:');
      console.log('Token A added:', amountAAdded);
      console.log('Token B added:', amountBAdded);
      console.log('LP tokens received:', liquidity);
      vm.stopBroadcast();
    }
  }
}
