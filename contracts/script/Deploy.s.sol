// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script, console } from 'forge-std/Script.sol';
import { Vm } from 'forge-std/Vm.sol';
import { ICreateX } from 'createx/ICreateX.sol';

import { DeployUtils } from '../libraries/DeployUtils.sol';
import { InitialSupplySuperchainERC20 } from '../src/InitialSupplySuperchainERC20.sol';
import { SuperSwapper } from '../src/SuperSwapper.sol';

// Example forge script for deploying as an alternative to sup: super-cli (https://github.com/ethereum-optimism/super-cli)
contract Deploy is Script {
  /// @notice Array of RPC URLs to deploy to, deploy to supersim 901 and 902 by default.
  string[] private rpcUrls = ['http://localhost:9545', 'http://localhost:9546'];

  /// @notice Modifier that wraps a function in broadcasting.
  modifier broadcast() {
    vm.startBroadcast(msg.sender);
    _;
    vm.stopBroadcast();
  }

  mapping(uint256 => address) public uniswapV2Routers;

  function run() public {
    uniswapV2Routers[10] = 0x4A7b5Da61326A6379179b40d00F57E5bbDC962c2;
    uniswapV2Routers[8453] = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    for (uint256 i = 0; i < rpcUrls.length; i++) {
      string memory rpcUrl = rpcUrls[i];

      console.log('Deploying to RPC: ', rpcUrl);
      vm.createSelectFork(rpcUrl);
      deployInitialSupplySuperchainERC20Contract();
    }
  }

  function deployInitialSupplySuperchainERC20Contract() public broadcast {
    bytes memory initCodeSP9000 = abi.encodePacked(
      type(InitialSupplySuperchainERC20).creationCode,
      abi.encode(msg.sender, 'SUPERTOKEN9000', 'ST9000', 18, 1_000_000e18, 10)
    );

    bytes memory initCodeSuperSwapper = abi.encodePacked(
      type(SuperSwapper).creationCode,
      abi.encode(msg.sender)
    );

    address addrSP9000 = DeployUtils.deployContract(
      'InitialSupplySuperchainERC20',
      _implSalt(),
      initCodeSP9000
    );
    address addrSuperSwapper = DeployUtils.deployContract(
      'SuperSwapper',
      _implSalt(),
      initCodeSuperSwapper
    );

    SuperSwapper(addrSuperSwapper).setUniswapV2Router(uniswapV2Routers[block.chainid]);

    console.log('Deployed InitialSupplySuperchainERC20 contract to: ', addrSP9000);
    console.log('Deployed SuperSwapper contract to: ', addrSuperSwapper);
  }

  /// @notice The CREATE2 salt to be used when deploying a contract.
  function _implSalt() internal view returns (bytes32) {
    return keccak256(abi.encodePacked(vm.envOr('DEPLOY_SALT', string('ethers phoenix'))));
  }
}
