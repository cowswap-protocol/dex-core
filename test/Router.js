const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { toBN, keccak256 } = require('web3-utils');
const { BN, expectEvent, expectRevert, time, constants, balance, send } = require('@openzeppelin/test-helpers');

const [ admin, deployer, user, holder, investor1, investor2, investor3, investor4, investor11, investor12 ] = accounts;


const StakeDex = contract.fromArtifact('StakeDex');
const Mock = contract.fromArtifact('Mock');
const PancakeFactory = contract.fromArtifact('PancakeFactory')
const Router = contract.fromArtifact('CowswapRouter')
const POT = contract.fromArtifact('ProofOfTrade')
const WETH = contract.fromArtifact('WBNB')
const IERC20 = contract.fromArtifact('IERC20')
const PancakePair = contract.fromArtifact('PancakePair')



describe("Router", function() {
  const BASE = new BN('10').pow(new BN('18'))
  const DEV =  "0x0000000000000000000000000000000000000003";
  const FEE =  "0x0000000000000000000000000000000000000fee";
  const AMM_FEE =  "0x0000000000000000000000000000000000001fee";

  const ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"


  beforeEach(async () => {
    this.TokenA = await Mock.new("TokenA", "A", 18);
    this.TokenB = await Mock.new("TokenB", "B", 18);
    this.TokenC = await Mock.new("TokenC", "C", 18);
    this.WETH = await WETH.new()
    this.Dex = await StakeDex.new(FEE, this.WETH.address);
    this.PancakeFactory = await PancakeFactory.new(admin)
    await this.PancakeFactory.setFeeTo(AMM_FEE, { from: admin })
    this.Router = await Router.new(this.Dex.address, this.PancakeFactory.address, this.WETH.address)
  });

  it("Router:addLiquidity", async() => {
  	let amountA = toBN('10000').mul(BASE);
  	let amountB = toBN('10000').mul(BASE);
  	let deadline = await time.latest()
  	deadline = deadline.add(toBN('10000'))

  	await this.TokenA.mint(deployer, amountA)
  	await this.TokenB.mint(deployer, amountB)

  	await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

  	await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })

  	let pair = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenB.address)

  	let lpt = await IERC20.at(pair)
  	let lptBalance = await lpt.balanceOf(deployer)
  	expect(lptBalance.gt(toBN('0'))).to.be.true
  })

  it("Router:addLiquidity ETH+Token", async() => {
    let amountETH = toBN('10').mul(BASE);
    let amountB = toBN('10000').mul(BASE);
    let deadline = await time.latest()
    deadline = deadline.add(toBN('10000'))

    await this.TokenB.mint(deployer, amountB)
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

    await this.Router.addLiquidity(ETH, this.TokenB.address, amountETH, amountB, 0, 0, deployer, deadline, { value: amountETH, from: deployer })

    let pair = await this.PancakeFactory.getPair(this.WETH.address, this.TokenB.address)

    let lpt = await IERC20.at(pair)
    let lptBalance = await lpt.balanceOf(deployer)
    expect(lptBalance.gt(toBN('0'))).to.be.true
  })

  it("Router:removeLiquidity", async() => {
  	let amountA = toBN('10000').mul(BASE);
  	let amountB = toBN('10000').mul(BASE);
  	let deadline = await time.latest()
  	deadline = deadline.add(toBN('10000'))

  	await this.TokenA.mint(deployer, amountA)
  	await this.TokenB.mint(deployer, amountB)

  	await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

  	await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })

  	let pair = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenB.address)

  	let lpt = await IERC20.at(pair)
  	lpt.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	let lptBalance = await lpt.balanceOf(deployer)
  	await this.Router.removeLiquidity(this.TokenA.address, this.TokenB.address, lptBalance, 0, 0, deployer, deadline, { from: deployer })

  	let lptBalanceAfter = await lpt.balanceOf(deployer)
  	expect(lptBalanceAfter.eq(toBN('0'))).to.be.true


  	let balanceA = await this.TokenA.balanceOf(deployer)

  	expect(balanceA.lt(amountA)).to.be.true
  })

  it("Router:removeLiquidity ETH+Token", async() => {
    let amountETH = toBN('10').mul(BASE);
    let amountB = toBN('10000').mul(BASE);
    let deadline = await time.latest()
    deadline = deadline.add(toBN('10000'))

    await this.TokenB.mint(deployer, amountB)
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

    await this.Router.addLiquidity(ETH, this.TokenB.address, amountETH, amountB, 0, 0, deployer, deadline, { value: amountETH, from: deployer })

    let pair = await this.PancakeFactory.getPair(this.WETH.address, this.TokenB.address)

    let lpt = await IERC20.at(pair)
    let lptBalance = await lpt.balanceOf(deployer)
    expect(lptBalance.gt(toBN('0'))).to.be.true


    await lpt.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

    let balanceB = await this.TokenB.balanceOf(deployer)
    expect(balanceB.toString()).to.eq('0')

    await this.Router.removeLiquidity(ETH, this.TokenB.address, lptBalance, 0, 0, deployer, deadline, { from: deployer })
    let balanceB2 = await this.TokenB.balanceOf(deployer)
    expect(balanceB2.gt(toBN('0'))).to.be.true
  })

  describe("Router:getAmountsOut", async() => {
    it("returns outputs", async() => {
      let amountA = toBN('10000').mul(BASE)
      let amountB = toBN('10000').mul(BASE)
      let amountC = toBN('3000').mul(BASE)
      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
      await this.TokenB.mint(deployer, amountB)
      await this.TokenC.mint(deployer, amountC)

      await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      // A + B => 10000A + 10000B
      await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
      // A + C => 10000A + 3000C
      await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })

      let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)


      await this.TokenA.mint(user, amountA);
      await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })

      // A -> B => 10000A -> 10000B
      await this.Dex.mint(this.TokenA.address, this.TokenB.address, amountA, amountB, { from: user })

      let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]

      let amountIn = toBN('100').mul(BASE)
      let out = await this.Router.getAmountsOut(amountIn, path, holder)
      expect(out.amounts.map(a=>a.toString())).to.have.members(['100000000000000000000', '99800000000000000000', '29570771491265873664'])
    })

    it("throw error if amm returns 0", async() => {
      let amountA = toBN('10000').mul(BASE)
      let amountB = toBN('10000').mul(BASE)
      let amountC = toBN('3000').mul(BASE)
      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
      await this.TokenB.mint(deployer, amountB)
      await this.TokenC.mint(deployer, amountC)

      await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      // A + B => 10000A + 10000B
      await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
      // A + C => 10000A + 3000C
      // await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })

      let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)


      await this.TokenA.mint(user, amountA);
      await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })

      // A -> B => 10000A -> 10000B
      await this.Dex.mint(this.TokenA.address, this.TokenB.address, amountA, amountB, { from: user })

      let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]

      let amountIn = toBN('100').mul(BASE)

      await expectRevert(this.Router.getAmountsOut(amountIn, path, holder), "CowswapRouter: INSUFFICIENT_LIQUIDITY")
    })

    it("throw error if unfilled amm returns 0", async() => {
      let amountA = toBN('10000').mul(BASE)
      let amountB = toBN('10000').mul(BASE)
      let amountC = toBN('3000').mul(BASE)
      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
      await this.TokenB.mint(deployer, amountB)
      await this.TokenC.mint(deployer, amountC)

      await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
      await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      // await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
      // A + C => 10000A + 3000C
      await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })

      let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)


      await this.TokenA.mint(user, amountA);
      await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })

      // A -> B => 100A -> 100B
      let dexAmountA = toBN('100').mul(BASE)
      let dexAmountB = toBN('100').mul(BASE)
      await this.Dex.mint(this.TokenA.address, this.TokenB.address, dexAmountA, dexAmountB, { from: user })

      let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]

      let amountIn = toBN('101').mul(BASE)
      // let outs = await this.Router.getAmountsOut(amountIn, path, holder)
      // console.log(outs.recipients)

      await expectRevert(this.Router.getAmountsOut(amountIn, path, holder), "CowswapRouter: INSUFFICIENT_LIQUIDITY")
    })

  });

  it("Router:exactInput", async() => {
  	let amountA = toBN('10000').mul(BASE)
  	let amountB = toBN('10000').mul(BASE)
  	let amountC = toBN('3000').mul(BASE)
  	let deadline = await time.latest()
  	deadline = deadline.add(toBN('10000'))

  	await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
  	await this.TokenB.mint(deployer, amountB)
  	await this.TokenC.mint(deployer, amountC)

  	await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	// A + B => 10000A + 10000B
  	await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
  	// A + C => 10000A + 3000C
  	await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })

  	let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)


  	await this.TokenA.mint(user, amountA);
  	await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })

    // A -> B => 10000A -> 10000B
  	await this.Dex.mint(this.TokenA.address, this.TokenB.address, amountA, amountB, { from: user })

  	let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]
  	let amountIn = toBN('100').mul(BASE)
  	let out = await this.Router.getAmountsOut(amountIn, path, holder)
  	expect(out.recipients).to.have.members([this.Dex.address, pairAC, holder])

		await this.TokenB.mint(holder, amountIn)
		await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, {from: holder})
		await this.Router.exactInput(amountIn, 0, path, holder, deadline, { from: holder })

		let traded = await this.TokenC.balanceOf(holder)
		expect(traded.toString()).to.eq("29570771491265873664")
  })

  it("Router:exactInput multiple routers", async() => {
    let amountA = toBN('10000').mul(BASE)
    let amountB = toBN('10000').mul(BASE)
    let amountC = toBN('3000').mul(BASE)
    let deadline = await time.latest()
    deadline = deadline.add(toBN('10000'))

    let dexA = toBN('100').mul(BASE)
    let dexB = toBN('100').mul(BASE)

    await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
    await this.TokenB.mint(deployer, amountB)
    await this.TokenC.mint(deployer, amountC)

    await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
    await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
    // A + B => 10000A + 10000B
    await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
    // A + C => 10000A + 3000C
    await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })

    let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)


    await this.TokenA.mint(user, amountA);
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })
    // A -> B => 100A -> 100B
    await this.Dex.mint(this.TokenA.address, this.TokenB.address, dexA, dexB, { from: user })


    // let pair = await this.Dex.pairs(this.TokenA.address, this.TokenB.address)
    // console.log(pair.depths.map(a=>a.toString()))
    // console.log(pair.prices.map(a=>a.toString()))

    let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]
    let amountIn = toBN('110').mul(BASE)
    let out = await this.Router.getAmountsOut(amountIn, path, holder)
    expect(out.recipients).to.have.members([this.Dex.address, pairAC, holder])

    // console.log(out.amounts.map(a=>a.toString()))
    // console.log(out.unfilledAmounts.map(a=>a.toString()))

    await this.TokenB.mint(holder, amountIn)
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, {from: holder})
    await this.Router.exactInput(amountIn, 0, path, holder, deadline, { from: holder })

    let traded = await this.TokenC.balanceOf(holder)
    expect(traded.toString()).to.eq("32491588013805849602") //32491588013805849603
  })

  it("Router:exactOutput", async() => {
  	let amountA = toBN('10000').mul(BASE)
  	let amountB = toBN('10000').mul(BASE)
  	let amountC = toBN('3000').mul(BASE)
  	let deadline = await time.latest()
  	deadline = deadline.add(toBN('10000'))

  	await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
  	await this.TokenB.mint(deployer, amountB)
  	await this.TokenC.mint(deployer, amountC)

  	await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
  	// A + B => 10000A + 10000B
  	await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
  	// A + C => 10000A + 3000C
  	await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })
  	let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)

  	// Dex limit price order A -> B 10000: 10000
  	await this.TokenA.mint(user, amountA)
  	await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })
  	await this.Dex.mint(this.TokenA.address, this.TokenB.address, amountA, amountB, { from: user })




  	let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]
  	let amountInMax = toBN('346384584916094396035')
  	let amountOut = toBN('100').mul(BASE)

    // let amountAa = await this.Router.amm_calcInAmount(this.TokenA.address, this.TokenC.address, '100000000000000000000')
    // console.log(amountAa.toString())
    // let amountBb = await this.Router.dex_calcInAmount(this.TokenB.address, this.TokenA.address, '345691815746262207243')
    // console.log(amountBb['0'].toString())

		await this.TokenB.mint(holder, amountInMax)
		await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, {from: holder})

    // let input = await this.Router.getAmountsIn(amountOut, path, holder)
    // console.log(input.amounts.map(a=>a.toString()))


    // let output = await this.Router.getAmountsOut('346384584916094396035', path, holder)
    // console.log(output.amounts.map(a=>a.toString()))

		await this.Router.exactOutputSupportingFeeOnTransferTokens(amountOut, amountInMax, path, holder, deadline, { from: holder })

		let traded = await this.TokenC.balanceOf(holder)
		expect(traded.toString()).to.eq('100000000000000000000')
    
  })

  it("Router:exactOutput multiple routers", async() => {
    let amountA = toBN('10000').mul(BASE)
    let amountB = toBN('10000').mul(BASE)
    let amountC = toBN('3000').mul(BASE)
    let deadline = await time.latest()
    deadline = deadline.add(toBN('10000'))

    await this.TokenA.mint(deployer, amountA.mul(toBN('2')))
    await this.TokenB.mint(deployer, amountB)
    await this.TokenC.mint(deployer, amountC)

    await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
    await this.TokenC.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })
    // A + B => 10000A + 10000B
    await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })
    // A + C => 10000A + 3000C
    await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })
    let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)

    let dexA = toBN('100').mul(BASE)
    let dexB = toBN('100').mul(BASE)
    // Dex limit price order
    await this.TokenA.mint(user, dexA)
    await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })
    await this.Dex.mint(this.TokenA.address, this.TokenB.address, dexA, dexB, { from: user })

    

    let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]
    let amountInMax = toBN('390661599210469860011') // 390661599210469860011
    let amountOut = toBN('110').mul(BASE)

    // let input = await this.Router.getAmountsIn(amountOut, path, holder)
    // console.log(input.amounts.map(a=>a.toString())) // 381576779318538560934
    // console.log(input.unfilledAmounts.map(a=>a.toString()))

    await this.TokenB.mint(holder, amountInMax)
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, {from: holder})
    await this.Router.exactOutput(amountOut, amountInMax, path, holder, deadline, { from: holder })

    let traded = await this.TokenC.balanceOf(holder)
    expect(traded.toString()).to.eq('110000000000000000000')
    
  })

  describe("fastAddLiquidity", async() => {
    it("fastAdd: ETH/Token", async() => {
      let amountETH = toBN('1').mul(BASE);
      let amountB = toBN('10000').mul(BASE);

      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenB.mint(deployer, amountB)
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.Router.addLiquidity(ETH, this.TokenB.address, amountETH, amountB, 0, 0, deployer, deadline, { value: amountETH, from: deployer })

      let pair = await this.PancakeFactory.getPair(this.WETH.address, this.TokenB.address)

      let lpt = await IERC20.at(pair)
      let lptBalance = await lpt.balanceOf(deployer)
      expect(lptBalance.gt(toBN('0'))).to.be.true

      // let output = await this.Router.getAmountsOut(amountETH.div(toBN('2')), [ this.WETH.address, this.TokenB.address ], this.Router.address)
      // console.log(output.amounts.map(a=>a.toString()))
      // console.log(output.recipients.map(a=>a.toString()))

      await this.Router.fastAddLiquidity(ETH, this.TokenB.address, amountETH, deployer, deadline, { value: amountETH, from: deployer })

      let lptBalance2 = await lpt.balanceOf(deployer)
      expect(lptBalance2.gt(lptBalance)).to.be.true
      
    })

    it("fastAdd: Token/ETH", async() => {
      let amountETH = toBN('1').mul(BASE);
      let amountB = toBN('10000').mul(BASE);
      let fastAmountB = toBN('1000').mul(BASE)

      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenB.mint(deployer, amountB.add(fastAmountB))
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.Router.addLiquidity(ETH, this.TokenB.address, amountETH, amountB, 0, 0, deployer, deadline, { value: amountETH, from: deployer })

      let pair = await this.PancakeFactory.getPair(this.WETH.address, this.TokenB.address)

      let lpt = await IERC20.at(pair)
      let lptBalance = await lpt.balanceOf(deployer)
      expect(lptBalance.gt(toBN('0'))).to.be.true


      await this.Router.fastAddLiquidity(this.TokenB.address, ETH, fastAmountB, deployer, deadline, { from: deployer })

      let lptBalance2 = await lpt.balanceOf(deployer)
      expect(lptBalance2.gt(lptBalance)).to.be.true
    })

    it("fastAdd: Token/Token", async() => {
      let amountA = toBN('10000').mul(BASE);
      let amountB = toBN('10000').mul(BASE);
      let fastAmountB = toBN('1000').mul(BASE)

      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenA.mint(deployer, amountA)
      await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.TokenB.mint(deployer, amountB.add(fastAmountB))
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })

      let pair = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenB.address)

      let lpt = await IERC20.at(pair)
      let lptBalance = await lpt.balanceOf(deployer)
      expect(lptBalance.gt(toBN('0'))).to.be.true

      await this.Router.fastAddLiquidity(this.TokenB.address, this.TokenA.address, fastAmountB, deployer, deadline, { from: deployer })

      let lptBalance2 = await lpt.balanceOf(deployer)
      expect(lptBalance2.gt(lptBalance)).to.be.true
    })
  })

  describe("fastRemoveLiquidity", async() => {
    it("fastRemove: ETH/Token->ETH", async() => {
      let amountETH = toBN('1').mul(BASE);
      let amountB = toBN('10000').mul(BASE);

      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenB.mint(deployer, amountB)
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.Router.addLiquidity(ETH, this.TokenB.address, amountETH, amountB, 0, 0, deployer, deadline, { value: amountETH, from: deployer })

      let pair = await this.PancakeFactory.getPair(this.WETH.address, this.TokenB.address)

      let lpt = await IERC20.at(pair)
      let lptBalance = await lpt.balanceOf(deployer)
      expect(lptBalance.gt(toBN('0'))).to.be.true

      await lpt.approve(this.Router.address, constants.MAX_UINT256, { from: deployer });

      let liqudity = lptBalance.div(toBN('10')) // 1/10

      let etherBefore = await balance.current(deployer)
      await this.Router.fastRemoveLiquidity(ETH, this.TokenB.address, liqudity, deployer, deadline, { from: deployer })
      let etherAfter = await balance.current(deployer)


      let lptBalance2 = await lpt.balanceOf(deployer)
      expect(lptBalance2.lt(lptBalance)).to.be.true
      expect(etherAfter.gt(etherBefore)).to.be.true
      
    })

    it("fastRemove: Token/ETH->Token", async() => {
      let amountETH = toBN('1').mul(BASE);
      let amountB = toBN('10000').mul(BASE);

      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenB.mint(deployer, amountB)
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.Router.addLiquidity(ETH, this.TokenB.address, amountETH, amountB, 0, 0, deployer, deadline, { value: amountETH, from: deployer })

      let pair = await this.PancakeFactory.getPair(this.WETH.address, this.TokenB.address)

      let lpt = await IERC20.at(pair)
      let lptBalance = await lpt.balanceOf(deployer)
      expect(lptBalance.gt(toBN('0'))).to.be.true

      let liqudity = lptBalance.div(toBN('10')) // 1/10

      await lpt.approve(this.Router.address, constants.MAX_UINT256, { from: deployer });

      let balanceB = await this.TokenB.balanceOf(deployer)
      expect(balanceB.toString()).to.eq('0')

      await this.Router.fastRemoveLiquidity(this.TokenB.address, ETH, liqudity, deployer, deadline, { from: deployer })

      let balanceB2 = await this.TokenB.balanceOf(deployer)
      expect(balanceB2.gt(toBN('0'))).to.be.true

      let lptBalance2 = await lpt.balanceOf(deployer)
      expect(lptBalance2.lt(lptBalance)).to.be.true
    })

    it("fastRemove: TokenA/TokenB -> TokenA", async() => {
      let amountA = toBN('10000').mul(BASE);
      let amountB = toBN('10000').mul(BASE);

      let deadline = await time.latest()
      deadline = deadline.add(toBN('10000'))

      await this.TokenA.mint(deployer, amountA)
      await this.TokenA.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.TokenB.mint(deployer, amountB)
      await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, { from: deployer })

      await this.Router.addLiquidity(this.TokenA.address, this.TokenB.address, amountA, amountB, 0, 0, deployer, deadline, { from: deployer })

      let pair = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenB.address)

      let lpt = await IERC20.at(pair)
      let lptBalance = await lpt.balanceOf(deployer)
      expect(lptBalance.gt(toBN('0'))).to.be.true

      let liqudity = lptBalance.div(toBN('10')) // 1/10
      await lpt.approve(this.Router.address, constants.MAX_UINT256, { from: deployer });

      let balanceA = await this.TokenA.balanceOf(deployer)
      expect(balanceA.toString()).to.eq('0')
      await this.Router.fastRemoveLiquidity(this.TokenB.address, this.TokenA.address, liqudity, deployer, deadline, { from: deployer })

      let balanceA2 = await this.TokenA.balanceOf(deployer)
      expect(balanceA2.lt(toBN('2000').mul(BASE))).to.be.true

      let lptBalance2 = await lpt.balanceOf(deployer)
      expect(lptBalance2.lt(lptBalance)).to.be.true
    })
  })

});