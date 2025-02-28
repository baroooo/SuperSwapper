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
  address public constant SUPERSWAPPER_ADDRESS = 0x141Cf3C1Cd0884A9170Aab82815589483EdB1741; // REPLACE WITH ACTUAL ADDRESS

  function run() external {
    vm.createSelectFork('http://localhost:9545');

    vm.startBroadcast();

    // Start broadcasting transactions

    // Get an instance of the deployed SuperSwapper contract
    ISuperSwapper swapper = ISuperSwapper(SUPERSWAPPER_ADDRESS);

    // // Define parameters for initiateSwap
    address tokenIn = swapper.SUPERTOKEN9000(); // Using the constant from SuperSwapper
    console.log('Token in:', tokenIn);
    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 1 ether; // Amount for first chain
    amounts[1] = 2 ether; // Amount for second chain
    amounts[2] = 0.5 ether; // Amount for third chain

    uint256[] memory chainIds = new uint256[](3);
    chainIds[0] = 10; // Optimism
    chainIds[1] = 8453; // Base
    chainIds[2] = 34443; // Mode

    IERC20(tokenIn).approve(SUPERSWAPPER_ADDRESS, amounts[0] + amounts[1] + amounts[2]);
    // Call initiateSwap function
    swapper.initiateSwap(tokenIn, amounts, chainIds);

    console.log('Swap initiated successfully!');
    vm.stopBroadcast();
  }
}
