import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import pool from '../config/database';
import { RowDataPacket } from 'mysql2';

/**
 * Get dashboard statistics
 */
export const getDashboardStats = async (req: AuthRequest, res: Response) => {
  try {
    const connection = await pool.getConnection();

    try {
      // Total and active users
      const [userStats] = await connection.query<RowDataPacket[]>(
        'SELECT COUNT(*) as total, SUM(is_active) as active FROM users'
      );

      // Transaction stats
      const [txnStats] = await connection.query<RowDataPacket[]>(`
        SELECT 
          COUNT(*) as total,
          SUM(amount) as volume,
          SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
          SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed
        FROM transactions
      `);

      res.json({
        totalUsers: userStats[0].total || 0,
        activeUsers: userStats[0].active || 0,
        totalTransactions: txnStats[0].total || 0,
        totalVolume: parseFloat(txnStats[0].volume) || 0,
        pendingTransactions: txnStats[0].pending || 0,
        failedTransactions: txnStats[0].failed || 0,
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to retrieve dashboard statistics' });
  }
};

/**
 * Get all users with pagination
 */
export const getUsers = async (req: AuthRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = (page - 1) * limit;

    const connection = await pool.getConnection();

    try {
      // Get total count
      const [countResult] = await connection.query<RowDataPacket[]>(
        'SELECT COUNT(*) as total FROM users'
      );
      const total = countResult[0].total;

      // Get paginated users
      const [users] = await connection.query<RowDataPacket[]>(
        `SELECT id, first_name, last_name, email, phone, is_active, created_at 
         FROM users 
         ORDER BY created_at DESC 
         LIMIT ? OFFSET ?`,
        [limit, offset]
      );

      res.json({
        users,
        total,
        page,
        pages: Math.ceil(total / limit),
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to retrieve users' });
  }
};

/**
 * Get user by ID
 */
export const getUserById = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const connection = await pool.getConnection();

    try {
      const [users] = await connection.query<RowDataPacket[]>(
        `SELECT id, first_name, last_name, email, phone, is_active, created_at 
         FROM users 
         WHERE id = ?`,
        [id]
      );

      if (users.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(users[0]);
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to retrieve user' });
  }
};

/**
 * Update user status (activate/deactivate)
 */
export const updateUserStatus = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    const connection = await pool.getConnection();

    try {
      await connection.query(
        'UPDATE users SET is_active = ? WHERE id = ?',
        [is_active, id]
      );

      res.json({ success: true, message: 'User status updated' });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({ error: 'Failed to update user status' });
  }
};

/**
 * Get all transactions with pagination and filters
 */
export const getTransactions = async (req: AuthRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = (page - 1) * limit;
    const status = req.query.status as string;
    const provider = req.query.provider as string;

    let whereClause = '';
    const params: any[] = [];

    if (status) {
      whereClause += ' WHERE status = ?';
      params.push(status);
    }

    if (provider) {
      whereClause += status ? ' AND' : ' WHERE';
      whereClause += ' wallet_provider = ?';
      params.push(provider);
    }

    const connection = await pool.getConnection();

    try {
      // Get total count
      const [countResult] = await connection.query<RowDataPacket[]>(
        `SELECT COUNT(*) as total FROM transactions${whereClause}`,
        params
      );
      const total = countResult[0].total;

      // Get paginated transactions
      const [transactions] = await connection.query<RowDataPacket[]>(
        `SELECT id, sender_id, recipient_phone, amount, wallet_provider, 
                status, reference_number, description, created_at 
         FROM transactions${whereClause} 
         ORDER BY created_at DESC 
         LIMIT ? OFFSET ?`,
        [...params, limit, offset]
      );

      res.json({
        transactions,
        total,
        page,
        pages: Math.ceil(total / limit),
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ error: 'Failed to retrieve transactions' });
  }
};

/**
 * Get transaction by ID
 */
export const getTransactionById = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const connection = await pool.getConnection();

    try {
      const [transactions] = await connection.query<RowDataPacket[]>(
        `SELECT * FROM transactions WHERE id = ?`,
        [id]
      );

      if (transactions.length === 0) {
        return res.status(404).json({ error: 'Transaction not found' });
      }

      res.json(transactions[0]);
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get transaction error:', error);
    res.status(500).json({ error: 'Failed to retrieve transaction' });
  }
};

/**
 * Get activity logs with pagination and filters
 */
export const getActivityLogs = async (req: AuthRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search as string;

    let whereClause = '';
    const params: any[] = [];

    if (search) {
      whereClause = ' WHERE action LIKE ? OR details LIKE ?';
      params.push(`%${search}%`, `%${search}%`);
    }

    const connection = await pool.getConnection();

    try {
      // Get total count
      const [countResult] = await connection.query<RowDataPacket[]>(
        `SELECT COUNT(*) as total FROM activity_logs${whereClause}`,
        params
      );
      const total = countResult[0].total;

      // Get paginated logs
      const [logs] = await connection.query<RowDataPacket[]>(
        `SELECT * FROM activity_logs${whereClause} 
         ORDER BY created_at DESC 
         LIMIT ? OFFSET ?`,
        [...params, limit, offset]
      );

      res.json({
        logs,
        total,
        page,
        pages: Math.ceil(total / limit),
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get activity logs error:', error);
    res.status(500).json({ error: 'Failed to retrieve activity logs' });
  }
};

/**
 * Get feedback with pagination
 */
export const getFeedback = async (req: AuthRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = (page - 1) * limit;

    const connection = await pool.getConnection();

    try {
      // Get total count
      const [countResult] = await connection.query<RowDataPacket[]>(
        'SELECT COUNT(*) as total FROM feedback'
      );
      const total = countResult[0].total;

      // Get paginated feedback
      const [feedback] = await connection.query<RowDataPacket[]>(
        `SELECT * FROM feedback 
         ORDER BY created_at DESC 
         LIMIT ? OFFSET ?`,
        [limit, offset]
      );

      res.json({
        feedback,
        total,
        page,
        pages: Math.ceil(total / limit),
      });
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Get feedback error:', error);
    res.status(500).json({ error: 'Failed to retrieve feedback' });
  }
};

/**
 * Export data as CSV
 */
export const exportData = async (req: AuthRequest, res: Response) => {
  try {
    const { type } = req.params;

    const connection = await pool.getConnection();

    try {
      let data: any[];
      let headers: string[];

      switch (type) {
        case 'users':
          [data] = await connection.query<RowDataPacket[]>(
            'SELECT id, first_name, last_name, email, phone, is_active, created_at FROM users'
          );
          headers = ['ID', 'First Name', 'Last Name', 'Email', 'Phone', 'Active', 'Created At'];
          break;

        case 'transactions':
          [data] = await connection.query<RowDataPacket[]>(
            'SELECT * FROM transactions'
          );
          headers = ['ID', 'Sender ID', 'Recipient Phone', 'Amount', 'Provider', 'Status', 'Reference', 'Description', 'Created At'];
          break;

        case 'logs':
          [data] = await connection.query<RowDataPacket[]>(
            'SELECT * FROM activity_logs'
          );
          headers = ['ID', 'User ID', 'Action', 'Details', 'IP Address', 'Created At'];
          break;

        case 'feedback':
          [data] = await connection.query<RowDataPacket[]>(
            'SELECT * FROM feedback'
          );
          headers = ['ID', 'User ID', 'Rating', 'Comment', 'Category', 'Created At'];
          break;

        default:
          return res.status(400).json({ error: 'Invalid export type' });
      }

      // Generate CSV
      const csv = [
        headers.join(','),
        ...data.map((row) => Object.values(row).join(',')),
      ].join('\n');

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="${type}_${Date.now()}.csv"`);
      res.send(csv);
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Export data error:', error);
    res.status(500).json({ error: 'Failed to export data' });
  }
};
