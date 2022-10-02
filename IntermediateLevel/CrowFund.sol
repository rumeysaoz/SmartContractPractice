// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IERC20.sol";

/*  
 * A contract to create crowd fundings.
*/

contract CrowdFund {
    struct Campaign {
        address owner;
        uint goal;                  // Amount of money campaign should raise before end-time.
        uint pledgedAmount;         // Amount of money campaign had raised.
        uint32 startAt;             // "startAt" and "endAt" will hold date&time value,
        uint32 endAt;               // so it's important that they're <uint32>.
        bool isClaimed;             // Did the goal satisfied?
    }

    IERC20 public immutable token;  // We should handle only one kind of token per contract for security issues.
    
    uint public count;              // Counter to count campaigns, also will be used as campaign ID
    
    mapping (uint => Campaign) public campaigns;
    mapping (uint => mapping(address => uint)) public pledgedAmount;

    event Launch (
        uint id,
        address indexed owner,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event Cancel (
        uint id
    );

    event Pledge (
        uint indexed id,
        address indexed _from,
        uint pledgedAmount
    );

    event Unpledge (
        uint indexed id,
        address indexed _to,
        uint amount
    );

    event Claim (
        uint id
    );

    event Refund (
        uint indexed id,
        address indexed _to,
        uint amount
    );

    constructor (address _token) {
        token = IERC20(_token);
    }

    // Function to launch a campaign.
    function launch (uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "Invalid start time");
        require(_endAt >= _startAt, "Invalid end time");
        require(_endAt <= block.timestamp + 90 days, "Invalid campaign duration");

        ++count;

        campaigns[count].owner = msg.sender;
        campaigns[count].goal = _goal;
        campaigns[count].pledgedAmount = 0;
        campaigns[count].startAt = _startAt;
        campaigns[count].endAt = _endAt;
        campaigns[count].isClaimed = false;

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    // Function (for only owner) to cancel a campaign if not started yet.
    function cancel (uint _id) external {
        require(msg.sender == campaigns[_id].owner, "Permission denied");
        require(block.timestamp < campaigns[_id].startAt, "Cannot cancel an ongoing campaign");

        delete campaigns[_id];

        emit Cancel(_id);
    }

    // Function (for users) to pledge money to campaign if it is still ongoing.
    function pledge (uint _id, uint _amount) external {
        require(block.timestamp >= campaigns[_id].startAt, "This campaign has not yet started");
        require(block.timestamp < campaigns[_id].endAt, "This campaign is ended");

        campaigns[_id].pledgedAmount += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, payable(address(this)), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    // Function (for users) to unpledge money from campaign if it is still ongoing.
    function unpledge (uint _id, uint _amount) external {
        require(block.timestamp >= campaigns[_id].startAt, "This campaign has not yet started");
        require(block.timestamp < campaigns[_id].endAt, "This campaign is ended");

        campaigns[_id].pledgedAmount -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(payable(msg.sender), _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    // If the goal is satisfied in the given campaign time, the owner can claim all the pledged tokens.
    function claim (uint _id) external {
        require(msg.sender == campaigns[_id].owner, "Permission denied");
        require(block.timestamp >= campaigns[_id].endAt, "The campaign is still ongoing");
        require(campaigns[_id].pledgedAmount >= campaigns[_id].goal, "The goal is not satisfied");
        require(!campaigns[_id].isClaimed, "Already claimed");

        token.transfer(payable(campaigns[_id].owner), campaigns[_id].pledgedAmount);
        campaigns[_id].isClaimed = true;

        emit Claim(_id);
    }
    
    // If the campaign is unsuccessful, then the pledged tokens should be refunded to each user.
    function refund (uint _id) external {
        require(block.timestamp >= campaigns[_id].endAt, "This campaign is still ongoing");
        require(campaigns[_id].pledgedAmount < campaigns[_id].goal, "The goal is satisfied");

        uint _amount = pledgedAmount[_id][msg.sender];
        token.transfer(payable(msg.sender), _amount);
        pledgedAmount[_id][msg.sender] = 0;

        emit Refund(_id, msg.sender, _amount);
    }
}