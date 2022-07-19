const runBatchTX = require('./batchTx')

const CONTRACT_ADDRESS_BLOOD = {
  80001: '0xC879CE4DB4AeD72E1ad243A2F9d775e60BED0D33',
  4: '0xc3b99c2a46b8DC82C96B8b61ED3A4c5E271164D7',
  97: '0x987Dcd895948c476654792d92f282A256099EA02',
  3: '0xA093B771F127FbBdbd2e2E722Aa2ee01F361384c',
  4002: '0xA093B771F127FbBdbd2e2E722Aa2ee01F361384c'
}

const CONTRACT_ADDRESS_BRIDGE = {
  80001: '0xE4c5a2aD567ee3820B679eE759D6E8113f7897E5',
  4: '0xfEA5Dc6668450e3De398320a53853Eb64DE887d1',
  97: '0xeDfB4F3Be49A087f037a68fFD217dd758ceF46F4',
  3: '0xF8ebdaE255fbdbB27ED8cdEaa5cF86E787470143',
  4002: '0xF8ebdaE255fbdbB27ED8cdEaa5cF86E787470143'
}

const ABI_BLOOD_TOKEN = require('../build/contracts/BloodToken.json').abi
const ABI_MRC20Bridge = require('../build/contracts/MRC20Bridge.json').abi

// // ADD minter role

// for (
//   let index = 0;
//   index < Object.keys(CONTRACT_ADDRESS_BLOOD).length;
//   index++
// ) {
//   const chainId = Object.keys(CONTRACT_ADDRESS_BLOOD)[index]
//   console.log({ chainId, bridge: CONTRACT_ADDRESS_BRIDGE[chainId] })
//   runBatchTX(
//     CONTRACT_ADDRESS_BLOOD[chainId],
//     'grantRole',
//     [
//       '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
//       CONTRACT_ADDRESS_BRIDGE[chainId]
//     ],
//     ABI_BLOOD_TOKEN,
//     chainId
//   )
// }

// // ADD burner role

// for (
//   let index = 0;
//   index < Object.keys(CONTRACT_ADDRESS_BLOOD).length;
//   index++
// ) {
//   const chainId = Object.keys(CONTRACT_ADDRESS_BLOOD)[index]
//   runBatchTX(
//     CONTRACT_ADDRESS_BLOOD[chainId],
//     'grantRole',
//     [
//       '0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848',
//       CONTRACT_ADDRESS_BRIDGE[chainId]
//     ],
//     ABI_BLOOD_TOKEN,
//     chainId
//   )
// }

// Add token to bridge

for (
  let index = 0;
  index < Object.keys(CONTRACT_ADDRESS_BLOOD).length;
  index++
) {
  const chainId = Object.keys(CONTRACT_ADDRESS_BLOOD)[index]
  runBatchTX(
    CONTRACT_ADDRESS_BRIDGE[chainId],
    'addToken',
    [1, CONTRACT_ADDRESS_BLOOD[chainId]],
    ABI_MRC20Bridge,
    chainId
  )
}
