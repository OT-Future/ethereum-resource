pragma solidity 0.4.16;


contract DecentralisedAuction {
    struct Auction {
        uint deadline;
        uint highestBid;
        address highestBidder;
        bytes32 bidHash;
        address recipient;
        address thirdParty;
        uint thirdPartyFee;
        uint deliveryDeadline;
    }

    mapping(uint => Auction) public auctions;
    uint public numAuctions;
    address _receiver;

    event CreateAuction(uint indexed id, uint timeLimit, address thirdParty, 
    uint thirdPartyFee, uint deliveryDeadline);

    event NewBid(uint indexed id, address bidder, uint bitvalue);
    event EndAuction(uint indexed id, address highestBidder, uint highestBidValue);
    event NotDeliver(uint indexed id, address highestBidder);
    
    event ShowAuction(uint indexed id, address recipient, uint timeLimit, address thirdParty, 
    uint thirdPartyFee, uint deliveryDeadline, address highestBidder, uint highestBidValue);

    function startAuction(uint timeLimit, address thirdParty, uint thirdPartyFee, uint deliveryDeadline) public {
        uint id = numAuctions++;
        Auction storage a = auctions[id];
        a.deadline = block.number + timeLimit;
        a.recipient = msg.sender;
        a.thirdParty = thirdParty;
        a.thirdPartyFee = thirdPartyFee;
        a.deliveryDeadline = block.number + timeLimit + deliveryDeadline;
        _receiver = msg.sender;
        
        CreateAuction(id, timeLimit, thirdParty, thirdPartyFee, deliveryDeadline);
        ShowAuction(id, a.recipient, a.deadline, a.thirdParty, a.thirdPartyFee, 
        a.deliveryDeadline, a.highestBidder, a.highestBid);
    }

    function bid(uint id, bytes32 biddersHash) public payable returns (address highestBidder) {
        Auction storage a = auctions[id];
        
        if (a.highestBid > msg.value || block.number > a.deadline) {
            msg.sender.transfer(msg.value);
            highestBidder = msg.sender;
            return highestBidder;
        }
        
        if (a.highestBid > 0) {
            highestBidder = a.highestBidder;
            highestBidder.transfer(a.highestBid);
        }
            
        a.highestBidder = msg.sender;
        a.highestBid = msg.value;
        a.bidHash = biddersHash;

        NewBid(id, msg.sender, a.highestBid);
        return highestBidder;
    }

    function endAuction(uint id, bytes32 biddersHash) public returns (address highestBidder) {
        Auction storage a = auctions[id];
        if (block.number >= a.deadline && biddersHash == a.bidHash) {
            if (a.highestBid > 0) {
                uint256 recipientValue = a.highestBid-a.thirdPartyFee;
                uint256 thirdPartyValue = a.thirdPartyFee;
                a.recipient.transfer(recipientValue);
                a.thirdParty.transfer(thirdPartyValue);
            }
            highestBidder = a.highestBidder;
            
            EndAuction(id, a.highestBidder, a.highestBid);
            ShowAuction(id, a.recipient, a.deadline, a.thirdParty, a.thirdPartyFee, 
            a.deliveryDeadline, a.highestBidder, a.highestBid);
            clean(id);
            return highestBidder;
        }
    }

    function notDelivered(uint id) public {
        Auction storage a = auctions[id];
        if (block.number >= a.deliveryDeadline && msg.sender == a.highestBidder) {
            if (a.highestBid > 0) {
                a.highestBidder.transfer(a.highestBid);
            }
            NotDeliver(id, a.highestBidder);
            clean(id);
        }
    }

    function clean(uint id) private {
        Auction storage a = auctions[id];
        a.highestBid = 0;
        a.highestBidder = 0;
        a.deadline = 0;
        a.deliveryDeadline = 0;
        a.recipient = 0;
        a.bidHash = 0x00;
        a.thirdPartyFee = 0;
        a.thirdParty = 0;
    }
}