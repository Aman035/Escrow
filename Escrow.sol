// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
