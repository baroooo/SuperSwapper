// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import { SuperSwapper } from '../src/SuperSwapper.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
contract LogState is Script {
  address public constant SUPERTOKEN9000 = 0xf793A6B9587e09e6149Ea99Ed638DE0655CcfcB8;
  address public constant SUPERWETH = 0x4200000000000000000000000000000000000024;
  address public constant SUPERSWAPPER_ADDRESS = 0xe05ba9c8827072e1508099E1797BA84baC657012; // REPLACE WITH ACTUAL ADDRESS
  address public constant trader = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  address public constant UNISwapBase = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
  function run() external {
    console.log('Addresses');
    console.log('SuperSwapper address:', SUPERSWAPPER_ADDRESS);
    console.log('SuperToken9000 address:', SUPERTOKEN9000);
    console.log('SuperWETH address:', SUPERWETH);
    console.log('Trader address:', trader);
    console.log('================================================');

    vm.createSelectFork('http://localhost:9545');
    console.log('OP-State');
    console.log(
      'SuperSwapper balance in ST9000:',
      IERC20(SUPERTOKEN9000).balanceOf(SUPERSWAPPER_ADDRESS)
    );
    console.log('SuperSwapper balance in WETH:', IERC20(SUPERWETH).balanceOf(SUPERSWAPPER_ADDRESS));
    console.log('Trader balance in ST9000:', IERC20(SUPERTOKEN9000).balanceOf(trader));
    console.log('Trader balance in WETH:', IERC20(SUPERWETH).balanceOf(trader));
    console.log('================================================');

    vm.createSelectFork('http://localhost:9546');
    console.log('Base-State');
    console.log('Base-State');
    console.log(
      'SuperSwapper balance in ST9000:',
      IERC20(SUPERTOKEN9000).balanceOf(SUPERSWAPPER_ADDRESS)
    );
    console.log(
      'SuperSwapper allowance on WETH for UNISwap:',
      IERC20(SUPERWETH).allowance(SUPERSWAPPER_ADDRESS, UNISwapBase)
    );
    console.log('SuperSwapper balance in WETH:', IERC20(SUPERWETH).balanceOf(SUPERSWAPPER_ADDRESS));
    console.log('Trader balance in ST9000:', IERC20(SUPERTOKEN9000).balanceOf(trader));
    console.log('Trader balance in WETH:', IERC20(SUPERWETH).balanceOf(trader));
  }
}
