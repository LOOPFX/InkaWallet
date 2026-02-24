import { Router } from 'express';
import { Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import { authenticateToken } from '../middleware/auth.middleware';
import pool from '../config/database';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

const router = Router();

// Configure multer for KYC document uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/kyc-documents/');
  },
  filename: (req, file, cb) => {
    const userId = (req as any).user.userId;
    const timestamp = Date.now();
    const ext = path.extname(file.originalname);
    cb(null, `kyc_${userId}_${timestamp}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, and PDF files are allowed.'));
    }
  }
});

// Get KYC profile for current user
router.get('/profile', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const [rows] = await pool.query<RowDataPacket[]>(
      'SELECT * FROM kyc_profiles WHERE user_id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'KYC profile not found' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Error fetching KYC profile:', error);
    res.status(500).json({ message: 'Error fetching KYC profile' });
  }
});

// Create or update KYC profile
router.post('/profile', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const {
      first_name,
      middle_name,
      last_name,
      date_of_birth,
      gender,
      nationality,
      national_id,
      passport_number,
      drivers_license,
      voters_id,
      residential_address,
      city,
      district,
      region,
      postal_code,
      occupation,
      employer_name,
      monthly_income_range,
      source_of_funds,
      has_disability,
      disability_type,
      requires_assistance,
      preferred_communication,
      next_of_kin_name,
      next_of_kin_relationship,
      next_of_kin_phone,
      next_of_kin_address,
      pep_status
    } = req.body;

    // Validation: At least one ID required
    if (!national_id && !passport_number && !drivers_license && !voters_id) {
      return res.status(400).json({
        message: 'At least one form of identification is required (National ID, Passport, Driver\'s License, or Voter\'s ID)'
      });
    }

    // Check if profile exists
    const [existing] = await pool.query<RowDataPacket[]>(
      'SELECT id FROM kyc_profiles WHERE user_id = ?',
      [userId]
    );

    let result;
    if (existing.length > 0) {
      // Update existing profile
      [result] = await pool.query<ResultSetHeader>(
        `UPDATE kyc_profiles SET
          first_name = ?, middle_name = ?, last_name = ?, date_of_birth = ?,
          gender = ?, nationality = ?, national_id = ?, passport_number = ?,
          drivers_license = ?, voters_id = ?, residential_address = ?, city = ?,
          district = ?, region = ?, postal_code = ?, occupation = ?,
          employer_name = ?, monthly_income_range = ?, source_of_funds = ?,
          has_disability = ?, disability_type = ?, requires_assistance = ?,
          preferred_communication = ?, next_of_kin_name = ?, next_of_kin_relationship = ?,
          next_of_kin_phone = ?, next_of_kin_address = ?, pep_status = ?,
          kyc_status = 'incomplete', updated_at = NOW()
        WHERE user_id = ?`,
        [
          first_name, middle_name, last_name, date_of_birth, gender, nationality,
          national_id, passport_number, drivers_license, voters_id,
          residential_address, city, district, region, postal_code,
          occupation, employer_name, monthly_income_range, source_of_funds,
          has_disability, disability_type, requires_assistance, preferred_communication,
          next_of_kin_name, next_of_kin_relationship, next_of_kin_phone,
          next_of_kin_address, pep_status, userId
        ]
      );

      // Log update
      await pool.query(
        `INSERT INTO kyc_verification_history (kyc_profile_id, action, performed_by, comments)
         VALUES (?, 'updated', ?, 'Profile information updated by user')`,
        [existing[0].id, userId]
      );
    } else {
      // Create new profile
      [result] = await pool.query<ResultSetHeader>(
        `INSERT INTO kyc_profiles (
          user_id, first_name, middle_name, last_name, date_of_birth, gender,
          nationality, national_id, passport_number, drivers_license, voters_id,
          residential_address, city, district, region, postal_code, occupation,
          employer_name, monthly_income_range, source_of_funds, has_disability,
          disability_type, requires_assistance, preferred_communication,
          next_of_kin_name, next_of_kin_relationship, next_of_kin_phone,
          next_of_kin_address, pep_status, kyc_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'incomplete')`,
        [
          userId, first_name, middle_name, last_name, date_of_birth, gender,
          nationality, national_id, passport_number, drivers_license, voters_id,
          residential_address, city, district, region, postal_code, occupation,
          employer_name, monthly_income_range, source_of_funds, has_disability,
          disability_type, requires_assistance, preferred_communication,
          next_of_kin_name, next_of_kin_relationship, next_of_kin_phone,
          next_of_kin_address, pep_status
        ]
      );

      // Log creation
      await pool.query(
        `INSERT INTO kyc_verification_history (kyc_profile_id, action, performed_by, comments)
         VALUES (?, 'created', ?, 'KYC profile created by user')`,
        [result.insertId, userId]
      );
    }

    res.json({
      message: 'KYC profile saved successfully',
      kyc_status: 'incomplete'
    });
  } catch (error: any) {
    console.error('Error saving KYC profile:', error);
    
    // Handle duplicate ID errors
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({
        message: 'This ID number is already registered with another account'
      });
    }
    
    res.status(500).json({ message: 'Error saving KYC profile' });
  }
});

// Upload KYC document
router.post('/documents', authenticateToken, upload.single('document'), async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { document_type, is_audio_description, has_sign_language_video } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    // Get KYC profile ID
    const [profile] = await pool.query<RowDataPacket[]>(
      'SELECT id FROM kyc_profiles WHERE user_id = ?',
      [userId]
    );

    if (profile.length === 0) {
      return res.status(404).json({
        message: 'Please complete your KYC profile before uploading documents'
      });
    }

    const kycProfileId = profile[0].id;

    // Insert document record
    await pool.query(
      `INSERT INTO kyc_documents (
        kyc_profile_id, document_type, file_path, file_name, file_size,
        mime_type, is_audio_description, has_sign_language_video
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        kycProfileId,
        document_type,
        req.file.path,
        req.file.filename,
        req.file.size,
        req.file.mimetype,
        is_audio_description || false,
        has_sign_language_video || false
      ]
    );

    res.json({
      message: 'Document uploaded successfully',
      file_name: req.file.filename
    });
  } catch (error) {
    console.error('Error uploading document:', error);
    res.status(500).json({ message: 'Error uploading document' });
  }
});

