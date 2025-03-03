import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// ... [Previous tests remain unchanged]

Clarinet.test({
  name: "Cannot add POI with invalid coordinates",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("mapnest", "add-poi", [
        types.utf8("Invalid POI"),
        types.utf8("Test description"),
        types.int(91000000),  // Invalid latitude
        types.int(-74000000),
        types.utf8("cafe")
      ], wallet_1.address)
    ]);
    
    assertEquals(block.receipts[0].result, '(err u105)');
  },
});

// ... [Additional tests for new features]
