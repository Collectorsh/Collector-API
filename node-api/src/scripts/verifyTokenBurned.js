import { connection } from "../utils/RpcConnection.js";

export async function verifyTokenBurned(mintPublicKey) {
  let state = ''
  try {
    //verify token is burned
    const mintAccountInfo = await connection.getParsedAccountInfo(mintPublicKey);
    if (mintAccountInfo === null) {
      state = 'burned'
    } else {
      if (mintAccountInfo.value.data.parsed.info.supply == '0') {
        state = 'burned'
      }
    }
  } catch (error) {
    // console.log("Error fetching account to verify token burned:", error)
    state = 'error-verifying-burn'
  }
  return state
}