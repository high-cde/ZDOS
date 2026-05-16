#!/usr/bin/env node

/**
 * X-ZDOS Quantum GhostNet OS - Simple Web Server
 * Serve static files with proper headers
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// MIME types
const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.eot': 'application/vnd.ms-fontobject'
};

const server = http.createServer((req, res) => {
  // Parse URL
  const parsedUrl = url.parse(req.url, true);
  let pathname = parsedUrl.pathname;

  // Default to index.html
  if (pathname === '/' || pathname === '') {
    pathname = '/index.html';
  }

  // Construct file path
  let filePath = path.join(__dirname, pathname);

  // Security: prevent directory traversal
  if (!filePath.startsWith(__dirname)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('Forbidden');
    return;
  }

  // Check if file exists
  fs.stat(filePath, (err, stats) => {
    if (err) {
      // File not found - serve index.html for SPA routing
      if (err.code === 'ENOENT') {
        filePath = path.join(__dirname, 'index.html');
        fs.readFile(filePath, (err, data) => {
          if (err) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Internal Server Error');
            return;
          }
          res.writeHead(200, {
            'Content-Type': 'text/html; charset=utf-8',
            'Cache-Control': 'no-cache'
          });
          res.end(data);
        });
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
      }
      return;
    }

    // If directory, serve index.html
    if (stats.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('Not Found');
          return;
        }
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8',
          'Cache-Control': 'no-cache'
        });
        res.end(data);
      });
      return;
    }

    // Read and serve file
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
        return;
      }

      // Get MIME type
      const ext = path.extname(filePath).toLowerCase();
      const contentType = mimeTypes[ext] || 'application/octet-stream';

      // Set cache headers
      let cacheControl = 'public, max-age=3600'; // 1 hour default
      if (ext === '.html') {
        cacheControl = 'no-cache, no-store, must-revalidate';
      } else if (['.css', '.js', '.svg', '.woff', '.woff2', '.ttf'].includes(ext)) {
        cacheControl = 'public, max-age=31536000'; // 1 year for assets
      }

      // Set security headers
      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': cacheControl,
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'SAMEORIGIN',
        'X-XSS-Protection': '1; mode=block',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'Access-Control-Allow-Origin': '*'
      });

      res.end(data);
    });
  });
});

server.listen(PORT, HOST, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║  X-ZDOS Quantum GhostNet OS                                ║
║  Server running at http://${HOST}:${PORT}                      ║
║  Press Ctrl+C to stop                                      ║
╚════════════════════════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\nServer stopped');
  process.exit(0);
});
