const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('Temp test', function () {
  let temp
  before(async function () {
    [owner, client1, client2, client3, ...addrs] = await ethers.getSigners()
    const Temp = await ethers.getContractFactory('TemperatureOracleV1')
    temp = await Temp.deploy()
    await temp.deployed()
    await temp.setProvider(client1.address, true)
    await temp.setProvider(client2.address, true)
    await temp.setProvider(client3.address, true)
  })

  beforeEach(async function () { })

  describe('Success case', () => {
    it('2 right, one wrong', async () => {
      // create request 1
      tx = await temp.createRequest()
      receipt = await tx.wait()
      let event = receipt.events.filter(function (e) {
        return e.event == 'NewRequested'
      })[0]
      requestId = event.args.requestId;

      await temp.connect(client1).updateTemperature(requestId, 1505)
      await temp.connect(client2).updateTemperature(requestId, 1567)
      await temp.connect(client3).updateTemperature(requestId, 1700)

      expect((await temp.getTemperature())[0]).to.eq(1567)
    })
  })
})