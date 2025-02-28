// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from 'forge-std/Script.sol';
import 'forge-std/console.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
interface ISuperSwapper {
  function initiateSwap(
    address tokenIn,
    uint256[] memory amounts,
    uint256[] memory chainIds
  ) external;

  function SUPERTOKEN9000() external view returns (address);
}

contract SwapScript is Script {
  // Address of the deployed SuperSwapper contract
  address public SUPERSWAPPER_ADDRESS;

  function run() external {
    SUPERSWAPPER_ADDRESS = vm.envAddress('SUPERSWAPPER_ADDRESS');

    vm.createSelectFork('http://localhost:9546');

    vm.startBroadcast();

    // Start broadcasting transactions

    // Get an instance of the deployed SuperSwapper contract
    ISuperSwapper swapper = ISuperSwapper(SUPERSWAPPER_ADDRESS);

    // // Define parameters for initiateSwap
    address tokenIn = swapper.SUPERTOKEN9000(); // Using the constant from SuperSwapper
    console.log('Token in:', tokenIn);
    uint256[] memory amounts = new uint256[](4);
    amounts[0] = 1 ether; // Amount for first chain
    amounts[1] = 2 ether; // Amount for second chain
    amounts[2] = 0.5 ether; // Amount for third chain
    amounts[3] = 2 ether; // Amount for fourth chain

    uint256[] memory chainIds = new uint256[](4);
    chainIds[0] = 10; // Optimism
    chainIds[1] = 8453; // Base
    chainIds[2] = 34443; // Mode
    chainIds[3] = 130; // Unichain

    IERC20(tokenIn).approve(
      SUPERSWAPPER_ADDRESS,
      amounts[0] + amounts[1] + amounts[2] + amounts[3]
    );
    // Call initiateSwap function
    swapper.initiateSwap(tokenIn, amounts, chainIds);

    console.log('Swap initiated successfully!');
    vm.stopBroadcast();
  }
}
