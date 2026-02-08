import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/api/health', async (req, res) => {
  const handler = await import('./api/health.ts');
  const mockRequest = new Request(`http://localhost:${PORT}/api/health`, {
    method: 'GET',
  });
  const response = await handler.default(mockRequest);
  const data = await response.json();
  res.status(response.status).json(data);
});

// Auth endpoints
app.post('/api/auth/signup', async (req, res) => {
  const handler = await import('./api/auth/signup.ts');
  const mockRequest = new Request(`http://localhost:${PORT}/api/auth/signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(req.body),
  });
  const response = await handler.default(mockRequest);
  const data = await response.json();
  res.status(response.status).json(data);
});

app.post('/api/auth/login', async (req, res) => {
  const handler = await import('./api/auth/login.ts');
  const mockRequest = new Request(`http://localhost:${PORT}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(req.body),
  });
  const response = await handler.default(mockRequest);
  const data = await response.json();
  res.status(response.status).json(data);
});

app.post('/api/auth/logout', async (req, res) => {
  const handler = await import('./api/auth/logout.ts');
  const mockRequest = new Request(`http://localhost:${PORT}/api/auth/logout`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': req.headers.authorization || '',
    },
  });
  const response = await handler.default(mockRequest);
  const data = await response.json();
  res.status(response.status).json(data);
});

// Device endpoints
app.post('/api/devices/register', async (req, res) => {
  const handler = await import('./api/devices/register.ts');
  const mockRequest = new Request(`http://localhost:${PORT}/api/devices/register`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': req.headers.authorization || '',
    },
    body: JSON.stringify(req.body),
  });
  const response = await handler.default(mockRequest);
  const data = await response.json();
  res.status(response.status).json(data);
});

app.get('/api/devices/list', async (req, res) => {
  const handler = await import('./api/devices/list.ts');
  const mockRequest = new Request(`http://localhost:${PORT}/api/devices/list`, {
    method: 'GET',
    headers: {
      'Authorization': req.headers.authorization || '',
    },
  });
  const response = await handler.default(mockRequest);
  const data = await response.json();
  res.status(response.status).json(data);
});

app.listen(PORT, () => {
  console.log(`\n🚀 DualTetraX Backend API (Dev Mode)`);
  console.log(`   Server running on http://localhost:${PORT}`);
  console.log(`\n📡 Available endpoints:`);
  console.log(`   GET  /api/health`);
  console.log(`   POST /api/auth/signup`);
  console.log(`   POST /api/auth/login`);
  console.log(`   POST /api/auth/logout`);
  console.log(`   POST /api/devices/register`);
  console.log(`   GET  /api/devices/list`);
  console.log(`\n✅ Press Ctrl+C to stop\n`);
});
