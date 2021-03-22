pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

import "../../libs/DecMath.sol";
import "../IMoneyMarket.sol";
import "./imports/SushiBar.sol";

contract SushiBarMarket is IMoneyMarket, Ownable {

  using SafeMath for uint256;
  using DecMath for uint256;
  using SafeERC20 for ERC20;
  using Address for address;

  ERC20 public sushi;
  SushiBar public sushibar;

  constructor(address _sushi, address _sushibar) public {
    require(
      _sushi.isContract() &&
      _sushibar.isContract(),
      "SushiBarMarket: An input address is not a contract"
    );

    sushi = ERC20(_sushi);
    sushibar = SushiBar(_sushibar);
  }

  function deposit(uint256 amount) external onlyOwner {
    require(amount > 0, "SushiBarMarket: amount is 0");

    // Transfer 'amount' sushi from 'msg.sender'
    sushi.safeTransferFrom(msg.sender, address(this), amount);

    // Deposit 'amount' sushi into sushibar
    sushi.safeIncreaseAllowance(address(sushibar), amount);
    sushibar.enter(amount);
  }

  function withdraw(uint256 amountInUnderlying)
    external
    onlyOwner
    returns (uint256 actualAmountWithdrawn)
  {
    require(amountInUnderlying > 0, "SushiBarMarket: amountInUnderlying is 0");

    // get balance of sushi before the transaction
    uint256 sushiBefore = sushi.balanceOf(address(this));

    // get sushibar balances and ensure they are non-zero
    uint256 totalShares = sushibar.totalSupply();
    uint256 totalSushi = sushi.balanceOf(address(sushibar));
    require (totalShares > 0 && totalSushi > 0, "SushiBarMarket: sushibar is empty");

    // calculate 'shares' needed to withdraw 'amountInUnderlying' from sushibar
    uint256 exchangeRate = totalSushi.decdiv(totalShares);
    uint256 shares = amountInUnderlying.decdiv(exchangeRate);

    // withdraw shares from sushibar
    if (shares > 0) {
      sushibar.leave(shares);
    }

    // calculate the actual amount of sushi withdrawn
    uint256 sushiAfter = sushi.balanceOf(address(this));
    uint256 amount = sushiAfter.sub(sushiBefore);

    //transfer 'amount' of sushi to the msg.sender
    if (amount > 0) {
      sushi.safeTransfer(msg.sender, amount);
    }

    return amount;
  }

  function claimRewards() external {}

  function totalValue() external returns (uint256) {
    uint256 shares = sushibar.balanceOf(address(this));
    if (shares == 0) {
      return 0;
    } else {
      uint256 totalShares = sushibar.totalSupply();
      uint256 totalSushi = sushi.balanceOf(address(sushibar));
      uint256 exr = totalSushi.decdiv(totalShares);
      return shares.decmul(exr);
    }
  }

  function incomeIndex() external returns (uint256) {
    uint256 totalShares = sushibar.totalSupply();
    uint256 totalSushi = sushi.balanceOf(address(sushibar));
    if (totalShares == 0) {
      return 1e18;
    } else {
      return totalSushi.decdiv(totalShares);
    }
  }

  function setRewards(address newValue) external onlyOwner {}

  function stablecoin() external view returns (address) {
    return address(sushi);
  }

}
