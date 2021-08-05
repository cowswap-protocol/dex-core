const { accounts, contract } = require('@openzeppelin/test-environment');
const { expect } = require('chai');
const { toBN, keccak256 } = require('web3-utils');
const { BN, expectEvent, expectRevert, time, constants, balance, send } = require('@openzeppelin/test-helpers');

const [ admin, deployer, user, holder, investor1, investor2, investor3, investor4, investor11, investor12 ] = accounts;


const StakeDex = contract.fromArtifact('StakeDex');
const Mock = contract.fromArtifact('Mock');
const PancakeFactory = contract.fromArtifact('PancakeFactory')
const Router = contract.fromArtifact('RouterV2')
const POT = contract.fromArtifact('ProofOfTrade')
const WETH = contract.fromArtifact('WBNB')
const IERC20 = contract.fromArtifact('IERC20')
const PancakePair = contract.fromArtifact('PancakePair')

describe("RouterV2", function() {
  const BASE = new BN('10').pow(new BN('18'))
  const DEV =  "0x0000000000000000000000000000000000000003";
  const FEE =  "0x0000000000000000000000000000000000000fee";
  const AMM_FEE =  "0x0000000000000000000000000000000000001fee";


  beforeEach(async () => {
    this.TokenA = await Mock.new("TokenA", "A", 18);
    this.TokenB = await Mock.new("TokenB", "B", 18);
    this.TokenC = await Mock.new("TokenC", "C", 18);
    this.WETH = await WETH.new()
    this.Dex = await StakeDex.new(FEE);
    this.PancakeFactory = await PancakeFactory.new(admin)
    await this.PancakeFactory.setFeeTo(AMM_FEE, { from: admin })
    this.Router = await Router.new(this.Dex.address, this.PancakeFactory.address, this.WETH.address)
  });

  it("RouterV2:addLiquidity", async() => {
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

  it("RouterV2:removeLiquidity", async() => {
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
  	await this.Router.removeLiquidity(this.TokenA.address, this.TokenB.address, lptBalance, 0, 0, deployer, deadline, false, { from: deployer })

  	let lptBalanceAfter = await lpt.balanceOf(deployer)
  	expect(lptBalanceAfter.eq(toBN('0'))).to.be.true


  	let balanceA = await this.TokenA.balanceOf(deployer)

  	expect(balanceA.lt(amountA)).to.be.true
  })

  it("RouterV2:exactInput", async() => {
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

  it("RouterV2:exactInput multiple routers", async() => {
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
    expect(traded.toString()).to.eq("32491704847806283310")
  })

  it("RouterV2:exactOutput", async() => {
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
  	// A + C => 10000A + 1000C
  	await this.Router.addLiquidity(this.TokenA.address, this.TokenC.address, amountA, amountC, 0, 0, deployer, deadline, { from: deployer })
  	let pairAC = await this.PancakeFactory.getPair(this.TokenA.address, this.TokenC.address)

  	// Dex limit price order
  	await this.TokenA.mint(user, amountA)
  	await this.TokenA.approve(this.Dex.address, constants.MAX_UINT256, { from: user })
  	await this.Dex.mint(this.TokenA.address, this.TokenB.address, amountA, amountB, { from: user })

  	let path = [ this.TokenB.address, this.TokenA.address, this.TokenC.address ]
  	let amountInMax = toBN('381021519315530204822')
  	let amountOut = toBN('100').mul(BASE)

		await this.TokenB.mint(holder, amountInMax)
		await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, {from: holder})
		await this.Router.exactOutput(amountOut, amountInMax, path, holder, deadline, { from: holder })

		let traded = await this.TokenC.balanceOf(holder)
		expect(traded.toString()).to.eq('100000000000000000000')
    
  })

  it("RouterV2:exactOutput multiple routers", async() => {
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
    let amountInMax = toBN('390661198408866653599')
    let amountOut = toBN('110').mul(BASE)

    // let ammOutA = await this.Router.amm_calcInAmount(this.TokenA.address, this.TokenC.address, amountOut)
    // console.log("ammOutA===", ammOutA.toString())

    // let dexOut = await this.Router.dex_calcInAmount(this.TokenB.address, this.TokenA.address, toBN('381576779318538560936'))
    // console.log("dexOut amountIn ===", dexOut[0].toString())
    // console.log("dexOut unfilled ===", dexOut[1].toString())

    // let ammOut = await this.Router.amm_calcInAmount(this.TokenB.address, this.TokenA.address, toBN('281576779318538560936'))
    // console.log("ammOut===", ammOut.toString())

    // let input = await this.Router.getAmountsIn(amountOut, path, holder)

    // console.log(input.amounts.map(a=>a.toString()))
    // console.log(input.recipients.map(a=>a.toString()))
    // console.log(input.unfilledAmounts.map(a=>a.toString()))

    await this.TokenB.mint(holder, amountInMax)
    await this.TokenB.approve(this.Router.address, constants.MAX_UINT256, {from: holder})
    await this.Router.exactOutput(amountOut, amountInMax, path, holder, deadline, { from: holder })

    let traded = await this.TokenC.balanceOf(holder)
    expect(traded.toString()).to.eq('110000000000000000000')
    
  })

});