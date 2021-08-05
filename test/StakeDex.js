const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { toBN } = require('web3-utils');
const { BN, expectEvent, expectRevert, time, constants, balance } = require('@openzeppelin/test-helpers');

const [ admin, deployer, user, holder, investor1, investor2, investor3, investor4, investor11, investor12 ] = accounts;


const StakeDex = contract.fromArtifact('StakeDex');
const Mock = contract.fromArtifact('Mock');




describe("StakeDex", function() {
  const BASE = new BN('10').pow(new BN('18'))
  const WETH = "0x0000000000000000000000000000000000000000";
  const DEV =  "0x0000000000000000000000000000000000000003";
  const FEE =  "0x0000000000000000000000000000000000000fee";


  beforeEach(async () => {
    this.TokenIn = await Mock.new("TokenIn", "IN", 18);
    this.TokenOut = await Mock.new("TokenOut", "OUT", 18);

    await this.TokenIn.mint(investor1, toBN('1000').mul(BASE));
    await this.TokenIn.mint(investor2, toBN('1000').mul(BASE));
    await this.TokenIn.mint(investor11, toBN('1000').mul(BASE));
    await this.TokenIn.mint(investor12, toBN('1000').mul(BASE));

    await this.TokenOut.mint(investor3, toBN('1000').mul(BASE));
    await this.TokenOut.mint(investor4, toBN('1000').mul(BASE));

    this.Dex = await StakeDex.new(FEE);
    await this.Dex.createPair(this.TokenIn.address, this.TokenOut.address)
  });

  it("StakeDex:createPair", async() => {
    let id = await this.Dex.getPairId(this.TokenIn.address, this.TokenOut.address);
    expect(id.toNumber()).to.eq(1)
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

  it("StakeDex:burn w/o traded", async() => {
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

  it("StakeDex:swap, simple", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    let amountIn = toBN('3').mul(BASE)
    let amountOut = toBN('1').mul(BASE)
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn, amountOut, { from: investor1});

    let price = amountOut.mul(toBN(10**10)).div(amountIn)

    // let id = await this.Dex.getPairId(this.TokenIn.address, this.TokenOut.address);
    let pair = await this.Dex.pairs(this.TokenIn.address, this.TokenOut.address)
    let buyIn = pair.depths[0].add(pair.depths[0].mul(toBN(20)).div(toBN(10000)))

    await this.TokenOut.transfer(this.Dex.address, buyIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS, { from: investor3 })

    let takeFee = pair.depths[0].mul(toBN(20)).div(toBN(10000))
    let realIn = buyIn.sub(takeFee)
    let realOut = realIn.mul(toBN(10**10)).div(price)
    expect(realOut.toString()).to.eq('3000000000000000000')
  })

  it("StakeDex:swap, take multi orders", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 });
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 });
    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('3').mul(BASE)
    let amountOut1 = toBN('1').mul(BASE)
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    // 3 -> 1.1, price = 3666666666
    let amountIn2 = toBN('3').mul(BASE)
    let amountOut2 = toBN('11').mul(BASE).div(toBN('10'))

    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });

    let takeOut = toBN('6').mul(BASE)
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)
    expect(buyIn.amountIn.toString()).to.eq('2104199999699400000')
    expect(buyIn.amountReturn.toString()).to.eq('0')

    this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let tradedIn = await this.TokenIn.balanceOf(investor3)
    expect(tradedIn.toString()).to.eq(takeOut.toString())
  })


  it("StakeDex:burn, check taker returns", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 });
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 });
    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('3').mul(BASE)
    let amountOut1 = toBN('1').mul(BASE)
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    // 3 -> 1.1, price = 3666666666
    let amountIn2 = toBN('3').mul(BASE)
    let amountOut2 = toBN('11').mul(BASE).div(toBN('10'))

    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });

    let takeOut = toBN('6').mul(BASE)
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)
    expect(buyIn.amountIn.toString()).to.eq('2104199999699400000')
    expect(buyIn.amountReturn.toString()).to.eq('0')

    this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let tradedIn = await this.TokenIn.balanceOf(investor3)
    expect(tradedIn.toString()).to.eq(takeOut.toString())


    let tokenId1 = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
    await this.Dex.burn(tokenId1, { from: investor1 })
    let out1 = await this.TokenOut.balanceOf(investor1)

    expect(out1.toString()).to.eq("1000999999899900000")


    let tokenId2 = await this.Dex.tokenOfOwnerByIndex(investor2, 0)
    await this.Dex.burn(tokenId2, { from: investor2 })
    let out2 = await this.TokenOut.balanceOf(investor2)

    expect(out2.toString()).to.eq("1101099999799800000")
  })

  it("StakeDex:burn, check maker returns", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 });
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2 });
    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('3').mul(BASE)
    let amountOut1 = toBN('1').mul(BASE)
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    // 3 -> 1.1, price = 3666666666
    let amountIn2 = toBN('3').mul(BASE)
    let amountOut2 = toBN('11').mul(BASE).div(toBN('10'))

    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn2, amountOut2, { from: investor2 });

    let takeOut = toBN('6').mul(BASE)
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)
    expect(buyIn.amountIn.toString()).to.eq('2104199999699400000')
    expect(buyIn.amountReturn.toString()).to.eq('0')

    await this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let tradedIn = await this.TokenIn.balanceOf(investor3)
    expect(tradedIn.toString()).to.eq(takeOut.toString())


    let tokenId1 = await this.Dex.tokenOfOwnerByIndex(investor1, 0)
    await this.Dex.burn(tokenId1, { from: investor1 })
    let out1 = await this.TokenOut.balanceOf(investor1)
    expect(out1.toString()).to.eq("1000999999899900000")


    let tokenId2 = await this.Dex.tokenOfOwnerByIndex(investor2, 0)
    await this.Dex.burn(tokenId2, { from: investor2 })
    let out2 = await this.TokenOut.balanceOf(investor2)
    expect(out2.toString()).to.eq("1101099999799800000")
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

    // 6 -> 2, price = 3333333333
    let amountIn3 = toBN('6').mul(BASE)
    let amountOut3 = toBN('2').mul(BASE)
    let tokenId3 = 3
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn3, amountOut3, { from: investor11 });

    // 0.3 -> 0.1, price = 3333333333
    let amountIn4 = toBN('3').mul(BASE).div(toBN('10'))
    let amountOut4 = toBN('1').mul(BASE).div(toBN('10'))
    let tokenId4 = 4
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn4, amountOut4, { from: investor12 });


    let takeOut = toBN('123').mul(BASE).div(toBN('10')) // 9.3
    let buyIn = await this.Dex.calcInAmount(this.TokenOut.address, this.TokenIn.address, takeOut)

    await this.TokenOut.transfer(this.Dex.address, buyIn.amountIn, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)


    let position1BeforeBurn = await this.Dex.positions(tokenId1)
    expect(position1BeforeBurn.pendingIn.toString()).to.eq('0')
    expect(position1BeforeBurn.pendingOut.toString()).to.eq('0')
    expect(position1BeforeBurn.rateRedeemedIndex.toNumber()).to.eq(1)
    expect(position1BeforeBurn.filled.toString()).to.eq('999999999900000000')
    expect(position1BeforeBurn.feeRewarded.toString()).to.eq('999999999900000')


    await this.Dex.burn(tokenId1, { from: investor1 })
    let out1 = await this.TokenOut.balanceOf(investor1)
    expect(out1.toString()).to.eq("1000999999899900000")

    await expectRevert(
      this.Dex.positions(tokenId1),
      "No position"
    );

    await this.Dex.burn(tokenId2, { from: investor2 })
    let out2 = await this.TokenOut.balanceOf(investor2)
    expect(out2.toString()).to.eq("1101099999799800000")

    await this.Dex.burn(tokenId3, { from: investor11 })
    let out3 = await this.TokenOut.balanceOf(investor11)
    expect(out3.toString()).to.eq("2001999999799800000")

    await this.Dex.burn(tokenId4, { from: investor12 })
    let out4 = await this.TokenOut.balanceOf(investor12)
    expect(out4.toString()).to.eq("100099999989990000")
  })

  it("StakeDex:swap, multi swaps", async() => {
    await this.TokenIn.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1 })

    // 3 -> 1, price = 3333333333
    let amountIn1 = toBN('30').mul(BASE)
    let amountOut1 = toBN('10').mul(BASE)
    let tokenId1 = 1
    await this.Dex.mint(this.TokenIn.address, this.TokenOut.address, amountIn1, amountOut1, { from: investor1 });

    let pos0 = await this.Dex.positions(tokenId1)
    expect(pos0.pendingIn.toString()).to.eq('30000000000000000000')
    expect(pos0.pendingOut.toString()).to.eq('9999999999000000000')

    let amount1 = toBN('5').mul(BASE)
    await this.TokenOut.transfer(this.Dex.address, amount1, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let pos1 = await this.Dex.positions(tokenId1)
    
    expect(pos1.pendingIn.toString()).to.eq('15029999998503000002') // 15029999998502999999
    expect(pos1.pendingOut.toString()).to.eq('5009999999000000001') // 5009999999000000000

    let increasedAmount = toBN('3').mul(BASE)
    await this.Dex.increasePosition(tokenId1, increasedAmount, {  from: investor1 })

    let pos2 = await this.Dex.positions(tokenId1)
    expect(pos2.pendingIn.toString()).to.eq('18029999998503000002') // 18029999998503000000
    expect(pos2.pendingOut.toString()).to.eq('6009999998900000001') // 6009999998900000000


    let amount2 = toBN('2').mul(BASE)
    await this.TokenOut.transfer(this.Dex.address, amount2, { from: investor3 })
    await this.Dex.swap(this.TokenOut.address, this.TokenIn.address, investor3, constants.ZERO_ADDRESS)

    let pos3 = await this.Dex.positions(tokenId1)
    expect(pos3.pendingIn.toString()).to.eq('12041999997904200014') // 12041999997904200000
    expect(pos3.pendingOut.toString()).to.eq('4013999998900000005') // 4013999998900000000

  })

});