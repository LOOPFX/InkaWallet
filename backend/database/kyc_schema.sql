-- KYC (Know Your Customer) Schema for InkaWallet
-- Compliant with Malawi Regulatory Framework (Reserve Bank of Malawi & Financial Intelligence Authority)
-- Designed for inclusive finance - supports people with disabilities
USE inkawallet_db;
-- KYC Profiles Table
CREATE TABLE IF NOT EXISTS kyc_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NOT NULL,
    nationality VARCHAR(100) DEFAULT 'Malawian',
    -- Identification Documents (At least one required)
    national_id VARCHAR(50) UNIQUE,
    passport_number VARCHAR(50) UNIQUE,
    drivers_license VARCHAR(50) UNIQUE,
    voters_id VARCHAR(50) UNIQUE,
    -- Address Information
    residential_address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    region ENUM('Northern', 'Central', 'Southern') NOT NULL,
    postal_code VARCHAR(20),
    -- Employment Information
    occupation VARCHAR(150),
    employer_name VARCHAR(200),
    monthly_income_range ENUM(
        'below_50000',
        -- Below MKW 50,000
        '50000_100000',
        -- MKW 50,000 - 100,000
        '100000_250000',
        -- MKW 100,000 - 250,000
        '250000_500000',
        -- MKW 250,000 - 500,000
        'above_500000' -- Above MKW 500,000
    ),
    -- Source of Funds (Anti-Money Laundering requirement)
    source_of_funds ENUM(
        'salary',
        'business',
        'agriculture',
        'remittances',
        'pension',
        'government_assistance',
        'other'
    ) NOT NULL,
    -- Accessibility & Disability Support (Inclusive Finance)
    has_disability BOOLEAN DEFAULT FALSE,
    disability_type ENUM(
        'visual_impairment',
        'hearing_impairment',
        'physical_disability',
        'cognitive_disability',
        'multiple',
        'other',
        'none'
    ) DEFAULT 'none',
    requires_assistance BOOLEAN DEFAULT FALSE,
    preferred_communication ENUM(
        'voice',
        'text',
        'sign_language',
        'braille',
        'assisted'
    ) DEFAULT 'text',
    -- Next of Kin (Required for financial services)
    next_of_kin_name VARCHAR(200),
    next_of_kin_relationship VARCHAR(100),
    next_of_kin_phone VARCHAR(20),
    next_of_kin_address TEXT,
    -- KYC Status & Verification
    kyc_status ENUM(
        'incomplete',
        'pending_verification',
        'verified',
        'rejected',
        'expired'
    ) DEFAULT 'incomplete',
    verification_level ENUM('tier1', 'tier2', 'tier3') DEFAULT 'tier1',
    verified_at TIMESTAMP NULL,
    verified_by INT NULL,
    -- Admin who verified
    rejection_reason TEXT,
    -- Transaction Limits based on verification level
    -- Tier 1: Basic (MKW 500,000/month)
    -- Tier 2: Enhanced (MKW 2,000,000/month) 
    -- Tier 3: Full (Unlimited)
    daily_transaction_limit DECIMAL(15, 2) DEFAULT 50000.00,
    monthly_transaction_limit DECIMAL(15, 2) DEFAULT 500000.00,
    -- Risk Assessment (AML/CFT)
    risk_rating ENUM('low', 'medium', 'high') DEFAULT 'low',
    pep_status BOOLEAN DEFAULT FALSE,
    -- Politically Exposed Person
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE
    SET NULL,
        INDEX idx_user_id (user_id),
        INDEX idx_kyc_status (kyc_status),
        INDEX idx_verification_level (verification_level),
        INDEX idx_national_id (national_id),
        INDEX idx_risk_rating (risk_rating)
);
-- KYC Documents Table (for uploaded verification documents)
CREATE TABLE IF NOT EXISTS kyc_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kyc_profile_id INT NOT NULL,
    document_type ENUM(
        'national_id_front',
        'national_id_back',
        'passport',
        'drivers_license',
        'voters_id',
        'proof_of_address',
        'selfie',
        'employment_letter',
        'other'
    ) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size INT,
    -- in bytes
    mime_type VARCHAR(100),
    -- Document verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP NULL,
    verified_by INT NULL,
    verification_notes TEXT,
    -- Accessibility support - alternative formats
    is_audio_description BOOLEAN DEFAULT FALSE,
    -- For blind users
    has_sign_language_video BOOLEAN DEFAULT FALSE,
    -- For deaf users
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kyc_profile_id) REFERENCES kyc_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE
    SET NULL,
        INDEX idx_kyc_profile (kyc_profile_id),
        INDEX idx_document_type (document_type),
        INDEX idx_verified (is_verified)
);
-- KYC Verification History Table (Audit trail)
CREATE TABLE IF NOT EXISTS kyc_verification_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kyc_profile_id INT NOT NULL,
    action ENUM(
        'created',
        'submitted',
        'verified',
        'rejected',
        'updated',
        'tier_upgraded',
        'tier_downgraded',
        'suspended',
        'reactivated'
    ) NOT NULL,
    performed_by INT NULL,
    -- Admin user ID
    previous_status VARCHAR(50),
    new_status VARCHAR(50),
    comments TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kyc_profile_id) REFERENCES kyc_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES users(id) ON DELETE
    SET NULL,
        INDEX idx_kyc_profile (kyc_profile_id),
        INDEX idx_action (action),
        INDEX idx_created (created_at)
);
-- Transaction Monitoring Table (for AML/CFT compliance)
CREATE TABLE IF NOT EXISTS transaction_monitoring (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    transaction_id VARCHAR(100),
    -- Daily/Monthly totals
    daily_total DECIMAL(15, 2) DEFAULT 0.00,
    monthly_total DECIMAL(15, 2) DEFAULT 0.00,
    transaction_count_today INT DEFAULT 0,
    transaction_count_month INT DEFAULT 0,
    -- Suspicious activity flags
    is_flagged BOOLEAN DEFAULT FALSE,
    flag_reason TEXT,
    flagged_at TIMESTAMP NULL,
    -- Investigation
    is_under_investigation BOOLEAN DEFAULT FALSE,
    investigation_notes TEXT,
    investigated_by INT NULL,
    monitoring_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (investigated_by) REFERENCES users(id) ON DELETE
    SET NULL,
        UNIQUE KEY unique_user_date (user_id, monitoring_date),
        INDEX idx_user_id (user_id),
        INDEX idx_flagged (is_flagged),
        INDEX idx_monitoring_date (monitoring_date)
);
-- Beneficiaries Table (for frequent recipients - enhanced due diligence)
CREATE TABLE IF NOT EXISTS beneficiaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    beneficiary_name VARCHAR(200) NOT NULL,
    beneficiary_phone VARCHAR(20) NOT NULL,
    beneficiary_type ENUM('individual', 'business') DEFAULT 'individual',
    relationship VARCHAR(100),
    -- For businesses
    business_name VARCHAR(200),
    business_registration_number VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    total_amount_sent DECIMAL(15, 2) DEFAULT 0.00,
    transaction_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_phone (beneficiary_phone)
);