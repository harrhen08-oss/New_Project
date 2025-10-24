import { Clarinet, Tx, Chain, Account, types } from '@clarinet/v1';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Deposit STX successfully",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const amount = 1000;

    let block = chain.mineBlock([
      Tx.contractCall('simple-eco-pool', 'deposit-stx', [types.uint(amount)], deployer.address),
    ]);

    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(amount);
  },
});

Clarinet.test({
  name: "Withdraw STX with interest and donation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const amount = 1000;

    chain.mineBlock([
      Tx.contractCall('simple-eco-pool', 'deposit-stx', [types.uint(amount)], deployer.address),
    ]);

    let block = chain.mineBlock([
      Tx.contractCall('simple-eco-pool', 'withdraw-stx', [types.uint(amount)], deployer.address),
    ]);

    block.receipts[0].result.expectOk();
    block.receipts[0].result.expectTuple().withdrawn.expectUint(amount);
    block.receipts[0].result.expectTuple().donated.expectUint(10); // 1% of 1000
  },
});

Clarinet.test({
  name: "Fail deposit with zero amount",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;

    let block = chain.mineBlock([
      Tx.contractCall('simple-eco-pool', 'deposit-stx', [types.uint(0)], deployer.address),
    ]);

    block.receipts[0].result.expectErr().expectUint(100);
  },
});