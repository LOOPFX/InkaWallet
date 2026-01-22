import axios from 'axios'
import type { User, Transaction, DashboardStats } from '../types'

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('adminToken')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export const apiService = {
  // Auth
  login: async (email: string, password: string) => {
    const response = await api.post('/auth/login', { email, password })
    return response.data
  },

  // Dashboard Stats
  getDashboardStats: async (): Promise<DashboardStats> => {
    const response = await api.get('/admin/stats')
    return response.data
  },

  // Users
  getUsers: async (page = 1, limit = 10) => {
    const response = await api.get(`/admin/users?page=${page}&limit=${limit}`)
    return response.data
  },

  getUserById: async (id: number): Promise<User> => {
    const response = await api.get(`/admin/users/${id}`)
    return response.data
  },

  updateUserStatus: async (id: number, isActive: boolean) => {
    const response = await api.patch(`/admin/users/${id}/status`, { is_active: isActive })
    return response.data
  },

  // Transactions
  getTransactions: async (page = 1, limit = 10, filters?: any) => {
    const params = new URLSearchParams({ page: String(page), limit: String(limit) })
    if (filters) {
      Object.keys(filters).forEach(key => {
        if (filters[key]) params.append(key, filters[key])
      })
    }
    const response = await api.get(`/admin/transactions?${params}`)
    return response.data
  },

  getTransactionById: async (id: number): Promise<Transaction> => {
    const response = await api.get(`/admin/transactions/${id}`)
    return response.data
  },

  // Activity Logs
  getActivityLogs: async (page = 1, limit = 10, filters?: any) => {
    const params = new URLSearchParams({ page: String(page), limit: String(limit) })
    if (filters) {
      Object.keys(filters).forEach(key => {
        if (filters[key]) params.append(key, filters[key])
      })
    }
    const response = await api.get(`/admin/logs?${params}`)
    return response.data
  },

  // Feedback
  getFeedback: async (page = 1, limit = 10) => {
    const response = await api.get(`/admin/feedback?page=${page}&limit=${limit}`)
    return response.data
  },

  // Export Data
  exportData: async (type: 'users' | 'transactions' | 'logs' | 'feedback') => {
    const response = await api.get(`/admin/export/${type}`, {
      responseType: 'blob',
    })
    return response.data
  },
}
