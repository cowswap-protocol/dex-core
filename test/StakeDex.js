const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { toBN } = require('web3-utils');
const { BN, expectEvent, expectRevert, time, constants, balance } = require('@openzeppelin/test-helpers');

const [ admin, deployer, user, holder, investor1, investor2, investor3, investor4 ] = accounts;


const StakeDex = contract.fromArtifact('StakeDex');
const Mock = contract.fromArtifact('Mock');




describe("StakeDex", function() {
  const BASE = new BN('10').pow(new BN('18'))
  const WETH = "0x0000000000000000000000000000000000000000";
  const DEV =  "0x0000000000000000000000000000000000000003";
  const FEE =  "0x0000000000000000000000000000000000000fee";


  beforeEach(async () => {
    this.TokenA = await Mock.new("Token A", "A", 18);
    this.TokenB = await Mock.new("Token B", "B", 18);

    this.Dex = await StakeDex.new(FEE);
    await this.Dex.createPair(this.TokenB.address, this.TokenA.address)
  });

  it("StakeDex:createPair", async() => {
    let id1 = await this.Dex.getPairId(this.TokenA.address, this.TokenB.address);
    let id2 = await this.Dex.getPairId(this.TokenB.address, this.TokenA.address);
    
    let a = toBN(this.TokenA.address)
    let b = toBN(this.TokenB.address)

    if(a.lt(b)) {
      expect(id1.toNumber()).to.eq(1)
      expect(id2.toNumber()).to.eq(2)
    } else {
      expect(id1.toNumber()).to.eq(2)
      expect(id2.toNumber()).to.eq(1)
    }
   
  })

  it("StakeDex:addLiquidity", async() => {

    await this.TokenA.mint(investor1, toBN('3').mul(BASE));
    await this.TokenA.mint(investor2, toBN('3').mul(BASE));
    await this.TokenA.mint(investor3, toBN('3').mul(BASE));
    await this.TokenA.mint(investor4, toBN('3').mul(BASE));


    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor3});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor4});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor2 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor3 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('4').mul(BASE), { from: investor4 });

    
    let prices = await this.Dex.getPrices(this.TokenA.address, this.TokenB.address);
    expect(prices.map(p => p.toString())).to.have.members([
      '33333333',
      '66666666',
      '100000000',
      '133333333'
    ])
  })

  it("StakeDex:addLiquidity case2", async() => {

    await this.TokenA.mint(investor1, toBN('10').mul(BASE));
    await this.TokenA.mint(investor2, toBN('10').mul(BASE));
    await this.TokenA.mint(investor3, toBN('10').mul(BASE));
    await this.TokenA.mint(investor4, toBN('10').mul(BASE));


    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor3});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor4});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor2 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor3 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor4 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor4 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor4 });

    
    let prices = await this.Dex.getPrices(this.TokenA.address, this.TokenB.address);
    expect(prices.map(p => p.toString())).to.have.members([
      '33333333',
      '66666666',
      '100000000'
    ])
  })


  it("StakeDex:swap", async() => {

    await this.TokenA.mint(investor1, toBN('3').mul(BASE));
    await this.TokenA.mint(investor2, toBN('3').mul(BASE));
    await this.TokenA.mint(investor3, toBN('3').mul(BASE));
    await this.TokenA.mint(investor4, toBN('3').mul(BASE));


    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor3});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor4});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor2 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor3 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor4 });

    let price1 = toBN('33333333');

    let id = await this.Dex.getPairId(this.TokenA.address, this.TokenB.address);

    let depth = await this.Dex.depth(id, price1);
    expect(depth.toString()).to.eq(toBN('1999999980000000000').toString())
      
    await this.TokenB.mint(user, toBN('1').mul(BASE));
    await this.TokenB.approve(this.Dex.address, constants.MAX_UINT256, { from: user });

    let out = await this.Dex.calcOutAmount(this.TokenB.address, this.TokenA.address, toBN('1').mul(BASE))

    await this.Dex.swap(this.TokenB.address, this.TokenA.address, toBN('1').mul(BASE), toBN('2').mul(BASE), { from: user })

    let outAmount = await this.TokenA.balanceOf(user)

    expect(outAmount.toString()).to.eq(out.amountOut.toString())


    depth = await this.Dex.depth(id, price1);
    expect(depth.toString()).to.eq(toBN('1001999980000000000').toString())
  })

  it("StakeDex:redeem", async() => {
    await this.TokenA.mint(investor1, toBN('3').mul(BASE));
    await this.TokenA.mint(investor2, toBN('3').mul(BASE));
    await this.TokenA.mint(investor3, toBN('3').mul(BASE));
    await this.TokenA.mint(investor4, toBN('3').mul(BASE));

    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor3});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor4});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor2 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor3 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor4 });

    let price1 = toBN('33333333');

    let id = await this.Dex.getPairId(this.TokenA.address, this.TokenB.address);
    
    await this.TokenB.mint(user, toBN('2').mul(BASE));
    await this.TokenB.approve(this.Dex.address, constants.MAX_UINT256, { from: user });

    let depth1  = await this.Dex.depth(id, price1);

    await this.Dex.swap(this.TokenB.address, this.TokenA.address, toBN('1').mul(BASE), toBN('2').mul(BASE), { from: user })
    
    // let rates = await this.Dex.getTradedRates(id, price1)
    // console.log(rates.map(x => x.toString()))

    await this.Dex.redeem(this.TokenA.address, this.TokenB.address, price1, { from: investor1 })
    // await this.Dex.redeem(this.TokenA.address, this.TokenB.address, price1, { from: investor2 })

    let amountB1 = await this.TokenB.balanceOf(investor1)
    let amountB2 = await this.TokenB.balanceOf(investor2)

    expect(amountB1.toString()).to.eq("499599999999999998")
    expect(amountB2.toString()).to.eq("0")


    let pending1 = await this.Dex.userOrders(investor1, id, price1);
    let pending2 = await this.Dex.userOrders(investor2, id, price1);

    expect(pending1.toString()).to.eq('500999990000000001')
    expect(pending2.toString()).to.eq('999999990000000000')


    await this.Dex.swap(this.TokenB.address, this.TokenA.address, toBN('1').mul(BASE).div(toBN('2')), toBN('0'), { from: user })


    await this.Dex.redeem(this.TokenA.address, this.TokenB.address, price1, { from: investor1 })
    amountB1_2 = await this.TokenB.balanceOf(investor1)
    expect(amountB1_2.toString()).to.eq("749399999999999997")

    await this.Dex.redeem(this.TokenA.address, this.TokenB.address, price1, { from: investor2 })
    amountB2_2 = await this.TokenB.balanceOf(investor2)

    expect(amountB2_2.toString()).to.eq("749399999999999997")
  })


  it("StakeDex:redeem case2", async() => {
    await this.TokenA.mint(investor1, toBN('3').mul(BASE));
    await this.TokenA.mint(investor2, toBN('3').mul(BASE));
    await this.TokenA.mint(investor3, toBN('3').mul(BASE));
    await this.TokenA.mint(investor4, toBN('3').mul(BASE));

    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor3});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor4});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor2 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor3 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor4 });

    let price1 = toBN('33333333');

    let id = await this.Dex.getPairId(this.TokenA.address, this.TokenB.address);
    
    await this.TokenB.mint(user, toBN('2').mul(BASE));
    await this.TokenB.approve(this.Dex.address, constants.MAX_UINT256, { from: user });

    let depth1  = await this.Dex.depth(id, price1);

    await this.Dex.swap(this.TokenB.address, this.TokenA.address, toBN('1').mul(BASE), toBN('2').mul(BASE), { from: user })
    await this.Dex.swap(this.TokenB.address, this.TokenA.address, toBN('1').mul(BASE).div(toBN('2')), toBN('0'), { from: user })

    await this.Dex.redeem(this.TokenA.address, this.TokenB.address, price1, { from: investor1 })
    await this.Dex.redeem(this.TokenA.address, this.TokenB.address, price1, { from: investor2 })

    let amountB1 = await this.TokenB.balanceOf(investor1)
    expect(amountB1.toString()).to.eq("749399999999999997")

    let amountB2 = await this.TokenB.balanceOf(investor2)
    expect(amountB2.toString()).to.eq("749399999999999997")

    let pending1 = await this.Dex.userOrders(investor1, id, price1);
    let pending2 = await this.Dex.userOrders(investor2, id, price1);

    expect(pending1.toString()).to.eq('251499990000000001')
    expect(pending2.toString()).to.eq('251499990000000001')
  })

  it("StakeDex:removeLiquidity", async() => {
    await this.TokenA.mint(investor1, toBN('3').mul(BASE));
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });

    let price1 = toBN('33333333');
    let id = await this.Dex.getPairId(this.TokenA.address, this.TokenB.address);



    await this.TokenB.mint(user, toBN('2').mul(BASE));
    await this.TokenB.approve(this.Dex.address, constants.MAX_UINT256, { from: user });

    let amountIN = toBN('500000000000000000')
    await this.Dex.swap(this.TokenB.address, this.TokenA.address, amountIN, toBN('1').mul(BASE), { from: user })

    await this.Dex.removeLiquidity(this.TokenA.address, this.TokenB.address, price1, { from: investor1 });

    let balance1 = await this.TokenB.balanceOf(investor1);
    expect(balance1.toString()).to.eq('499599999999999998')

    let balance2 = await this.TokenA.balanceOf(investor1);
    expect(balance2.toString()).to.eq('1502999985029999850')

    let prices = await this.Dex.getPrices(this.TokenA.address, this.TokenB.address)
    expect(prices.length).to.eq(0)
  })

  it("StakeDex:removeLiquidity:2", async() => {
    await this.TokenA.mint(investor1, toBN('6').mul(BASE));
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor1 });

    let price1 = toBN('33333333');
    let price2 = toBN('66666666');
    let id = await this.Dex.getPairId(this.TokenA.address, this.TokenB.address);

    
    let prices = await this.Dex.getPrices(this.TokenA.address, this.TokenB.address)
    expect(prices[0].toString()).to.eq(price1.toString())
    expect(prices[1].toString()).to.eq(price2.toString())

    await this.Dex.removeLiquidity(this.TokenA.address, this.TokenB.address, price1, { from: investor1 });
    prices = await this.Dex.getPrices(this.TokenA.address, this.TokenB.address)
    expect(prices[0].toString()).to.eq(price2.toString())

    await this.Dex.removeLiquidity(this.TokenA.address, this.TokenB.address, price2, { from: investor1 });


    prices = await this.Dex.getPrices(this.TokenA.address, this.TokenB.address)
    expect(prices.length).to.eq(0)

  })

  it("StakeDex:getDepth", async() => {

    await this.TokenA.mint(investor1, toBN('3').mul(BASE));
    await this.TokenA.mint(investor2, toBN('3').mul(BASE));
    await this.TokenA.mint(investor3, toBN('3').mul(BASE));
    await this.TokenA.mint(investor4, toBN('3').mul(BASE));


    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor1});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor2});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor3});
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: investor4});

    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('1').mul(BASE), { from: investor1 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('3').mul(BASE), { from: investor2 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('2').mul(BASE), { from: investor3 });
    await this.Dex.addLiquidity(this.TokenA.address, this.TokenB.address, toBN('3').mul(BASE), toBN('4').mul(BASE), { from: investor4 });

    
    let depths = await this.Dex.getDepth(this.TokenA.address, this.TokenB.address);

    expect(depths.map(d=>d.amount.toString())).to.have.members([
      '999999990000000000',
      '1999999980000000000',
      '3000000000000000000',
      '3999999990000000000'
    ])
  })



});