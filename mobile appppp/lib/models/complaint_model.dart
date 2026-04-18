class Complaint {
  final String? id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? priority;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? voiceUrl;
  final String? assignedDepartment;
  final String? assignedTo;
  final String userId;
  final int? upvotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  Complaint({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    this.status = 'Submitted',
    this.priority,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.voiceUrl,
    this.assignedDepartment,
    this.assignedTo,
    required this.userId,
    this.upvotes = 0,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? 'other').toString();
    final description = (json['description'] ?? '').toString();
    final fallbackTitle = description.isNotEmpty
        ? (description.length > 40
            ? '${description.substring(0, 40)}...'
            : description)
        : category;

    return Complaint(
      id: json['id'],
      title: (json['title'] ?? fallbackTitle).toString(),
      description: description,
      category: category,
      status: json['status'] ?? 'Submitted',
      priority: json['priority'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      imageUrl: json['image_url'],
      voiceUrl: json['voice_url'],
      assignedDepartment:
          (json['assigned_department'] ?? json['department'])?.toString(),
      assignedTo: json['assigned_to'],
      userId: (json['user_id'] ?? json['citizen_username'] ?? '').toString(),
      upvotes: json['upvotes'] ?? 0,
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolutionNotes: json['resolution_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'voice_url': voiceUrl,
      'assigned_department': assignedDepartment,
      'assigned_to': assignedTo,
      'user_id': userId,
      'upvotes': upvotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
    };
  }
}