// Get user's uploaded documents
router.get('/documents', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const [documents] = await pool.query<RowDataPacket[]>(
      `SELECT d.* FROM kyc_documents d
       INNER JOIN kyc_profiles p ON d.kyc_profile_id = p.id
       WHERE p.user_id = ?
       ORDER BY d.created_at DESC`,
      [userId]
    );

    res.json(documents);
  } catch (error) {
    console.error('Error fetching documents:', error);
    res.status(500).json({ message: 'Error fetching documents' });
  }
});

// Submit KYC for verification
router.post('/submit', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    // Check if profile exists and is complete
    const [profile] = await pool.query<RowDataPacket[]>(
      'SELECT id, kyc_status FROM kyc_profiles WHERE user_id = ?',
      [userId]
    );

    if (profile.length === 0) {
      return res.status(404).json({ message: 'Please complete your KYC profile first' });
    }

    // Check if required documents are uploaded
    const [documents] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) as count FROM kyc_documents WHERE kyc_profile_id = ?`,
      [profile[0].id]
    );

    if (documents[0].count < 2) {
      return res.status(400).json({
        message: 'Please upload at least 2 documents (ID and proof of address/selfie)'
      });
    }

    // Update status to pending verification
    await pool.query(
      `UPDATE kyc_profiles SET kyc_status = 'pending_verification', updated_at = NOW()
       WHERE id = ?`,
      [profile[0].id]
    );

    // Log submission
    await pool.query(
      `INSERT INTO kyc_verification_history (kyc_profile_id, action, performed_by, comments)
       VALUES (?, 'submitted', ?, 'KYC submitted for verification')`,
      [profile[0].id, userId]
    );

    res.json({
      message: 'KYC submitted successfully. Our team will review your documents within 24-48 hours.',
      kyc_status: 'pending_verification'
    });
  } catch (error) {
    console.error('Error submitting KYC:', error);
    res.status(500).json({ message: 'Error submitting KYC' });
  }
});

// Get KYC status
router.get('/status', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const [profile] = await pool.query<RowDataPacket[]>(
      `SELECT kyc_status, verification_level, verified_at, rejection_reason,
              daily_transaction_limit, monthly_transaction_limit, risk_rating
       FROM kyc_profiles WHERE user_id = ?`,
      [userId]
    );

    if (profile.length === 0) {
      return res.json({
        kyc_status: 'not_started',
        verification_level: null,
        message: 'Please start your KYC verification to unlock full wallet features'
      });
    }

    res.json(profile[0]);
  } catch (error) {
    console.error('Error fetching KYC status:', error);
    res.status(500).json({ message: 'Error fetching KYC status' });
  }
});

// Admin: Get all pending KYC verifications
router.get('/admin/pending', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    // Check if user is admin
    const [admin] = await pool.query<RowDataPacket[]>(
      'SELECT is_admin FROM users WHERE id = ?',
      [userId]
    );

    if (admin.length === 0 || !admin[0].is_admin) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const [pending] = await pool.query<RowDataPacket[]>(
      `SELECT p.*, u.email, u.phone_number, u.full_name as user_name
       FROM kyc_profiles p
       INNER JOIN users u ON p.user_id = u.id
       WHERE p.kyc_status = 'pending_verification'
       ORDER BY p.created_at ASC`
    );

    res.json(pending);
  } catch (error) {
    console.error('Error fetching pending KYC:', error);
    res.status(500).json({ message: 'Error fetching pending KYC' });
  }
});

// Admin: Verify or reject KYC
router.put('/admin/verify/:kycProfileId', authenticateToken, async (req: Request, res: Response) => {
  try {
    const adminId = (req as any).user.userId;
    const { kycProfileId } = req.params;
    const { action, rejection_reason, verification_level, daily_limit, monthly_limit } = req.body;

    // Check if user is admin
    const [admin] = await pool.query<RowDataPacket[]>(
      'SELECT is_admin FROM users WHERE id = ?',
      [adminId]
    );

    if (admin.length === 0 || !admin[0].is_admin) {
      return res.status(403).json({ message: 'Access denied' });
    }

    if (action === 'verify') {
      // Approve KYC
      await pool.query(
        `UPDATE kyc_profiles SET
          kyc_status = 'verified',
          verification_level = ?,
          verified_at = NOW(),
          verified_by = ?,
          daily_transaction_limit = ?,
          monthly_transaction_limit = ?,
          rejection_reason = NULL
        WHERE id = ?`,
        [verification_level || 'tier1', adminId, daily_limit || 50000, monthly_limit || 500000, kycProfileId]
      );

      // Log verification
      await pool.query(
        `INSERT INTO kyc_verification_history (kyc_profile_id, action, performed_by, new_status, comments)
         VALUES (?, 'verified', ?, 'verified', 'KYC approved by admin')`,
        [kycProfileId, adminId]
      );

      res.json({ message: 'KYC verified successfully' });
    } else if (action === 'reject') {
      // Reject KYC
      await pool.query(
        `UPDATE kyc_profiles SET
          kyc_status = 'rejected',
          rejection_reason = ?,
          verified_by = ?
        WHERE id = ?`,
        [rejection_reason, adminId, kycProfileId]
      );

      // Log rejection
      await pool.query(
        `INSERT INTO kyc_verification_history (kyc_profile_id, action, performed_by, new_status, comments)
         VALUES (?, 'rejected', ?, 'rejected', ?)`,
        [kycProfileId, adminId, rejection_reason]
      );

      res.json({ message: 'KYC rejected' });
    } else {
      res.status(400).json({ message: 'Invalid action' });
    }
  } catch (error) {
    console.error('Error verifying KYC:', error);
    res.status(500).json({ message: 'Error verifying KYC' });
  }
});

// Check transaction limits before processing
router.post('/check-limits', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { amount } = req.body;

    // Get KYC profile and limits
    const [profile] = await pool.query<RowDataPacket[]>(
      `SELECT kyc_status, verification_level, daily_transaction_limit, monthly_transaction_limit
       FROM kyc_profiles WHERE user_id = ?`,
      [userId]
    );

    if (profile.length === 0 || profile[0].kyc_status !== 'verified') {
      return res.status(403).json({
        allowed: false,
        message: 'Please complete KYC verification to make transactions',
        kyc_status: profile.length > 0 ? profile[0].kyc_status : 'not_started'
      });
    }

    // Get today's and this month's transaction totals
    const [monitoring] = await pool.query<RowDataPacket[]>(
      `SELECT daily_total, monthly_total FROM transaction_monitoring
       WHERE user_id = ? AND monitoring_date = CURDATE()`,
      [userId]
    );

    const dailyTotal = monitoring.length > 0 ? monitoring[0].daily_total : 0;
    const monthlyTotal = monitoring.length > 0 ? monitoring[0].monthly_total : 0;

    const dailyLimit = profile[0].daily_transaction_limit;
    const monthlyLimit = profile[0].monthly_transaction_limit;

    // Check limits
    if (dailyTotal + amount > dailyLimit) {
      return res.status(403).json({
        allowed: false,
        message: `Daily transaction limit exceeded. Limit: MKW ${dailyLimit.toLocaleString()}, Used: MKW ${dailyTotal.toLocaleString()}`,
        daily_limit: dailyLimit,
        daily_used: dailyTotal
      });
    }

    if (monthlyTotal + amount > monthlyLimit) {
      return res.status(403).json({
        allowed: false,
        message: `Monthly transaction limit exceeded. Limit: MKW ${monthlyLimit.toLocaleString()}, Used: MKW ${monthlyTotal.toLocaleString()}`,
        monthly_limit: monthlyLimit,
        monthly_used: monthlyTotal
      });
    }

    res.json({
      allowed: true,
      verification_level: profile[0].verification_level,
      daily_limit: dailyLimit,
      daily_used: dailyTotal,
      daily_remaining: dailyLimit - dailyTotal,
      monthly_limit: monthlyLimit,
      monthly_used: monthlyTotal,
      monthly_remaining: monthlyLimit - monthlyTotal
    });
  } catch (error) {
    console.error('Error checking limits:', error);
    res.status(500).json({ message: 'Error checking transaction limits' });
  }
});

export default router;
