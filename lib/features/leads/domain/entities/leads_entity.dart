class LeadEntity {
  final String id;
  final String status;
  final String? source;
  final String? assignedTo;
  final List<String> tags;
  final String name;
  final String? position;
  final String? email;
  final String? website;
  final String? phone;
  final String? leadValue;
  final String? company;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zip;
  final String? defaultLanguage;
  final String? description;
  final bool isPublic;
  final bool contactedToday;
  final DateTime createdAt;

  LeadEntity({
    required this.id,
    required this.status,
    this.source,
    this.assignedTo,
    this.tags = const [],
    required this.name,
    this.position,
    this.email,
    this.website,
    this.phone,
    this.leadValue,
    this.company,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zip,
    this.defaultLanguage,
    this.description,
    this.isPublic = false,
    this.contactedToday = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  LeadEntity copyWith({
    String? id,
    String? status,
    String? source,
    String? assignedTo,
    List<String>? tags,
    String? name,
    String? position,
    String? email,
    String? website,
    String? phone,
    String? leadValue,
    String? company,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zip,
    String? defaultLanguage,
    String? description,
    bool? isPublic,
    bool? contactedToday,
    DateTime? createdAt,
  }) {
    return LeadEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      source: source ?? this.source,
      assignedTo: assignedTo ?? this.assignedTo,
      tags: tags ?? this.tags,
      name: name ?? this.name,
      position: position ?? this.position,
      email: email ?? this.email,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      leadValue: leadValue ?? this.leadValue,
      company: company ?? this.company,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zip: zip ?? this.zip,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      contactedToday: contactedToday ?? this.contactedToday,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // --- Added JSON (de)serialization ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'source': source,
      'assignedTo': assignedTo,
      'tags': tags,
      'name': name,
      'position': position,
      'email': email,
      'website': website,
      'phone': phone,
      'leadValue': leadValue,
      'company': company,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip': zip,
      'defaultLanguage': defaultLanguage,
      'description': description,
      'isPublic': isPublic,
      'contactedToday': contactedToday,
      // Keep DateTime as ISO string at entity layer;
      // Firestore conversion to Timestamp should be done in the repository.
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LeadEntity.fromJson(Map<String, dynamic> json) {
    return LeadEntity(
      id: json['id'] as String,
      status: json['status'] as String,
      source: json['source'] as String?,
      assignedTo: json['assignedTo'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      name: json['name'] as String,
      position: json['position'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      leadValue: json['leadValue'] as String?,
      company: json['company'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zip: json['zip'] as String?,
      defaultLanguage: json['defaultLanguage'] as String?,
      description: json['description'] as String?,
      isPublic: (json['isPublic'] as bool?) ?? false,
      contactedToday: (json['contactedToday'] as bool?) ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

// Top-level helper to avoid importing Firestore into domain layer
DateTime _parseDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  // If a Firestore Timestamp is passed accidentally, try to access toDate via dynamic
  try {
    final toDate = (v as dynamic)?.toDate();
    if (toDate is DateTime) return toDate;
  } catch (_) {}
  return DateTime.now();
}
