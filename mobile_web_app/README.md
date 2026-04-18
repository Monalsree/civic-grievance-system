# 🏛️ Civic Grievance System - Mobile Web App

A premium, mobile-first web application for citizens to submit and track civic grievances with voice input capabilities.

## ✨ Features

- **📱 Mobile-First Design**: Fully responsive interface optimized for all devices
- **🎤 Voice Input**: Browser-native speech recognition for quick complaint submission
- **📍 Geolocation**: Automatic location detection using GPS
- **📊 Real-Time Tracking**: Visual timeline to track complaint status
- **🎨 Premium UI**: Dark theme with vibrant gradients and glassmorphism effects
- **💾 Auto-Save**: Automatic draft saving to prevent data loss
- **📷 Evidence Upload**: Image upload support for complaint evidence
- **🔔 Toast Notifications**: Real-time feedback for user actions

## 🚀 Quick Start

### Prerequisites

- Modern web browser (Chrome, Edge, Firefox, Safari)
- Microphone access for voice input feature
- Location services enabled for GPS feature

### Installation

1. **Clone or download the project**
   ```bash
   cd civic-grievance-system/mobile_web_app
   ```

2. **Open in browser**
   - Simply open `index.html` in your web browser
   - Or use a local server:
   ```bash
   # Using Python
   python -m http.server 8000
   
   # Using Node.js
   npx http-server
   ```

3. **Access the application**
   - Navigate to `http://localhost:8000` (if using local server)
   - Or directly open `index.html` in your browser

## 📂 File Structure

```
mobile_web_app/
├── index.html          # Complaint submission page
├── track.html          # Complaint tracking page
├── style.css           # Premium design system & styles
├── script.js           # Main application logic
└── voice_input.js      # Voice recognition module
```

## 🎯 Usage Guide

### Submitting a Complaint

1. **Open** `index.html` in your browser
2. **Fill in** your personal details (name, email, phone)
3. **Select** complaint category (Roads, Water, Electricity, etc.)
4. **Enter location** or click "📍 GPS" to auto-detect
5. **Describe** your complaint:
   - Type manually, or
   - Click the 🎤 microphone button for voice input
6. **Upload** evidence photo (optional)
7. **Submit** and save your Complaint ID

### Voice Input

1. Click the **🎤 microphone button** in the description field
2. **Allow** microphone access when prompted
3. **Speak** your complaint clearly
4. The text will appear automatically in the description field
5. Click the microphone again to stop recording

### Tracking Complaints

1. **Open** `track.html` in your browser
2. **Enter** your Complaint ID or Phone Number
3. **Click** "Search Complaint"
4. **View** detailed status timeline and information
5. **Refresh** to get latest updates

## 🎨 Design Features

- **Dark Theme**: Easy on the eyes with vibrant accent colors
- **Glassmorphism**: Modern frosted glass card effects
- **Smooth Animations**: Micro-interactions for enhanced UX
- **Gradient Accents**: Purple, blue, and cyan color palette
- **Responsive Layout**: Adapts to mobile, tablet, and desktop

## 🔧 Configuration

### Backend Integration

Update the API endpoint in `script.js`:

```javascript
const API_BASE_URL = 'http://your-backend-url.com/api';
```

### Voice Recognition Language

Change the language in `voice_input.js`:

```javascript
this.recognition.lang = 'hi-IN'; // For Hindi
this.recognition.lang = 'en-US'; // For English
```

## 🌐 Browser Compatibility

| Feature | Chrome | Edge | Firefox | Safari |
|---------|--------|------|---------|--------|
| Core UI | ✅ | ✅ | ✅ | ✅ |
| Voice Input | ✅ | ✅ | ⚠️ Limited | ⚠️ Limited |
| Geolocation | ✅ | ✅ | ✅ | ✅ |
| File Upload | ✅ | ✅ | ✅ | ✅ |

**Note**: Voice input works best in Chrome and Edge browsers.

## 📱 Mobile Testing

### Using Browser DevTools

1. Open Chrome DevTools (F12)
2. Click "Toggle Device Toolbar" (Ctrl+Shift+M)
3. Select a mobile device (iPhone, Pixel, etc.)
4. Test all features

### On Real Device

1. Connect your mobile device to the same network
2. Find your computer's IP address
3. Access `http://[YOUR-IP]:8000` on mobile browser
4. Test voice input and geolocation

## 🔐 Privacy & Permissions

- **Microphone**: Required for voice input feature
- **Location**: Required for GPS auto-detection
- **Storage**: Uses localStorage for draft saving and demo tracking

## 🛠️ Customization

### Colors

Edit CSS variables in `style.css`:

```css
:root {
  --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --bg-dark: #0a0e27;
  /* ... more variables */
}
```

### Categories

Add/modify categories in `index.html`:

```html
<option value="traffic">🚦 Traffic Management</option>
```

## 📊 Demo Mode

The app currently runs in **demo mode** using localStorage:
- Complaints are saved locally in your browser
- No backend server required for testing
- Data persists until browser cache is cleared

To enable **production mode**:
1. Set up your backend API
2. Update `API_BASE_URL` in `script.js`
3. Uncomment API call sections in the code

## 🤝 Integration with Backend

The app expects the following API endpoints:

```
POST   /api/complaints          # Submit new complaint
GET    /api/complaints/search   # Search by ID or phone
GET    /api/complaints/:id      # Get complaint details
PUT    /api/complaints/:id      # Update complaint status
```

## 📝 License

This project is part of the Civic Grievance System for Smart India Hackathon.

## 🙋 Support

For issues or questions:
- Check browser console for errors
- Ensure microphone/location permissions are granted
- Use Chrome/Edge for best voice input experience

---

**Built with ❤️ for Smart India Hackathon**
