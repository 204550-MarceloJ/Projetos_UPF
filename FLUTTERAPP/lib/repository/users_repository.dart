import 'dart:convert';
import 'package:flutterapp/core/constants.dart';
import 'package:flutterapp/models/user_model.dart';
import 'package:http/http.dart' as http;

class UsersRepository {
  final urlBaseApi = "${baseURLMockApi}users";

  Future<List<UserModel>> getUsers() async {
    final response = await http.get(Uri.parse(urlBaseApi));

    if (response.statusCode == 200) {
      final List<dynamic> usersJson = jsonDecode(response.body);
      return usersJson.map((user) => UserModel.fromJson(user)).toList();
    } else {
      throw Exception("❌ Erro ao carregar usuários [${response.statusCode}]");
    }
  }

  Future<void> postNewUser(UserModel userModel) async {
    final json = jsonEncode(userModel.toJson());

    final response = await http.post(
      Uri.parse(urlBaseApi),
      body: json,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(" Erro ao inserir usuário [${response.statusCode}]");
    }
  }

  Future<void> updateUser(String id, UserModel userModel) async {
    final url = "$urlBaseApi/$id";

    final json = jsonEncode(userModel.toJson());

    final response = await http.put(
      Uri.parse(url),
      body: json,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception(" Erro ao atualizar usuário [${response.statusCode}]");
    }
  }

  Future<void> deleteUser(String id) async {
    final url = '$urlBaseApi/$id';
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(" Erro ao excluir usuário [${response.statusCode}]");
    }
  }
}