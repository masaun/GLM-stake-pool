import chai, {expect} from 'chai';
import {createMockProvider, getWallets, solidity} from 'ethereum-waffle';
import {NewGolemNetworkTokenFactory} from '../..';
import {BigNumberish, keccak256, parseEther, SigningKey, solidityKeccak256} from 'ethers/utils';
import {ethers} from 'ethers';
import {NewGolemNetworkToken} from '../../build/contract-types/NewGolemNetworkToken';
import {BatchingSidecar} from '../../build/contract-types/BatchingSidecar';
import {BatchingSidecarFactory} from '../../build/contract-types/BatchingSidecarFactory';
import {currentTime, DEFAULT_TEST_OVERRIDES} from '../utils';
import {AddressZero, MaxUint256} from 'ethers/constants';

const DEFAULT_CHAIN_ID = 4;

chai.use(solidity);


describe('New Golem Network Token', () => {
  const provider = createMockProvider();
  const [deployWallet, minterWallet, holderWallet, spenderWallet, thirdWallet, fourthWallet] = getWallets(provider);
  const holder = holderWallet.address;
  const spender = spenderWallet.address;
  const minter = minterWallet.address;
  let asSpender: NewGolemNetworkToken;
  let asHolder: NewGolemNetworkToken;

  const third = thirdWallet.address;
  const fourth = fourthWallet.address;
  let token: NewGolemNetworkToken;
  let batchingSidecar: BatchingSidecar;
  let PERMIT_TYPEHASH: string;

  let DOMAIN_SEPARATOR: string;
  beforeEach(async () => {
    token = await deployNGNT();
    DOMAIN_SEPARATOR = await token.DOMAIN_SEPARATOR();
    PERMIT_TYPEHASH = await token.PERMIT_TYPEHASH();
    asHolder = NewGolemNetworkTokenFactory.connect(token.address, holderWallet);
    asSpender = NewGolemNetworkTokenFactory.connect(token.address, spenderWallet);

  });
  describe('deployment', async () => {

    it('sets token properties', async () => {
      expect(await token.name()).to.eq('Golem Network Token');
      expect(await token.symbol()).to.eq('GLM');
      expect(await token.decimals()).to.eq(18);
    });

    it('sets migration agent as the only minter', async () => {
      const asDeployer = await new NewGolemNetworkTokenFactory(deployWallet).deploy(minter, DEFAULT_CHAIN_ID);
      const asMinter = NewGolemNetworkTokenFactory.connect(asDeployer.address, minterWallet);

      await expect(asDeployer.mint(holder, parseEther('100'), DEFAULT_TEST_OVERRIDES))
        .to.be.revertedWith('MinterRole: caller does not have the Minter role');

      await asMinter.mint(holder, parseEther('100'));
      expect(await asMinter.balanceOf(holderWallet.address)).to.equal(parseEther('100'));
    });

  });


  describe('permit', () => {

    it('allows spender to spend tokens', async () => {
      const signature = signPermitDigest(holder, spender, 0, 0, true);
      await permit(signature, {holder, spender, nonce: 0, expiry: 0, allowed: true});
      await mint(token, holder, parseEther('100'));

      await asSpender.transferFrom(holder, third, parseEther('100'), DEFAULT_TEST_OVERRIDES);

      expect(await token.balanceOf(holder)).to.equal(0);
      expect(await token.balanceOf(third)).to.equal(parseEther('100'));
    });

    it('emits approval event', async () => {
      const signature = signDefaultPermit({holder, spender});
      await expect(permit(signature, {holder, spender})).to.emit(token, 'Approval').withArgs(holder, spender, MaxUint256);
    });

    it('cannot approve address 0', async () => {
      const signature = signDefaultPermit({holder: AddressZero});
      await expect(permit(signature, {holder: AddressZero})).to.be.revertedWith('Ngnt/invalid-address-0');
    });

    it('fails when invalid signature', async () => {
      const signature = signDefaultPermit({nonce: 0});
      await expect(permit(signature, {nonce: 1})).to.be.revertedWith('Ngnt/invalid-permit');
    });

    it('fails when expiry passed', async () => {
      const expiry = await currentTime(provider) - 100;
      const signature = signDefaultPermit({expiry});
      await expect(permit(signature, {expiry})).to.be.revertedWith('Ngnt/permit-expired');
    });

    it('fails when nonce used twice', async () => {
      await permit(signDefaultPermit({nonce: 0}), {nonce: 0});
      await expect(permit(signDefaultPermit({nonce: 0}), {nonce: 0})).to.be.revertedWith('Ngnt/invalid-nonce');
    });

    it('fails when nonce is out of order', async () => {
      await expect(permit(signDefaultPermit({nonce: 10}), {nonce: 10})).to.be.revertedWith('Ngnt/invalid-nonce');
    });

    it('does not change allowance from permit in transferFrom', async () => {
      await permit(signDefaultPermit());
      await mint(token, holderWallet.address, parseEther('100'));

      await asSpender.transferFrom(holderWallet.address, thirdWallet.address, parseEther('100'), DEFAULT_TEST_OVERRIDES);

      expect(await token.allowance(holder, spender)).to.eq(MaxUint256);
    });

    it('transferFrom fails after permit called with allowed=false', async () => {
      await mint(token, holder, parseEther('1000'));

      const allowingSignature = signDefaultPermit({nonce: 0, allowed: true});
      await permit(allowingSignature, {nonce: 0, allowed: true});

      const revokingSignature = signDefaultPermit({nonce: 1, allowed: false});
      await permit(revokingSignature, {nonce: 1, allowed: false});

      await (expect(asSpender.transferFrom(holder, thirdWallet.address, parseEther('105'), DEFAULT_TEST_OVERRIDES))
        .to.be.revertedWith('ERC20: transfer amount exceeds allowance'));
    });

  });

  describe('permit combined with approve', () => {
    it('Positive permit should override an approve', async () => {
      await asHolder.approve(spender, 10);
      expect(await token.allowance(holder, spender)).to.eq(10);

      await permit(signDefaultPermit());
      expect(await token.allowance(holder, spender)).to.eq(MaxUint256);
    });

    it('Negative permit should override an approve', async () => {
      await asHolder.approve(spender, 10);
      expect(await token.allowance(holder, spender)).to.eq(10);

      const signature = signDefaultPermit({allowed: false});
      await permit(signature, {allowed: false});
      expect(await token.allowance(holder, spender)).to.eq(0);
    });

    it('Finite approve should override a permit', async () => {
      await permit(signDefaultPermit());
      expect(await token.allowance(holder, spender)).to.eq(MaxUint256);

      await asHolder.approve(spender, 10);
      expect(await token.allowance(holder, spender)).to.eq(10);
    });

    it('Zero-approve should override a permit', async () => {
      await permit(signDefaultPermit());
      expect(await token.allowance(holder, spender)).to.eq(MaxUint256);

      await asHolder.approve(spender, 0);
      expect(await token.allowance(holder, spender)).to.eq(0);
    });
  });

  describe('transferFrom', () => {
    it('works for msg.sender without approve', async () => {
      await mint(token, holder, parseEther('110'));

      await asHolder.transferFrom(holder, third, parseEther('100'));

      expect(await token.balanceOf(holder)).to.equal(parseEther('10'));
      expect(await token.balanceOf(third)).to.equal(parseEther('100'));
    });

    it('uses same allowance storage as permit', async () => {
      await mint(token, holder, parseEther('100'));
      await asHolder.approve(spender, MaxUint256);

      await asSpender.transferFrom(holder, third, parseEther('100'), DEFAULT_TEST_OVERRIDES);

      expect(await token.allowance(holder, spender)).to.eq(MaxUint256);
    });

  });

  context('with ERC20 allowance of 100 tokens', () => {

    beforeEach(async () => {
      await mint(token, holder, parseEther('110'));
      await asHolder.approve(spender, parseEther('100'));
    });

    it('transferFrom reduces the ERC20 allowance', async () => {
      await asSpender.transferFrom(holder, third, parseEther('51'), DEFAULT_TEST_OVERRIDES);

      expect(await token.allowance(holder, spender)).to.eq(parseEther('49'));
      expect(await token.balanceOf(third)).to.equal(parseEther('51'));
    });

    it('transferFrom fails if permit is called with allowed=false', async () => {
      const signature = signDefaultPermit({allowed: false});
      await permit(signature, {allowed: false});

      await (expect(asSpender.transferFrom(holder, thirdWallet.address, parseEther('90'), DEFAULT_TEST_OVERRIDES))
        .to.be.revertedWith('ERC20: transfer amount exceeds allowance'));
    });

    it('transferFrom fails if allowance is too small', async () => {
      await (expect(asSpender.transferFrom(holder, thirdWallet.address, parseEther('105'), DEFAULT_TEST_OVERRIDES))
        .to.be.revertedWith('ERC20: transfer amount exceeds allowance'));
    });

    it('transferFrom fails if balance is too small', async () => {
      await (expect(asSpender.transferFrom(holder, thirdWallet.address, parseEther('200'), DEFAULT_TEST_OVERRIDES))
        .to.be.revertedWith('ERC20: transfer amount exceeds balance'));
    });

    it('transferFrom works for msg.sender', async () => {
      await asHolder.transferFrom(holder, third, parseEther('100'));

      expect(await token.balanceOf(holder)).to.equal(parseEther('10'));
      expect(await token.balanceOf(third)).to.equal(parseEther('100'));
      expect(await token.allowance(holder, spender)).to.eq(parseEther('100'));
    });
  });

  describe('batching sidecar', async () => {
    beforeEach(async () => {
      batchingSidecar = (await new BatchingSidecarFactory(deployWallet).deploy(token.address))
        .connect(holderWallet);
      await mint(token, holder, parseEther('110'));
    });

    it('sets the token address', async () => {
      expect(await batchingSidecar.ngnt()).to.eq(token.address);
    });

    it('should not allow to batch transfer without permitting', async () => {
      expect(batchingSidecar.batchTransfer([third, fourth], [33, 44])).to.eventually.be.rejected;
      expect(await token.balanceOf(third)).to.eq(0);
      expect(await token.balanceOf(fourth)).to.eq(0);
    });

    it('should not allow to batch transfer with invalid parameters', async () => {
      await expect(batchingSidecar.batchTransfer([third], [33, 44])).to.eventually.be.rejected;
      await expect(batchingSidecar.batchTransfer([third, fourth], [33])).to.eventually.be.rejected;
      await expect(batchingSidecar.batchTransfer([], [])).to.eventually.be.rejected;
      expect(await token.balanceOf(third)).to.eq(0);
      expect(await token.balanceOf(fourth)).to.eq(0);
    });

    it('should allow to batch transfer after permitting', async () => {
      const spender = batchingSidecar.address;
      const signature = signPermitDigest(holder, spender, 0, 0, true);
      await permit(signature, {holder, spender, nonce: 0, expiry: 0, allowed: true});

      await batchingSidecar.batchTransfer([third, fourth], [33, 44]);

      expect(await token.balanceOf(third)).to.eq(33);
      expect(await token.balanceOf(fourth)).to.eq(44);
    });
  });

  async function mint(token: NewGolemNetworkToken, account: string, amount: BigNumberish) {
    await NewGolemNetworkTokenFactory.connect(token.address, provider.getSigner(minterWallet.address)).mint(account, amount, DEFAULT_TEST_OVERRIDES);
  }

  async function deployNGNT() {
    return new NewGolemNetworkTokenFactory(deployWallet).deploy(minterWallet.address, DEFAULT_CHAIN_ID);
  }

  function permit(signature, {
    holder = holderWallet.address, spender = spenderWallet.address, nonce = 0, expiry = 0, allowed = true
  } = {}) {
    return token.permit(holder, spender, nonce, expiry, allowed, signature.v!, signature.r, signature.s, DEFAULT_TEST_OVERRIDES);
  }

  function signDefaultPermit({
    holder = holderWallet.address, spender = spenderWallet.address, nonce = 0, expiry = 0, allowed = true
  } = {}) {
    return signPermitDigest(holder, spender, nonce, expiry, allowed);
  }

  function signPermitDigest(holderAddress: string, spenderAddress: string, nonce: number, expiry: number, allowed: boolean) {
    const inner = keccak256(ethers.utils.defaultAbiCoder.encode(
      ['bytes32', 'address', 'address', 'uint256', 'uint256', 'bool'],
      [PERMIT_TYPEHASH, holderAddress, spenderAddress, nonce, expiry, allowed]));
    const message = solidityKeccak256(
      ['bytes2', 'bytes32', 'bytes32'],
      ['0x1901', DOMAIN_SEPARATOR, inner]);
    return new SigningKey(holderWallet.privateKey).signDigest(message);
  }

});
