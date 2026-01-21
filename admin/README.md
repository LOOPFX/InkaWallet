# InkaWallet Admin Dashboard

Web-based admin dashboard for monitoring and managing the InkaWallet system.

## Features

- **Dashboard Overview**: Real-time statistics and metrics
- **User Management**: View and manage registered users
- **Transaction Monitoring**: Track all transactions with filtering
- **Activity Logs**: Monitor system events and user activities
- **Feedback Analysis**: Review user feedback and ratings
- **Data Export**: Export data to CSV for research analysis

## Tech Stack

- React 18 with TypeScript
- Material-UI (MUI) for UI components
- React Router for navigation
- Axios for API calls
- Recharts for data visualization
- Vite for build tooling

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Running InkaWallet backend API

### Installation

```bash
# Navigate to admin directory
cd admin

# Install dependencies
npm install

# Start development server
npm run dev
```

The dashboard will be available at `http://localhost:3001`

### Build for Production

```bash
npm run build
npm run preview
```

## Default Login

Use any registered InkaWallet user credentials to access the admin dashboard.

For testing, create an admin user through the registration flow.

## Available Routes

- `/` - Dashboard with statistics
- `/users` - User management
- `/transactions` - Transaction monitoring
- `/logs` - Activity logs
- `/feedback` - User feedback

## API Integration

The dashboard communicates with the backend API at `/api/admin/*` endpoints.

All requests require JWT authentication via the `Authorization: Bearer <token>` header.

## Features in Detail

### Dashboard
- Total users (active and inactive)
- Transaction statistics (count, volume, status)
- Real-time metrics
- Research data collection info

### User Management
- View all registered users
- Paginated user list
- Activate/deactivate users
- Export user data to CSV

### Transactions
- View all transactions
- Filter by status (completed, pending, failed)
- Filter by wallet provider
- Export transaction data

### Activity Logs
- Track user actions
- Search logs by action or user
- View IP addresses and timestamps
- Export logs for analysis

### Feedback
- View user ratings and comments
- Calculate average satisfaction score
- Export feedback data

## Development

### Project Structure

```
admin/
├── src/
│   ├── components/      # Reusable components
│   │   └── Layout.tsx   # Main layout with navigation
│   ├── contexts/        # React contexts
│   │   └── AuthContext.tsx
│   ├── pages/          # Page components
│   │   ├── Dashboard.tsx
│   │   ├── Users.tsx
│   │   ├── Transactions.tsx
│   │   ├── ActivityLogs.tsx
│   │   ├── Feedback.tsx
│   │   └── Login.tsx
│   ├── services/       # API services
│   │   └── api.ts
│   ├── types/          # TypeScript types
│   │   └── index.ts
│   ├── App.tsx         # Main app component
│   └── main.tsx        # Entry point
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

### Adding New Features

1. Create page component in `src/pages/`
2. Add route in `src/App.tsx`
3. Add navigation item in `src/components/Layout.tsx`
4. Create API service methods in `src/services/api.ts`
5. Add TypeScript types in `src/types/index.ts`

## Security

- JWT-based authentication
- All API requests require valid token
- Tokens stored in localStorage
- Automatic logout on token expiration
- Admin-only access to sensitive data

## Research Data Collection

The admin dashboard facilitates research data collection by providing:

1. **Anonymized user activity metrics**
2. **Transaction patterns and success rates**
3. **Accessibility feature usage statistics**
4. **User satisfaction and feedback analysis**
5. **CSV export for external analysis tools**

All data collection follows research ethics guidelines and user privacy policies.

## Environment Variables

Create a `.env` file if needed:

```env
VITE_API_URL=http://localhost:3000/api
```

## Troubleshooting

### Cannot connect to API
- Ensure backend server is running on port 3000
- Check CORS settings in backend
- Verify API URL in vite.config.ts proxy

### Login fails
- Verify user credentials are correct
- Check backend API is accessible
- Ensure JWT tokens are being generated properly

### Build errors
- Delete node_modules and run `npm install` again
- Clear build cache: `rm -rf dist`
- Check TypeScript errors: `npm run lint`

## Contributing

This is a research project. For questions or contributions, contact the development team.

## License

Proprietary - InkaWallet Research Project
