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
  TablePagination,
  Button,
  TextField,
} from '@mui/material'
import { Download } from '@mui/icons-material'
import { apiService } from '../services/api'
import type { ActivityLog } from '../types'
import { format } from 'date-fns'

export default function ActivityLogs() {
  const [logs, setLogs] = useState<ActivityLog[]>([])
  const [_loading, setLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [total, setTotal] = useState(0)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    loadLogs()
  }, [page, rowsPerPage, searchTerm])

  const loadLogs = async () => {
    try {
      const response = await apiService.getActivityLogs(page + 1, rowsPerPage, { search: searchTerm })
      setLogs(response.logs)
      setTotal(response.total)
    } catch (error) {
      console.error('Failed to load logs:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleExport = async () => {
    try {
      const blob = await apiService.exportData('logs')
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `activity_logs_${Date.now()}.csv`
      a.click()
    } catch (error) {
      console.error('Export failed:', error)
    }
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Activity Logs
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Track user activities and system events
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
        <TextField
          fullWidth
          label="Search logs"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Search by action or user ID..."
        />
      </Paper>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell>User ID</TableCell>
              <TableCell>Action</TableCell>
              <TableCell>Details</TableCell>
              <TableCell>IP Address</TableCell>
              <TableCell>Timestamp</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {logs.map((log) => (
              <TableRow key={log.id}>
                <TableCell>{log.id}</TableCell>
                <TableCell>{log.user_id}</TableCell>
                <TableCell>
                  <Typography variant="body2" fontWeight="medium">
                    {log.action}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {log.details || '-'}
                  </Typography>
                </TableCell>
                <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.875rem' }}>
                  {log.ip_address || '-'}
                </TableCell>
                <TableCell>
                  {format(new Date(log.created_at), 'MMM dd, yyyy HH:mm:ss')}
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
