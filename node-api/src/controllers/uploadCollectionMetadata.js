
import crypto from "crypto"
import fs from "fs"
import path from "path"
import { Keypair, Connection } from "@solana/web3.js";
import { Metaplex, bundlrStorage, keypairIdentity, toMetaplexFile, toMetaplexFileFromBrowser } from "@metaplex-foundation/js";
import { formatRSAPrivateKey } from '../utils/formatRSA.js';
import { connection } from "../utils/RpcConnection.js";
import postgres from "../../db/postgres.js";

//Standard Ref = https://docs.metaplex.com/programs/token-metadata/changelog/v1.0

export const uploadCollectionMetadata = async (req, res) => {
  try {
    const imageFile = req.files.imageFile[0]

    const nft = JSON.parse(req.body.nft)
    const { collectionName, collectionDescription } = nft

    const handleUpload = async (imageBuffer, altBuffer) => {
      const imgExtension = path.extname(imageFile.originalname)
      const imgMetaplexFile = toMetaplexFile(imageBuffer, imageFile.originalname, {
        contentType: imageFile.mimetype,
        extension: imgExtension
      });

      const fundingHash = await postgres('key_hashes')
        .where("name", "curation_authority_funds")
        .first()
        .catch((e) => {
          throw e;
        })

      const fundingPrivateKey = crypto.privateDecrypt(
        {
          key: formatRSAPrivateKey(process.env.RSA_PRIVATE_KEY),
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256'
        },
        Buffer.from(fundingHash.hash, "base64")
      )

      const fundingKeypair = Keypair.fromSecretKey(fundingPrivateKey)

      const bundlrMetaplex = new Metaplex(connection)
        .use(keypairIdentity(fundingKeypair))
        .use(bundlrStorage())

      const bundlr = bundlrMetaplex.storage().driver()

  
      const imageUri = await bundlr.upload(imgMetaplexFile);

      const imageUriWithExtension = imageUri + "?ext=" + imgExtension.replace(".", "")

      const files = [{
        type: imgMetaplexFile.contentType,
        uri: imageUriWithExtension
      }]

      const { uri } = await bundlrMetaplex
        .nfts()
        .uploadMetadata({
          name: collectionName,
          description: collectionDescription,
          image: imageUriWithExtension,
          properties: {
            files,
          }
        });

      res.status(200).json({ uri })
    }

    fs.readFile(imageFile.path, async (err, data) => {
      if (err) throw err;
      const imageBuffer = data;

      await handleUpload(imageBuffer)
    })

  } catch (e) {
    res.status(500).json({ error: e.message })
  }
}
