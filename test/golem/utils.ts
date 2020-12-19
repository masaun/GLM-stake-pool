import {NewGolemNetworkToken} from 'gnt2-contracts/build/contract-types/NewGolemNetworkToken';
import {NGNTFaucet} from 'gnt2-contracts/build/contract-types/NGNTFaucet';
import {NewGolemNetworkTokenFactory} from '../..';
import {Wallet} from 'ethers';
import {NGNTFaucetFactory} from 'gnt2-contracts/build/contract-types/NGNTFaucetFactory';

const DEFAULT_CHAIN_ID = 4;

export async function deployNGNT(deployer: Wallet, minter: string): Promise<NewGolemNetworkToken> {
  return new NewGolemNetworkTokenFactory(deployer).deploy(minter, DEFAULT_CHAIN_ID);
}

export async function deployNGNTFaucet(deployer: Wallet): Promise<NGNTFaucet> {
  return new NGNTFaucetFactory(deployer).deploy();
}
