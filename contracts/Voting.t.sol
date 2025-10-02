// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Voting.sol";

contract VotingTest is Test {
    Voting public voting;
    address public owner;
    address public voter1;
    address public voter2;
    address public voter3;

    event CandidateAdded(uint indexed candidateIndex, string name);
    event VoteCast(address indexed voter, uint indexed candidateIndex);

    function setUp() public {
        owner = address(this);
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        
        voting = new Voting();
    }

    // ============ Deployment Tests ============

    function test_DeploymentSetsOwner() public view {
        assertEq(voting.owner(), owner);
    }

    function test_DeploymentStartsWithZeroCandidates() public view {
        assertEq(voting.getCandidateCount(), 0);
    }

    // ============ Add Candidate Tests ============

    function test_OwnerCanAddCandidate() public {
        vm.expectEmit(true, false, false, true);
        emit CandidateAdded(0, "Alice");
        
        voting.addCandidate("Alice");
        
        assertEq(voting.getCandidateCount(), 1);
        
        Voting.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[0].name, "Alice");
        assertEq(candidates[0].voteCount, 0);
    }

    function test_OwnerCanAddMultipleCandidates() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        
        assertEq(voting.getCandidateCount(), 3);
        
        Voting.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[0].name, "Alice");
        assertEq(candidates[1].name, "Bob");
        assertEq(candidates[2].name, "Charlie");
    }

    function test_RevertWhen_NonOwnerTriesToAddCandidate() public {
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, voter1));
        voting.addCandidate("Alice");
    }

    function test_RevertWhen_AddingCandidateWithEmptyName() public {
        vm.expectRevert(Voting.EmptyCandidateName.selector);
        voting.addCandidate("");
    }

    // ============ Voting Tests ============

    function test_UserCanVote() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        
        vm.expectEmit(true, true, false, true);
        emit VoteCast(voter1, 0);
        
        vm.prank(voter1);
        voting.vote(0);
        
        assertTrue(voting.hasVoted(voter1));
        
        Voting.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[0].voteCount, 1);
    }

    function test_MultipleUsersCanVoteForDifferentCandidates() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        
        vm.prank(voter1);
        voting.vote(0); // Vote for Alice
        
        vm.prank(voter2);
        voting.vote(1); // Vote for Bob
        
        vm.prank(voter3);
        voting.vote(0); // Vote for Alice
        
        Voting.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[0].voteCount, 2); // Alice: 2 votes
        assertEq(candidates[1].voteCount, 1); // Bob: 1 vote
        assertEq(candidates[2].voteCount, 0); // Charlie: 0 votes
    }

    function test_RevertWhen_UserTriesToVoteTwice() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        
        vm.startPrank(voter1);
        voting.vote(0);
        
        vm.expectRevert(Voting.AlreadyVoted.selector);
        voting.vote(1);
        vm.stopPrank();
    }

    function test_RevertWhen_VotingForInvalidCandidateIndex() public {
        voting.addCandidate("Alice");
        
        vm.prank(voter1);
        vm.expectRevert(Voting.InvalidCandidateIndex.selector);
        voting.vote(10);
    }

    function test_HasVotedMappingUpdatesCorrectly() public {
        voting.addCandidate("Alice");
        
        assertFalse(voting.hasVoted(voter1));
        
        vm.prank(voter1);
        voting.vote(0);
        
        assertTrue(voting.hasVoted(voter1));
        assertFalse(voting.hasVoted(voter2));
    }

    // ============ Get Candidates Tests ============

    function test_GetCandidatesReturnsEmptyArrayWhenNoCandidates() public view {
        Voting.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates.length, 0);
    }

    function test_GetCandidatesReturnsAllCandidatesWithVoteCounts() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        
        vm.prank(voter1);
        voting.vote(0);
        
        vm.prank(voter2);
        voting.vote(0);
        
        vm.prank(voter3);
        voting.vote(1);
        
        Voting.Candidate[] memory candidates = voting.getCandidates();
        
        assertEq(candidates.length, 2);
        assertEq(candidates[0].name, "Alice");
        assertEq(candidates[0].voteCount, 2);
        assertEq(candidates[1].name, "Bob");
        assertEq(candidates[1].voteCount, 1);
    }

    // ============ Get Winner Tests ============

    function test_GetWinnerReturnsCorrectWinner() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        
        vm.prank(voter1);
        voting.vote(1); // Bob
        
        vm.prank(voter2);
        voting.vote(1); // Bob
        
        vm.prank(voter3);
        voting.vote(0); // Alice
        
        string memory winner = voting.getWinner();
        assertEq(winner, "Bob");
    }

    function test_GetWinnerReturnsClearLeader() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        
        vm.prank(voter1);
        voting.vote(2); // Charlie
        
        vm.prank(voter2);
        voting.vote(2); // Charlie
        
        vm.prank(voter3);
        voting.vote(2); // Charlie
        
        string memory winner = voting.getWinner();
        assertEq(winner, "Charlie");
    }

    function test_GetWinnerReturnsFirstCandidateInCaseOfTie() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        
        vm.prank(voter1);
        voting.vote(0); // Alice
        
        vm.prank(voter2);
        voting.vote(1); // Bob
        
        // Both have 1 vote, should return Alice (first with highest count)
        string memory winner = voting.getWinner();
        assertEq(winner, "Alice");
    }

    function test_RevertWhen_GetWinnerCalledWithNoCandidates() public {
        vm.expectRevert(Voting.NoCandidates.selector);
        voting.getWinner();
    }

    function test_RevertWhen_GetWinnerCalledWithNoVotes() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        
        vm.expectRevert(Voting.NoVotesCast.selector);
        voting.getWinner();
    }

    // ============ Helper Functions Tests ============

    function test_GetTotalVotesReturnsCorrectCount() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        
        assertEq(voting.getTotalVotes(), 0);
        
        vm.prank(voter1);
        voting.vote(0);
        assertEq(voting.getTotalVotes(), 1);
        
        vm.prank(voter2);
        voting.vote(1);
        assertEq(voting.getTotalVotes(), 2);
        
        vm.prank(voter3);
        voting.vote(0);
        assertEq(voting.getTotalVotes(), 3);
    }

    function test_GetCandidateCountReturnsCorrectCount() public {
        assertEq(voting.getCandidateCount(), 0);
        
        voting.addCandidate("Alice");
        assertEq(voting.getCandidateCount(), 1);
        
        voting.addCandidate("Bob");
        assertEq(voting.getCandidateCount(), 2);
        
        voting.addCandidate("Charlie");
        assertEq(voting.getCandidateCount(), 3);
    }

    // ============ Ownership Transfer Tests ============

    function test_OwnerCanTransferOwnership() public {
        voting.transferOwnership(voter1);
        assertEq(voting.owner(), voter1);
    }

    function test_NewOwnerCanAddCandidatesAfterTransfer() public {
        voting.transferOwnership(voter1);
        
        vm.prank(voter1);
        voting.addCandidate("NewCandidate");
        
        Voting.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[0].name, "NewCandidate");
    }

    function test_OldOwnerCannotAddCandidatesAfterTransfer() public {
        voting.transferOwnership(voter1);
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        voting.addCandidate("TestCandidate");
    }
}
