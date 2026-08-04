// serve.mjs — minimal static file server for local preview. No dependencies beyond Node core.
// Usage: node serve.mjs  (serves the project root at http://localhost:3000)
import http from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join } from 'node:path';

const ROOT = process.cwd();
const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
};

const server = http.createServer(async (req, res) => {
  try {
    let urlPath = decodeURIComponent(req.url.split('?')[0]);
    let filePath = join(ROOT, urlPath);

    let stats;
    try {
      stats = await stat(filePath);
    } catch {
      stats = null;
    }

    if (stats && stats.isDirectory()) {
      filePath = join(filePath, 'index.html');
    } else if (!stats) {
      // no extension and not found as-is: try treating as a directory with index.html
      if (!extname(filePath)) {
        filePath = join(ROOT, urlPath, 'index.html');
      }
    }

    let data;
    try {
      data = await readFile(filePath);
    } catch {
      try {
        data = await readFile(join(ROOT, '404.html'));
        res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(data);
        return;
      } catch {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 Not Found');
        return;
      }
    }

    const ext = extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  } catch (err) {
    res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('500 Internal Server Error: ' + err.message);
  }
});

server.listen(PORT, () => {
  console.log(`Serving ${ROOT} at http://localhost:${PORT}`);
});
