// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import { console2 } from 'forge-std/console2.sol';
import { SuperSwapper } from '../src/SuperSwapper.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function token0() external view returns (address);
  function token1() external view returns (address);
}

contract LogState is Script {
  address public SUPERTOKEN9000;
  address public constant SUPERWETH = 0x4200000000000000000000000000000000000024;
  address public SUPERSWAPPER_ADDRESS;
  address public constant trader = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  address public constant UNISwapBase = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
  mapping(uint256 => address) public uniswapV2Factories;

  string[] private rpcs = [
    'http://localhost:9545',
    'http://localhost:9546',
    'http://localhost:9547',
    'http://localhost:9548'
  ];

  function run() external {
    SUPERTOKEN9000 = vm.envAddress('SUPERTOKEN9000_ADDRESS');
    SUPERSWAPPER_ADDRESS = vm.envAddress('SUPERSWAPPER_ADDRESS');

    uniswapV2Factories[10] = 0x0c3c1c532F1e39EdF36BE9Fe0bE1410313E074Bf;
    uniswapV2Factories[8453] = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    uniswapV2Factories[34443] = 0x50fD14F0eba5A678c1eBC16bDd3794f09362a95C;
    uniswapV2Factories[130] = 0x1F98400000000000000000000000000000000002;

    prettyBalances();
    console.log("\n\n");
    prettyBuckets();
  }

  function prettyBalances() public {
    console2.log('=================================================== Balances ====================================================');
    console2.log('Chain\t\t\t\t\tST9000\t\t\t\t\t\t\tWETH\n');
    for (uint256 i = 0; i < rpcs.length; i++) {
      vm.createSelectFork(rpcs[i]);
      console2.log('%s\t\t\t\t%d\t\t\t\t%d', chainIdToName(block.chainid), 
        IERC20(SUPERTOKEN9000).balanceOf(trader),
        IERC20(SUPERWETH).balanceOf(trader)
      );
    }
  }

  function prettyBuckets() public {
    console2.log('============================================= Uniswap Reserves ==================================================');
    console2.log('Chain\t\t\t\t\tST9000\t\t\t\t\t\t\tWETH\n');
    for (uint256 i = 0; i < rpcs.length; i++) {
      vm.createSelectFork(rpcs[i]);
      address factory = uniswapV2Factories[block.chainid];
      address pair = IUniswapV2Factory(factory).getPair(SUPERTOKEN9000, SUPERWETH);
      (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();

      console2.log('%s\t\t\t\t%d\t\t\t\t\t%d', chainIdToName(block.chainid),
        reserve1,
        reserve0
      );
    }
  }

  function chainIdToName(uint256 chainId) public pure returns (string memory) {
    if (chainId == 10) return 'OP      ';
    if (chainId == 8453) return 'BASE    ';
    if (chainId == 130) return 'UNICHAIN';
    if (chainId == 34443) return 'MODE    ';
    return 'UNKNOWN';
  }
}