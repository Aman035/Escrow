// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Escrow {
    /* Errors */
    error Escrow__Unauthorized(address expected, address actual);

    /* Interface */

    /* Events */

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

    /**
     * @dev - Inplementation Pending
     */
    function sendPayment() public payable onlyBuyer {}

    /**
     * @dev - Inplementation Pending
     */
    function confirmDelivery() public payable onlyBuyer {}

    /**
     * @dev - Inplementation Pending
     */
    function resolveDispute(address winner) public onlyAgent {}
}
