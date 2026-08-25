/**
 * Mining Engine
 * SHA-256 hashing, difficulty variabile, reward GNT
 */

import crypto from 'crypto';
import { Worker } from 'worker_threads';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export class MiningJob {
  constructor(jobId, data, difficulty, reward = 10) {
    this.jobId = jobId;
    this.data = data;
    this.difficulty = difficulty;
    this.reward = reward;
    this.startTime = Date.now();
    this.nonce = 0;
    this.hash = null;
    this.completed = false;
  }

  getTarget() {
    return '0'.repeat(this.difficulty);
  }

  getElapsedTime() {
    return Date.now() - this.startTime;
  }
}

export class MiningEngine {
  constructor(maxWorkers = 4) {
    this.maxWorkers = maxWorkers;
    this.activeJobs = new Map();
    this.completedJobs = [];
    this.difficulty = 2;
    this.hashRate = 0;
    this.totalHashes = 0;
  }

  /**
   * Avvia un job di mining
   */
  startMiningJob(data, difficulty = null, reward = 10) {
    const jobId = crypto.randomBytes(8).toString('hex');
    const job = new MiningJob(
      jobId,
      data,
      difficulty || this.difficulty,
      reward
    );

    this.activeJobs.set(jobId, job);
    this.mineSync(job);
    return jobId;
  }

  /**
   * Mining sincrone (per semplicità)
   */
  mineSync(job) {
    const target = job.getTarget();
    let nonce = 0;

    while (true) {
      const hash = this.calculateHash(job.data, nonce);
      this.totalHashes++;

      if (hash.substring(0, job.difficulty) === target) {
        job.hash = hash;
        job.nonce = nonce;
        job.completed = true;
        this.activeJobs.delete(job.jobId);
        this.completedJobs.push(job);
        this.updateHashRate();
        return job;
      }

      nonce++;
      if (nonce % 100000 === 0) {
        this.updateHashRate();
      }
    }
  }

  /**
   * Calcola hash SHA-256
   */
  calculateHash(data, nonce) {
    const input = JSON.stringify({ data, nonce });
    return crypto.createHash('sha256').update(input).digest('hex');
  }

  /**
   * Aggiorna hash rate
   */
  updateHashRate() {
    const recentJobs = this.completedJobs.slice(-10);
    if (recentJobs.length === 0) {
      this.hashRate = 0;
      return;
    }

    const totalTime = recentJobs.reduce((sum, job) => sum + job.getElapsedTime(), 0) / 1000;
    const totalHashes = recentJobs.reduce((sum, job) => {
      const target = job.getTarget();
      let count = 0;
      for (let i = 0; i <= job.nonce; i++) {
        const hash = this.calculateHash(job.data, i);
        if (hash.substring(0, job.difficulty) === target) count++;
      }
      return sum + job.nonce;
    }, 0);

    this.hashRate = Math.round(totalHashes / totalTime);
  }

  /**
   * Ottiene lo stato di un job
   */
  getJobStatus(jobId) {
    const job = this.activeJobs.get(jobId) || this.completedJobs.find(j => j.jobId === jobId);
    if (!job) return null;

    return {
      jobId: job.jobId,
      completed: job.completed,
      difficulty: job.difficulty,
      nonce: job.nonce,
      hash: job.hash,
      elapsedTime: job.getElapsedTime(),
      reward: job.reward
    };
  }

  /**
   * Ottiene i job completati
   */
  getCompletedJobs(limit = 10) {
    return this.completedJobs.slice(-limit).map(job => ({
      jobId: job.jobId,
      difficulty: job.difficulty,
      nonce: job.nonce,
      hash: job.hash,
      elapsedTime: job.getElapsedTime(),
      reward: job.reward,
      completedAt: new Date(job.startTime + job.getElapsedTime()).toISOString()
    }));
  }

  /**
   * Ottiene statistiche mining
   */
  getStats() {
    return {
      activeJobs: this.activeJobs.size,
      completedJobs: this.completedJobs.length,
      totalHashes: this.totalHashes,
      hashRate: this.hashRate,
      averageDifficulty: this.completedJobs.length > 0
        ? this.completedJobs.reduce((sum, job) => sum + job.difficulty, 0) / this.completedJobs.length
        : 0,
      totalRewards: this.completedJobs.reduce((sum, job) => sum + job.reward, 0)
    };
  }

  /**
   * Regola la difficoltà
   */
  adjustDifficulty(targetTime = 10000) {
    if (this.completedJobs.length < 10) return;

    const recentJobs = this.completedJobs.slice(-10);
    const avgTime = recentJobs.reduce((sum, job) => sum + job.getElapsedTime(), 0) / recentJobs.length;

    if (avgTime < targetTime / 2 && this.difficulty < 5) {
      this.difficulty++;
    } else if (avgTime > targetTime * 2 && this.difficulty > 1) {
      this.difficulty--;
    }
  }

  /**
   * Cancella i job completati
   */
  clearCompletedJobs() {
    const count = this.completedJobs.length;
    this.completedJobs = [];
    return count;
  }
}

export default MiningEngine;
