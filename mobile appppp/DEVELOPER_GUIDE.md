# Flutter Mobile App - Comprehensive Developer Guide

## Overview

The Civic Grievance System Flutter Mobile App is a production-ready mobile application built to integrate with the Flask backend API. It provides both citizen and admin interfaces for managing civic complaints.

## Architecture

### Multi-Layer Architecture

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens, Widgets, UI Components)  │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│      Business Logic Layer           │
│   (Services, State Management)      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│      Data Access Layer              │
│     (API Service, Local Storage)    │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│      External Services              │
│    (Flask Backend, Shared Prefs)    │
└─────────────────────────────────────┘
```

## Components Breakdown

### 1. Configuration Layer (`lib/config/`)

#### constants.dart
- API endpoints and base URL
- Application constants
- Complaint categories
- Status and priority levels
- Local storage keys
- UI dimensions

#### app_theme.dart
- Color palette (primary, accent, status colors)
- Typography styles
- Theme configuration
- Gradient definitions

### 2. Models Layer (`lib/models/`)

#### user_model.dart
```dart
User {
  id: String
  username: String
  name: String
  email: String
  phone: String
  role: String ('citizen' | 'admin')
  department?: String
}
```

#### complaint_model.dart
```dart
Complaint {
  id: String
  name: String
  email: String
  phone: String
  category: String
  location: String
  description: String
  department: String
  priority: String ('low' | 'medium' | 'high')
  status: String ('submitted' | 'assigned' | 'in-progress' | 'resolved')
  urgencyScore: double
  frequencyScore: double
  impactScore: double
  fuzzyPriorityScore: double
  createdAt: DateTime
  updatedAt?: DateTime
  resolvedAt?: DateTime
  history: List<StatusHistory>
}

StatusHistory {
  id: String
  complaintId: String
  status: String
  notes?: String
  changedAt: DateTime
}
```

#### analytics_model.dart
```dart
AnalyticsSummary {
  total: int
  resolved: int
  pending: int
  highPriority: int
  resolutionRate: double
  byCategory: List<CategoryStats>
  byStatus: List<StatusStats>
  byPriority: List<PriorityStats>
  byDepartment: List<DepartmentStats>
  recent: List<AnalyticsComplaint>
}

