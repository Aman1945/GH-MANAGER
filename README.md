# GH Manager — Guest House Management System

Full-stack MVP: Flutter Web + Node.js/Express + MongoDB Atlas

---

## Login Credentials (after seeding)

| Role | Email | Password |
|---|---|---|
| Admin | admin@ghmanager.in | Admin@123 |
| Booking Manager | booking@ghmanager.in | Book@123 |
| GH Manager – Goa | ramesh@ghmanager.in | GH@123 |
| GH Manager – Shimla | sunita@ghmanager.in | GH@123 |
| GH Manager – Mumbai | vikram@ghmanager.in | GH@123 |

---

## Booking Workflow

```
Lead PENDING
   ↓  Booking Manager approves + assigns room
Booking CONFIRMED  →  Room BLOCKED
   ↓  Admin marks payment
Payment PAID  →  Room OCCUPIED
   ↓  Admin checks out
Booking COMPLETED  →  Room AVAILABLE
```

---

## Part 1 — MongoDB Atlas Setup

1. Visit https://cloud.mongodb.com → Create free account
2. Create **Free M0 cluster** (any region, "gh-manager-cluster")
3. **Database Access** → Add Database User (username + password, read/write access)
4. **Network Access** → Add IP Address → Allow from anywhere: `0.0.0.0/0`
5. **Connect** → Drivers → copy connection string:
   ```
   mongodb+srv://<username>:<password>@gh-manager-cluster.xxxxx.mongodb.net/gh_manager?retryWrites=true&w=majority
   ```
6. Paste into `backend/.env` as `MONGODB_URI`

---

## Part 2 — Backend (Local Development)

```bash
cd "HOTEL BOOKING/backend"

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env — fill MONGODB_URI, JWT_SECRET

# Seed database
npm run seed

# Start dev server
npm run dev
# → API at http://localhost:5000

# Test
curl http://localhost:5000/api/health
```

### .env

```env
PORT=5000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/gh_manager?retryWrites=true&w=majority
JWT_SECRET=replace_with_long_random_string_min_32_chars
EMAIL_USER=optional@gmail.com
EMAIL_PASS=optional_app_password
```

---

## Part 3 — Flutter Frontend (Local Development)

```bash
cd "HOTEL BOOKING/frontend"

# Install dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome

# Production build (point to your EC2)
flutter build web --dart-define=API_URL=http://YOUR_EC2_IP/api
```

---

## Part 4 — AWS EC2 Deployment

### 4.1 — Launch EC2

- **AMI:** Ubuntu 22.04 LTS
- **Instance type:** t3.micro (free tier)
- **Security Group — Inbound rules:**
  ```
  SSH    port 22   from your IP
  HTTP   port 80   from 0.0.0.0/0
  Custom port 5000 from 0.0.0.0/0  (or remove after Nginx setup)
  ```
- **Key pair:** Download `.pem` file

### 4.2 — Connect & Setup Server

```bash
# Connect
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Update packages
sudo apt-get update && sudo apt-get upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node -v   # v18.x.x
npm -v

# Install PM2
sudo npm install -g pm2

# Install Nginx
sudo apt-get install -y nginx
```

### 4.3 — Deploy Backend

```bash
# Upload backend folder (from your local machine)
scp -i your-key.pem -r ./backend ubuntu@YOUR_EC2_IP:/home/ubuntu/gh-manager/backend

# On the server
cd /home/ubuntu/gh-manager/backend
npm install

# Create .env
nano .env
# Paste your environment variables

# Seed the database
npm run seed

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 process list (survive reboots)
pm2 save
pm2 startup
# Copy and run the sudo command it prints
```

### 4.4 — Deploy Flutter Web

```bash
# Build locally (replace with your EC2 IP)
cd frontend
flutter build web --dart-define=API_URL=http://YOUR_EC2_IP/api

# Upload build output to EC2
scp -i your-key.pem -r ./build/web ubuntu@YOUR_EC2_IP:/var/www/gh-manager
```

### 4.5 — Configure Nginx

```bash
# On EC2
sudo nano /etc/nginx/sites-available/gh-manager
```

Paste this config:

