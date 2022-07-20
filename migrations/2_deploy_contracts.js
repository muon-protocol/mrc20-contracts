const bridge = artifacts.require('./MRC20Bridge.sol')
const token = artifacts.require('./BloodToken.sol')
const presale = artifacts.require('./MRC20Presale.sol')
const presaleClaimable = artifacts.require('./MRC20PresaleClaimable.sol')
const muonPresale = artifacts.require('./MuonPresale.sol')

const ERT_d6 = artifacts.require('./ERT_d6.sol')

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
      case 'token':
        await deployer.deploy(
          token,
          params['name'],
          params['symbol'],
          params['decimals']
        )
        break
      case 'bridge':
        let minReqSigs = 1
        let fee = 0

        if (!params['muonAddress']) {
          throw { message: 'muonAddress required.' }
        }

        await deployer.deploy(bridge, params['muonAddress'], minReqSigs, fee)
        break
      case 'presale':
        if (!params['muonAddress']) {
          throw { message: 'muonAddress required.' }
        }
        if (!params['presaleToken']) {
          throw { message: 'presaleToken required.' }
        }
        if (!params['mounFeesAddress']) {
          throw { message: 'mounFeesAddress required.' }
        }
        await deployer.deploy(
          presale,
          params['muonAddress'],
          params['presaleToken'],
          params['mounFeesAddress']
        )
        break

      case 'presaleClaimable':
        if (!params['muonAddress']) {
          throw { message: 'muonAddress required.' }
        }
        if (!params['presaleToken']) {
          throw { message: 'presaleToken required.' }
        }
        if (!params['mounFeesAddress']) {
          throw { message: 'mounFeesAddress required.' }
        }
        await deployer.deploy(
          presaleClaimable,
          params['muonAddress'],
          params['presaleToken'],
          params['mounFeesAddress']
        )
        break
      case 'muonPresale':
        if (!params['muonAddress']) {
          throw { message: 'muonAddress required.' }
        }
        await deployer.deploy(muonPresale, params['muonAddress'])
        break
      case 'ERT':
        await deployer.deploy(ERT_d6)
        break

      default:
        break
    }
  })
}
