import Web3 from "web3";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const deploymentPath = path.join(__dirname, "../../../deployment.json");
const deployment = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));

const artifactPath = path.join(
  __dirname,
  "../../../artifacts/contracts/Voting.sol/Voting.json"
);
const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

export const CONTRACT_ADDRESS = deployment.address;
export const CONTRACT_ABI = artifact.abi;

export const RPC_URL = process.env.RPC_URL || "http://127.0.0.1:8545";

export const web3 = new Web3(RPC_URL);

export function getVotingContract() {
  return new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
}

export function getOwnerAccount() {
  const ownerPrivateKey = process.env.OWNER_PRIVATE_KEY;
  if (!ownerPrivateKey) {
    throw new Error("OWNER_PRIVATE_KEY not set in environment variables");
  }
  
  const formattedKey = ownerPrivateKey.startsWith('0x') 
    ? ownerPrivateKey 
    : '0x' + ownerPrivateKey;
  
  return web3.eth.accounts.privateKeyToAccount(formattedKey);
}
