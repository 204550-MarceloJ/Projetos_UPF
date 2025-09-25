import 'user_model.dart';

class UserModelCsv extends UserModel {
  UserModelCsv({
    super.id,
    super.name,
    super.email,
    super.avatar,
    super.contact,
    super.createdAt,
  });

  static UserModel fromCsvRow(List<dynamic> row) {
    return UserModel(
      id: row.isNotEmpty ? row[0]?.toString() : "",
      name: row.length > 1 ? row[1]?.toString() : "",
      email: row.length > 2 ? row[2]?.toString() : "",
      avatar: row.length > 3 ? row[3]?.toString() : "",
      contact: row.length > 4 ? row[4]?.toString() : "",
      createdAt: row.length > 5 ? row[5]?.toString() : "",
    );
  }
}
