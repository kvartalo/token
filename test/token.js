/* global artifacts */
/* global contract */
/* global web3 */
/* global assert */


const Token = artifacts.require("../contracts/Token.sol");
const ethutil = require("ethereumjs-util")

const buf = b => ethutil.toBuffer(b)
const sha3 = b => web3.utils.soliditySha3(b)
const uint256 = n => "0x"+n.toString(16).padStart(64,'0')
const uint8 = n => "0x"+n.toString(16)

contract("token", (accounts) => {

    const 
        addr1 = "0x627306090abab3a6e1400e9345bc60c78a8bef57",
        pvk1 = ethutil.toBuffer("0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3"),
        addr2 = "0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef",
        addr3 = "0xf93010995479739501018f6f53b7b9dda325dc6a"


    beforeEach(async () => {
        token = await Token.new(addr3)
    });

    async function transfer (fromaddr, frompvk, toaddr, value) {
        let nonce = (await token.nonceOf(fromaddr)).toNumber()
        let msg = "0x"+Buffer.concat([
            buf(uint8(0x19)),buf(uint8(0)),
            buf(token.address),buf(uint256(nonce)),
            buf(fromaddr),buf(toaddr),buf(uint256(value))
        ]).toString('hex')
        let sig = ethutil.ecsign(buf(sha3(msg)),frompvk)
        await token.transfer(fromaddr,toaddr,value,sig.r,sig.s,sig.v)
    } 

    it("can transfer using offchain signatures" , async() => {
        await token.mint(addr1,1000);
        assert.equal(1000,await token.balanceOf(addr1));

        await transfer(addr1,pvk1,addr2,500);
        assert.equal(495,await token.balanceOf(addr2));
        assert.equal(5,await token.balanceOf(addr3));

        await transfer(addr1,pvk1,addr2,500);
        assert.equal(0,await token.balanceOf(addr1));
    })
})