Notification {
  id: String
  complaintId: String
  message: String
  type: String
  read: bool
  createdAt: DateTime
}
```

### 3. Services Layer (`lib/services/`)

#### api_service.dart
- HTTP client initialization with Dio
- Request/response interceptors
- Logging and error handling
- API endpoints implementation
- Error handling and API exceptions

**Key Features:**
- Automatic token attachment to headers
- Request/response logging in debug mode
- Graceful error handling with custom exceptions
- Base URL configuration

#### auth_service.dart
- User authentication logic
- Registration and login handling
- Token management
- User session management
- Role-based access control

#### complaint_service.dart
- Complaint submission
- Complaint retrieval and filtering
- Status updates
- Search functionality
- Complaint analytics helpers

#### storage_service.dart
- Local storage using SharedPreferences
- User data persistence
- Token management
- Phone number storage for tracking

### 4. Screens Layer (`lib/screens/`)

#### Authentication Screens
- **login_screen.dart**: User login interface
- **register_screen.dart**: User registration interface

#### Citizen Screens
- **citizen_home_screen.dart**: Main dashboard with quick actions
- **submit_complaint_screen.dart**: Form for submitting new complaints
- **my_complaints_screen.dart**: List and filter user's complaints
- **complaint_details_screen.dart**: Detailed view with status history

#### Admin Screens
- **admin_home_screen.dart**: Admin dashboard with analytics
- **admin_complaint_management_screen.dart**: Complaint management interface
- **admin_complaint_details_screen.dart**: Detailed view with update capability

### 5. Widgets Layer (`lib/widgets/`)

#### common_widgets.dart
- **CustomTextField**: Reusable input field with validation
- **CustomDropdownField**: Dropdown with label
- **CustomButton**: Styled button with loading state
- **CustomCard**: Card wrapper with tap handling
- **CustomBadge**: Badge component
- **CustomLoader**: Loading indicator with message
- **EmptyState**: Empty state placeholder
- **StatusChip**: Status indicator

### 6. Utilities Layer (`lib/utils/`)

#### format_utils.dart
- Date/time formatting functions
- Relative time display (e.g., "2 hours ago")
- Status and priority label conversion
- String truncation and capitalization

#### validators.dart
- Email validation
- Password validation
- Username validation
- Phone number validation
- Name and location validation
- Description validation
- Required field validation

## Data Flow

### Complaint Submission Flow

```
1. User fills form in SubmitComplaintScreen
2. Form validation (validators.dart)
3. ComplaintService.submitComplaint() called
4. ApiService.createComplaint() sends POST request
5. Backend processes with AI/ML classification
6. Response with complaintId and priority
7. Success message and UI update
8. User redirected to MyComplaintsScreen
```

### Status Update Flow (Admin)

```
1. Admin views complaint in AdminComplaintManagement
2. Clicks on complaint to view details
3. Updates status in AdminComplaintDetailsScreen
4. ComplaintService.updateStatus() called
5. ApiService.updateComplaintStatus() sends PUT request
6. Backend updates database and notifications
7. Response confirms update
8. UI refreshes with new status
9. Status history updated
```

### Analytics Flow

```
1. AdminDashboardScreen loads
2. AnalyticsService.getSummary() called
3. ApiService.getAnalyticsSummary() fetches data
4. Backend aggregates and returns statistics
5. AnalyticsSummary model populated
6. Widgets display with visualizations
7. Auto-refresh on user request
```

## Authentication Flow

### Login Process

```
1. User submits username and password
2. AuthService.login() validates input
3. ApiService sends POST to /auth/login
4. Server verifies credentials
5. Returns user object (id, name, role, email, phone)
6. AuthService stores user locally
7. App navigates to appropriate dashboard
   - Citizens → CitizenHomeScreen
   - Admins → AdminHomeScreen
