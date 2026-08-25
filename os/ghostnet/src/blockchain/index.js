/**
 * Mini-Blockchain Engine
 * JSON-DB locale, persistente, con Proof-of-Work
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

export class Block {
  constructor(index, timestamp, transactions, previousHash, nonce = 0, difficulty = 2) {
    this.index = index;
    this.timestamp = timestamp;
    this.transactions = transactions;
    this.previousHash = previousHash;
    this.nonce = nonce;
    this.difficulty = difficulty;
    this.hash = this.calculateHash();
  }

  calculateHash() {
    const data = JSON.stringify({
      index: this.index,
      timestamp: this.timestamp,
      transactions: this.transactions,
      previousHash: this.previousHash,
      nonce: this.nonce
    });
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  mineBlock() {
    const target = '0'.repeat(this.difficulty);
    while (this.hash.substring(0, this.difficulty) !== target) {
      this.nonce++;
      this.hash = this.calculateHash();
    }
    return this.nonce;
  }
}

export class Blockchain {
  constructor(dbPath = './data/blockchain.json') {
    this.dbPath = dbPath;
    this.chain = [];
    this.pendingTransactions = [];
    this.difficulty = 2;
    this.miningReward = 10; // GNT
    this.ensureDB();
    this.loadChain();
  }

  ensureDB() {
    const dir = path.dirname(this.dbPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(this.dbPath)) {
      this.chain = [this.createGenesisBlock()];
      this.saveChain();
    }
  }

  createGenesisBlock() {
    return new Block(0, Date.now(), [], '0', 0, this.difficulty);
  }

  getLatestBlock() {
    return this.chain[this.chain.length - 1];
  }

  addTransaction(transaction) {
    if (!transaction.from || !transaction.to || !transaction.amount) {
      throw new Error('Invalid transaction');
    }
    this.pendingTransactions.push({
      ...transaction,
      timestamp: Date.now(),
      id: crypto.randomBytes(16).toString('hex')
    });
    return transaction.id;
  }

  minePendingTransactions(minerAddress) {
    const block = new Block(
      this.chain.length,
      Date.now(),
      this.pendingTransactions,
      this.getLatestBlock().hash,
      0,
      this.difficulty
    );

    block.mineBlock();
    this.chain.push(block);

    // Aggiungi reward di mining
    this.pendingTransactions = [{
      from: 'SYSTEM',
      to: minerAddress,
      amount: this.miningReward,
      type: 'mining_reward',
      timestamp: Date.now()
    }];

    this.saveChain();
    return block;
  }

  getBalance(address) {
    let balance = 0;
    for (const block of this.chain) {
      for (const tx of block.transactions) {
        if (tx.from === address) balance -= tx.amount;
        if (tx.to === address) balance += tx.amount;
      }
    }
    return balance;
  }

  isChainValid() {
    for (let i = 1; i < this.chain.length; i++) {
      const currentBlock = this.chain[i];
      const previousBlock = this.chain[i - 1];

      if (currentBlock.hash !== currentBlock.calculateHash()) {
        return false;
      }
      if (currentBlock.previousHash !== previousBlock.hash) {
        return false;
      }
      if (currentBlock.hash.substring(0, currentBlock.difficulty) !== '0'.repeat(currentBlock.difficulty)) {
        return false;
      }
    }
    return true;
  }

  getChainInfo() {
    return {
      height: this.chain.length,
      difficulty: this.difficulty,
      totalTransactions: this.chain.reduce((sum, block) => sum + block.transactions.length, 0),
      pendingTransactions: this.pendingTransactions.length,
      isValid: this.isChainValid(),
      latestBlock: {
        index: this.getLatestBlock().index,
        hash: this.getLatestBlock().hash,
        timestamp: this.getLatestBlock().timestamp,
        transactions: this.getLatestBlock().transactions.length
      }
    };
  }

  saveChain() {
    fs.writeFileSync(this.dbPath, JSON.stringify({
      chain: this.chain,
      pendingTransactions: this.pendingTransactions,
      difficulty: this.difficulty,
      miningReward: this.miningReward,
      lastSaved: new Date().toISOString()
    }, null, 2));
  }

  loadChain() {
    try {
      const data = JSON.parse(fs.readFileSync(this.dbPath, 'utf8'));
      this.chain = data.chain || [this.createGenesisBlock()];
      this.pendingTransactions = data.pendingTransactions || [];
      this.difficulty = data.difficulty || 2;
      this.miningReward = data.miningReward || 10;
    } catch (error) {
      this.chain = [this.createGenesisBlock()];
      this.saveChain();
    }
  }

  adjustDifficulty() {
    if (this.chain.length % 10 === 0) {
      this.difficulty = Math.min(this.difficulty + 1, 5);
      this.saveChain();
    }
  }

  getTransactionPool() {
    return this.pendingTransactions;
  }

  getBlockByIndex(index) {
    return this.chain[index] || null;
  }

  getBlockByHash(hash) {
    return this.chain.find(block => block.hash === hash) || null;
  }

  getTransactionHistory(address, limit = 50) {
    const history = [];
    for (let i = this.chain.length - 1; i >= 0 && history.length < limit; i--) {
      const block = this.chain[i];
      for (const tx of block.transactions) {
        if (tx.from === address || tx.to === address) {
          history.push({
            ...tx,
            blockIndex: block.index,
            blockHash: block.hash
          });
        }
      }
    }
    return history;
  }
}

export default Blockchain;
