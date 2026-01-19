import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32).toString('hex');
const ENCRYPTION_IV = process.env.ENCRYPTION_IV || crypto.randomBytes(16).toString('hex');

/**
 * Security utility functions for encryption, hashing, and data protection
 */

/**
 * Hash password using bcrypt
 */
export const hashPassword = async (password: string): Promise<string> => {
  const salt = await bcrypt.genSalt(12);
  return bcrypt.hash(password, salt);
};

/**
 * Compare password with hash
 */
export const comparePassword = async (
  password: string,
  hash: string
): Promise<boolean> => {
  return bcrypt.compare(password, hash);
};

/**
 * Encrypt sensitive data using AES-256-CBC
 */
export const encrypt = (text: string): string => {
  try {
    const key = Buffer.from(ENCRYPTION_KEY, 'hex').slice(0, 32);
    const iv = Buffer.from(ENCRYPTION_IV, 'hex').slice(0, 16);
    
    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    return encrypted;
  } catch (error) {
    throw new Error('Encryption failed');
  }
};

/**
 * Decrypt data
 */
export const decrypt = (encryptedText: string): string => {
  try {
    const key = Buffer.from(ENCRYPTION_KEY, 'hex').slice(0, 32);
    const iv = Buffer.from(ENCRYPTION_IV, 'hex').slice(0, 16);
    
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  } catch (error) {
    throw new Error('Decryption failed');
  }
};

/**
 * Generate secure random token
 */
export const generateToken = (length: number = 32): string => {
  return crypto.randomBytes(length).toString('hex');
};

/**
 * Generate transaction reference number
 */
export const generateReferenceNumber = (): string => {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `TXN${timestamp}${random}`;
};

/**
 * Generate wallet account number
 */
export const generateAccountNumber = (): string => {
  const prefix = '265'; // Malawi country code
  const random = crypto.randomInt(100000000, 999999999).toString();
  return prefix + random;
};

/**
 * Sanitize user input to prevent injection
 */
export const sanitizeInput = (input: string): string => {
  return input.replace(/[<>\"']/g, '').trim();
};

/**
 * Validate phone number format
 */
export const validatePhoneNumber = (phone: string): boolean => {
  const phoneRegex = /^\+?[0-9]{10,15}$/;
  return phoneRegex.test(phone);
};

/**
 * Validate email format
 */
export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return emailRegex.test(email);
};

/**
 * Mask sensitive data for logging
 */
export const maskSensitiveData = (data: string, visibleChars: number = 4): string => {
  if (data.length <= visibleChars) return '*'.repeat(data.length);
  return data.slice(0, visibleChars) + '*'.repeat(data.length - visibleChars);
};

/**
 * Generate checksum for data integrity
 */
export const generateChecksum = (data: string): string => {
  return crypto.createHash('sha256').update(data).digest('hex');
};

/**
 * Verify checksum
 */
export const verifyChecksum = (data: string, checksum: string): boolean => {
  return generateChecksum(data) === checksum;
};
