
import crypto from "crypto"
import fs from "fs"
import path from "path"
import { Keypair, Connection } from "@solana/web3.js";
import { Metaplex, bundlrStorage, keypairIdentity, toMetaplexFile, toMetaplexFileFromBrowser } from "@metaplex-foundation/js";
import { formatRSAPrivateKey } from '../utils/formatRSA.js';
import { connection } from "../utils/RpcConnection.js";
import postgres from "../../db/postgres.js";

//Standard Ref = https://docs.metaplex.com/programs/token-metadata/changelog/v1.0

export const uploadMetadata = async (req, res) => { 
  try {
    const imageFile = req.file
    const nft = JSON.parse(req.body.nft)
    const { name, description, seller_fee_basis_points, attributes, creators, external_url, category } = nft

    fs.readFile(imageFile.path, async (err, data) => {
      if (err) throw err;
      const imageBuffer = data;

      const extension = path.extname(imageFile.originalname)
      const imgMetaplexFile = toMetaplexFile(imageBuffer, imageFile.originalname, {
        displayName: name,
        contentType: imageFile.mimetype,
        extension
      });
      
      const fundingHash = await postgres('key_hashes')
      .where("name", "curation_authority_funds")
      .first()
      .catch((e) => { 
        throw e; 
      })
      
      console.log("🚀 ~ file: uploadMetadata.js:31 ~ fs.readFile ~ fundingHash:", fundingHash)
      const fundingPrivateKey = crypto.privateDecrypt(
        {
          key: formatRSAPrivateKey(process.env.RSA_PRIVATE_KEY),
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256'
        },
        Buffer.from(fundingHash.hash, "base64")
      )

      const fundingKeypair = Keypair.fromSecretKey(fundingPrivateKey)
      console.log("🚀 ~ file: uploadMetadata.js:47 ~ fs.readFile ~ fundingKeypair:", fundingKeypair.publicKey.toString())

      const bundlrMetaplex = new Metaplex(connection)
        .use(keypairIdentity(fundingKeypair))
        .use(bundlrStorage())

      const bundlr = bundlrMetaplex.storage().driver()

      const imageUri = await bundlr.upload(imgMetaplexFile);
      console.log("🚀 ~ file: uploadMetadata.js:57 ~ fs.readFile ~ imageUri:", imageUri)
      const imageUriWithExtension = imageUri + "?ext=" + extension.replace(".", "")

      const files = [{
        type: imgMetaplexFile.contentType,
        uri: imageUriWithExtension
      }]

      const { uri } = await bundlrMetaplex
        .nfts()
        .uploadMetadata({
          name,
          description,
          image: imageUriWithExtension,
          seller_fee_basis_points,
          attributes,
          external_url,
          properties: {
            category,
            files,
            creators
          }
        });

      res.status(200).json({ uri })
    })
    
    
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
}
