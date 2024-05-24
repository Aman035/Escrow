// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// PUSH Comm Contract Interface
interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract Escrow {
    /* Errors */
    error Escrow__Unauthorized(address expected, address actual);
    error Escrow__IncorrectPaymentAmount();
    error Escrow__IncorrectState(EscrowState expected, EscrowState actual);
    error Escrow__TransactionFailed();
    error Escrow__IncorrectDisputeWinner();

    /* Interface */

    /* Events */
    event Escrow_Transaction_Successful(address buyer, address seller, uint256 amount);

    /* Type Declarations */
    enum EscrowState {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE
    }

    /* Variables */
    address public buyer;
    address payable public seller;
    address public escrowAgent;
    uint256 public price;
    EscrowState public currentState;

    /* Modifiers */

    modifier onlyBuyer() {
        if (msg.sender != buyer) {
            revert Escrow__Unauthorized(buyer, msg.sender);
        }
        _;
    }

    modifier onlyAgent() {
        if (msg.sender != escrowAgent) {
            revert Escrow__Unauthorized(escrowAgent, msg.sender);
        }
        _;
    }

    constructor(address _buyer, address payable _seller, uint256 _price) {
        buyer = _buyer;
        seller = _seller;
        price = _price;
        escrowAgent = msg.sender;
        currentState = EscrowState.AWAITING_PAYMENT;
    }

    // Helper function to convert address to string
    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function sendNotification() private {
        IPUSHCommInterface(0x6e489B7af21cEb969f49A90E481274966ce9D74d).sendNotification(
            0xD5eB12FD5B8d53f12A3ABde6B7fb43c6a7cde4A8, // from channel
            0xD5eB12FD5B8d53f12A3ABde6B7fb43c6a7cde4A8, // to recipient
            bytes(
                string(
                    abi.encodePacked(
                        "0", // minimal identity
                        "+", // segregator
                        "1", // notification type
                        "+", // segregator
                        "Escrow Payment Successful", // notification title
                        "+", // segregator
                        "Escrow Transaction for Amount ",
                        uint2str(price), // add the amount
                        " between ",
                        addressToString(buyer), // buyer address
                        " and ",
                        addressToString(seller) // seller address
                    )
                )
            )
        );
    }

    function sendPayment() public payable onlyBuyer {
        if (currentState != EscrowState.AWAITING_PAYMENT) {
            revert Escrow__IncorrectState(EscrowState.AWAITING_PAYMENT, currentState);
        }
        if (msg.value != price) {
            revert Escrow__IncorrectPaymentAmount();
        }
        currentState = EscrowState.AWAITING_DELIVERY;
    }

    function confirmDelivery() public payable onlyBuyer {
        if (currentState != EscrowState.AWAITING_DELIVERY) {
            revert Escrow__IncorrectState(EscrowState.AWAITING_DELIVERY, currentState);
        }
        currentState = EscrowState.COMPLETE;

        emit Escrow_Transaction_Successful(buyer, seller, price);

        sendNotification();

        (bool success,) = seller.call{value: price}("");
        if (!success) {
            revert Escrow__TransactionFailed();
        }
    }

    function resolveDispute(address winner) public onlyAgent {
        if (currentState != EscrowState.AWAITING_DELIVERY) {
            revert Escrow__IncorrectState(EscrowState.AWAITING_DELIVERY, currentState);
        }

        if (winner != buyer && winner != seller) {
            revert Escrow__IncorrectDisputeWinner();
        }

        currentState = EscrowState.COMPLETE;

        (bool success,) = winner.call{value: price}("");
        if (!success) {
            revert Escrow__TransactionFailed();
        }
    }
}
