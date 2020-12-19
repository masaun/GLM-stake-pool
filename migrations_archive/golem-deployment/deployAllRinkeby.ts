import {providers, utils, Wallet} from 'ethers';
import {deployOldToken, wrapGNTtoGNTB} from './deployDevGolemContracts';
import {
  GolemNetworkTokenBatchingFactory,
  NewGolemNetworkTokenFactory
} from 'gnt2-contracts';
import {GNTDepositFactory} from '../..';

import {writeFile} from 'fs';
import {GNTMigrationAgentFactory} from '../../build/contract-types/GNTMigrationAgentFactory';
import {getChainId} from '../utils/network';

const infuraAddress = 'https://rinkeby.infura.io/v3/e9c991e7745b46908ce2b091a4cf643a';
const walletPrivateKeyAddress = '0xACE228774FDCDD8CEF12E94FE561747C7CD3601C9119AA389ECB43D9909E0BDC';

const delay = 48 * 60 * 60;

async function deployAllContracts() {
  const provider = new providers.JsonRpcProvider(infuraAddress);
  const deployer = new Wallet(walletPrivateKeyAddress, provider);

  console.log(`Deploying GNT ...`);
  const {token: oldGNT, holderSignedToken} = await deployOldToken(provider, deployer, deployer);
  console.log(`GNT deployed at address: ${oldGNT.address}`);

  console.log(`Deploying GNTB ...`);
  const GNTB = await new GolemNetworkTokenBatchingFactory(deployer).deploy(oldGNT.address);
  console.log(`GNTB deployed at address: ${GNTB.address}`);

  console.log(`Deploying deposit contract ...`);
  const GNTD = await new GNTDepositFactory(deployer).deploy(GNTB.address, oldGNT.address, deployer.address, delay);
  console.log(`Deposit contract deployed at address: ${GNTD.address}`);

  console.log(`Deploying Migration Agent ...`);
  const migrationAgent = await new GNTMigrationAgentFactory(deployer).deploy(oldGNT.address);
  console.log(`Migration Agent deployed at address: ${migrationAgent.address}`);

  console.log(`Deploying NGNT ...`);
  const NGNT = await new NewGolemNetworkTokenFactory(deployer).deploy(migrationAgent.address, await getChainId(provider));
  console.log(`NGNT deployed at address: ${NGNT.address}`);

  console.log('Setting migration agent ...');
  await migrationAgent.setTarget(NGNT.address);
  await oldGNT.setMigrationAgent(migrationAgent.address);
  console.log('Set!');

  console.log(`Wrapping oldGNT to GNTB ...`);
  const wrappedTokens = await wrapGNTtoGNTB(deployer, GNTB, holderSignedToken, utils.parseEther('10000000').toString());
  await wrappedTokens.wait();
  console.log(`done. tx hash: ${wrappedTokens.hash}`);

  console.log(`Transfer funds to deposit ...`);
  const deposit = await GNTB.transferAndCall(GNTD.address, utils.parseEther('100'), [], {gasLimit: 100000});
  await deposit.wait();
  console.log(`done. tx hash: ${deposit.hash}`);

  console.log('Distributing tokens');

  const ganacheWallets = ['0x17ec8597ff92C3F44523bDc65BF0f1bE632917ff',
    '0x63FC2aD3d021a4D7e64323529a55a9442C444dA0',
    '0xD1D84F0e28D6fedF03c73151f98dF95139700aa7',
    '0xd59ca627Af68D29C547B91066297a7c469a7bF72',
    '0xc2FCc7Bcf743153C58Efd44E6E723E9819E9A10A',
    '0x2ad611e02E4F7063F515C8f190E5728719937205',
    '0x5e8b3a7e6241CeE1f375924985F9c08706f41d34',
    '0xFC6F167a5AB77Fe53C4308a44d6893e8F2E54131',
    '0xDe41151d0762CB537921c99208c916f1cC7dA04D',
    '0x121199e18C70ac458958E8eB0BC97c0Ba0A36979'];

  for (let i = 0; i < 10; i++) {
    const contractTransaction = await holderSignedToken.transfer(ganacheWallets[i], utils.parseEther('10000'));
    await contractTransaction.wait();
    process.stdout.write('.');
  }
  console.log('\ndone!');

  const data = {
    deployer: {
      publicKey: deployer.address,
      privateKey: deployer.privateKey
    },
    addresses: {
      oldGNT: oldGNT.address,
      GNTB: GNTB.address,
      GNTD: GNTD.address,
      NGNT: NGNT.address
    }
  };

  writeFile('rinkeby-deployment.json', JSON.stringify({data}, null, 2), (err) => err && console.log(JSON.stringify(err)));
}

deployAllContracts();
