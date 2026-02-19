-- InkaWallet Database Schema
-- Created: 2026-02-19
CREATE DATABASE IF NOT EXISTS inkawallet_db;
USE inkawallet_db;
-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  google_id VARCHAR(255) UNIQUE,
  accessibility_enabled BOOLEAN DEFAULT TRUE,
  voice_enabled BOOLEAN DEFAULT TRUE,
  haptics_enabled BOOLEAN DEFAULT TRUE,
  biometric_enabled BOOLEAN DEFAULT FALSE,
  is_admin BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_phone (phone_number)
);
-- Wallets Table
CREATE TABLE IF NOT EXISTS wallets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  balance DECIMAL(15, 2) DEFAULT 100000.00,
  currency VARCHAR(3) DEFAULT 'MKW',
  is_locked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);
-- Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id VARCHAR(100) UNIQUE NOT NULL,
  sender_id INT,
  receiver_id INT,
  amount DECIMAL(15, 2) NOT NULL,
  transaction_type ENUM('send', 'receive', 'deposit', 'withdrawal') NOT NULL,
  payment_method ENUM('inkawallet', 'mpamba', 'airtel_money', 'bank') DEFAULT 'inkawallet',
  status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE
  SET NULL,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE
  SET NULL,
    INDEX idx_sender (sender_id),
    INDEX idx_receiver (receiver_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
);
-- Two-Factor Authentication Table
CREATE TABLE IF NOT EXISTS two_factor_auth (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_code (user_id, code)
);
-- Voice Biometrics Table
CREATE TABLE IF NOT EXISTS voice_biometrics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  voice_signature TEXT NOT NULL,
  confidence_level DECIMAL(5, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);
-- Activity Logs Table
CREATE TABLE IF NOT EXISTS activity_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(255) NOT NULL,
  details TEXT,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE
  SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_created (created_at)
);
-- Payment Providers (Mock External Services)
CREATE TABLE IF NOT EXISTS payment_providers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Insert mock payment providers
INSERT INTO payment_providers (name, code)
VALUES ('TNM Mpamba', 'mpamba'),
  ('Airtel Money', 'airtel_money'),
  ('National Bank of Malawi', 'nbm_bank'),
  ('Standard Bank', 'standard_bank'),
  ('FDH Bank', 'fdh_bank');
-- Create default admin user (password: admin123)
INSERT INTO users (
    email,
    password_hash,
    full_name,
    phone_number,
    is_admin,
    accessibility_enabled,
    voice_enabled,
    haptics_enabled
  )
VALUES (
    'admin@inkawallet.com',
    '$2a$10$rKzQXoXTxVVPjKGH8JHk0uMqPZ6qvJY5qEKGH8JHk0uMqPZ6qvJY5q',
    'System Administrator',
    '+265888000000',
    TRUE,
    FALSE,
    FALSE,
    FALSE
  );
-- Create wallet for admin
INSERT INTO wallets (user_id, balance)
VALUES (1, 100000.00);