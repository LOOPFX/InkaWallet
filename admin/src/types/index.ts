export interface User {
  id: number
  first_name: string
  last_name: string
  email: string
  phone: string
  is_active: boolean
  created_at: string
}

export interface Transaction {
  id: number
  sender_id: number
  recipient_phone: string
  amount: number
  wallet_provider: string
  status: 'pending' | 'completed' | 'failed'
  reference_number: string
  description?: string
  created_at: string
}

export interface ActivityLog {
  id: number
  user_id: number
  action: string
  details?: string
  ip_address?: string
  created_at: string
}

export interface FeedbackItem {
  id: number
  user_id: number
  rating: number
  comment?: string
  category?: string
  created_at: string
}

export interface DashboardStats {
  totalUsers: number
  activeUsers: number
  totalTransactions: number
  totalVolume: number
  pendingTransactions: number
  failedTransactions: number
}
