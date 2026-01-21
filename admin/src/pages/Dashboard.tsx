import { useEffect, useState } from 'react'
import {
  Box,
  Grid,
  Paper,
  Typography,
  Card,
  CardContent,
} from '@mui/material'
import {
  People,
  AccountBalance,
  TrendingUp,
  Warning,
} from '@mui/icons-material'
import { apiService } from '../services/api'
import type { DashboardStats } from '../types'

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    try {
      const data = await apiService.getDashboardStats()
      setStats(data)
    } catch (error) {
      console.error('Failed to load stats:', error)
    } finally {
      setLoading(false)
    }
  }

  const statCards = [
    {
      title: 'Total Users',
      value: stats?.totalUsers || 0,
      icon: <People sx={{ fontSize: 40 }} />,
      color: '#6B46C1',
    },
    {
      title: 'Active Users',
      value: stats?.activeUsers || 0,
      icon: <People sx={{ fontSize: 40 }} />,
      color: '#10B981',
    },
    {
      title: 'Total Transactions',
      value: stats?.totalTransactions || 0,
      icon: <AccountBalance sx={{ fontSize: 40 }} />,
      color: '#3B82F6',
    },
    {
      title: 'Transaction Volume',
      value: `MWK ${(stats?.totalVolume || 0).toLocaleString()}`,
      icon: <TrendingUp sx={{ fontSize: 40 }} />,
      color: '#F59E0B',
    },
    {
      title: 'Pending Transactions',
      value: stats?.pendingTransactions || 0,
      icon: <Warning sx={{ fontSize: 40 }} />,
      color: '#EF4444',
    },
  ]

  if (loading) {
    return <Typography>Loading...</Typography>
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      <Typography variant="body2" color="text.secondary" paragraph>
        Overview of InkaWallet system metrics
      </Typography>

      <Grid container spacing={3}>
        {statCards.map((card) => (
          <Grid item xs={12} sm={6} md={4} key={card.title}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Box>
                    <Typography color="text.secondary" gutterBottom variant="overline">
                      {card.title}
                    </Typography>
                    <Typography variant="h4" component="div">
                      {card.value}
                    </Typography>
                  </Box>
                  <Box sx={{ color: card.color }}>
                    {card.icon}
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Box sx={{ mt: 4 }}>
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Research Data Collection
          </Typography>
          <Typography variant="body2" color="text.secondary">
            This dashboard collects anonymized data for research purposes including:
          </Typography>
          <ul>
            <li>User activity patterns and feature usage</li>
            <li>Transaction success rates and volumes</li>
            <li>Accessibility feature adoption rates</li>
            <li>User feedback and satisfaction ratings</li>
          </ul>
          <Typography variant="body2" color="text.secondary">
            All data is collected in accordance with privacy policies and research ethics guidelines.
          </Typography>
        </Paper>
      </Box>
    </Box>
  )
}
