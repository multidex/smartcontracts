pragma solidity 0.4.18;
import './TradeAccount.sol';

contract TradeAccountsFactory {
    event TradeAccountCreated(address user, address tradeAccount);
    mapping(address => address) public tradeAccounts;

    function createAccount() public {
        if (tradeAccounts[msg.sender] == address(0)) {
            tradeAccounts[msg.sender] = address(new TradeAccount(msg.sender));
            TradeAccountCreated(msg.sender, tradeAccounts[msg.sender]);
        }
    }
}