```nginx
server {
    listen 80;
    server_name YOUR_EC2_IP;

    # Flutter Web static files
    root /var/www/gh-manager;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to Node backend
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable and restart
sudo ln -s /etc/nginx/sites-available/gh-manager /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

App is now live at `http://YOUR_EC2_IP`

---

## PM2 Commands

```bash
pm2 list                   # list processes
pm2 logs gh-manager        # view logs
pm2 restart gh-manager     # restart
pm2 stop gh-manager        # stop
pm2 monit                  # monitor CPU/memory
```

---

## API Reference

| Method | Endpoint | Roles |
|---|---|---|
| POST | /api/auth/login | Public |
| GET | /api/auth/me | All |
| GET | /api/dashboard/admin | ADMIN |
| GET | /api/dashboard/booking-manager | BOOKING_MANAGER |
| GET | /api/dashboard/gh-manager | GH_MANAGER |
| GET | /api/leads | ADMIN, BOOKING_MANAGER |
| POST | /api/leads | ADMIN |
| GET | /api/approvals/pending | BOOKING_MANAGER |
| POST | /api/approvals/:id/approve | BOOKING_MANAGER |
| POST | /api/approvals/:id/reject | BOOKING_MANAGER |
| GET | /api/bookings | All |
| PATCH | /api/bookings/:id/payment | ADMIN |
| PATCH | /api/bookings/:id/checkout | ADMIN |
| GET | /api/rooms | All |
| GET | /api/rooms/availability | ADMIN, BOOKING_MANAGER |

---

## Part 5 — Render Deployment (Alternative to EC2)

### 5.1 — Deploy Backend to Render

1. **Push code to GitHub**
   ```bash
   git add . && git commit -m "deploy" && git push origin main
   ```

2. **Create Render service**
   - Go to https://render.com → Sign up
   - New → Web Service
   - Connect GitHub account
   - Select `HOTEL BOOKING/backend` folder
   - **Name:** gh-manager-backend
   - **Environment:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `npm run dev`
   - Add environment variables:
     ```
     MONGODB_URI = your_mongodb_atlas_url
     JWT_SECRET = your_jwt_secret
     EMAIL_USER = (optional)
     EMAIL_PASS = (optional)
     ```
   - Plan: **Free** (will auto-spin down after 15 min inactivity)
   - Click Deploy

3. **Note the URL** (e.g., `https://gh-manager-backend.onrender.com`)

### 5.2 — Keep Server ALIVE on Render (FREE)

**Problem:** Render spins down free apps after 15 min inactivity → slow first request

**Solution:** Use UptimeRobot to ping every 5 minutes

**Setup (2 minutes):**

1. Go to https://uptimerobot.com → Sign up FREE
2. Click **Add Monitor** → Select **HTTP(s)**
3. Fill form:
   ```
   URL: https://gh-manager-backend.onrender.com/api/health
   Friendly Name: GH Manager Backend
   Monitoring Interval: Every 5 minutes
   Timeout: 30 seconds
   ```
4. Click **Create Monitor**
5. Done! ✅

Now Render app will get pinged every 5 minutes → stays warm → instant response

### 5.3 — Deploy Flutter Frontend to Render (Optional)

1. Add a `render.yaml` in project root:
   ```yaml
   services:
   - type: web
     name: gh-manager-frontend
     buildCommand: flutter build web --dart-define=API_URL=https://gh-manager-backend.onrender.com/api
     staticPublishPath: build/web
   ```

2. Push to GitHub, Render auto-deploys

3. Frontend available at: `https://gh-manager-frontend.onrender.com`

---

## Troubleshooting

**MongoDB: "bad auth" error**
→ URL-encode special chars in password (`@` → `%40`, `#` → `%23`)

**MongoDB: connection timeout**
→ Check Network Access in Atlas — add `0.0.0.0/0`

**Flutter: white screen**
→ Make sure Nginx `try_files $uri $uri/ /index.html` is configured

**PM2: not running after reboot**
→ Run `pm2 save` and `pm2 startup`, execute the printed command

**CORS errors in browser**
→ Backend `app.js` already has `cors({ origin: '*' })` — check API_URL matches server IP

**Render server going to sleep**
→ Use UptimeRobot (free) to ping `/api/health` every 5 minutes
→ See Part 5.2 above
