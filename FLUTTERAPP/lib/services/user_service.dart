import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/user_model_csv.dart';

class UserService {
  static const String _storageKey = 'usuarios_v1';
  static const int avatarMaxLength = 200000; // ~200 KB em base64

  Future<List<UserModel>> carregarUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      await prefs.setString(_storageKey, '[]');
      return [];
    }
  }

  Future<bool> salvarUsuarios(List<UserModel> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = usuarios.map((u) => u.toJson()).toList();
    return prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<String?> exportarUsuarios() async {
    final usuarios = await carregarUsuarios();
    if (usuarios.isEmpty) return null;

    final rows = <List<String>>[];
    rows.add(['id', 'name', 'email', 'avatar', 'contact', 'createdAt']);
    for (final u in usuarios) {
      rows.add(u.toCsvRow());
    }

    return const ListToCsvConverter(eol: '\n').convert(rows);
  }

  Future<bool> importarUsuarios(String csvStr) async {
    try {
      final normalized = csvStr.replaceAll('\r\n', '\n').trim();

      const converter = CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
        shouldParseNumbers: false,
      );
      final rows = converter.convert(normalized);

      if (rows.isEmpty) return false;

      final existentes = await carregarUsuarios();
      final existentesIds = existentes.map((e) => e.id).toSet();
      final imported = <UserModel>[];

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i].cast<dynamic>();
        if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) continue;

        final first = row.isNotEmpty ? row[0].toString().toLowerCase() : '';
        if (first == 'id') continue;

        final userFromCsv = UserModelCsv.fromCsvRow(row);

        var id = userFromCsv.id ?? '';
        if (id.isEmpty || existentesIds.contains(id)) {
          id = "${DateTime.now().millisecondsSinceEpoch}_${imported.length}";
        }

        // ⚡ Checagem de tamanho do avatar
        String? avatar = _cleanCsvValue(userFromCsv.avatar);
        if (avatar != null && avatar.length > avatarMaxLength) {
          print(" Avatar ignorado para o usuário '${userFromCsv.name}' "
              "pois ultrapassa o limite de ${avatarMaxLength ~/ 1000} KB.");
          avatar = null;
        }

        final user = UserModel(
          id: id,
          name: userFromCsv.name,
          email: userFromCsv.email,
          avatar: avatar,
          contact: userFromCsv.contact,
          createdAt: userFromCsv.createdAt,
        );

        imported.add(user);
        existentesIds.add(id);
      }

      if (imported.isEmpty) return false;

      final merged = [...existentes, ...imported];
      await salvarUsuarios(merged);
      return true;
    } catch (e) {
      return false;
    }
  }

  String? _cleanCsvValue(String? value) {
    if (value == null) return null;
    var v = value.trim();
    if (v.startsWith('"') && v.endsWith('"')) {
      v = v.substring(1, v.length - 1);
    }
    return v.isEmpty ? null : v;
  }
}