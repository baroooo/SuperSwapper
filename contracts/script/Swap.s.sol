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
  address public constant SUPERSWAPPER_ADDRESS = 0x4980d56173f6BD9b969fD434Cbf50EDd13D57fc2; // REPLACE WITH ACTUAL ADDRESS

  function run() external {
    vm.createSelectFork('http://localhost:9545');

    // Start broadcasting transactions

    // Get an instance of the deployed SuperSwapper contract
    ISuperSwapper swapper = ISuperSwapper(SUPERSWAPPER_ADDRESS);

    // // Define parameters for initiateSwap
    address tokenIn = 0xf793A6B9587e09e6149Ea99Ed638DE0655CcfcB8; // Using the constant from SuperSwapper
    console.log('Token in:', tokenIn);
    // // Example: Swap to 3 different chains with different amounts
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1 ether; // Amount for first chain
    // amounts[1] = 2 ether; // Amount for second chain

    uint256[] memory chainIds = new uint256[](1);
    // chainIds[0] = 10; // Optimism
    chainIds[0] = 8453; // Base
    console.log('balance', IERC20(tokenIn).balanceOf(msg.sender));
    console.log('balance', IERC20(tokenIn).balanceOf(address(this)));

    IERC20(tokenIn).transfer(SUPERSWAPPER_ADDRESS, amounts[0]);
    // Call initiateSwap function
    swapper.initiateSwap(tokenIn, amounts, chainIds);

    console.log('Swap initiated successfully!');
  }
}
