/**
 * Identity Engine - ECDSA secp256k1
 * Generazione chiavi, firma/verifica messaggi, storage cifrato AES-256-GCM
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

const ALGORITHM = 'aes-256-gcm';
const KEY_SIZE = 32;
const IV_SIZE = 16;
const AUTH_TAG_SIZE = 16;

export class IdentityEngine {
  constructor(storagePath = './data/identities') {
    this.storagePath = storagePath;
    this.ensureStorageDir();
  }

  ensureStorageDir() {
    if (!fs.existsSync(this.storagePath)) {
      fs.mkdirSync(this.storagePath, { recursive: true });
    }
  }

  /**
   * Genera una nuova identità GHOST con chiavi ECDSA secp256k1
   */
  generateIdentity() {
    const keyPair = crypto.generateKeyPairSync('ec', {
      namedCurve: 'secp256k1',
      publicKeyEncoding: {
        type: 'spki',
        format: 'pem'
      },
      privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem'
      }
    });

    const ghostAddress = this.generateGhostAddress();
    const displayAlias = `ghost_${crypto.randomBytes(4).toString('hex')}`;
    const timestamp = new Date().toISOString();

    return {
      ghostAddress,
      displayAlias,
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey,
      createdAt: timestamp,
      version: '1.0'
    };
  }

  /**
   * Genera un indirizzo GHOST unico
   */
  generateGhostAddress() {
    const prefix = 'GHOST-';
    const randomBytes = crypto.randomBytes(20);
    const hash = crypto.createHash('sha256').update(randomBytes).digest();
    const address = hash.toString('hex').substring(0, 32).toUpperCase();
    return prefix + address;
  }

  /**
   * Firma un messaggio con la chiave privata
   */
  signMessage(privateKey, message) {
    const sign = crypto.createSign('sha256');
    sign.update(message);
    const signature = sign.sign(privateKey, 'hex');
    return signature;
  }

  /**
   * Verifica la firma di un messaggio
   */
  verifySignature(publicKey, message, signature) {
    try {
      const verify = crypto.createVerify('sha256');
      verify.update(message);
      return verify.verify(publicKey, Buffer.from(signature, 'hex'));
    } catch (error) {
      return false;
    }
  }

  /**
   * Cifra una chiave privata con AES-256-GCM
   */
  encryptPrivateKey(privateKey, password) {
    const salt = crypto.randomBytes(16);
    const derivedKey = crypto.pbkdf2Sync(password, salt, 100000, KEY_SIZE, 'sha256');
    const iv = crypto.randomBytes(IV_SIZE);
    
    const cipher = crypto.createCipheriv(ALGORITHM, derivedKey, iv);
    let encrypted = cipher.update(privateKey, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      salt: salt.toString('hex'),
      iv: iv.toString('hex'),
      encrypted,
      authTag: authTag.toString('hex')
    };
  }

  /**
   * Decifra una chiave privata cifrata
   */
  decryptPrivateKey(encryptedData, password) {
    try {
      const salt = Buffer.from(encryptedData.salt, 'hex');
      const derivedKey = crypto.pbkdf2Sync(password, salt, 100000, KEY_SIZE, 'sha256');
      const iv = Buffer.from(encryptedData.iv, 'hex');
      const authTag = Buffer.from(encryptedData.authTag, 'hex');
      
      const decipher = crypto.createDecipheriv(ALGORITHM, derivedKey, iv);
      decipher.setAuthTag(authTag);
      
      let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      throw new Error('Decryption failed: invalid password or corrupted data');
    }
  }

  /**
   * Salva un'identità cifrata su disco
   */
  saveIdentity(identity, password, filename = null) {
    const file = filename || `${identity.ghostAddress}.json`;
    const filepath = path.join(this.storagePath, file);
    
    const encryptedPrivateKey = this.encryptPrivateKey(identity.privateKey, password);
    
    const data = {
      ghostAddress: identity.ghostAddress,
      displayAlias: identity.displayAlias,
      publicKey: identity.publicKey,
      encryptedPrivateKey,
      createdAt: identity.createdAt,
      version: identity.version
    };
    
    fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
    return filepath;
  }

  /**
   * Carica un'identità da disco e decifra la chiave privata
   */
  loadIdentity(filename, password) {
    const filepath = path.join(this.storagePath, filename);
    
    if (!fs.existsSync(filepath)) {
      throw new Error(`Identity file not found: ${filepath}`);
    }
    
    const data = JSON.parse(fs.readFileSync(filepath, 'utf8'));
    const privateKey = this.decryptPrivateKey(data.encryptedPrivateKey, password);
    
    return {
      ghostAddress: data.ghostAddress,
      displayAlias: data.displayAlias,
      publicKey: data.publicKey,
      privateKey,
      createdAt: data.createdAt,
      version: data.version
    };
  }

  /**
   * Elenca tutte le identità salvate
   */
  listIdentities() {
    if (!fs.existsSync(this.storagePath)) {
      return [];
    }
    
    return fs.readdirSync(this.storagePath)
      .filter(f => f.endsWith('.json'))
      .map(f => {
        const data = JSON.parse(fs.readFileSync(path.join(this.storagePath, f), 'utf8'));
        return {
          file: f,
          ghostAddress: data.ghostAddress,
          displayAlias: data.displayAlias,
          createdAt: data.createdAt
        };
      });
  }

  /**
   * Elimina un'identità salvata
   */
  deleteIdentity(filename) {
    const filepath = path.join(this.storagePath, filename);
    if (fs.existsSync(filepath)) {
      fs.unlinkSync(filepath);
      return true;
    }
    return false;
  }
}

export default IdentityEngine;
