# 🚀 How to Run the Civic Grievance System - Complete Guide

## 📋 System Components

The system has **3 main components** that need to run together:

1. **Backend API** (Flask) - Port 5000
2. **Mobile Web App** (Citizens) - Port 8000
3. **Admin Portal** (Administrators) - Port 8001
4. **Flutter Mobile App** (Optional) - Edge/Chrome browser

---

## 🎯 Quick Start (All Components)

### **Method 1: Run Everything (Recommended)**

#### **Terminal 1 - Backend API**
```powershell
cd D:\civic-grievance-system\backend
python app.py
```
- Runs on: `http://10.234.155.122:5000`
- Status: ✅ Running (debug mode enabled)

#### **Terminal 2 - Mobile Web App (Citizens)**
```powershell
cd "D:\civic-grievance-system\mobile_web_app"
python -m http.server 8000
```
- Runs on: `http://localhost:8000`
- Access: `http://localhost:8000/index.html` (Submit complaints)
- Track: `http://localhost:8000/track.html` (Track status)

#### **Terminal 3 - Admin Portal**
```powershell
cd "D:\civic-grievance-system\admin_portal"
python -m http.server 8001
```
- Runs on: `http://localhost:8001`
- Access: `http://localhost:8001/dashboard.html` (Admin dashboard)

---

## 🌐 Accessing the Application

### **Citizens Interface**
```
http://localhost:8000
```
**Features:**
- Submit new complaints
- Upload images/evidence
- View complaint status
- Track complaint timeline

**Pages:**
- `index.html` - Submit complaint form
- `track.html` - Track complaint status

### **Admin Dashboard**
```
http://localhost:8001
```
**Features:**
- View all complaints
- Manage complaint status
- Assign to departments
- View analytics
- Respond to grievances

**Page:**
- `dashboard.html` - Admin control panel

### **Citizen Mobile App (Flutter)**
```powershell
cd "D:\civic-grievance-system\mobile appppp"
flutter run -d edge --no-web-resources-cdn
```
**Features:**
- Voice input for complaints ⭐
- Offline sync capability
- Real-time notifications
- Complaint tracking

---

## 📊 Complete Setup Commands

### **Step 1: Activate Python Environment**
```powershell
cd D:\civic-grievance-system
# For Windows PowerShell
& .\venv\Scripts\Activate.ps1

# For Command Prompt
.\venv\Scripts\activate.bat
```

### **Step 2: Start Backend (Terminal 1)**
```powershell
cd D:\civic-grievance-system\backend
python app.py
```
Expected output:
```
* Running on http://127.0.0.1:5000
* Running on http://10.234.155.122:5000
```

### **Step 3: Start Mobile Web App (Terminal 2)**
```powershell
cd "D:\civic-grievance-system\mobile_web_app"
python -m http.server 8000
```
Expected output:
```
Serving HTTP on port 8000...
```

### **Step 4: Start Admin Portal (Terminal 3)**
```powershell
cd "D:\civic-grievance-system\admin_portal"
python -m http.server 8001
```
Expected output:
```
Serving HTTP on port 8001...
```

### **Step 5: Open in Browser**
- Citizens: Open `http://localhost:8000`
- Admin: Open `http://localhost:8001`

---

## 🔗 API Endpoints Reference

All API calls go to: `http://10.234.155.122:5000`

### **Authentication**
```
POST /api/auth/register
POST /api/auth/login
```

### **Complaints**
```
POST /api/complaints             # Submit complaint
GET /api/complaints              # Get all complaints
GET /api/complaints/{id}         # Get complaint details
PUT /api/complaints/{id}         # Update complaint status
```

### **Notifications**
```
GET /api/notifications           # Get user notifications
POST /api/notifications          # Create notification
```

### **Health Check**
```
GET /health                      # Check API status
```

---

## 🎨 Application Screenshots

### **Citizens - Submit Complaint**
- Dark themed form
- Category dropdown
- Image upload
- Voice input support ⭐
- Location auto-capture

### **Citizens - Track Status**
- Search by complaint ID
- Real-time status updates
- Upvote complaints
- View resolution notes

### **Admin Dashboard**
- List all complaints
- Sort by status/category
- Filter options
- Quick actions
- Analytics widgets

---

## ⚡ Development Mode

### **Watch for Changes (Backend)**
Flask automatically reloads when files change (debug mode on)

### **Live Reload (Web App)**
Refresh browser to see HTML/CSS/JS changes

### **Hot Reload (Flutter)**
```
r  - Hot reload
R  - Hot restart
q  - Quit
```

---

## 🐛 Troubleshooting

### **Backend won't start**
```powershell
# Check Python is installed
python --version

# Install requirements
pip install -r requirements.txt

# Try again
python app.py
```

### **Port already in use**
```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill process
taskkill /PID <PID> /F

# OR use different port
python -m http.server 9000  # Web app on 9000
```

### **Database connection error**
```powershell
# Check database file exists
dir D:\civic-grievance-system\database\grievances.db

# If missing, it will auto-initialize on first backend start
```

### **CORS errors in browser**
- Make sure backend is running on `http://10.234.155.122:5000`
- Web app sends requests to this IP, not localhost

---

## 📱 Example Workflow

### **As a Citizen:**
1. Open `http://localhost:8000`
2. Fill complaint form
3. Use voice input (speak complaint) 🎤
4. Upload evidence image
5. Click "Submit"
6. Get complaint ID
7. Go to `track.html`
8. Enter complaint ID to track status

### **As an Administrator:**
1. Open `http://localhost:8001`
2. View dashboard with all complaints
3. Click complaint to expand
4. Assign to department
5. Update status (Under Review → In Progress → Resolved)
6. Add resolution notes
7. System sends notifications to citizen

---

## 🔑 Test Credentials

### **Default Admin**
- Username: `admin`
- Password: `admin123`
- Role: Administrator

### **Test User** (register via app)
- Email: Any email
- Password: Any password (min 4 chars)

---

## 📊 Ports Summary

| Component | Port | URL |
|-----------|------|-----|
| Backend API | 5000 | http://10.234.155.122:5000 |
| Mobile Web App | 8000 | http://localhost:8000 |
| Admin Portal | 8001 | http://localhost:8001 |
| Flutter App | Edge | Browser (localhost:auto) |

---

## ✅ Verification Checklist

Before considering setup complete:

- [ ] Backend running on port 5000
- [ ] Mobile web app running on port 8000
- [ ] Admin portal running on port 8001
- [ ] Can access `http://localhost:8000` in browser
- [ ] Can access `http://localhost:8001` in browser
- [ ] Backend logs show "Running on..." messages
- [ ] No CORS errors in browser console
- [ ] Database file exists at `database/grievances.db`

---

## 🎯 Next Steps

1. **Submit a Test Complaint**
   - Go to `http://localhost:8000`
   - Fill form and submit
   - Note the complaint ID

2. **Track in Admin**
   - Go to `http://localhost:8001`
   - Find your complaint
   - Update status

3. **Check Database**
   - View SQLite database
   - Verify complaint was saved

4. **Try Flutter App**
   - Run `flutter run -d edge --no-web-resources-cdn`
   - Try voice input feature
   - Submit complaint from mobile

---

## 📞 Support

If components won't start:
1. Activate Python environment first
2. Check all required ports are free
3. Verify file paths are correct
4. Check Python requirements installed
5. Review error messages carefully

**All set! Your Civic Grievance System is ready to use! 🎉**
