import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import transactionRoutes from './routes/transaction.routes';
import walletRoutes from './routes/wallet.routes';
import voiceRoutes from './routes/voice.routes';
import adminRoutes from './routes/admin.routes';
import moneyRequestRoutes from './routes/money-request.routes';
import servicesRoutes from './routes/services.routes';
import qrRoutes from './routes/qr.routes';
import creditRoutes from './routes/credit.routes';
import bnplRoutes from './routes/bnpl.routes';
import { SpeechmaticsProxyService } from './services/speechmatics-proxy.service';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3000;

// Create HTTP server for both Express and WebSocket
const server = createServer(app);

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/voice', voiceRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/money-requests', moneyRequestRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/credit', creditRoutes);
app.use('/api/bnpl', bnplRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'InkaWallet API is running' });
});

// Initialize Speechmatics WebSocket proxy
const speechmaticsProxy = new SpeechmaticsProxyService();
const wss = new WebSocketServer({ server, path: '/ws/voice' });

wss.on('connection', (ws, req) => {
  speechmaticsProxy.handleConnection(ws, req);
});

// Start server
server.listen(PORT, () => {
  console.log(`🚀 InkaWallet API running on port ${PORT}`);
  console.log(`📱 Environment: ${process.env.NODE_ENV}`);
  console.log(`🎤 WebSocket Voice Proxy: ws://localhost:${PORT}/ws/voice`);
  console.log(`🔑 Speechmatics API Key: ${speechmaticsProxy.getMaskedApiKey()}`);
});

export default app;
