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
  Rating,
  TablePagination,
  Button,
  Grid,
  Card,
  CardContent,
} from '@mui/material'
import { Download } from '@mui/icons-material'
import { apiService } from '../services/api'
import type { FeedbackItem } from '../types'
import { format } from 'date-fns'

export default function Feedback() {
  const [feedback, setFeedback] = useState<FeedbackItem[]>([])
  const [_loading, setLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [total, setTotal] = useState(0)

  useEffect(() => {
    loadFeedback()
  }, [page, rowsPerPage])

  const loadFeedback = async () => {
    try {
      const response = await apiService.getFeedback(page + 1, rowsPerPage)
      setFeedback(response.feedback)
      setTotal(response.total)
    } catch (error) {
      console.error('Failed to load feedback:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleExport = async () => {
    try {
      const blob = await apiService.exportData('feedback')
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `feedback_${Date.now()}.csv`
      a.click()
    } catch (error) {
      console.error('Export failed:', error)
    }
  }

  const averageRating = feedback.length > 0
    ? (feedback.reduce((sum, item) => sum + item.rating, 0) / feedback.length).toFixed(1)
    : '0.0'

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Feedback
          </Typography>
          <Typography variant="body2" color="text.secondary">
            User feedback and satisfaction ratings
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

      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom variant="overline">
                Average Rating
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Typography variant="h3">{averageRating}</Typography>
                <Rating value={parseFloat(averageRating)} readOnly precision={0.1} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom variant="overline">
                Total Feedback
              </Typography>
              <Typography variant="h3">{total}</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell>User ID</TableCell>
              <TableCell>Rating</TableCell>
              <TableCell>Comment</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Date</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {feedback.map((item) => (
              <TableRow key={item.id}>
                <TableCell>{item.id}</TableCell>
                <TableCell>{item.user_id}</TableCell>
                <TableCell>
                  <Rating value={item.rating} readOnly size="small" />
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {item.comment || '-'}
                  </Typography>
                </TableCell>
                <TableCell>{item.category || '-'}</TableCell>
                <TableCell>
                  {format(new Date(item.created_at), 'MMM dd, yyyy')}
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
