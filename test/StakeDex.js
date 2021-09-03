const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { toBN } = require('web3-utils');
const { BN, expectEvent, expectRevert, time, constants, balance } = require('@openzeppelin/test-helpers');

const [ admin, deployer, user, holder, investor1, investor2, investor3, investor4, investor11, investor12 ] = accounts;


const StakeDex = contract.fromArtifact('StakeDex');
const Mock = contract.fromArtifact('Mock');
const WETH = contract.fromArtifact('WBNB')




describe("StakeDex", function() {
  const BASE = new BN('10').pow(new BN('18'))
  const DEV =  "0x0000000000000000000000000000000000000003";
  const FEE =  "0x0000000000000000000000000000000000000fee";
  const ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"



  beforeEach(async () => {
    this.TokenIn = await Mock.new("TokenIn", "IN", 18);
    this.TokenOut = await Mock.new("TokenOut", "OUT", 18);
    this.WETH = await WETH.new()

    await this.TokenIn.mint(investor1, toBN('1000').mul(BASE));
    await this.TokenIn.mint(investor2, toBN('1000').mul(BASE));
    await this.TokenIn.mint(investor11, toBN('1000').mul(BASE));
    await this.TokenIn.mint(investor12, toBN('1000').mul(BASE));

    await this.TokenOut.mint(investor3, toBN('1000').mul(BASE));
    await this.TokenOut.mint(investor4, toBN('1000').mul(BASE));

    this.Dex = await StakeDex.new(FEE, this.WETH.address);
    await this.Dex.updateDefaultDecimals(10)
    await this.Dex.createPair(this.TokenIn.address, this.TokenOut.address)
  });

  it("StakeDex:createPair", async() => {
    let id = await this.Dex.getPairId(this.TokenIn.address, this.TokenOut.address);
    expect(id.toNumber()).to.eq(1)

    await this.Dex.createPair(this.TokenOut.address, this.TokenIn.address)
    let id2 = await this.Dex.getPairId(this.TokenOut.address, this.TokenIn.address);

    expect(id2.toNumber()).to.eq(2)
  })

  it("StakeDex:mint", async()=> {
      await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
      let amountIn = toBN('3').mul(BASE)
      let amountOut = toBN('1').mul(BASE)
      await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn, amountOut, { from: investor1 });
      let tokenId = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
      expect(tokenId.toNumber()).to.eq(1)

      let position = await this.Dex.positions(tokenId)
      expect(position.price.toString()).to.eq('3333333333')
      expect(position.pendingOut.toString()).to.eq('999999999900000000')

      // let id = await this.Dex.getPairId(this.TokenIn.address, this.TokenOut.address);
      let pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
      expect(pair.depths.map(a => a.toString())).to.have.members(
        ['999999999900000000']
      )
  })

  it("StakeDex:mint with ETH input", async()=> {
      let amountIn = toBN('3').mul(BASE)
      let amountOut = toBN('1').mul(BASE)
      await this.Dex.mint(ETH, this.TokenOut.address, amountIn, amountOut, { value: amountIn, from: investor1 });
      let tokenId = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
      expect(tokenId.toNumber()).to.eq(1)

      let position = await this.Dex.positions(tokenId)
      expect(position.price.toString()).to.eq('3333333333')
      expect(position.pendingOut.toString()).to.eq('999999999900000000')
      expect(position.etherInOrOut.toNumber()).to.eq(1)

      let wethBalance = await this.WETH.balanceOf(this.Dex.address)
      expect(wethBalance.toString()).to.eq(amountIn.toString())

      let pair = await this.Dex.pairs(this.WETH.address, this.TokenOut.address)
      expect(pair.depths.map(a => a.toString())).to.have.members(
        ['999999999900000000']
      )
  })

  it("StakeDex:mint with ETH output", async()=> {
      await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
      let amountIn = toBN('3').mul(BASE)
      let amountOut = toBN('1').mul(BASE)
      await this.Dex.mint(this.TokenIn.address, ETH, amountIn, amountOut, { from: investor1 });
      let tokenId = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
      expect(tokenId.toNumber()).to.eq(1)

      let position = await this.Dex.positions(tokenId)
      expect(position.price.toString()).to.eq('3333333333')
      expect(position.pendingOut.toString()).to.eq('999999999900000000')
      expect(position.etherInOrOut.toNumber()).to.eq(2)

      let pair = await this.Dex.pairs(this.TokenIn.address, this.WETH.address)
      expect(pair.depths.map(a => a.toString())).to.have.members(
        ['999999999900000000']
      )
  })

  it("StakeDex:burn without traded", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    let amountIn = toBN('3').mul(BASE)
    let amountOut = toBN('1').mul(BASE)
    let balanceBefore = await this.TokenIn.balanceOf(investor1)

    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn, amountOut, { from: investor1});

    let tokenId = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
    let balance0 = await this.TokenIn.balanceOf(investor1)
    await this.Dex.burn(tokenId, { from: investor1 })

    let balance1 = await this.TokenIn.balanceOf(investor1)
    expect(balance1.toString()).to.eq(balanceBefore.toString())
  })

  it("StakeDex:burn with ETH input", async() => {
    let amountIn = toBN('3').mul(BASE)
    let amountOut = toBN('1').mul(BASE)
    let balanceBefore = await this.TokenIn.balanceOf(investor1)

    await this.Dex.mint(ETH, this.TokenOut.address, amountIn, amountOut, { value: amountIn, from: investor1});

    let tokenId = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
    let balance0 = await this.TokenIn.balanceOf(investor1)

    let etherBefore = await balance.current(investor1)
    await this.Dex.burn(tokenId, { from: investor1 })
    let etherAfter = await balance.current(investor1)
    let amountInMin = toBN('299').mul(BASE).div(toBN('100'))
    expect(etherAfter.sub(etherBefore).gt(amountInMin)).to.be.true
  })

  it("StakeDex:burn, check taker and maker returns", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 });
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 });
    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('3').mul(BASE)
    let amountOut1 = toBN('1').mul(BASE)
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });
    // pendingOut = 999999999900000000

    // 3 -> 1.1, price = 3666666666
    let amountIn2 = toBN('3').mul(BASE)
    let amountOut2 = toBN('11').mul(BASE).div(toBN('10'))
    // pendingOut = 1099999999800000000

    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });

    // let pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
    // console.log(pair.prices.map(a=>a.toString()))
    // console.log(pair.depths.map(a=>a.toString()))

    let takeOut = toBN('6').mul(BASE)
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)
    expect(buyIn.amountIn.toString()).to.eq('2104208416533066131')
    expect(buyIn.amountReturn.toString()).to.eq('0')

    this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let tradedIn = await this.TokenIn.balanceOf(investor3)
    expect(tradedIn.toString()).to.eq(takeOut.toString())


    let tokenId1 = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
    await this.Dex.burn(tokenId1, { from: investor1 })
    let out1 = await this.TokenOut.balanceOf(investor1)

    expect(out1.toString()).to.eq("1001002003907915830") // 1001002003907915831


    let tokenId2 = await this.Dex.tokenOfOwnerByIndex(investor2, 0)
    await this.Dex.burn(tokenId2, { from: investor2 })
    let out2 = await this.TokenOut.balanceOf(investor2)

    expect(out2.toString()).to.eq("1101102204208617233") // 1101102204208617234
  })

  it("StakeDex:burn, check multi makers", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 })
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 })
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor11 })
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor12 })

    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('3').mul(BASE)
    let amountOut1 = toBN('1').mul(BASE)
    let tokenId1 = 1
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    let position1Before = await this.Dex.positions(tokenId1)
    expect(position1Before.pendingIn.toString()).to.eq('3000000000000000000')
    expect(position1Before.pendingOut.toString()).to.eq('999999999900000000')
    expect(position1Before.rateRedeemedIndex.toNumber()).to.eq(1)

    // 3 -> 1.1, price = 3666666666
    let amountIn2 = toBN('3').mul(BASE)
    let amountOut2 = toBN('11').mul(BASE).div(toBN('10'))
    let tokenId2 = 2
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });
    // pendingOut => 1099999999800000000

    // 6 -> 2, price = 3333333333
    let amountIn3 = toBN('6').mul(BASE)
    let amountOut3 = toBN('2').mul(BASE)
    let tokenId3 = 3
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn3, amountOut3, { from: investor11 });
    // pendingOut => 

    // 0.3 -> 0.1, price = 3333333333
    let amountIn4 = toBN('3').mul(BASE).div(toBN('10'))
    let amountOut4 = toBN('1').mul(BASE).div(toBN('10'))
    let tokenId4 = 4
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn4, amountOut4, { from: investor12 });
    // pendingOut => 99999999990000000

    let takeOut = toBN('123').mul(BASE).div(toBN('10'))
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)

    await this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)


    let position1BeforeBurn = await this.Dex.positions(tokenId1)
    expect(position1BeforeBurn.pendingIn.toString()).to.eq('0')
    expect(position1BeforeBurn.pendingOut.toString()).to.eq('0')
    expect(position1BeforeBurn.rateRedeemedIndex.toNumber()).to.eq(1)
    expect(position1BeforeBurn.filled.toString()).to.eq('999999999900000000')
    expect(position1BeforeBurn.feeRewarded.toString()).to.eq('1002004007915831')


    await this.Dex.burn(tokenId1, { from: investor1 })
    let out1 = await this.TokenOut.balanceOf(investor1)
    expect(out1.toString()).to.eq("1001002003907915831")

    await expectRevert(
      this.Dex.positions(tokenId1),
      "No position"
    );

    await this.Dex.burn(tokenId2, { from: investor2 })
    let out2 = await this.TokenOut.balanceOf(investor2)
    expect(out2.toString()).to.eq("1101102204208617233")

    await this.Dex.burn(tokenId3, { from: investor11 })
    let out3 = await this.TokenOut.balanceOf(investor11)
    expect(out3.toString()).to.eq("2002004007815831663")


    // let pos4 = await this.Dex.positions(tokenId4)

    // console.log("pendingIn===", pos4.pendingIn.toString())
    // console.log("pendingOut===", pos4.pendingOut.toString())
    // console.log("filled===", pos4.filled.toString())
    // console.log("feeRewarded===", pos4.feeRewarded.toString())

    // let dexBalance = await this.TokenOut.balanceOf(this.Dex.address)
    // console.log("dexBalance==", dexBalance.toString())

    // Rounding problem

    await this.Dex.burn(tokenId4, { from: investor12 })
    let out4 = await this.TokenOut.balanceOf(investor12)
    expect(out4.toString()).to.eq("100100200390791583")
  })

  it("StakeDex:swap, simple", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    let amountIn = toBN('3').mul(BASE)
    let amountOut = toBN('1').mul(BASE)
    // 3 -> 1 => 3333333333
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn, amountOut, { from: investor1});
    // pendingOut => 999999999900000000

    let buyIn = toBN('1002004007915831663') // will be fulfilled
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })

    let balanceInBefore = await this.TokenIn.balanceOf(investor3)
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS, { from: investor3 })
    let balanceInAfter = await this.TokenIn.balanceOf(investor3)
    let realOut = balanceInAfter.sub(balanceInBefore)

    expect(realOut.toString()).to.eq('3000000000000000000')
  })

  it("StakeDex:swap, take multi orders", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 });
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 });
    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('3').mul(BASE)
    let amountOut1 = toBN('1').mul(BASE)
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });
    // pendingOut = 999999999900000000


    // 3 -> 1.1, price = 3666666666
    let amountIn2 = toBN('3').mul(BASE)
    let amountOut2 = toBN('11').mul(BASE).div(toBN('10'))
    // pendingOut = 1099999999800000000

    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });

    let takeOut = toBN('6').mul(BASE)
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)
    expect(buyIn.amountIn.toString()).to.eq('2104208416533066131')
    expect(buyIn.amountReturn.toString()).to.eq('0')

    this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let tradedIn = await this.TokenIn.balanceOf(investor3)
    expect(tradedIn.toString()).to.eq(takeOut.toString())
  })

  it("StakeDex:swap, multi swaps", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 })

    // 30 -> 10, price = 3333333333
    let amountIn1 = toBN('30').mul(BASE)
    let amountOut1 = toBN('10').mul(BASE)
    let tokenId1 = 1
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    let pos0 = await this.Dex.positions(tokenId1)
    expect(pos0.pendingIn.toString()).to.eq('30000000000000000000')
    expect(pos0.pendingOut.toString()).to.eq('9999999999000000000')

    let amount1 = toBN('5').mul(BASE)

    let investor3BalanceBefore = await this.TokenIn.balanceOf(investor3);
    await this.TokenOut.transfer(this.Dex.address, amount1, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)
    let investor3BalanceAfter = await this.TokenIn.balanceOf(investor3)
    expect(investor3BalanceAfter.sub(investor3BalanceBefore).toString()).to.eq('14970000001497000000')

    let pos1 = await this.Dex.positions(tokenId1)
    
    expect(pos1.pendingIn.toString()).to.eq('15029999998503000002') // 15029999998503000000
    expect(pos1.pendingOut.toString()).to.eq('5009999999000000001') // 5009999999000000000
    expect(pos1.filled.toString()).to.eq('4989999999999999999') // 4990000000000000000
    expect(pos1.feeRewarded.toString()).to.eq('4999999999999999') // 4990000000000000000

    let increasedAmount = toBN('3').mul(BASE)
    // Redeem traded and fee rewarded after increased poisiton
    await this.Dex.increasePosition(tokenId1, increasedAmount, {  from: investor1 })
    let tradedAndFee = await this.TokenOut.balanceOf(investor1);
    expect(tradedAndFee.toString()).to.eq('4994999999999999998')

    let pos2 = await this.Dex.positions(tokenId1)
    expect(pos2.pendingIn.toString()).to.eq('18029999998503000002') // 18029999998503000000
    expect(pos2.pendingOut.toString()).to.eq('6009999998900000001') // 6009999998900000000
    expect(pos2.filled.toString()).to.eq('0')

    let amount2 = toBN('2').mul(BASE)
    await this.TokenOut.transfer(this.Dex.address, amount2, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)
    

    let pos3 = await this.Dex.positions(tokenId1)
    expect(pos3.pendingIn.toString()).to.eq('12041999997904200002') // 12041999997904200000
    expect(pos3.pendingOut.toString()).to.eq('4013999998900000001') // 4013999998900000000
    expect(pos3.filled.toString()).to.eq('1996000000000000000')
    expect(pos3.feeRewarded.toString()).to.eq('2000000000000000')


    // let dexIn = await this.TokenIn.balanceOf(this.Dex.address)
    // let dexOut = await this.TokenOut.balanceOf(this.Dex.address)
    // console.log("dexIn===", dexIn.toString()) // 12041999997904200000
    // console.log("dexOut===", dexOut.toString())

    // let pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
    // console.log(pair.depths.map(a=>a.toString()))

    let beforeIn = await this.TokenIn.balanceOf(investor1)
    let beforeOut = await this.TokenOut.balanceOf(investor1)
    await this.Dex.burn(tokenId1, { from: investor1 })
    let afterIn = await this.TokenIn.balanceOf(investor1)
    let afterOut = await this.TokenOut.balanceOf(investor1)

    expect(afterIn.sub(beforeIn).toString()).to.eq('12041999997904199999')
    expect(afterOut.sub(beforeOut).toString()).to.eq('1998000000000000000')

  })

  it("StakeDex:swaps with fulfilled", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 })
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 })
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor11 })
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor12 })

    let amountIn1 = toBN('12000000000000000000')
    let amountOut1 = toBN('4000000000000000000')
    let tokenId1 = 1
    // 12 -> 4, price = 0.3333333333
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    let pos1 = await this.Dex.positions(tokenId1)
    expect(pos1.pendingOut.toString()).to.eq('3999999999600000000')


    let totalBuyIn = toBN('0')
    let buyIn = toBN('1000000000000000000')
    totalBuyIn = totalBuyIn.add(buyIn)
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)


    // check investor1 filled
    pos1 = await this.Dex.positions(tokenId1)
    expect(pos1.pendingOut.toString()).to.eq('3001999999600000001')
    expect(pos1.filled.toString()).to.eq('997999999999999999')
    expect(pos1.feeRewarded.toString()).to.eq('999999999999999')


    let amountIn2 = toBN('3000000000000000000')
    let amountOut2 = toBN('1000000000000000000')
    let tokenId2 = 2
    // 3 -> 1, price = 0.3333333333
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });


    let pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('999999999900000000')

    buyIn = toBN('2000000000000000000')
    totalBuyIn = totalBuyIn.add(buyIn)
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)

    

    // check investor1 filled
    // check investor2 filled

    let amountIn3 = toBN('6000000000000000000')
    let amountOut3 = toBN('2000000000000000000')
    let tokenId3 = 3
    // 6 -> 2, price = 0.3333333333
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn3, amountOut3, { from: investor11 });

    pos1 = await this.Dex.positions(tokenId1)
    expect(pos1.pendingOut.toString()).to.eq('1504750624300093782')
    expect(pos1.filled.toString()).to.eq('2495249375299906218') // 1497249375299906218 + 998000000000000000
    expect(pos1.feeRewarded.toString()).to.eq('2500249875050006') // 1500249875050006 + 1000000000000000

    pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('501249375199906219')
    expect(pos2.filled.toString()).to.eq('498750624700093781')
    expect(pos2.feeRewarded.toString()).to.eq('499750124949993')

    let pos3 = await this.Dex.positions(tokenId3)
    expect(pos3.pendingOut.toString()).to.eq('1999999999800000000')
    expect(pos3.filled.toString()).to.eq('0')
    expect(pos3.feeRewarded.toString()).to.eq('0')


    let pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
    console.log(pair.depths[0].toString())

    // total swap 2000000000000000000

    for(var i = 0; i < 10; i++) {
      // swap
      buyIn = toBN('100000000000000000')
      totalBuyIn = totalBuyIn.add(buyIn)
      await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
      await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)
    }

    buyIn = toBN('100000000000000000')
    totalBuyIn = totalBuyIn.add(buyIn)
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)

    buyIn = toBN('500000000000000000')
    totalBuyIn = totalBuyIn.add(buyIn)
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)

    buyIn = toBN('400000000000000000')
    totalBuyIn = totalBuyIn.add(buyIn)
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)


    let rates = await this.Dex.getRates(this.TokenIn.address, this.TokenOut.address, toBN('3333333333'))
    console.log(rates.tradedRates.map(a=>a.toString()))
    // bal = await this.TokenOut.balanceOf(this.Dex.address)
    // reserve = await this.Dex.reserves(this.TokenOut.address)
    // console.log(bal.toString(), reserve.toString())

    // pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
    // console.log(pair.depths[0].toString())

    console.log("totalBuyIn=", totalBuyIn.toString())

    pos1 = await this.Dex.positions(tokenId1)
    expect(pos1.pendingOut.toString()).to.eq('755004681557255702')
    expect(pos1.filled.toString()).to.eq('3244995318042744298') // 3244995318042744297 = 1497249375299906218 + 998000000000000000 + 749745942742838079
    expect(pos1.feeRewarded.toString()).to.eq('3251498314672088') // 3251498314672088 = 1500249875050006 + 1000000000000000 +751248439622082

    pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('251500560154015809')
    expect(pos2.filled.toString()).to.eq('748499439745984191') // 748499439745984191 = 498750624700093782 + 249748815045890409
    expect(pos2.feeRewarded.toString()).to.eq('749999438623230') // 749999438623230 = 499750124949994 + 250249313673236

    pos3 = await this.Dex.positions(tokenId3)
    expect(pos3.pendingOut.toString()).to.eq('1003494757588728490')
    expect(pos3.filled.toString()).to.eq('996505242211271510')
    expect(pos3.feeRewarded.toString()).to.eq('998502246704680')

   
    // check investor1 filled
    // check investor2 filled
    // check investor11 filled

    // investor1 burn
    await this.Dex.burn(tokenId1, { from: investor1 });
    await expectRevert(
      this.Dex.positions(tokenId1),
      "No position"
    );
    let investor1Out = await this.TokenOut.balanceOf(investor1)
    expect(investor1Out.toString()).to.eq('3248246816357416386') // filled + fee


    pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
    console.log(pair.depths[0].toString())

    // pos1 = await this.Dex.positions(tokenId1)
    // expect(pos1.pendingOut.toString()).to.eq('755004681557255702')
    // expect(pos1.filled.toString()).to.eq('3244995318042744298') 
    // expect(pos1.feeRewarded.toString()).to.eq('3251498314672088') 

    pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('251500560154015809')
    expect(pos2.filled.toString()).to.eq('748499439745984191') 
    expect(pos2.feeRewarded.toString()).to.eq('749999438623230') 

    pos3 = await this.Dex.positions(tokenId3)
    expect(pos3.pendingOut.toString()).to.eq('1003494757588728490')
    expect(pos3.filled.toString()).to.eq('996505242211271510')
    expect(pos3.feeRewarded.toString()).to.eq('998502246704680')
    

    //fulfil
    buyIn = toBN('2000000000000000000')
    totalBuyIn = totalBuyIn.add(buyIn)
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)





    pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('0')
    expect(pos2.filled.toString()).to.eq('999999999900000000') // 748499439745984191 = 498750624700093782 + 249748815045890409
    expect(pos2.feeRewarded.toString()).to.eq('1002004007915831') // 749999438623230 + 252004569292600

    pos3 = await this.Dex.positions(tokenId3)
    expect(pos3.pendingOut.toString()).to.eq('0')
    expect(pos3.filled.toString()).to.eq('1999999999800000000')
    expect(pos3.feeRewarded.toString()).to.eq('2004008015831662') // 998502246704680 + 1005505769126982



    // check investor1 filled
    // check investor2 filled
    // check investor11 filled

    amountIn1 = toBN('6000000000000000000')
    amountOut1 = toBN('2000000000000000000')
    let tokenId4 = 4
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });
    let pos4 = await this.Dex.positions(tokenId4);
    expect(pos4.pendingOut.toString()).to.eq('1999999999800000000')


    amountIn2 = toBN('3000000000000000000')
    amountOut2 = toBN('1000000000000000000')
    await this.Dex.increasePosition(tokenId2, amountIn2, { from: investor2 });
    let investor2Out = await this.TokenOut.balanceOf(investor2)
    expect(investor2Out.toString()).to.eq('1001002003907915831')

    pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('999999999900000000')
    expect(pos2.filled.toString()).to.eq('0')

    // Check investor1
    // Check investor2

    // swap 1
    buyIn = toBN('1000000000000000000')
    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, investor3)

    pos1 = await this.Dex.positions(tokenId4)
    expect(pos1.pendingOut.toString()).to.eq('1334666666466666667')
    expect(pos1.filled.toString()).to.eq('665333333333333333')
    expect(pos1.feeRewarded.toString()).to.eq('666666666666666')

    pos2 = await this.Dex.positions(tokenId2)
    expect(pos2.pendingOut.toString()).to.eq('667333333233333334')
    expect(pos2.filled.toString()).to.eq('332666666666666666')
    expect(pos2.feeRewarded.toString()).to.eq('333333333333333')


    // investor11 redeem
    await this.Dex.redeem(tokenId3, { from: investor11 })

    let balance11 = await this.TokenOut.balanceOf(investor11)
    expect(balance11.toString()).to.eq('2002004007815831662')
  })

  it("StakeDex:redeem with ETH output", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    let amountIn = toBN('3').mul(BASE)
    let amountOut = toBN('1').mul(BASE)
    // 3 -> 1, price = 0.3333333333
    await this.Dex.mint(this.TokenIn.address, ETH, amountIn, amountOut, { from: investor1 });
    let tokenId = 1
    let position = await this.Dex.positions(tokenId)
    expect(position.price.toString()).to.eq('3333333333')
    expect(position.pendingOut.toString()).to.eq('999999999900000000')
    expect(position.etherInOrOut.toNumber()).to.eq(2)

    let buyIn = toBN('500000000000000000')
    await this.WETH.deposit({ value: buyIn, from: investor3 })
    let balanceWETH = await this.WETH.balanceOf(investor3);
    expect(balanceWETH.toString()).to.eq('500000000000000000')

    await this.WETH.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.WETH.address, this.TokenIn.address, investor3, investor3)

    let pos = await this.Dex.positions(tokenId)
    expect(pos.pendingOut.toString()).to.eq('500999999900000001')
    expect(pos.filled.toString()).to.eq('498999999999999999')
    expect(pos.feeRewarded.toString()).to.eq('499999999999999')


    let beforeETH = await balance.current(investor1)
    await this.Dex.increasePosition(tokenId, amountIn, { from: investor1 })
    let afterETH = await balance.current(investor1)
    console.log("ETH get =", afterETH.sub(beforeETH).toString())
    expect(afterETH.sub(beforeETH).gt(toBN('490000000000000000'))).to.be.true // consider gas const

    pos = await this.Dex.positions(tokenId)
    expect(pos.pendingOut.toString()).to.eq('1500999999800000001')
    expect(pos.filled.toString()).to.eq('0')
    expect(pos.feeRewarded.toString()).to.eq('0')


    buyIn = toBN('800000000000000000')
    await this.WETH.deposit({ value: buyIn, from: investor3 })
    balanceWETH = await this.WETH.balanceOf(investor3);
    expect(balanceWETH.toString()).to.eq('800000000000000000')
    await this.WETH.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.WETH.address, this.TokenIn.address, investor3, investor3)


    pos = await this.Dex.positions(tokenId)
    expect(pos.pendingOut.toString()).to.eq('702599999800000001')
    expect(pos.filled.toString()).to.eq('798400000000000000')
    expect(pos.feeRewarded.toString()).to.eq('800000000000000')

    beforeETH = await balance.current(investor1)
    await this.Dex.redeem(tokenId, { from: investor1 })
    afterETH = await balance.current(investor1)
    console.log("ETH get =", afterETH.sub(beforeETH).toString())
    expect(afterETH.sub(beforeETH).gt(toBN('790000000000000000'))).to.be.true 

    pos = await this.Dex.positions(tokenId)
    expect(pos.pendingIn.toString()).to.eq('2107799999610780002')
    expect(pos.pendingOut.toString()).to.eq('702599999800000001')
    expect(pos.filled.toString()).to.eq('0')
    expect(pos.feeRewarded.toString()).to.eq('0')


    let balanceBefore = await this.TokenIn.balanceOf(investor1)
    await this.Dex.decreasePosition(tokenId, toBN('1000000000000000011'), { from: investor1 })
    let balanceAfter = await this.TokenIn.balanceOf(investor1)
    expect(balanceAfter.sub(balanceBefore).toString()).to.eq('1000000000000000009')

    pos = await this.Dex.positions(tokenId)
    expect(pos.pendingIn.toString()).to.eq('1107799999610779993')
    expect(pos.pendingOut.toString()).to.eq('369266666499999998')
    expect(pos.filled.toString()).to.eq('0')
    expect(pos.feeRewarded.toString()).to.eq('0')

    balanceBefore = await this.TokenIn.balanceOf(investor1)
    await this.Dex.burn(tokenId, { from: investor1 })
    balanceAfter = await this.TokenIn.balanceOf(investor1)
    expect(balanceAfter.sub(balanceBefore).toString()).to.eq('1107799999610779990')
  })

});