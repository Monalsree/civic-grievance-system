# Civic Grievance System

A full-stack **AI-powered civic grievance management platform** that enables citizens to easily submit, track, and resolve complaints. Administrators can efficiently manage grievances with intelligent AI routing, analytics, and smart decision support.

The system combines **Google Gemini AI** for advanced complaint understanding and response suggestions, along with traditional ML models, fuzzy logic for priority scoring, and a clean, modern responsive interface.

---

## ✨ Key Features

### For Citizens
- Submit complaints using text, voice input, image upload, and automatic location capture
- Real-time tracking of complaint status
- Upvote important public grievances
- Receive notifications for status changes
- Offline support with sync (in Flutter mobile app)

### For Administrators
- Centralized dashboard to view and manage all complaints
- AI-powered categorization, urgency detection, and department routing
- Analytics dashboard with trends and response time reports
- Quick status updates and response management

### AI & Smart Features
- Google Gemini API for intelligent complaint analysis and suggestions
- TF-IDF + Naive Bayes ML model (trained on 1500+ complaints) as fallback
- Fuzzy logic engine for dynamic priority scoring
- Keyword-based sentiment and urgency analysis
- Automatic routing to relevant departments

---

## 🏗️ Project Architecture

The project uses a modular architecture separating frontend, backend, AI/ML, and analytics layers.

**Main Components:**
- **Backend**: Flask-based REST API (Python)
- **Frontend**: HTML/CSS/JS web applications (Citizen Mobile Web + Admin Portal)
- **Mobile App**: Complete Flutter/Dart application with voice and offline support
- **AI/ML Layer**: Google Gemini + Scikit-learn + Fuzzy Logic
- **Database**: SQLite with schema and sample dataset (`complaints_1500.csv`)

---

## 📁 Project Structure

```bash
civic-grievance-system/
├── backend/                    # Flask REST API
├── ml_engine/                  # AI/ML services (Gemini integration & model training)
├── soft_computing/             # Fuzzy logic priority scoring engine
├── analytics_engine/           # Analytics and report generation
├── database/                   # Database schema, SQLite DB, and complaints_1500.csv
├── mobile_web_app/             # Citizen-facing web interface (index.html, track.html)
├── admin_portal/               # Admin dashboard
├── mobile appppp/              # Full Flutter mobile application
├── tests/                      # Unit and integration tests
├── run_project.py              # Helper script to launch the project
├── fix_routing.py
├── migrate_upvotes.py
├── update_dio_errors.py
├── PROJECT_GUIDE.md
├── RUN_WEBAPP.md
├── FLUTTER_APP_GUIDE.md
└── FEATURES_GUIDE.md

```
## 🛠️ Technologies Used

| Layer              | Technology                                                                 |
|--------------------|----------------------------------------------------------------------------|
| Backend            | Python 3.8+, Flask, Flask-CORS, SQLite                                     |
| AI/ML              | Google Gemini API, scikit-learn (TF-IDF + Naive Bayes), Fuzzy Logic        |
| Web Frontend       | HTML5, CSS3 (Glassmorphism + Dark Theme), JavaScript, Chart.js             |
| Mobile             | Flutter (Dart), speech_to_text, image_picker, geolocator, sqflite          |
| Others             | Web Speech API, Nominatim (OpenStreetMap)                                  |

---

## 🚀 Local Setup & Run Guide

### Prerequisites

- Python 3.8 or higher
- Flutter SDK (run `flutter doctor` and resolve all issues)
- Git
- Modern web browser (Chrome or Edge recommended)

---

### 📊 Dataset
- The AI/ML models are trained on database/complaints_1500.csv, covering common civic issues such as:
- Electricity, Garbage, Roads, Sanitation, Water Supply, Drainage, Street Lights, etc.
---
### 🔮 Future Roadmap

- Official Android & iOS builds of the Flutter app
- Real-time notifications using WebSockets
- Advanced image analysis for complaint evidence
- Multi-language support (Tamil, Hindi, etc.)
- Integration with official government grievance portals

---

### Author:
- Monal sree P
### GitHub:
- Monalsree/civic-grievance-system
  
