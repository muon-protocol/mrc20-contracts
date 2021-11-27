const bridge = artifacts.require('./FearBridge.sol')
const fearToken = artifacts.require('./FearToken.sol')
const fearPresale = artifacts.require('./FearPresale.sol')

function parseArgv() {
  let args = process.argv.slice(2)
  let params = args.filter((arg) => arg.startsWith('--'))
  let result = {}
  params.map((p) => {
    let [key, value] = p.split('=')
    result[key.slice(2)] = value === undefined ? true : value
  })
  return result
}

module.exports = function (deployer) {
  deployer.then(async () => {
    let params = parseArgv()
    switch (params['contract']) {
      case 'FearToken':
        await deployer.deploy(
          fearToken,
          params['name'],
          params['symbol'],
          params['decimals']
        )
        break
      case 'FearBridge':
        let mintable = params['mintable'] || 'true'
        mintable = mintable === 'true' || mintable === true || mintable == 1
        let minReqSigs = 1
        let fee = 0

        if (!params['muonAddress']) {
          throw { message: 'muonAddress required.' }
        }

        await deployer.deploy(
          bridge,
          params['muonAddress'],
          mintable,
          minReqSigs,
          fee
        )
        break
      case 'FearPresale':
        await deployer.deploy(fearPresale, params['muonAddress'])
        break

      default:
        break
    }
  })
}
