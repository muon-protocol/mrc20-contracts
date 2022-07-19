require('dotenv').config({ path: '../.env' })

const { networksWeb3, sendTx } = require('./web3')

module.exports = async (contractAddress, methodName, params, abi, chainId) => {
  const web3 = networksWeb3[chainId]

  const acc = web3.eth.accounts.privateKeyToAccount(process.env.PK)
  web3.eth.accounts.wallet.add(acc)
  web3.eth.defaultAccount = acc.address

  // for (let index = 0; index < Object.keys(networksWeb3).length; index++) {
  //   const chainId = Object.keys(networksWeb3)[index]
  console.log({
    contractAddress,
    methodName,
    params,
    chainId,
    from: acc.address
  })
  const result = await sendTx(
    contractAddress,
    methodName,
    params,
    abi,
    chainId,
    acc.address
  )
  console.log(result)
  // }
}
