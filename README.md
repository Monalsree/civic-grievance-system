**# Civic Grievance System

A full-stack **AI-powered civic grievance management platform** that enables citizens to submit, track, and resolve complaints efficiently while administrators manage and analyze grievances with intelligent routing and analytics.

The system integrates **Google Gemini AI** for smart classification and response generation, along with traditional ML models, fuzzy logic for priority scoring, and a modern responsive interface.

---

## ✨ Key Features

### For Citizens
- Submit complaints with text, voice input, image upload, and auto location capture
- Real-time complaint tracking and status updates
- Upvote important grievances
- Notifications for status changes
- Offline complaint saving and sync (Flutter app)

### For Administrators
- Centralized dashboard to view and manage all complaints
- AI-assisted categorization, urgency detection, and department routing
- Analytics and trend reports (response time, category-wise trends)
- Quick status updates and responses

### AI & Smart Features
- Google Gemini API for intelligent complaint understanding and suggestions
- TF-IDF + Naive Bayes ML model (trained on 1500+ complaints) as fallback
- Fuzzy logic engine for priority scoring
- Keyword-based sentiment and urgency analysis
- Automatic department routing

---

## 🏗️ Project Architecture

The system follows a modular architecture with separate components for frontend, backend, AI/ML, and analytics.

**Main Components:**
- **Backend**: Flask REST API (Python)
- **Frontend**: HTML/CSS/JS web apps (Mobile Web + Admin Portal)
- **Mobile**: Full Flutter/Dart app with voice input and offline support
- **AI/ML**: Gemini + Scikit-learn + Fuzzy Logic
- **Database**: SQLite with schema and sample dataset

---

## 📁 Project Structure
civic-grievance-system/
├── backend/                    # Flask REST API
├── ml_engine/                  # AI & ML services (Gemini, model training)
├── soft_computing/             # Fuzzy logic priority engine
├── analytics_engine/           # Trend and report generation
├── database/                   # Schema, SQLite DB, complaints_1500.csv
├── mobile_web_app/             # Citizen web interface (index.html, track.html)
├── admin_portal/               # Admin dashboard
├── mobile appppp/              # Flutter mobile app (fully functional)
├── tests/                      # Unit tests
├── run_project.py              # Helper launcher script
├── fix_routing.py
├── migrate_upvotes.py
├── PROJECT_GUIDE.md
├── RUN_WEBAPP.md
├── FLUTTER_APP_GUIDE.md
└── FEATURES_GUIDE.md
text---

## 🛠️ Technologies Used

| Layer              | Technology                          |
|--------------------|-------------------------------------|
| Backend            | Python 3.8+, Flask, Flask-CORS, SQLite |
| AI/ML              | Google Gemini API, scikit-learn (TF-IDF + Naive Bayes), Fuzzy Logic |
| Web Frontend       | HTML5, CSS3 (Glassmorphism + Dark UI), JavaScript, Chart.js |
| Mobile             | Flutter (Dart), speech_to_text, image_picker, geolocator, sqflite |
| Others             | Web Speech API, Nominatim (OpenStreetMap), Chart.js |

---

## 🚀 Complete Local Setup & Run Guide

### Prerequisites
- Python 3.8+
- Flutter SDK (run `flutter doctor` and fix issues)
- Git
- A modern browser (Edge/Chrome recommended)

### Step 1: Clone the Repository
```bash
git clone https://github.com/Monalsree/civic-grievance-system.git
cd civic-grievance-system
Step 2: Backend Setup (Most Important)
Bashcd backend
pip install -r requirements.txt
python app.py

Backend runs on: http://127.0.0.1:5000 (and your local IP)

Step 3: Run Web Interfaces (Recommended Quick Start)
Terminal 2 – Citizen Mobile Web App
Bashcd mobile_web_app
python -m http.server 8000
→ Open: http://localhost:8000
Terminal 3 – Admin Portal
Bashcd admin_portal
python -m http.server 8001
→ Open: http://localhost:8001/dashboard.html
Step 4: Run Flutter Mobile App (Optional but Fully Featured)
Bashcd "mobile appppp"
flutter pub get
flutter run -d edge --no-web-resources-cdn
(You can also use Chrome: flutter run -d chrome)
One-Click Launcher (Experimental)
Bashpython run_project.py

📱 How to Use the Application
As a Citizen

Go to http://localhost:8000
Fill the complaint form (or use voice input in Flutter app)
Submit with optional photo and location
Track status using complaint ID on track.html or in the app

As an Administrator

Go to http://localhost:8001/dashboard.html
View all complaints
Update status, add notes, or assign departments
Check analytics widgets


🔧 Troubleshooting

Backend not starting: Run pip install -r requirements.txt in /backend
Port already in use: Kill the process using the port (5000, 8000, 8001)
Flutter issues: Run flutter clean && flutter pub get
API connection errors: Ensure backend is running first. Check constants.dart for base URL.
Voice input not working: Grant microphone permission in browser

For detailed instructions, refer to:

RUN_WEBAPP.md
FLUTTER_APP_GUIDE.md
PROJECT_GUIDE.md


📊 Dataset & Training
The system is trained on database/complaints_1500.csv covering common categories:

Electricity, Garbage, Roads, Sanitation, Water, etc.

You can retrain the ML model using ml_engine/train_model.py.

🔮 Future Enhancements (Roadmap)

Mobile app build for Android/iOS
Real-time notifications (WebSockets)
Advanced image analysis for evidence
Multi-language support
Integration with government APIs

📄 License
This project is open for learning and contribution.

Made with ❤️ for better civic governance
Author: Monalsree
Repository: github.com/Monalsree/civic-grievance-system
