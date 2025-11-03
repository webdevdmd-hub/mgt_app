class Lead {
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

  Lead({
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

  Lead copyWith({
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
    return Lead(
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
}
