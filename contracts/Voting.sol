// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Voting
 * @dev A secure voting contract where only the owner can add candidates
 * and each address can vote only once
 */
contract Voting is Ownable {
    // Custom errors for gas efficiency
    error EmptyCandidateName();
    error AlreadyVoted();
    error InvalidCandidateIndex();
    error NoCandidates();
    error NoVotesCast();

    // Struct to represent a candidate
    struct Candidate {
        string name;
        uint voteCount;
    }

    // State variables
    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;

    // Events
    event CandidateAdded(uint256 candidateIndex, string name);
    event VoteCast(address voter, uint256 candidateIndex);

    /**
     * @dev Constructor sets the deployer as the owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Adds a new candidate (only owner can call)
     * @param _name The name of the candidate
     */
    function addCandidate(string memory _name) external onlyOwner {
        if (bytes(_name).length == 0) {
            revert EmptyCandidateName();
        }

        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));

        emit CandidateAdded(candidates.length - 1, _name);
    }

    /**
     * @dev Allows a user to vote for a candidate (one vote per address)
     * @param _candidateIndex The index of the candidate to vote for
     */
    function vote(uint _candidateIndex) external {
        if (hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }

        if (_candidateIndex >= candidates.length) {
            revert InvalidCandidateIndex();
        }

        hasVoted[msg.sender] = true;
        candidates[_candidateIndex].voteCount++;

        emit VoteCast(msg.sender, _candidateIndex);
    }

    /**
     * @dev Returns all candidates and their vote counts
     * @return An array of all candidates
     */
    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    /**
     * @dev Returns the name of the winning candidate
     * @return The name of the candidate with the most votes
     */
    function getWinner() external view returns (string memory) {
        if (candidates.length == 0) {
            revert NoCandidates();
        }

        uint totalVotes = getTotalVotes();
        if (totalVotes == 0) {
            revert NoVotesCast();
        }

        uint winningVoteCount = 0;
        uint winningCandidateIndex = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }

        return candidates[winningCandidateIndex].name;
    }

    /**
     * @dev Returns the total number of votes cast
     * @return The total vote count across all candidates
     */
    function getTotalVotes() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < candidates.length; i++) {
            total += candidates[i].voteCount;
        }
        return total;
    }

    /**
     * @dev Returns the total number of candidates
     * @return The number of candidates
     */
    function getCandidateCount() external view returns (uint) {
        return candidates.length;
    }
}
