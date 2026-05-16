/**
 * Wallet Engine
 * Generazione address, import/export chiavi, gestione saldi GNT
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

export class Wallet {
  constructor(address, publicKey, privateKey = null) {
    this.address = address;
    this.publicKey = publicKey;
    this.privateKey = privateKey;
    this.balance = 0;
    this.createdAt = new Date().toISOString();
  }

  getPublicAddress() {
    return this.address;
  }

  getBalance() {
    return this.balance;
  }

  setBalance(amount) {
    this.balance = Math.max(0, amount);
  }

  addBalance(amount) {
    this.balance += amount;
  }

  subtractBalance(amount) {
    if (this.balance < amount) {
      throw new Error('Insufficient balance');
    }
    this.balance -= amount;
  }

  toJSON() {
    return {
      address: this.address,
      publicKey: this.publicKey,
      balance: this.balance,
      createdAt: this.createdAt
    };
  }
}

export class WalletEngine {
  constructor(storagePath = './data/wallets') {
    this.storagePath = storagePath;
    this.wallets = new Map();
    this.ensureStorageDir();
    this.loadWallets();
  }

  ensureStorageDir() {
    if (!fs.existsSync(this.storagePath)) {
      fs.mkdirSync(this.storagePath, { recursive: true });
    }
  }

  /**
   * Crea un nuovo wallet da chiavi ECDSA
   */
  createWallet(publicKey, privateKey = null) {
    const address = this.generateAddress(publicKey);
    const wallet = new Wallet(address, publicKey, privateKey);
    this.wallets.set(address, wallet);
    this.saveWallet(wallet);
    return wallet;
  }

  /**
   * Genera un indirizzo wallet da chiave pubblica
   */
  generateAddress(publicKey) {
    const hash = crypto.createHash('sha256').update(publicKey).digest();
    const address = 'GNT-' + hash.toString('hex').substring(0, 40).toUpperCase();
    return address;
  }

  /**
   * Ottiene un wallet per indirizzo
   */
  getWallet(address) {
    return this.wallets.get(address) || null;
  }

  /**
   * Ottiene il saldo di un wallet
   */
  getBalance(address) {
    const wallet = this.getWallet(address);
    return wallet ? wallet.getBalance() : 0;
  }

  /**
   * Aggiorna il saldo di un wallet
   */
  updateBalance(address, amount) {
    let wallet = this.getWallet(address);
    if (!wallet) {
      wallet = new Wallet(address, null);
      this.wallets.set(address, wallet);
    }
    wallet.setBalance(amount);
    this.saveWallet(wallet);
    return wallet;
  }

  /**
   * Trasferisce GNT da un wallet all'altro
   */
  transfer(fromAddress, toAddress, amount) {
    const fromWallet = this.getWallet(fromAddress);
    if (!fromWallet) {
      throw new Error('Source wallet not found');
    }

    fromWallet.subtractBalance(amount);

    let toWallet = this.getWallet(toAddress);
    if (!toWallet) {
      toWallet = new Wallet(toAddress, null);
      this.wallets.set(toAddress, toWallet);
    }
    toWallet.addBalance(amount);

    this.saveWallet(fromWallet);
    this.saveWallet(toWallet);

    return {
      from: fromAddress,
      to: toAddress,
      amount,
      fromBalance: fromWallet.getBalance(),
      toBalance: toWallet.getBalance(),
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Salva un wallet su disco
   */
  saveWallet(wallet) {
    const filename = `${wallet.address}.json`;
    const filepath = path.join(this.storagePath, filename);
    fs.writeFileSync(filepath, JSON.stringify(wallet.toJSON(), null, 2));
  }

  /**
   * Carica un wallet da disco
   */
  loadWallet(address) {
    const filename = `${address}.json`;
    const filepath = path.join(this.storagePath, filename);
    
    if (!fs.existsSync(filepath)) {
      return null;
    }

    const data = JSON.parse(fs.readFileSync(filepath, 'utf8'));
    const wallet = new Wallet(data.address, data.publicKey);
    wallet.setBalance(data.balance);
    return wallet;
  }

  /**
   * Carica tutti i wallet da disco
   */
  loadWallets() {
    if (!fs.existsSync(this.storagePath)) {
      return;
    }

    const files = fs.readdirSync(this.storagePath).filter(f => f.endsWith('.json'));
    for (const file of files) {
      const filepath = path.join(this.storagePath, file);
      const data = JSON.parse(fs.readFileSync(filepath, 'utf8'));
      const wallet = new Wallet(data.address, data.publicKey);
      wallet.setBalance(data.balance);
      this.wallets.set(data.address, wallet);
    }
  }

  /**
   * Elenca tutti i wallet
   */
  listWallets() {
    return Array.from(this.wallets.values()).map(w => ({
      address: w.address,
      balance: w.balance,
      createdAt: w.createdAt
    }));
  }

  /**
   * Elimina un wallet
   */
  deleteWallet(address) {
    const filename = `${address}.json`;
    const filepath = path.join(this.storagePath, filename);
    if (fs.existsSync(filepath)) {
      fs.unlinkSync(filepath);
      this.wallets.delete(address);
      return true;
    }
    return false;
  }

  /**
   * Esporta un wallet (privato)
   */
  exportWallet(address) {
    const wallet = this.getWallet(address);
    if (!wallet) {
      throw new Error('Wallet not found');
    }
    return {
      address: wallet.address,
      publicKey: wallet.publicKey,
      privateKey: wallet.privateKey,
      balance: wallet.balance
    };
  }

  /**
   * Importa un wallet da chiavi
   */
  importWallet(publicKey, privateKey = null) {
    const address = this.generateAddress(publicKey);
    const wallet = new Wallet(address, publicKey, privateKey);
    this.wallets.set(address, wallet);
    this.saveWallet(wallet);
    return wallet;
  }

  /**
   * Ottiene statistiche wallet
   */
  getStats() {
    const wallets = Array.from(this.wallets.values());
    const totalBalance = wallets.reduce((sum, w) => sum + w.balance, 0);
    return {
      totalWallets: wallets.length,
      totalBalance,
      averageBalance: wallets.length > 0 ? totalBalance / wallets.length : 0,
      topWallets: wallets
        .sort((a, b) => b.balance - a.balance)
        .slice(0, 10)
        .map(w => ({ address: w.address, balance: w.balance }))
    };
  }
}

export default WalletEngine;
