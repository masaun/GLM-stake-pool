import chai, {expect, assert} from 'chai';
import {createMockProvider, getWallets, solidity} from 'ethereum-waffle';
import {NewGolemNetworkTokenFactory, NGNTFaucetFactory} from '../..';
import {BigNumber} from 'ethers/utils';
import {NewGolemNetworkToken} from '../../build/contract-types/NewGolemNetworkToken';
import {deployNGNT, deployNGNTFaucet} from './utils';
import {NGNTFaucet} from 'gnt2-contracts/build/contract-types/NGNTFaucet';
import {AddressZero} from 'ethers/constants';

chai.use(solidity);

describe('NGNT Faucet', () => {
  const provider = createMockProvider();
  const [deployWallet, accountWallet] = getWallets(provider);

  const account = accountWallet.address;
  const deployer = deployWallet.address;

  const faucetMaxBalance = new BigNumber('1000000000000000000000');

  let token: NewGolemNetworkToken;
  let faucet: NGNTFaucet;

  beforeEach(async () => {
    faucet = await deployNGNTFaucet(deployWallet);
    token = await deployNGNT(deployWallet, faucet.address);
  });

  describe('Faucet deployment', async () => {
    it('only deployer can set New Golem Network Token contract', async () => {
      await expect(NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).setNGNT(token.address))
        .to.be.reverted;
    });

    it('New Golem Network Token contract address cannot be 0 address', async () => {
      await expect(NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(AddressZero))
        .to.be.reverted;
    });

    it('should set New Golem Network Token contract properly', async () => {
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(token.address);
    });

    it('New Golem Network Token contract can be set only once', async () => {
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(token.address);
      await expect(NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(token.address))
        .to.be.reverted;
    });
  });

  describe('Faucet usage', async () => {
    it('requires Faucet to have token contract initialized', async () => {
      await expect(NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).create())
        .to.be.reverted;
    });

    it('creates funds correctly while having no funds', async () => {
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(token.address);
      expect(await token.balanceOf(account)).to.be.eq(new BigNumber('0'));
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).create();
      expect(await token.balanceOf(account)).to.be.eq(faucetMaxBalance);
    });

    it('cannot creates funds while having more than 1.000 NGNT', async () => {
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(token.address);
      expect(await token.balanceOf(account)).to.be.eq(new BigNumber('0'));
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).create();
      expect(await token.balanceOf(account)).to.be.eq(faucetMaxBalance);

      await expect(NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).create())
        .to.be.reverted;
    });

    it('creates funds while having less than 1.000 NGNT', async () => {
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(deployer)).setNGNT(token.address);
      expect(await token.balanceOf(account)).to.be.eq(new BigNumber('0'));
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).create();
      expect(await token.balanceOf(account)).to.be.eq(faucetMaxBalance);

      // get rid of some NGNT tokens
      await NewGolemNetworkTokenFactory.connect(token.address, provider.getSigner(account)).transfer(deployer, new BigNumber('100'));
      // must use BigNumber's function instead of `to.be.lessThan`
      assert((await token.balanceOf(account)).lt(faucetMaxBalance));

      // creates new funds
      await NGNTFaucetFactory.connect(faucet.address, provider.getSigner(account)).create();
      // same as above
      assert((await token.balanceOf(account)).gt(faucetMaxBalance));
    });
  });
});
