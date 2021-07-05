const assert = require('assert')
const ganache = require('ganache-cli')
const Web3 = require('web3')
const web3 = new Web3(ganache.provider())

const compiledFactory = require('../etherium/build/Factory.json')
const compiledCampaign = require('../etherium/build/Campaign.json')

let accounts;
let factory;
let campaignAddress;
let campaign;
let account5Balance;

const convertedBallance = async (account) => {
  let balance = await new web3.eth.getBalance(account)
  balance = web3.utils.fromWei(balance, 'ether')
  balance = parseFloat(balance)

  return balance
}

beforeEach(async() => {
  // generate 10 accounts
  accounts = await web3.eth.getAccounts();
  account5Balance = await convertedBallance(accounts[5])
  // load from bytecode
  factory = await new web3.eth.Contract(compiledFactory.abi)
  .deploy({data: compiledFactory.evm.bytecode.object})
  .send({from: accounts[0], gas: 3000000})

  await factory.methods.createCampaign('100')
  .send({from: accounts[0], gas: 1000000})

  const campaigns = await factory.methods.getDeployedCampaigns()
  .call()

  campaignAddress = campaigns[0]
  // load from address
  campaign = await new web3.eth.Contract(compiledCampaign.abi, campaignAddress)
})


describe('Campaigns', () => {
  it('deploys a factory and a campaign', () => {
    assert.ok(factory.options.address)
    assert.ok(campaign.options.address)
  })

  it('marks caller as a campaign manager', async() => {
    const manager = await campaign.methods.manager().call()
    assert.strictEqual(manager, accounts[0])
  })

  it('allows to contribute money and marks them as approvers', async () => {
    await campaign.methods.contribute()
    .send({value: 200, from: accounts[1]})

    const isContributor = await campaign.methods.approvers(accounts[1])
    .call()

    assert(isContributor)
  })

  it('requires minimal contribution', async () => {

    try {
      await campaign.methods.contribute()
      .send({value: 10, from: accounts[3]})
      assert(false)

    } catch (error) {
      assert(error)
    }
    
  })

  it('allows a manager to make a payment requiest', async() => {
    await campaign.methods.createRequest("Buy batteries", '100', accounts[1])
    .send({gas: 1000000, from: accounts[0]})

    const request = await campaign.methods.requests(0)
    .call()

    assert.strictEqual(request.description, "Buy batteries")
  })

  it('processes requiest', async () => {
    await campaign.methods.contribute()
      .send({value: web3.utils.toWei('10', 'ether'), from: accounts[0]})

    await campaign.methods.createRequest("Sell batteries", web3.utils.toWei('5', 'ether'), accounts[5])
    .send({gas: 1000000, from: accounts[0]})

    const request = await campaign.methods.requests(0)
    .call()
    assert.strictEqual(request.description, "Sell batteries")


    await campaign.methods.approveRequest(0)
    .send({gas: 1000000, from: accounts[0]})

    await campaign.methods.finalizeRequest(0)
    .send({gas: 1000000, from: accounts[0]})

    
    const balance = await convertedBallance(accounts[5])
    console.log(balance, account5Balance)
    assert(balance > account5Balance)
  })
})