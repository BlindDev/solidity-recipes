const assert = require('assert')
const ganache = require('ganache-cli')
const Web3 = require('web3')
const web3 = new Web3(ganache.provider())
const {abi, evm} = require('../compile')

let lottery
let accounts;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts()

  lottery = await new web3.eth.Contract(abi)
  .deploy({data: evm.bytecode.object})
  .send({from: accounts[0], gas: 1000000})
})

describe('Lottery Contract', () => {
  it('deploys contract', () => {
    assert.ok(lottery.options.address)
  })

  it('allows accounts to enter', async() => {
    await lottery.methods.enter().send({
      from: accounts[0],
      value: web3.utils.toWei('0.02', 'ether')
    })

    await lottery.methods.enter().send({
      from: accounts[1],
      value: web3.utils.toWei('0.02', 'ether')
    })

    await lottery.methods.enter().send({
      from: accounts[2],
      value: web3.utils.toWei('0.02', 'ether')
    })

    const players = await lottery.methods.getPlayers().call({
      from: accounts[0]
    })

    assert.strictEqual(accounts[0], players[0])
    assert.strictEqual(accounts[1], players[1])
    assert.strictEqual(accounts[2], players[2])

  })

  it('requires minimal amount of ether to enter', async () => {

    try {
      await lottery.methods.enter().send({
        from: accounts[0],
        value: 200
      })
      assert(false)
    } catch (error) {
      assert(error)
    }
    
  })

  it('only manager can pick winner', async () => {

    try {
      await lottery.methods.pickWinner().send({
        from: accounts[0],
      })
      assert(false)
    } catch (error) {
      assert(error)
    }
    
  })

  it('sends money to winner and resets array of players', async () => {

    await lottery.methods.enter().send({
      from: accounts[0],
      value: web3.utils.toWei('2', 'ether')
    })


    const initialBallance = await web3.eth.getBalance(accounts[0])
    
    await lottery.methods.pickWinner().send({
      from: accounts[0],
    })

    const endBallance = await web3.eth.getBalance(accounts[0])

    const difference = endBallance - initialBallance

    assert(difference > web3.utils.toWei('1.8', 'ether'))
  })
})