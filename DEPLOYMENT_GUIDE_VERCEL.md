# InkaWallet Deployment Guide - Vercel

## Prerequisites

- Vercel account (sign up at https://vercel.com)
- GitHub repository connected to Vercel
- PostgreSQL database (recommended: Neon, Supabase, or PlanetScale)

## Backend Deployment to Vercel

### Step 1: Prepare Backend for Vercel

Create `vercel.json` in the backend directory:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/server.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "src/server.ts"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

### Step 2: Update package.json

Add build script for Vercel:

```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "vercel-build": "npm run build"
  }
}
```

### Step 3: Environment Variables

Set these in Vercel Dashboard (Settings → Environment Variables):

**Required:**

- `DATABASE_HOST` - Your production MySQL/PostgreSQL host
- `DATABASE_USER` - Database username
- `DATABASE_PASSWORD` - Database password
- `DATABASE_NAME` - Database name
- `JWT_SECRET` - Random secure string (generate with `openssl rand -base64 32`)
- `SPEECHMATICS_API_KEY` - Your Speechmatics API key
- `NODE_ENV` - Set to `production`

**Optional:**

- `PORT` - 3000 (default)
- `DATABASE_PORT` - 3306 for MySQL

### Step 4: Deploy Backend

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy from backend directory
cd backend
vercel --prod
```

Or use Vercel's GitHub integration:

1. Go to https://vercel.com/new
2. Import your GitHub repository
3. Select `backend` as root directory
4. Add environment variables
5. Click Deploy

### Step 5: Database Setup

Run database migrations on your production database:

```bash
# Connect to production database and run:
mysql -h <host> -u <user> -p <database> < database/schema.sql
mysql -h <host> -u <user> -p <database> < database/credit_bnpl_schema.sql
```

---

## Admin Web Deployment to Vercel

### Step 1: Update API URL

Edit `admin-web/app/page.tsx` or create a config file to use production backend URL:

```typescript
const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "https://your-backend.vercel.app/api";
```

### Step 2: Environment Variables

Set in Vercel Dashboard:

- `NEXT_PUBLIC_API_URL` - Your backend Vercel URL

### Step 3: Deploy Admin Web

```bash
cd admin-web
vercel --prod
```

Or via GitHub:

1. Go to https://vercel.com/new
2. Import repository
3. Select `admin-web` as root directory
4. Framework: Next.js (auto-detected)
5. Add environment variables
6. Deploy

---

## Post-Deployment Steps

### 1. Update Mobile App Config

Update `mobile/lib/config/app_config.dart`:

```dart
class AppConfig {
  // Production URLs
  static const String apiBaseUrl = 'https://your-backend.vercel.app/api';
  static const String apiBaseUrlProduction = 'https://your-backend.vercel.app';

  // WebSocket for production (if supported)
  static const String wsBaseUrl = 'wss://your-backend.vercel.app';
  static const String wsBaseUrlProduction = 'wss://your-backend.vercel.app';
}
```

### 2. Test Endpoints

```bash
# Test backend health
curl https://your-backend.vercel.app/health

# Test admin web
curl https://your-admin.vercel.app
```

### 3. Set Up Custom Domain (Optional)

1. Go to Vercel Dashboard → Settings → Domains
2. Add your custom domain
3. Update DNS records as instructed

---

## Important Notes

### WebSocket Limitations

⚠️ **Vercel has limitations with WebSockets:**

- Serverless functions timeout after 10 seconds (Hobby) or 5 minutes (Pro)
- WebSocket connections (Speechmatics) may not work reliably
- Consider deploying WebSocket services separately to:
  - Railway.app
  - Render.com
  - AWS EC2/Lambda
  - Digital Ocean App Platform

### Database Recommendations

- **Neon** - PostgreSQL (free tier, serverless)
- **PlanetScale** - MySQL (free tier, serverless)
- **Supabase** - PostgreSQL (free tier, includes auth)
- **AWS RDS** - Production-grade
- **Railway** - PostgreSQL/MySQL with easy setup

### File Uploads

- Vercel serverless has 50MB deployment limit
- Store KYC documents in:
  - AWS S3
  - Cloudinary
  - Vercel Blob Storage

---

## Troubleshooting

### Build Fails

- Check Node.js version (use 18.x or 20.x)
- Verify all dependencies in package.json
- Check TypeScript compilation errors

### Database Connection Issues

- Verify environment variables are set correctly
- Check database whitelist (allow Vercel IPs)
- Test connection string locally first

### API Returns 500 Errors

- Check Vercel function logs
- Verify all environment variables are set
- Check database connectivity

---

## Alternative Deployment Options

If Vercel doesn't meet your needs:

### Railway.app

- Better for long-running services
- Native WebSocket support
- Database included
- Easy deployment: `railway up`

### Render.com

- Free tier available
- Native databases
- WebSocket support
- Background workers

### AWS

- Most flexible
- EC2 for full control
- Lambda for serverless
- RDS for database

### Digital Ocean

- App Platform
- Droplets (VPS)
- Managed databases
