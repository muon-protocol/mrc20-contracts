const Web3 = require('web3')

const HttpProvider = Web3.providers.HttpProvider

const networksWeb3 = {
  //   1: new Web3(
  //     new HttpProvider('https://mainnet.infura.io/v3/' + process.env.INFURA_KEY)
  //   ),
  3: new Web3(
    new HttpProvider('https://ropsten.infura.io/v3/' + process.env.INFURA_KEY)
  ),
  4: new Web3(
    new HttpProvider('https://rinkeby.infura.io/v3/' + process.env.INFURA_KEY)
  ),
  //   56: new Web3(new HttpProvider('https://bsc-dataseed1.binance.org')),
  97: new Web3(
    new HttpProvider('https://data-seed-prebsc-1-s2.binance.org:8545')
  ),
  //   250: new Web3(new HttpProvider('https://rpcapi.fantom.network/')),
  4002: new Web3(new HttpProvider('https://rpc.testnet.fantom.network/')),
  //   100: new Web3(new HttpProvider('https://rpc.xdaichain.com/')),
  // 77: new Web3(new HttpProvider('https://sokol.poa.network')),
  //   137: new Web3(new HttpProvider('https://rpc-mainnet.maticvigil.com/')),
  80001: new Web3(new HttpProvider('https://rpc-mumbai.maticvigil.com/'))
}

function getWeb3(chainId) {
  if (networksWeb3[chainId]) return Promise.resolve(networksWeb3[chainId])
  else return Promise.reject({ message: `invalid chainId "${chainId}"` })
}

async function sendTx(contractAddress, methodName, params, abi, chainId, from) {
  const web3 = await getWeb3(chainId)
  let contract = new web3.eth.Contract(abi, contractAddress)

  return contract.methods[methodName](...params).send({ from, gas: 3000000 })
}

module.exports = { sendTx, networksWeb3 }
