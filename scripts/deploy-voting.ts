import { network } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
  console.log("Starting Voting contract deployment...");
  
  const networkName = "localhost";
  
  const { ethers } = await network.connect({
    network: networkName,
  });

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  const Voting = await ethers.getContractFactory("Voting");
  const voting = await Voting.deploy();

  await voting.waitForDeployment();
  const votingAddress = await voting.getAddress();

  console.log("\nVoting contract deployed!");
  console.log("Contract Address:", votingAddress);
  console.log("Owner Address:", await voting.owner());
  console.log("Network:", (await ethers.provider.getNetwork()).name);

  const deploymentData = {
    address: votingAddress
  };

  const deploymentPath = path.join(process.cwd(), "deployment.json");
  fs.writeFileSync(deploymentPath, JSON.stringify(deploymentData, null, 2));
  console.log("\nContract address saved to deployment.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });
