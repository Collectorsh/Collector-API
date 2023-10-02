class ScriptController < ApplicationController
  def upload_metadata
    puts "Uploading metadata"
    #move to env var 
    # add rpcenv here too
    rsaPrivateKey = "-----BEGIN PRIVATE KEY-----MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDp7j+WwFwZLAS+Xc3q6c7gUr3bGJ5tF64lmtPTHewIgFzyVwEBS8U7RNGc473ZIBK9mULf8gVDb1TpWpQU+wSH4DWT6EWFH/PmbgbeIApZgqs9XxHmJRv6Z2SAdk09Lu/3w/JPhlJcKtDG9PuQOG8q8185cApk/kjgnoFgqOE/aC9fTWXmUpQAgq8bc1zc4kJfDjPVMzPK2PdQCCYNg7LduwswjLlE64TvX6X6OEhvq/01S3XuBVyX0UVFmCoi8xR//j2VN4PtDX20zdYkQkzOTwTpjOTfws+7Sx+9+3DLQMStVN5ckLCVENPveXiUVzGjq1MLDeMjpV3pDgLq9c17AgMBAAECggEASAapwI5QrRVvDngOZ1Z+8nW3bCa73MYOQhjWQKn1Wza+p4UfU5lTTGjni0FZ2mj0LDlsrEw1z6oPQFw5vO3+2qEvje9VvGP2skvNRIYj+aRwehB0D+L8JtC/0ofaR0zU6PoFePPYFvW924xhimm93MEbYDF9mdPrd3GGT08gL2ebfqHeAAZyQlGUBrPTSwDEQXZczTnzE22NYfGMmnySgs2gOPN9oKhVqm3BMPif6OJjaALY0l007B6Sk/jL+Tu2Il5ozZpV45qBzAWRHhUji4ySQDKOHE1koUKun2s58MWmS1QSFhLdFPFDviKJouvXojKeU2+LcmkV3yYeRKHpiQKBgQD242iOBB7KLJP33OCGJbtWBQf5JckraGQdbcaNRFPPBNmYLe1E/AzMMvimu8a5cSlPds/FX/Siqq7Bi3Bs2s9Dn/G3vcwq4f9eolH0Zr4UrblngJRs2ULR9CaZSPz95Wdgsf26Ur3s5SXD6/Q/Hr8Mfgw7AVSkwGVbmh5gxCuhwwKBgQDykGqhRLc7f3qNJWroPPCLYj5to/ewfGFXXMRTuZlhbCP/VM+4Vaij4cQQz+50eo00fDXqH/TczFBwK4G70os72vlBeomoGGCpqyBjrsIuCFaqaRsziaSgDwweCymuRz6PdAtGZG7PSQyq3qfK3oogIprrbjx25sebpN66tb3x6QKBgQDNWgOKNHUjtoZw4OBD1DiI6PBj1IEKQO8c50UCFXYcOC2A/ZpgCcHfSvo1PPSjJDO3K9zPj+ucLZnj1EZz1GAXIH9eVFjwxj+xiBPg1GCANKuFIpbSHrgMiCZe0y3TRS+CZynjA5WD6GlMGAN1SO6hxmoH3ih4TKtB0OQ5mpGsHwKBgGdkdX8eSjg7Q2Kso2AwsZvIGbIkZSy+J8PUT/8cKqvjK4jnfs8k/Ag28Jr19r+BiXToyRZt3rLLCDJ36QnFWgH+eaaWc9zJ31ITFnBHCpASj9Z9jNGwBxMOtuyLd43I4nrFTRUJNE545cRjugP4Tcoa1gwqZe2Mu2K1qRbO5xMZAoGBAI2AuksQNAzc22LOVpLLJwSClty6ZRUI+n7kWAcOnYLo2oW0AJYA7nikK91I7LQ96OOCgM8ehmcOd1sH5WWxokOeyzv3foCb4uO4Hzg3yv+I9GaqisEldJ739TttRxOWFC15nUJLiO+KvroOp/bBveahfl7dhxtDnyM+PZVtVJjx-----END PRIVATE KEY-----"
    fundingHash = KeyHash.find_by(name: 'curation_authority_funds').hash

    
    script_params = { 
      imageBuffer: params[:imageBuffer],
      nft: params[:nft],
      fundingHash: fundingHash, 
      rsaPrivateKey: rsaPrivateKey,
    }  

    puts "Params"

    temp_file_path = Rails.root.join('tmp', 'params.json')
    File.write(temp_file_path, script_params.to_json)

  
    script_path = Rails.root.join('app', 'javascript', 'uploadMetadata.js')
    node_command = "node #{script_path} '#{temp_file_path}'"
    result = `#{node_command}`

    puts "Result gotten"

    parsed = JSON.parse(result)

    puts "Parsed result #{parsed}"

    
    File.delete(temp_file_path) if File.exist?(temp_file_path)


    if parsed['uri']
      return render json: { status: 'success', uri: parsed['uri'] }
    else
      return render json: { status: 'error', error: parsed['error'] }
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    # In your Ruby controller, after executing the node command
    File.delete(temp_file_path) if File.exist?(temp_file_path)

    return render json: { status: 'error', error: e.message }
  end
end