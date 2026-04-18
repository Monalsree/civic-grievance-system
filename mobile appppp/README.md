# Civic Grievance System - Flutter Mobile App

A comprehensive Flutter mobile application for the Civic Grievance System with citizen and admin interfaces, built to integrate seamlessly with the Flask backend API.

## Features

### Citizen Features
- **User Authentication**: Secure login and registration
- **Submit Complaints**: Easy-to-use form with categories, location, and description
- **Track Complaints**: Real-time status tracking with history
- **View History**: Complete timeline of complaint status changes
- **Dashboard**: Quick access to key features and categories

### Admin Features
- **Analytics Dashboard**: Comprehensive analytics with:
  - Total complaints, Resolved, Pending, High Priority counts
  - Resolution rate visualization
  - Charts by status, category, and priority
  - Recent complaints feed
- **Complaint Management**: Advanced filtering and search
  - Filter by status and priority
  - Search by complaint ID or phone number
  - View and manage all complaints
- **Status Updates**: Update complaint status with notes
- **Real-time Updates**: Auto-refresh functionality

## Project Structure

```
lib/
├── config/
│   ├── constants.dart       # App constants and categories
│   └── app_theme.dart       # Theme configuration
├── models/
│   ├── user_model.dart      # User model
│   ├── complaint_model.dart # Complaint and history models
│   ├── analytics_model.dart # Analytics models
│   └── index.dart           # Model exports
├── services/
│   ├── api_service.dart     # API client with Dio
│   ├── auth_service.dart    # Authentication service
│   ├── complaint_service.dart # Complaint operations
│   └── index.dart           # Service exports
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── citizen/
│   │   ├── citizen_home_screen.dart
│   │   ├── submit_complaint_screen.dart
│   │   └── my_complaints_screen.dart
│   └── admin/
│       ├── admin_home_screen.dart
│       └── admin_complaint_management_screen.dart
├── widgets/
│   └── common_widgets.dart  # Reusable UI components
├── utils/
│   ├── format_utils.dart    # Formatting utilities
│   └── validators.dart      # Form validators
└── main.dart                # App entry point
```

## Installation & Setup

### Prerequisites
- Flutter SDK (3.0+)
- Android Studio / Xcode
- API Backend running on localhost:5000

### Steps

1. **Clone the repository**
```bash
cd civic-grievance-system/mobile\ appppp
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API Base URL**
Edit `lib/config/constants.dart` and update the API base URL if needed:
```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

4. **Run the app**
```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run -d iPhone

# For Web
flutter run -d chrome
```

## API Integration

The app connects to the Flask backend with the following key endpoints:

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - User login

### Complaints (Citizen)
- `POST /complaints` - Submit new complaint
- `GET /complaints/mine` - Get user's complaints
- `GET /complaints/<id>` - Get complaint details

### Complaints (Admin)
- `GET /complaints` - Get all complaints
- `PUT /complaints/<id>/status` - Update complaint status
- `GET /complaints/search` - Search complaints

### Analytics
- `GET /analytics/summary` - Get analytics summary
- `GET /notifications` - Get notifications

## Demo Accounts

| Role | Username | Password |
|------|----------|----------|
| Citizen | user1 | pass123 |
| Admin | admin | admin123 |

## Key Technologies

- **Flutter**: Cross-platform mobile framework
- **Dio**: HTTP client for API calls
- **Provider**: State management
- **Shared Preferences**: Local data storage
- **FL Chart**: Data visualization
- **Intl**: Localization and formatting
- **Image Picker**: Image selection
- **Google Maps**: Location services (optional)

## Building for Production

### Android
```bash
flutter build apk --release
# or for split ABIs
flutter build apk --split-per-abi --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Features Implementation Status

✅ User Authentication (Login/Register)
✅ Complaint Submission
✅ Complaint Tracking & Status History
✅ Citizen Dashboard
✅ Admin Analytics Dashboard
✅ Admin Complaint Management
✅ Real-time Filtering & Search
✅ Status Updates with Notes
✅ Local Storage & Caching
✅ Error Handling & Validation
✅ Responsive UI Design

## Future Enhancements

- [ ] Push Notifications
- [ ] File Upload (Images, Documents)
- [ ] Voice Input for Complaints
- [ ] Offline Support
- [ ] Multi-language Support
- [ ] Advanced Analytics Charts
- [ ] Complaint Reassignment
- [ ] SMS Notifications
- [ ] QR Code Scanning

## Troubleshooting

### Port Already in Use
If port 5000 is already in use, update the API base URL in constants.dart

### Connection Refused
Ensure the Flask backend is running: `python3 run_project.py`

### Dependencies Issues
```bash
flutter clean
flutter pub get
```

## Support & Contribution

For issues or contributions, please refer to the main project documentation.

## License

This project is part of the Civic Grievance System initiative.
