# InkaWallet Database Setup Instructions

## Quick Setup

1. **Start MySQL service:**

   ```bash
   sudo service mysql start
   ```

2. **Create database and import schema:**

   ```bash
   # Option 1: If you have no password
   mysql -u root < backend/database/schema.sql

   # Option 2: With password
   mysql -u root -p < backend/database/schema.sql
   ```

3. **Update backend/.env** with your MySQL credentials

4. **Start backend server:**
   ```bash
   cd backend
   npm run dev
   ```

## Manual Setup via MySQL CLI

```bash
mysql -u root -p
```

Then in MySQL:

```sql
SOURCE /home/loopfx/InkaWallet/backend/database/schema.sql;
```

## Default Users

- **Admin:** admin@inkawallet.com / admin123
- **Test Users:** Created with 100,000 MKW balance on registration
