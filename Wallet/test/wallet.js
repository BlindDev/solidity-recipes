const { expectRevert } = require('@openzeppelin/test-helpers')
const Wallet = artifacts.require('Wallet')

contract('Wallet', (accounts) => {
  let wallet

  beforeEach(async () => {
    wallet = await Wallet.new([accounts[0], accounts[1], accounts[2]], 2)
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: wallet.address,
      value: 1000,
    })
  })

  it('should have correct approvers and quorum', async () => {
    const approvers = await wallet.getApprovers()
    const quorum = await wallet.quorum()

    assert(approvers.length === 3)
    assert(approvers[0] === accounts[0])
    assert(approvers[1] === accounts[1])
    assert(approvers[2] === accounts[2])
    // numbers of contract are wrapped in BN.js
    assert(quorum.toNumber() === 2)
  })

  it('Should create transfers', async () => {
    await wallet.createTransfer(100, accounts[5], { from: accounts[0] })

    const transfers = await wallet.getTransfers()
    const zero = transfers[0]
    assert(transfers.length === 1)

    // numbers that are fields of struct are not wrapped in BN.js, but arr strings
    assert(zero.id === '0')
    assert(zero.amount === '100')
    assert(zero.to === accounts[5])
    assert(zero.approvals === '0')
    assert(zero.sent === false)
  })

  // use 'it.only' to launch only that test
  it('Should not create transfers if sender is not approved', async () => {
    await expectRevert(
      wallet.createTransfer(100, accounts[5], { from: accounts[4] }),
      'only approver allowed',
    )
  })

  it('should increment approvals', async () => {
    await wallet.createTransfer(100, accounts[5], { from: accounts[0] })

    await wallet.approveTransfer(0, { from: accounts[0] })

    const transfers = await wallet.getTransfers()
    const balance = await web3.eth.getBalance(wallet.address)
    const zero = transfers[0]
    assert(zero.approvals === '1')
    assert(zero.sent === false)
    assert(balance === '1000')
  })

  it('should send transfer if quorum reached', async () => {
    const balanceBefore = web3.utils.toBN(
      await web3.eth.getBalance(accounts[6]),
    )
    await wallet.createTransfer(100, accounts[6], { from: accounts[0] })
    await wallet.approveTransfer(0, { from: accounts[0] })
    await wallet.approveTransfer(0, { from: accounts[1] })

    const balanceAfter = web3.utils.toBN(await web3.eth.getBalance(accounts[6]))

    assert(balanceAfter.sub(balanceBefore).toNumber() === 100)
  })

  it('should not approve transfer if sender is not approved', async () => {
    await wallet.createTransfer(100, accounts[5], { from: accounts[0] })

    await expectRevert(
      wallet.approveTransfer(0, { from: accounts[4] }),
      'only approver allowed',
    )
  })

  it('should not approve transfer if transfer is already sent', async () => {
    await wallet.createTransfer(100, accounts[6], { from: accounts[0] })
    await wallet.approveTransfer(0, { from: accounts[0] })
    await wallet.approveTransfer(0, { from: accounts[1] })

    await expectRevert(
      wallet.approveTransfer(0, { from: accounts[2] }),
      'transfer has already been sent',
    )
  })

  it('should not approve transfer twice', async () => {
    await wallet.createTransfer(100, accounts[6], { from: accounts[0] })
    await wallet.approveTransfer(0, { from: accounts[0] })

    await expectRevert(
      wallet.approveTransfer(0, { from: accounts[0] }),
      'cannot approve transfer twice',
    )
  })
})
