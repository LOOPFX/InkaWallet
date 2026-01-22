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
  IconButton,
  TablePagination,
  Button,
} from '@mui/material'
import { CheckCircle, Cancel, Download } from '@mui/icons-material'
import { apiService } from '../services/api'
import type { User } from '../types'
import { format } from 'date-fns'

export default function Users() {
  const [users, setUsers] = useState<User[]>([])
  const [_loading, setLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [total, setTotal] = useState(0)

  useEffect(() => {
    loadUsers()
  }, [page, rowsPerPage])

  const loadUsers = async () => {
    try {
      const response = await apiService.getUsers(page + 1, rowsPerPage)
      setUsers(response.users)
      setTotal(response.total)
    } catch (error) {
      console.error('Failed to load users:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleToggleStatus = async (userId: number, currentStatus: boolean) => {
    try {
      await apiService.updateUserStatus(userId, !currentStatus)
      loadUsers()
    } catch (error) {
      console.error('Failed to update user status:', error)
    }
  }

  const handleExport = async () => {
    try {
      const blob = await apiService.exportData('users')
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `users_${Date.now()}.csv`
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
            Users
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Manage registered users
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

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Phone</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Registered</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.id}>
                <TableCell>{user.id}</TableCell>
                <TableCell>{`${user.first_name} ${user.last_name}`}</TableCell>
                <TableCell>{user.email}</TableCell>
                <TableCell>{user.phone}</TableCell>
                <TableCell>
                  <Chip
                    label={user.is_active ? 'Active' : 'Inactive'}
                    color={user.is_active ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  {format(new Date(user.created_at), 'MMM dd, yyyy')}
                </TableCell>
                <TableCell>
                  <IconButton
                    size="small"
                    onClick={() => handleToggleStatus(user.id, user.is_active)}
                    color={user.is_active ? 'error' : 'success'}
                  >
                    {user.is_active ? <Cancel /> : <CheckCircle />}
                  </IconButton>
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
