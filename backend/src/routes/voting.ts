import { Router, Request, Response } from "express";
import { getVotingContract, getOwnerAccount, web3 } from "../config/blockchain.js";
import { asyncHandler } from "../middleware/errorHandler.js";

const router = Router();

router.post(
  "/candidates/add",
  asyncHandler(async (req: Request, res: Response) => {
    const { name } = req.body;

    // Validate input
    if (!name || typeof name !== "string") {
      return res.status(400).json({
        success: false,
        error: "ValidationError",
        message: "Candidate name is required and must be a string",
      });
    }

    // Get owner account and contract
    const ownerAccount = getOwnerAccount();
    const votingContract = getVotingContract();

    // Add candidate
    const tx = await votingContract.methods.addCandidate(name).send({
      from: ownerAccount.address,
      gas: 300000,
    });

    // Get candidate index from event
    let candidateIndex = null;
    if (tx.events && tx.events.CandidateAdded) {
      candidateIndex = tx.events.CandidateAdded.returnValues.candidateIndex;
    }

    res.status(201).json({
      success: true,
      message: "Candidate added successfully",
      data: {
        transactionHash: tx.transactionHash,
        candidateIndex: candidateIndex?.toString(),
        name,
      },
    });
  })
);

router.get(
  "/candidates",
  asyncHandler(async (req: Request, res: Response) => {
    const votingContract = getVotingContract();

    const candidates = await votingContract.methods.getCandidates().call();

    const formattedCandidates = candidates.map((candidate: any, index: number) => ({
      index,
      name: candidate.name,
      voteCount: candidate.voteCount.toString(),
    }));

    res.json({
      success: true,
      data: {
        candidates: formattedCandidates,
        totalCandidates: formattedCandidates.length,
      },
    });
  })
);

router.post(
  "/vote",
  asyncHandler(async (req: Request, res: Response) => {
    const { voterPrivateKey, candidateIndex } = req.body;

    // Validate input
    if (typeof voterPrivateKey !== "string" || typeof candidateIndex !== "number") {
      return res.status(400).json({
        success: false,
        error: "ValidationError",
        message: "Missing or invalid required fields: voterPrivateKey, candidateIndex",
      });
    }

    let voterAccount;
    try {
      const formattedKey = voterPrivateKey.startsWith('0x') 
        ? voterPrivateKey 
        : '0x' + voterPrivateKey;
      voterAccount = web3.eth.accounts.privateKeyToAccount(formattedKey);
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: "ValidationError",
        message: "Invalid private key format",
      });
    }

    const votingContract = getVotingContract();

    const tx = await votingContract.methods.vote(candidateIndex).send({
      from: voterAccount.address,
      gas: 300000,
    });

    res.json({
      success: true,
      message: "Vote cast successfully",
      data: {
        transactionHash: tx.transactionHash,
        voterAddress: voterAccount.address,
        candidateIndex,
        blockNumber: tx.blockNumber.toString(),
      },
    });
  })
);

router.get(
  "/winner",
  asyncHandler(async (req: Request, res: Response) => {
    const votingContract = getVotingContract();

    const winnerName = await votingContract.methods.getWinner().call();

    const totalVotes = await votingContract.methods.getTotalVotes().call();

    res.json({
      success: true,
      data: {
        winner: winnerName,
        totalVotes: totalVotes.toString(),
      },
    });
  })
);

export default router;