```

### Registration Process

```
1. User fills registration form
2. Form validators check all fields
3. AuthService.register() called
4. ApiService sends POST to /auth/register
5. Server creates user account
6. Returns success response
7. User navigated to login screen
8. User logs in with new credentials
```

## State Management Strategy

### Current Implementation
- Local state management with `StatefulWidget`
- Future-based async data loading
- RefreshIndicator for pull-to-refresh

### Service Layer Pattern
- Services handle business logic
- Screens use services through Future/async-await
- Local storage for caching critical data

### Potential Enhancements
- Implement Provider for global state
- Use Riverpod for reactive state management
- Add local database with SQLite

## Error Handling

### API Errors
- Custom `ApiException` class
- DioException caught and converted
- Graceful error messages to users
- Retry functionality in key screens

### Validation Errors
- Real-time form validation
- Clear error messages
- Field-level error display

### Network Errors
- Connection failure detection
- Retry prompts
- Offline state handling (future feature)

## Security Considerations

### Current Implementation
- No hardcoded credentials
- API token in headers (when available)
- Data stored in SharedPreferences
- HTTPS ready (configure in constants)

### Recommendations
- Use secure storage (flutter_secure_storage)
- Implement certificate pinning
- Add JWT token refresh mechanism
- Validate server SSL certificates
- Sanitize user inputs

## Performance Optimization

### Current Optimizations
- Lazy loading in lists
- RefreshIndicator for efficient reloading
- Proper disposal of resources
- Minimal widget rebuilds

### Further Optimizations
- Implement list virtualization with ListView.builder
- Add caching layer
- Use const constructors where possible
- Implement pagination for long lists
- Add skeleton loaders during fetch

## Testing Strategy

### Unit Tests
```dart
// Test models, validators, utilities
test('Email validation', () {
  expect(Validators.validateEmail('test@test.com'), null);
  expect(Validators.validateEmail('invalid'), isNotNull);
});
```

### Integration Tests
```dart
// Test full user flows
testWidgets('Login and navigate', (tester) async {
  await tester.pumpWidget(MyApp());
  // Complete login flow test
});
```

### Mock API Responses
```dart
// Mock API service for testing
var mockComplaints = [
  Complaint(...),
  Complaint(...),
];
```

## Deployment Checklist

### Pre-Release
- [ ] Update version in pubspec.yaml
- [ ] Test on multiple devices/screen sizes
- [ ] Verify all API endpoints functional
- [ ] Test error scenarios
- [ ] Security audit of code
- [ ] Performance profiling

### Android Release
- [ ] Generate signing key
- [ ] Build APK/AAB
- [ ] Test installed app
- [ ] Update buildNumber in build.gradle
- [ ] Sign released APK

### iOS Release (macOS)
- [ ] Update build number
- [ ] Create production certificate
- [ ] Build IPA
- [ ] Create app ID and profile
- [ ] Archive and upload to TestFlight

### App Store/Play Store
- [ ] Create developer account
- [ ] Complete app listing
- [ ] Add screenshots and description
- [ ] Set pricing and distribution
- [ ] Submit for review

## Future Enhancements

### Feature Roadmap
1. **Push Notifications** - Real-time complaint updates
2. **File Upload** - Images and document attachments
3. **Voice Input** - Speech-to-text for complaints
4. **Offline Support** - Work without internet
5. **Multi-language** - Support multiple languages
6. **Advanced Charts** - More detailed analytics
7. **QR Codes** - Quick complaint tracking
8. **SMS Notifications** - Text message updates

### Technical Debt
- [ ] Migrate to Provider/Riverpod for state
- [ ] Add comprehensive unit tests
- [ ] Implement local database (SQLite)
- [ ] Add CI/CD pipeline
- [ ] Implement proper error boundary
- [ ] Add analytics and crash reporting

## Troubleshooting Guide

### Common Issues

**Issue**: API Connection Refused
- Verify backend running on localhost:5000
- Check firewall settings
- Update API URL if needed

**Issue**: Build Failures
- Run `flutter clean`
- Delete .gradle and Pods
- Reinstall dependencies

**Issue**: Login Not Working
- Verify credentials
- Check API endpoints
- Enable network debugging

## Performance Tips

### Development
- Use --release flag for performance testing
- Profile with DevTools
- Monitor memory usage
- Check frame rendering

### Production
- Enable optimization flags
- Minimize image assets
- Remove debug logging
- Use production API URL

---

## Quick Reference

### Key Patterns Used

1. **Service Pattern**: Abstraction of API/business logic
2. **Model Pattern**: Type-safe data structures
3. **Provider Pattern**: Dependency injection
4. **Future-based Async**: Non-blocking operations
5. **Validation Pattern**: Before/after data operations

### Important Files to Modify

- **API URL**: `lib/config/constants.dart` → `apiBaseUrl`
- **Theme Colors**: `lib/config/app_theme.dart`
- **Categories**: `lib/config/constants.dart`
- **Endpoints**: `lib/services/api_service.dart`

### CLI Commands Cheat Sheet

```bash
# Development
flutter run                  # Run app in debug
flutter run --release       # Run optimized
flutter run -v             # Verbose logging

# Build
flutter build apk           # Android APK
flutter build appbundle     # Android AAB
flutter build ios           # iOS (macOS only)
flutter build web           # Web/PWA

# Maintenance
flutter clean              # Clean build files
flutter pub get            # Get dependencies
flutter pub upgrade        # Upgrade packages
flutter analyze            # Static analysis
flutter doctor             # Check setup
```

---

For more information, refer to [Flutter Documentation](https://flutter.dev) and [Backend Integration Guide](../backend/README.md).
