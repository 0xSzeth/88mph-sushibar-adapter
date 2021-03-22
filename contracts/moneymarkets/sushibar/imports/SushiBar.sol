// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface SushiBar {

  // Sushibar specific funcitons
  function enter(uint256 _amount) external;
  function leave(uint256 _share) external;

  // General ERC20 functions
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
