pragma solidity 0.4.18;

/** Trade account mapped to and owned by user
 */
contract TradeAccount {

    event TradeExecutedSuccessfully(uint tradeId, ERC20 srcToken, ERC20 destToken);
    event TokenWithdrawn(address token, uint amount);
    event TradeStoredSuccessfully(uint tradeId);

    struct Trade {
            address srcToken;
            address destToken;
            uint srcQty;
            uint tradeType;
            uint threshold;
            uint condition;
            uint duration;
        }

    KyberNetworkProxy kyberNetworkProxyContract;
    address public owner;
    address public oracle;
    string public oracleJobId = "76ca51361e4e444f8a9b18ae350a5725";
    mapping(uint => Trade) public trades;
    int256 public result;
    

    function TradeAccount (
        address _owner, 
        KyberNetworkProxy _kyberNetworkProxyContract
        ) public {
        owner = _owner;
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }

    /** default function to accept tokens and ETH */
    function() external payable {}
    
       /** verify if the given trade is authorised by account owner */
    function isTradeAuthorised(string memory trade, bytes memory signature)
            public view returns (bool){
        return address(owner) == address(getSigningAccount(trade, signature));
    }

    /** returns the address that signed a given string message */
    function verifyString(string memory message, uint8 v, bytes32 r,
            bytes32 s) public pure returns (address signer) {
    // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
        // The first word of a string is its length
        length := mload(message)
        // The beginning of the base-10 message length in the prefix
        lengthOffset := add(header, 57)
        }
        // Maximum length we support
        require(length <= 999999, 'exceeded max length');
        // The length of the message's length in base-10
        uint256 lengthLength = 0;
        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;
        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                divisor /= 10;
                continue;
                }
            }
            // Found a non-zero digit or non-leading zero digit
            lengthLength++;
            // Remove this digit from the message length's current value
            length -= digit * divisor;
            // Shift our base-10 divisor over
            divisor /= 10;
            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
        lengthLength = 1 + 0x19 + 1;
        } else {
        lengthLength += 1 + 0x19;
        }
        // Truncate the tailing zeros from the header
        assembly {
        mstore(header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    /** retrieve account address that signed this message */
   function getSigningAccount(string memory message, bytes memory sig)
            public pure returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        return verifyString(message, v,r,s);
    }

    /** withdraw tokens from contract balance */
    function withdrawTokens(address token, uint amount) public {
        //validate that sender is the account owner
        require(msg.sender == owner);
        //check if ETH needs to be withdrawn
        if(token == 0x0000000000000000000000000000000000000000) {
            //validate if account has enough ETH balance
            require(address(this).balance > amount);
            //send ETH
            msg.sender.transfer(amount);
            TokenWithdrawn(0x0000000000000000000000000000000000000000, amount);
            return;
        }
        //validate if account has enough token balance
        require(ERC20(token).balanceOf(address(this)) >= amount);
        //transfer token
        ERC20(token).transfer(msg.sender, amount);
        TokenWithdrawn(token, amount);
    }
   
     /**
     * @dev Stores the incoming trade request
     */
    function addTrade( 
            uint tradeId,
            address srcToken,
            address destToken,
            uint srcQty,
            uint tradeType,
            uint threshold,
            uint condition,
            uint duration) public {
        //check if sender is account owner
        require(msg.sender == owner);

        trades[tradeId] = Trade(srcToken, destToken, srcQty, tradeType, threshold, condition, duration);
        TradeStoredSuccessfully(tradeId);
    }


    /**
     * @dev Swap the user's ERC20 token to another ERC20 token/ETH
     * @param srcToken source token contract address
     * @param srcQty amount of source tokens
     * @param destToken destination token contract address
     * @param destAddress address to send swapped tokens to
     * @param maxDestAmount address to send swapped tokens to
     */
    function executeTrade(
        uint tradeId,
        ERC20 srcToken,
        uint srcQty,
        ERC20 destToken,
        address destAddress,
        uint maxDestAmount
    ) public {
        uint minConversionRate;

        //verify is this trade is authorised by account owner
        require(isTradeAuthorised(trade, signature));

        //verify if trade exists
        require(trades[tradeId].srcQty != 0));

        // Set the spender's token allowance to tokenQty
        require(srcToken.approve(address(kyberNetworkProxyContract), srcQty));

        // Get the minimum conversion rate
        (minConversionRate, ) = kyberNetworkProxyContract.getExpectedRate(srcToken, destToken, srcQty);

        // Swap the ERC20 token and send to destAddress
        kyberNetworkProxyContract.trade(
            srcToken,
            srcQty,
            destToken,
            destAddress,
            maxDestAmount,
            minConversionRate,
            0 //walletId for fee sharing program
        );

        // Log the event
        TradeExecutedSuccessfully(tradeId, srcToken, destToken);
    }
    
}

contract ERC20 {
        function totalSupply() public view returns (uint);
        function balanceOf(address tokenOwner) public view returns (uint balance);
        function allowance(address tokenOwner, address spender) public view returns (uint remaining);
        function transfer(address to, uint tokens) public returns (bool success);
        function approve(address spender, uint tokens) public returns (bool success);
        function transferFrom(address from, address to, uint tokens) public returns (bool success);
        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }

contract KyberNetworkProxy {
    function trade(ERC20 srcToken,
            uint srcQty,
            ERC20 destToken,
            address destAddress,
            uint maxDestAmount,
            uint minConversionRate,
            address walletId
        ) public returns (uint destQty);
        
    function getExpectedRate(ERC20 srcToken, ERC20 destToken, uint srcQty) public returns (uint, uint);
}