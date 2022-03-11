// deploy/00_deploy_your_contract.js
const ipfsAPI = require("ipfs-http-client");
const { globSource } = require("ipfs-http-client");

const projectId = process.env.IPFS_INFURA_KEY;
const projectSecret = process.env.IPFS_DEPLOYER_PRIV_KEY;
console.log(projectId);
const auth =
  "Basic " + Buffer.from(projectId + ":" + projectSecret).toString("base64");

const ipfs = ipfsAPI({
  host: "ipfs.infura.io",
  port: "5001",
  protocol: "https",
  headers: {
    authorization: auth,
  },
});

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // First, we upload the metadata to IPFS and get the CID
  const file = await ipfs.add(
    globSource("./erc1155metadata", { recursive: true })
  );
  console.log("file.cid = " + file.cid.toString());
  const tokenUri = "https://ipfs.io/ipfs/" + file.cid.toString() + "/{id}.json";

  await deploy("YourCollectible", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [tokenUri],
    log: true,
  });
};
module.exports.tags = ["YourCollectible"];
