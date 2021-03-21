pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IHordCongressMembersRegistry.sol";


/**
 * HordCogress contract.
 * @author Nikola Madjarevic
 * Date created: 18.3.21.
 * Github: madjarevicn
 */
contract HordCongress {
    /// @notice The name of this contract
    string public constant name = "HordCongress";

    // Members registry contract
    IHordCongressMembersRegistry membersRegistry;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        // Unique id for looking up a proposal
        uint id;

        // Creator of the proposal
        address proposer;

        // the ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // Current number of votes in favor of this proposal
        uint forVotes;

        // Current number of votes in opposition to this proposal
        uint againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal
        bool support;
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint id);

    /// @notice An event emitted everytime ether is received
    event ReceivedEther(address sender, uint amount);

    /// @notice Event which will fire every time transaction is executed
    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data);

    modifier onlyMember {
        require(membersRegistry.isMember(msg.sender) == true, "Only HordCongress member can call this function");
        _;
    }

    /// One time call function to set members registry contract
    function setMembersRegistry(
        address _membersRegistry
    )
    public
    {
        require(address(membersRegistry) == address(0x0));
        membersRegistry = IHordCongressMembersRegistry(_membersRegistry);
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    )
    public
    onlyMember
    returns (uint)
    {
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "HordCongress::propose: proposal function information arity mismatch"
        );

        require(targets.length != 0, "HordCongress::propose: must provide actions");
        require(membersRegistry.isMember(msg.sender) == true, "HordCongress::propose: only members can submit proposal");

        proposalCount++;

        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[newProposal.id] = newProposal;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, description);
        return newProposal.id;
    }


    function castVote(
        uint proposalId,
        bool support
    )
    public
    {
        return _castVote(msg.sender, proposalId, support);
    }


    function execute(
        uint proposalId
    )
    public
    payable
    {
        // load the proposal
        Proposal storage proposal = proposals[proposalId];
        // Require that proposal is not previously executed neither cancelled
        require(proposal.executed == false && proposal.canceled == false);
        // Mark that proposal is executed
        proposal.executed = true;
        // Require that votes in favor of proposal are greater or equal to minimalQuorum
        require(proposal.forVotes >= membersRegistry.getMinimalQuorum());

        for (uint i = 0; i < proposal.targets.length; i++) {
            bytes memory callData;

            if (bytes(proposal.signatures[i]).length == 0) {
                callData = proposal.calldatas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            }

            // solium-disable-next-line security/no-call-value
            (bool success,) = proposal.targets[i].call.value(proposal.values[i])(callData);

            // Require that transaction went through
            require(success, "HordCongress::executeTransaction: Transaction execution reverted.");

            // Emit event that transaction is being executed
            emit ExecuteTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i]);
        }

        // Emit event that proposal executed
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        // Require that proposal is not previously executed neither cancelled
        require(proposal.executed == false && proposal.canceled == false);
        // Proposal with reached minimalQuorum cant be cancelled
        require(proposal.forVotes < membersRegistry.getMinimalQuorum(), "HordCongress:cancel: Proposal already reached quorum");
        // Set that proposal is cancelled
        proposal.canceled = true;
        // Emit event
        emit ProposalCanceled(proposalId);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, 1);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, 1);
        }

        receipt.hasVoted = true;
        receipt.support = support;

        emit VoteCast(voter, proposalId, support);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getMembersRegistry()
    external
    view
    returns (address)
    {
        return address(membersRegistry);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}
