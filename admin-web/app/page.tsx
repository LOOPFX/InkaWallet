'use client';

import { useState, useEffect } from 'react';
import axios from 'axios';
import { Container, Row, Col, Card, Table, Button, Nav, Form, Alert } from 'react-bootstrap';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

export default function AdminDashboard() {
  const [stats, setStats] = useState({ total_users: 0, total_transactions: 0, total_balance: 0 });
  const [users, setUsers] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [token, setToken] = useState('');
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [loginError, setLoginError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError('');
    try {
      const response = await axios.post(`${API_URL}/auth/login`, {
        email: loginEmail,
        password: loginPassword
      });
      
      if (!response.data.user.is_admin) {
        setLoginError('Access denied. Admin privileges required.');
        return;
      }

      const authToken = response.data.token;
      setToken(authToken);
      setCurrentUser(response.data.user);
      setIsLoggedIn(true);
      localStorage.setItem('admin_token', authToken);
      localStorage.setItem('admin_user', JSON.stringify(response.data.user));
      loadDashboardData(authToken);
    } catch (error: any) {
      setLoginError(error.response?.data?.error || 'Login failed');
    }
  };

  const handleLogout = () => {
    setToken('');
    setIsLoggedIn(false);
    setCurrentUser(null);
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
  };

  useEffect(() => {
    const savedToken = localStorage.getItem('admin_token');
    const savedUser = localStorage.getItem('admin_user');
    if (savedToken && savedUser) {
      setToken(savedToken);
      setCurrentUser(JSON.parse(savedUser));
      setIsLoggedIn(true);
      loadDashboardData(savedToken);
    }
  }, []);

  const loadDashboardData = async (authToken: string) => {
    try {
      const headers = { Authorization: `Bearer ${authToken}` };
      
      const [statsRes, usersRes, txRes] = await Promise.all([
        axios.get(`${API_URL}/admin/stats`, { headers }),
        axios.get(`${API_URL}/admin/users`, { headers }),
        axios.get(`${API_URL}/admin/transactions`, { headers })
      ]);

      setStats(statsRes.data);
      setUsers(usersRes.data);
      setTransactions(txRes.data);
    } catch (error: any) {
      if (error.response?.status === 401 || error.response?.status === 403) {
        handleLogout();
      }
      console.error('Failed to load data:', error);
    }
  };

  const deactivateUser = async (userId: number) => {
    if (userId === currentUser?.id) {
      alert('You cannot deactivate yourself!');
      return;
    }

    if (!confirm('Are you sure you want to deactivate this user?')) {
      return;
    }

    try {
      await axios.put(
        `${API_URL}/admin/users/${userId}/deactivate`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      loadDashboardData(token);
      alert('User deactivated successfully');
    } catch (error) {
      alert('Failed to deactivate user');
    }
  };

  const activateUser = async (userId: number) => {
    if (!confirm('Are you sure you want to activate this user?')) {
      return;
    }

    try {
      await axios.put(
        `${API_URL}/admin/users/${userId}/activate`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      loadDashboardData(token);
      alert('User activated successfully');
    } catch (error) {
      alert('Failed to activate user');
    }
  };

  if (!isLoggedIn) {
    return (
      <div className="min-vh-100 d-flex align-items-center justify-content-center" style={{ backgroundColor: '#7C3AED' }}>
        <Container>
          <Row className="justify-content-center">
            <Col md={6} lg={4}>
              <Card className="shadow-lg">
                <Card.Body className="p-5">
                  <div className="text-center mb-4">
                    <h2 style={{ color: '#7C3AED' }}>🏦 InkaWallet</h2>
                    <p className="text-muted">Admin Panel</p>
                  </div>
                  
                  {loginError && <Alert variant="danger">{loginError}</Alert>}
                  
                  <Form onSubmit={handleLogin}>
                    <Form.Group className="mb-3">
                      <Form.Label>Email</Form.Label>
                      <Form.Control
                        type="email"
                        placeholder="admin@inkawallet.com"
                        value={loginEmail}
                        onChange={(e) => setLoginEmail(e.target.value)}
                        required
                      />
                    </Form.Group>

                    <Form.Group className="mb-4">
                      <Form.Label>Password</Form.Label>
                      <Form.Control
                        type="password"
                        placeholder="Enter password"
                        value={loginPassword}
                        onChange={(e) => setLoginPassword(e.target.value)}
                        required
                      />
                    </Form.Group>

                    <Button 
                      type="submit" 
                      style={{ backgroundColor: '#7C3AED', border: 'none' }}
                      className="w-100"
                    >
                      Sign In
                    </Button>
                  </Form>
                </Card.Body>
              </Card>
            </Col>
          </Row>
        </Container>
      </div>
    );
  }

  return (
    <div className="min-vh-100" style={{ backgroundColor: '#f8f9fa' }}>
      <nav className="navbar navbar-dark" style={{ backgroundColor: '#7C3AED' }}>
        <Container>
          <span className="navbar-brand mb-0 h1">🏦 InkaWallet Admin Panel</span>
          <div className="d-flex align-items-center gap-3">
            <span className="text-white">Welcome, {currentUser?.full_name}</span>
            <Button variant="outline-light" size="sm" onClick={handleLogout}>Logout</Button>
          </div>
        </Container>
      </nav>

      <Container className="py-4">
        <Nav variant="pills" activeKey={activeTab} onSelect={(k) => setActiveTab(k || 'dashboard')} className="mb-4">
          <Nav.Item>
            <Nav.Link eventKey="dashboard">Dashboard</Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link eventKey="users">Users</Nav.Link>
          </Nav.Item>
          <Nav.Item>
            <Nav.Link eventKey="transactions">Transactions</Nav.Link>
          </Nav.Item>
        </Nav>

        {activeTab === 'dashboard' && (
          <Row>
            <Col md={4}>
              <Card className="text-center mb-3" style={{ borderTop: '4px solid #7C3AED' }}>
                <Card.Body>
                  <Card.Title>Total Users</Card.Title>
                  <h2 className="display-4">{stats.total_users}</h2>
                </Card.Body>
              </Card>
            </Col>
            <Col md={4}>
              <Card className="text-center mb-3" style={{ borderTop: '4px solid #10B981' }}>
                <Card.Body>
                  <Card.Title>Total Transactions</Card.Title>
                  <h2 className="display-4">{stats.total_transactions}</h2>
                </Card.Body>
              </Card>
            </Col>
            <Col md={4}>
              <Card className="text-center mb-3" style={{ borderTop: '4px solid #F59E0B' }}>
                <Card.Body>
                  <Card.Title>Total Balance</Card.Title>
                  <h2 className="display-4">MKW {stats.total_balance?.toLocaleString() || 0}</h2>
                </Card.Body>
              </Card>
            </Col>
          </Row>
        )}

        {activeTab === 'users' && (
          <Card>
            <Card.Header style={{ backgroundColor: '#7C3AED', color: 'white' }}>
              <h5 className="mb-0">User Management</h5>
            </Card.Header>
            <Card.Body>
              <Table striped bordered hover responsive>
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Email</th>
                    <th>Full Name</th>
                    <th>Phone</th>
                    <th>Accessibility</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user: any) => (
                    <tr key={user.id}>
                      <td>{user.id}</td>
                      <td>{user.email}</td>
                      <td>{user.full_name}</td>
                      <td>{user.phone_number}</td>
                      <td>
                        {user.accessibility_enabled ? (
                          <span className="badge bg-success">Enabled</span>
                        ) : (
                          <span className="badge bg-secondary">Disabled</span>
                        )}
                      </td>
                      <td>
                        {user.is_active ? (
                          <span className="badge bg-success">Active</span>
                        ) : (
                          <span className="badge bg-danger">Inactive</span>
                        )}
                      </td>
                      <td>
                        {user.is_active && !user.is_admin && (
                          <Button variant="danger" size="sm" onClick={() => deactivateUser(user.id)}>
                            Deactivate
                          </Button>
                        )}
                        {!user.is_active && (
                          <Button variant="success" size="sm" onClick={() => activateUser(user.id)}>
                            Activate
                          </Button>
                        )}
                        {user.id === currentUser?.id && (
                          <span className="badge bg-primary ms-2">You</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </Card.Body>
          </Card>
        )}

        {activeTab === 'transactions' && (
          <Card>
            <Card.Header style={{ backgroundColor: '#7C3AED', color: 'white' }}>
              <h5 className="mb-0">Transaction History</h5>
            </Card.Header>
            <Card.Body>
              <Table striped bordered hover responsive>
                <thead>
                  <tr>
                    <th>Transaction ID</th>
                    <th>Type</th>
                    <th>Amount (MKW)</th>
                    <th>Method</th>
                    <th>Status</th>
                    <th>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {transactions.map((tx: any) => (
                    <tr key={tx.id}>
                      <td><code>{tx.transaction_id}</code></td>
                      <td>
                        <span className={`badge ${tx.transaction_type === 'send' ? 'bg-danger' : 'bg-success'}`}>
                          {tx.transaction_type.toUpperCase()}
                        </span>
                      </td>
                      <td className="text-end">
                        {tx.transaction_type === 'send' ? '-' : '+'} {parseFloat(tx.amount).toLocaleString()}
                      </td>
                      <td>{tx.payment_method}</td>
                      <td>
                        <span className={`badge ${
                          tx.status === 'completed' ? 'bg-success' : 
                          tx.status === 'pending' ? 'bg-warning' : 'bg-danger'
                        }`}>
                          {tx.status}
                        </span>
                      </td>
                      <td>{new Date(tx.created_at).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </Card.Body>
          </Card>
        )}
      </Container>
    </div>
  );
}
