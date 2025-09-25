class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? avatar;
  final String? contact;
  final String? createdAt;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.avatar,
    this.contact,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      contact: json['contact'] ?? "",
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'contact': contact,
      'createdAt': createdAt,
    };
  }

  /// Escapa vírgulas, aspas e quebras de linha para não quebrar o CSV
  String _sanitize(String? value) {
    if (value == null) return "";
    var text = value.replaceAll('"', '""');
    if (text.contains(',') || text.contains(';') || text.contains('"') || text.contains('\n')) {
      text = '"$text"';
    }
    return text;
  }

  List<String> toCsvRow() {
    return [
      _sanitize(id),
      _sanitize(name),
      _sanitize(email),
      avatar ?? "",   // ⚡ avatar vai cru, sem sanitize
      _sanitize(contact),
      _sanitize(createdAt),
    ];
  }
}
