import { useEffect, useState } from 'react'
import {
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  Chip,
  TablePagination,
  Button,
  TextField,
  Grid,
  MenuItem,
} from '@mui/material'
import { Download } from '@mui/icons-material'
import { apiService } from '../services/api'
import type { Transaction } from '../types'
import { format } from 'date-fns'

export default function Transactions() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [_loading, setLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [total, setTotal] = useState(0)
  const [filters, setFilters] = useState({
    status: '',
    provider: '',
  })

  useEffect(() => {
    loadTransactions()
  }, [page, rowsPerPage, filters])

  const loadTransactions = async () => {
    try {
      const response = await apiService.getTransactions(page + 1, rowsPerPage, filters)
      setTransactions(response.transactions)
      setTotal(response.total)
    } catch (error) {
      console.error('Failed to load transactions:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleExport = async () => {
    try {
      const blob = await apiService.exportData('transactions')
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `transactions_${Date.now()}.csv`
      a.click()
    } catch (error) {
      console.error('Export failed:', error)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'success'
      case 'pending':
        return 'warning'
      case 'failed':
        return 'error'
      default:
        return 'default'
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Transactions
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Monitor all transactions
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<Download />}
          onClick={handleExport}
        >
          Export
        </Button>
      </Box>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2}>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              select
              fullWidth
              label="Status"
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value })}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="completed">Completed</MenuItem>
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="failed">Failed</MenuItem>
            </TextField>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              select
              fullWidth
              label="Provider"
              value={filters.provider}
              onChange={(e) => setFilters({ ...filters, provider: e.target.value })}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="InkaWallet">InkaWallet</MenuItem>
              <MenuItem value="Mpamba">Mpamba</MenuItem>
              <MenuItem value="Airtel Money">Airtel Money</MenuItem>
            </TextField>
          </Grid>
        </Grid>
      </Paper>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Reference</TableCell>
              <TableCell>Recipient</TableCell>
              <TableCell>Amount</TableCell>
              <TableCell>Provider</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Date</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {transactions.map((txn) => (
              <TableRow key={txn.id}>
                <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.875rem' }}>
                  {txn.reference_number}
                </TableCell>
                <TableCell>{txn.recipient_phone}</TableCell>
                <TableCell>MWK {txn.amount.toLocaleString()}</TableCell>
                <TableCell>{txn.wallet_provider}</TableCell>
                <TableCell>
                  <Chip
                    label={txn.status.toUpperCase()}
                    color={getStatusColor(txn.status)}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  {format(new Date(txn.created_at), 'MMM dd, yyyy HH:mm')}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <TablePagination
          component="div"
          count={total}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => setRowsPerPage(parseInt(e.target.value, 10))}
        />
      </TableContainer>
    </Box>
  )
}
