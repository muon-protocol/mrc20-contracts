const token = artifacts.require('BloodToken')

contract('BloodToken', (accounts) => {
  let token, minterRole, burnerRole
  let mintAmount = web3.utils.toWei('500')

  beforeEach(async () => {
    token = await BloodToken.new(accounts[1], 'BT', 'Blood TK', '18')
    minterRole = await token.MINTER_ROLE.call()
    burnerRole = await token.BURNER_ROLE.call()
  })

  describe('Burn and Mint token', async () => {
    //   Mint Token
    test(' other account should not be abled to mint', async () => {
      let res = await token.mint(accounts[0], mintAmount)
      expect(res).toBeFalsy()
    })

    test('admin can mint', async () => {
      let res = await token.mint(accounts[0], mintAmount, { from: accounts[1] })
      let balance = await token.balanceOf(accounts[0])
      expect(res).toBeTruthy()
      expect(balance).toBe(mintAmount)
    })

    // Burn Token
    test(' other account should not be abled to burn', async () => {
      let res = await token.burn(accounts[0], mintAmount)
      expect(res).toBeFalsy()
    })

    test('admin can mint', async () => {
      let res = await token.burn(accounts[0], mintAmount, { from: accounts[1] })
      let balance = await token.balanceOf(accounts[0])
      expect(res).toBeTruthy()
      expect(balance).toBe(0)
    })
  })
})
