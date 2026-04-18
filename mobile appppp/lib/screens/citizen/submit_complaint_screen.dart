import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/voice_input_button.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  static const String _draftKey = 'citizen_complaint_draft_v2';
  static const String _offlineQueueKey = 'citizen_offline_queue_v2';
  static const int _maxEvidenceBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _apiService = ApiService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  late final stt.SpeechToText _speech;

  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final Map<String, String> _categoryLabels = {
    'roads': 'Roads and Infrastructure',
    'water': 'Water Supply',
    'electricity': 'Electricity',
    'sanitation': 'Sanitation and Cleanliness',
    'garbage': 'Garbage and Waste',
    'drainage': 'Drainage and Sewage',
    'streetlights': 'Street Lights',
    'parks': 'Parks and Gardens',
    'noise': 'Noise Pollution',
    'other': 'Other',
  };

  final Map<String, String> _departmentMap = {
    'roads': 'Roads and Infrastructure Department',
    'water': 'Water Supply Department',
    'electricity': 'Electricity Board',
    'sanitation': 'Sanitation Department',
    'garbage': 'Waste Management Department',
    'drainage': 'Drainage and Sewage Department',
    'streetlights': 'Municipal Electrical Department',
    'parks': 'Parks and Recreation Department',
    'noise': 'Environmental Department',
    'other': 'General Administration',
  };

  String _selectedCategory = 'roads';
  bool _isSubmitting = false;
  bool _isListening = false;
  bool _isOnline = true;
  bool _isSyncingQueue = false;

  XFile? _selectedEvidence;
  Uint8List? _evidencePreview;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _prefs = await SharedPreferences.getInstance();
    _prefillUserDetails();
    _attachDraftListeners();
    await _restoreDraft();
    await _initializeConnectivity();
    await _syncOfflineQueue(showFeedback: false);
    await _fetchCurrentLocation(showFeedback: false);
  }

  void _prefillUserDetails() {
    final user = _authService.currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
  }

  void _attachDraftListeners() {
    _nameController.addListener(_saveDraft);
    _emailController.addListener(_saveDraft);
    _phoneController.addListener(_saveDraft);
    _locationController.addListener(_saveDraft);
    _descriptionController.addListener(_saveDraft);
  }

  Future<void> _initializeConnectivity() async {
    final connectivity = Connectivity();
    final current = await connectivity.checkConnectivity();
    _updateOnlineStatus(current);

    _connectivitySub = connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> state) {
      final wasOffline = !_isOnline;
      _updateOnlineStatus(state);

      if (wasOffline && _isOnline) {
        _showToast(
            'Back online. Syncing offline complaints...', ToastType.success);
        _syncOfflineQueue();
      }
    });
  }

  void _updateOnlineStatus(List<ConnectivityResult> state) {
    final online = state.isNotEmpty && !state.contains(ConnectivityResult.none);
    if (!mounted) return;
    setState(() {
      _isOnline = online;
    });
  }

  bool _looksLikeCoordinates(String value) {
    final text = value.trim();
    return RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(text);
  }

  String? _formatPlacemark(Placemark place) {
    final parts = <String>[];

    void add(String? value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return;
      if (parts.contains(text)) return;
      parts.add(text);
    }

    add(place.name);
    add(place.street);
    add(place.subLocality);
    add(place.locality);
    add(place.subAdministrativeArea);
    add(place.administrativeArea);
    add(place.country);

    if (parts.isEmpty) return null;
    return parts.take(4).join(', ');
  }

  Future<String?> _resolvePlaceName(double latitude, double longitude) async {
    try {
      final places = await placemarkFromCoordinates(latitude, longitude);
      if (places.isNotEmpty) {
        final readable = _formatPlacemark(places.first);
        if (readable != null && readable.isNotEmpty) {
          return readable;
        }
      }
    } catch (_) {
      // Ignore and return null.
    }

    return null;
  }

  Future<void> _fetchCurrentLocation({bool showFeedback = true}) async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (showFeedback) {
          _showToast('Location services are disabled.', ToastType.error);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFeedback) {
          _showToast('Location permission denied.', ToastType.error);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final placeName =
          await _resolvePlaceName(position.latitude, position.longitude);
      if (placeName != null && placeName.trim().isNotEmpty) {
        _locationController.text = placeName;
      } else {
        final existing = _locationController.text.trim();
        _locationController.text =
            existing.isNotEmpty && !_looksLikeCoordinates(existing)
                ? existing
                : 'Current location detected';
      }

      _saveDraft();

      if (showFeedback) {
        if (placeName != null && placeName.trim().isNotEmpty) {
          _showToast('Location captured: $placeName', ToastType.success);
        } else {
          _showToast(
            'Location detected, but place name was unavailable. Please edit if needed.',
            ToastType.info,
          );
        }
      }
    } catch (_) {
      if (showFeedback) {
        _showToast('Could not fetch your location right now.', ToastType.error);
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final isAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (!mounted) return;
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
        });
        _showToast('Voice input failed. Try again.', ToastType.error);
      },
    );

    if (!isAvailable) {
      _showToast(
          'Voice input not available on this device/browser.', ToastType.error);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!result.finalResult) return;

        final spokenText = result.recognizedWords.trim();
        if (spokenText.isEmpty) return;

        final existing = _descriptionController.text.trim();
        _descriptionController.text =
            existing.isEmpty ? spokenText : '$existing $spokenText';
        _saveDraft();
      },
    );
  }

  Future<void> _pickEvidence() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final lowercaseName = file.name.toLowerCase();
    final isImage = lowercaseName.endsWith('.jpg') ||
        lowercaseName.endsWith('.jpeg') ||
        lowercaseName.endsWith('.png') ||
        lowercaseName.endsWith('.webp');

    if (!isImage) {
      _showToast('Please select an image file only.', ToastType.error);
      return;
    }

    final size = await file.length();
    if (size > _maxEvidenceBytes) {
      _showToast('Evidence image must be less than 5 MB.', ToastType.error);
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedEvidence = file;
      _evidencePreview = bytes;
    });
  }

  void _removeEvidence() {
    setState(() {
      _selectedEvidence = null;
      _evidencePreview = null;
    });
  }

  Future<void> _saveDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final draft = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'category': _selectedCategory,
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
    };

    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  Future<void> _restoreDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final draft = Map<String, dynamic>.from(jsonDecode(raw) as Map);

      if ((draft['name'] ?? '').toString().trim().isNotEmpty) {
        _nameController.text = draft['name'].toString();
      }
      if ((draft['email'] ?? '').toString().trim().isNotEmpty) {
        _emailController.text = draft['email'].toString();
      }
      if ((draft['phone'] ?? '').toString().trim().isNotEmpty) {
        _phoneController.text = draft['phone'].toString();
      }
      if ((draft['location'] ?? '').toString().trim().isNotEmpty) {
        _locationController.text = draft['location'].toString();
      }
      if ((draft['description'] ?? '').toString().trim().isNotEmpty) {
        _descriptionController.text = draft['description'].toString();
      }

      final draftCategory = (draft['category'] ?? '').toString();
      if (_categoryLabels.containsKey(draftCategory)) {
        _selectedCategory = draftCategory;
      }

      if (draft['latitude'] is num) {
        _latitude = (draft['latitude'] as num).toDouble();
      }
      if (draft['longitude'] is num) {
        _longitude = (draft['longitude'] as num).toDouble();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Ignore invalid draft data and proceed with clean form.
    }
  }

  Future<void> _clearDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_draftKey);
  }

  Future<List<Map<String, dynamic>>> _readOfflineQueue() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final raw = prefs.getString(_offlineQueueKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeOfflineQueue(List<Map<String, dynamic>> queue) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_offlineQueueKey, jsonEncode(queue));
  }

  Future<void> _enqueueOfflineComplaint(Map<String, dynamic> payload) async {
    final queue = await _readOfflineQueue();
    queue.add({
      ...payload,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await _writeOfflineQueue(queue);
  }

  Future<void> _syncOfflineQueue({bool showFeedback = true}) async {
    if (_isSyncingQueue || !_isOnline) return;

    final queue = await _readOfflineQueue();
    if (queue.isEmpty) return;

    _isSyncingQueue = true;
    int successCount = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        await _apiService.submitCitizenComplaint(
          name: (item['name'] ?? '').toString(),
          email: (item['email'] ?? '').toString(),
          phone: (item['phone'] ?? '').toString(),
          category: (item['category'] ?? 'other').toString(),
          location: (item['location'] ?? '').toString(),
          description: (item['description'] ?? '').toString(),
          username: (item['username'] ?? '').toString(),
          latitude: item['latitude'] is num
              ? (item['latitude'] as num).toDouble()
              : null,
          longitude: item['longitude'] is num
              ? (item['longitude'] as num).toDouble()
              : null,
        );
        successCount++;
      } catch (_) {
        remaining.add(item);
      }
    }

    await _writeOfflineQueue(remaining);
    _isSyncingQueue = false;

    if (showFeedback && successCount > 0) {
      _showToast(
        'Synced $successCount offline complaint(s) successfully.',
        ToastType.success,
      );
    }

    if (showFeedback && remaining.isNotEmpty) {
      _showToast(
        '${remaining.length} complaint(s) still pending sync.',
        ToastType.info,
      );
    }
  }

  bool _looksLikeNetworkError(String message) {
    final m = message.toLowerCase();
    return m.contains('network') ||
        m.contains('connection') ||
        m.contains('socket') ||
        m.contains('timeout') ||
        m.contains('failed host lookup');
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'category': _selectedCategory,
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'username': _authService.currentUser?.username ?? 'citizen',
      'latitude': _latitude,
      'longitude': _longitude,
    };

    if (!_isOnline) {
      await _enqueueOfflineComplaint(payload);
      await _clearDraft();
      _clearComplaintOnlyFields();
      _showToast(
        'You are offline. Complaint saved and will sync automatically.',
        ToastType.info,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.submitCitizenComplaint(
        name: payload['name'].toString(),
        email: payload['email'].toString(),
        phone: payload['phone'].toString(),
        category: payload['category'].toString(),
        location: payload['location'].toString(),
        description: payload['description'].toString(),
        username: payload['username'].toString(),
        latitude: _latitude,
        longitude: _longitude,
        evidence: _selectedEvidence,
      );

      await _clearDraft();

      final complaintId = (response['complaint_id'] ?? '').toString();
      final priority =
          (response['priority'] ?? 'medium').toString().toUpperCase();
      final department = (response['department'] ??
              _departmentMap[_selectedCategory] ??
              'General Administration')
          .toString();

      _clearComplaintOnlyFields();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Complaint Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complaint ID: $complaintId'),
                const SizedBox(height: 8),
                Text('Priority: $priority'),
                const SizedBox(height: 8),
                Text('Department: $department'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Track Now'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (complaintId.isNotEmpty) {
        context.go('/my-complaints?q=${Uri.encodeComponent(complaintId)}');
      } else {
        context.go('/my-complaints');
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '').trim();

      if (_looksLikeNetworkError(message)) {
        await _enqueueOfflineComplaint(payload);
        await _clearDraft();
        _clearComplaintOnlyFields();
        _showToast(
          'Network error. Complaint saved offline and will sync automatically.',
          ToastType.info,
        );
      } else {
        _showToast(message.isEmpty ? 'Failed to submit complaint.' : message,
            ToastType.error);
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearComplaintOnlyFields() {
    _selectedCategory = 'roads';
    _locationController.clear();
    _descriptionController.clear();
    _selectedEvidence = null;
    _evidencePreview = null;
    _latitude = null;
    _longitude = null;

    if (mounted) {
      setState(() {});
    }
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;

    final color = switch (type) {
      ToastType.success => const Color(0xFF16A34A),
      ToastType.error => const Color(0xFFDC2626),
      ToastType.info => const Color(0xFF2563EB),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
        ),
      );
  }

  String get _suggestedDepartment {
    return _departmentMap[_selectedCategory] ?? 'General Administration';
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _speech.stop();

    _nameController
      ..removeListener(_saveDraft)
      ..dispose();
    _emailController
      ..removeListener(_saveDraft)
      ..dispose();
    _phoneController
      ..removeListener(_saveDraft)
      ..dispose();
    _locationController
      ..removeListener(_saveDraft)
      ..dispose();
    _descriptionController
      ..removeListener(_saveDraft)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/citizen-home'),
        ),
        title: const Text(
          'Submit Complaint',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isOnline)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'You are offline. New complaints will be queued and auto-synced when online.',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Full Name'),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.black),
                            decoration: _inputDecoration(
                              'Enter your full name',
                              suffixIcon: VoiceInputButton(
                                controller: _nameController,
                                idleColor: Color(0xFF4B5563),
                                onTextUpdated: _saveDraft,
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Email'),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.black),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              'Enter your email',
                              suffixIcon: VoiceInputButton(
                                controller: _emailController,
                                idleColor: Color(0xFF4B5563),
                                onTextUpdated: _saveDraft,
                              ),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'Email is required';
                              if (!text.contains('@') || !text.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Phone'),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.black),
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              'Enter phone number',
                              suffixIcon: VoiceInputButton(
                                controller: _phoneController,
                                idleColor: Color(0xFF4B5563),
                                onTextUpdated: _saveDraft,
                              ),
                            ),
                            validator: (value) {
                              final text = (value ?? '')
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              if (text.isEmpty)
                                return 'Phone number is required';
                              if (text.length < 10) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Category'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              iconEnabledColor: Colors.black,
                              dropdownColor: Colors.white,
                              decoration: _inputDecoration('Select category'),
                              style: const TextStyle(color: Colors.black),
                              items: _categoryLabels.entries
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedCategory = value;
                                });
                                _saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFF6366F1)),
                            ),
                            child: Text(
                              'Auto-assigned department: $_suggestedDepartment',
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Location'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _locationController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: _inputDecoration(
                                    'Enter location or tap Auto GPS',
                                    suffixIcon: VoiceInputButton(
                                      controller: _locationController,
                                      idleColor: Color(0xFF4B5563),
                                      onTextUpdated: _saveDraft,
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Location is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _fetchCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 18),
                                  label: const Text('Auto GPS'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Description'),
                          TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.black),
                            minLines: 4,
                            maxLines: 6,
                            decoration: _inputDecoration(
                                    'Describe your complaint in detail')
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF4B5563),
                                ),
                                onPressed: _toggleVoiceInput,
                              ),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) {
                                return 'Description is required';
                              }
                              if (text.length < 10) {
                                return 'Please provide more detail';
                              }
                              return null;
                            },
                          ),
                          if (_isListening)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Listening for voice input...',
                                style: TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          _buildLabel('Evidence Image (optional)'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _pickEvidence,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Choose Image'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF4B5563),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedEvidence == null
                                            ? 'No image selected'
                                            : _selectedEvidence!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (_selectedEvidence != null)
                                      IconButton(
                                        onPressed: _removeEvidence,
                                        icon: const Icon(
                                          Icons.close,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_evidencePreview != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _evidencePreview!,
                                        height: 170,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _submitComplaint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Submit Complaint',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTipsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Tips',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '- Add precise location for faster resolution',
            style: TextStyle(color: Color(0xFFD1D5DB)),
          ),
          Text(
            '- Attach a clear image when available',
            style: TextStyle(color: Color(0xFFD1D5DB)),
          ),
          Text(
            '- Save your complaint ID to track updates quickly',
            style: TextStyle(color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.3),
      ),
    );
  }
}

enum ToastType { success, error, info }
