const HDWalletProvider = require('@truffle/hdwallet-provider')
const Web3 = require('web3')
const {abi, evm} = require('../etherium/build/Factory.json')
// const compiledCampaign = require('../etherium/build/Campaign.json')

const mnemonic = 'equip leaf obscure talk file ordinary miss twice under party gossip loan'
const providerOrUrl = 'https://rinkeby.infura.io/v3/e5411e2a2780484dba3237e2a0c1dce0'

const provider = new HDWalletProvider({mnemonic,providerOrUrl});

const web3 = new Web3(provider)

const deploy = async () => {
  const accounts = await web3.eth.getAccounts()

  console.log('Account: ', accounts[0])

  const result = await new web3.eth.Contract(abi)
  .deploy({data: evm.bytecode.object})
  .send({from: accounts[0], gas: 3000000})

  console.log('Result address: ', result.options.address)
  // 0xdcaa00BbbeBFAa7223b2CB93fc4f7EfAe8713759
}
 
deploy()
