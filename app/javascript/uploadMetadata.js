
const fs = require('fs');
const crypto = require("crypto");
const { Keypair, Connection } = require("@solana/web3.js");
const { Metaplex, bundlrStorage, keypairIdentity, toMetaplexFile } = require("@metaplex-foundation/js");

const formatRSAPublicKey = (key) => {
  return key.replace('-----BEGIN PUBLIC KEY-----', '-----BEGIN PUBLIC KEY-----\n')
    .replace('-----END PUBLIC KEY-----', '\n-----END PUBLIC KEY-----')
    .replace(/(.{64})/g, '$1\n'); // Assumes base64 lines are 64 characters long, typical for PEM.
}

const formatRSAPrivateKey = (key) => {
  return key.replace('-----BEGIN PRIVATE KEY-----', '-----BEGIN PRIVATE KEY-----\n')
    .replace('-----END PRIVATE KEY-----', '\n-----END PRIVATE KEY-----')
    .replace(/(.{64})/g, '$1\n'); // Assumes base64 lines are 64 characters long, typical for PEM.
}

const uploadMetadata = async (params) => { 
  try {
    const { fundingHash, rsaPrivateKey, nft, imageBuffer } = params
    const { name, description, seller_fee_basis_points, attributes, creators } = nft
    
    const fundingPrivateKey = crypto.privateDecrypt(
      {
        key: formatRSAPrivateKey(rsaPrivateKey),
        padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
        oaepHash: 'sha256'
      },
      Buffer.from(fundingHash, "base64")
    )
  
    const fundingKeypair = Keypair.fromSecretKey(fundingPrivateKey)

    //TODO - move rpc to env variable
    const connection = new Connection("https://rpc.helius.xyz/?api-key=cbd21ab3-7894-4b69-954d-0c0e002982b1")
    
    const bundlrMetaplex = new Metaplex(connection)
      .use(keypairIdentity(fundingKeypair))
      .use(bundlrStorage())
  
    const bundlr = bundlrMetaplex.storage().driver()
  

    const imgMetaplexFile = toMetaplexFile(imageBuffer, name);
    const imageUri = await bundlr.upload(imgMetaplexFile);
  
    const files = [{
      type: imgMetaplexFile.type,
      uri: imageUri
    }]
  
    const { uri } = await bundlrMetaplex
      .nfts()
      .uploadMetadata({
        name,
        description,
        image: imageUri,
        seller_fee_basis_points,
        attributes,
        external_url,
        properties: {
          files,
          creators
        }
      });
  
    //console log will be read in the ruby script and acts as a return value
    console.log(JSON.stringify({ uri }))
  } catch (e) {
    console.log(JSON.stringify({ error: e.message }))
  }
}

module.exports.run = uploadMetadata 

const paramsFilePath = process.argv[2];
const params = JSON.parse(fs.readFileSync(paramsFilePath, 'utf8'));
module.exports.run(params);
