
import crypto from "crypto"
import fs from "fs"
import path from "path"
import { Keypair, Connection } from "@solana/web3.js";
import { Metaplex, bundlrStorage, keypairIdentity, toMetaplexFile, toMetaplexFileFromBrowser } from "@metaplex-foundation/js";
import { formatRSAPrivateKey } from '../utils/formatRSA.js';
import { connection } from "../utils/RpcConnection.js";
import postgres from "../../db/postgres.js";
import { logtail } from "../utils/logtail.js";
import { parseError } from "../utils/misc.js";

//Standard Ref = https://docs.metaplex.com/programs/token-metadata/changelog/v1.0

export const uploadMetadata = async (req, res) => { 
  try {
    const imageFile = req.files.imageFile[0]
    const altMediaFile = req.files.altMediaFile?.[0]

    const nft = JSON.parse(req.body.nft)
    const { name, description, seller_fee_basis_points, attributes, creators, external_url, category } = nft

    const handleUpload = async (imageBuffer, altBuffer) => {
      const imgExtension = path.extname(imageFile.originalname)
      const imgMetaplexFile = toMetaplexFile(imageBuffer, imageFile.originalname, {
        contentType: imageFile.mimetype,
        extension: imgExtension
      });
      
      let altMetaplexFile, altExtension;
      if (altMediaFile) {
        altExtension = path.extname(altMediaFile.originalname)

        const isGLB = altExtension === ".glb";
        const mimetype = isGLB ? "model/gltf-binary" : altMediaFile.mimetype

        altMetaplexFile = toMetaplexFile(altBuffer, altMediaFile.originalname, {
          contentType: mimetype,
          extension: altExtension
        });
      }
      
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

      const filesToUpload = [imgMetaplexFile, altMetaplexFile].filter((f) => f)//filter out undefined
      const [imageUri, altUri] = await bundlr.uploadAll(filesToUpload);

      const imageUriWithExtension = imageUri + "?ext=" + imgExtension.replace(".", "")

      const files = [{
        type: imgMetaplexFile.contentType,
        uri: imageUriWithExtension
      }]

      let altUriWithExtension = undefined
      if (altUri) {
        altUriWithExtension = altUri + "?ext=" + altExtension.replace(".", "")

        //insert alt media first aas it will be primary, with the image being fallback
        files.unshift({
          type: altMetaplexFile.contentType,
          uri: altUriWithExtension
        })
      }

      let metadataRes
      try {
        metadataRes = await bundlrMetaplex
          .nfts()
          .uploadMetadata({
            name,
            description,
            image: imageUriWithExtension,
            animation_url: altUriWithExtension,
            seller_fee_basis_points,
            attributes,
            external_url,
            properties: {
              category,
              files,
              creators
            }
          });
        
        if(!metadataRes) throw new Error("Failed to upload metadata")
      } catch (e) {
        const err = parseError(e)
        logtail.error(`uploadMetadata error: ${ err }`)
        res.status(500).json({ error: err })
      }
      
      const uri = metadataRes.uri
      const metadata = metadataRes.metadata

      res.status(200).json({ uri, metadata })
    }

    if (!altMediaFile) {
      fs.readFile(imageFile.path, async (err, data) => {
        if (err) throw err;
        const imageBuffer = data;

        await handleUpload(imageBuffer)
      })
    } else {
      fs.readFile(imageFile.path, async (err, imageData) => {
        if (err) throw err;
        const imageBuffer = imageData;

        fs.readFile(altMediaFile.path, async (err, altData) => {
          if (err) throw err;
          const altBuffer = altData;

          await handleUpload(imageBuffer, altBuffer)
        })
      })
    }

  } catch (e) {
    const err = parseError(e)
    logtail.error(`uploadMetadata Route error: ${err}`)
    res.status(500).json({ error: err })
  }
}
