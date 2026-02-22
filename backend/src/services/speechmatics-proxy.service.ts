import WebSocket from 'ws';
import { IncomingMessage } from 'http';

/**
 * Speechmatics WebSocket Proxy Service
 * 
 * This service acts as a secure proxy between the mobile app and Speechmatics API.
 * The API key is kept safe on the backend and never exposed to the client.
 */
export class SpeechmaticsProxyService {
  private speechmaticsUrl = 'wss://eu2.rt.speechmatics.com/v2';
  private apiKey: string;

  constructor() {
    this.apiKey = process.env.SPEECHMATICS_API_KEY || '';
    
    if (!this.apiKey) {
      console.warn('⚠️  SPEECHMATICS_API_KEY not set in .env file');
    } else {
      console.log('✅ Speechmatics API key loaded from backend .env');
    }
  }

  /**
   * Handle WebSocket connection from mobile app
   */
  handleConnection(clientWs: WebSocket, req: IncomingMessage) {
    console.log('📱 Mobile app connected for voice transcription');

    if (!this.apiKey) {
      clientWs.send(JSON.stringify({
        error: 'Speechmatics API key not configured on server'
      }));
      clientWs.close();
      return;
    }

    // Connect to Speechmatics with API key
    const speechmaticsWs = new WebSocket(`${this.speechmaticsUrl}?jwt=${this.apiKey}`);

    // Forward messages from mobile app to Speechmatics
    clientWs.on('message', (data) => {
      if (speechmaticsWs.readyState === WebSocket.OPEN) {
        speechmaticsWs.send(data);
      }
    });

    // Forward messages from Speechmatics to mobile app
    speechmaticsWs.on('message', (data) => {
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.send(data);
      }
    });

    // Handle Speechmatics connection open
    speechmaticsWs.on('open', () => {
      console.log('✅ Connected to Speechmatics API');
      
      // Notify mobile app that connection is ready
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.send(JSON.stringify({
          type: 'proxy_connected',
          message: 'Connected to Speechmatics via backend proxy'
        }));
      }
    });

    // Handle errors
    speechmaticsWs.on('error', (error) => {
      console.error('❌ Speechmatics WebSocket error:', error);
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.send(JSON.stringify({
          type: 'error',
          message: 'Speechmatics connection error'
        }));
      }
    });

    clientWs.on('error', (error) => {
      console.error('❌ Client WebSocket error:', error);
    });

    // Handle disconnections
    speechmaticsWs.on('close', () => {
      console.log('🔌 Speechmatics connection closed');
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.close();
      }
    });

    clientWs.on('close', () => {
      console.log('📱 Mobile app disconnected');
      if (speechmaticsWs.readyState === WebSocket.OPEN) {
        speechmaticsWs.close();
      }
    });
  }

  /**
   * Check if API key is configured
   */
  isConfigured(): boolean {
    return !!this.apiKey;
  }

  /**
   * Get masked API key for debugging (shows only first/last 4 chars)
   */
  getMaskedApiKey(): string {
    if (!this.apiKey) return 'NOT_CONFIGURED';
    if (this.apiKey.length < 12) return '***';
    
    return `${this.apiKey.substring(0, 4)}...${this.apiKey.substring(this.apiKey.length - 4)}`;
  }
}
