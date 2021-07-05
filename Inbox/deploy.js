const HDWalletProvider = require('@truffle/hdwallet-provider')
const Web3 = require('web3')
const {abi, evm} = require('./compile')

const mnemonic = 'equip leaf obscure talk file ordinary miss twice under party gossip loan'
const providerOrUrl = 'https://rinkeby.infura.io/v3/e5411e2a2780484dba3237e2a0c1dce0'

const provider = new HDWalletProvider({mnemonic,providerOrUrl});

const web3 = new Web3(provider)

const deploy = async () => {
  const accounts = await web3.eth.getAccounts()
  const INITIAL_STRING = 'Hi there!'

  console.log('Account: ', accounts[0])

  const result = await new web3.eth.Contract(abi)
  .deploy({data: evm.bytecode.object, arguments: [INITIAL_STRING]})
  .send({from: accounts[0], gas: 1000000})

  console.log('Result: ', result)
}
 
deploy()