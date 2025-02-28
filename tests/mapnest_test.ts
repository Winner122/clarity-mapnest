import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can add new POI and earn points",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("mapnest", "add-poi", [
        types.utf8("Coffee Shop"),
        types.utf8("Amazing hidden coffee shop"),
        types.int(40000000),
        types.int(-74000000)
      ], wallet_1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok u1)');
  },
});

Clarinet.test({
  name: "Can add review and update POI rating",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("mapnest", "add-poi", [
        types.utf8("Coffee Shop"),
        types.utf8("Amazing hidden coffee shop"),
        types.int(40000000),
        types.int(-74000000)
      ], wallet_1.address),
      Tx.contractCall("mapnest", "add-review", [
        types.uint(1),
        types.uint(5),
        types.utf8("Great place!")
      ], wallet_2.address)
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Cannot add invalid rating",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("mapnest", "add-poi", [
        types.utf8("Coffee Shop"),
        types.utf8("Amazing hidden coffee shop"),
        types.int(40000000),
        types.int(-74000000)
      ], wallet_1.address),
      Tx.contractCall("mapnest", "add-review", [
        types.uint(1),
        types.uint(6),
        types.utf8("Invalid rating!")
      ], wallet_2.address)
    ]);
    
    assertEquals(block.receipts[1].result, '(err u104)');
  },
});

Clarinet.test({
  name: "Can claim rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("mapnest", "add-poi", [
        types.utf8("Coffee Shop"),
        types.utf8("Amazing hidden coffee shop"),
        types.int(40000000),
        types.int(-74000000)
      ], wallet_1.address),
      Tx.contractCall("mapnest", "claim-rewards", [], wallet_1.address)
    ]);
    
    assertEquals(block.receipts[1].result, '(ok u100)');
  },
});
