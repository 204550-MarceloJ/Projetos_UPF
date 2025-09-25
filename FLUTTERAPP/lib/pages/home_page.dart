// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html; // necessário para download no web
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'form_user_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = UserService();
  late Future<List<UserModel>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _futureUsuarios = _service.carregarUsuarios();
  }

  void _reload() {
    setState(() {
      _futureUsuarios = _service.carregarUsuarios();
    });
  }

  Uint8List? _decodeBase64(String? dataUrl) {
    if (dataUrl == null || dataUrl.isEmpty) return null;
    try {
      final base64Str = dataUrl.split(",").last;
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmAndDeleteSingle(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir ${user.name ?? "este usuário"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmed == true && user.id != null) {
      final usuarios = await _service.carregarUsuarios();
      usuarios.removeWhere((u) => u.id == user.id);
      await _service.salvarUsuarios(usuarios);
      _reload();
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Apagar tudo"),
        content: const Text("Deseja realmente apagar todos os usuários?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Apagar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.salvarUsuarios([]);
      _reload();
    }
  }

  /// Importar CSV usando FilePicker
  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.single.bytes;
      if (fileBytes != null) {
        final csvStr = utf8.decode(fileBytes);
        final ok = await _service.importarUsuarios(csvStr);
        if (ok) {
          _reload();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Usuários importados com sucesso!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Erro ao importar usuários.")),
          );
        }
      }
    }
  }

  /// Exportar CSV e baixar no navegador
  Future<void> _exportCsv() async {
    final csvStr = await _service.exportarUsuarios();
    if (csvStr != null) {
      final blob = html.Blob([csvStr], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'usuarios.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📤 Arquivo exportado!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Erro ao exportar usuários.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuários"),
        actions: [
          IconButton(icon: const Icon(Icons.upload_file), tooltip: "Importar CSV", onPressed: _importCsv),
          IconButton(icon: const Icon(Icons.download), tooltip: "Exportar CSV", onPressed: _exportCsv),
          IconButton(icon: const Icon(Icons.delete_forever), tooltip: "Apagar todos", onPressed: _deleteAll),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }

          final usuarios = snapshot.data ?? [];
          if (usuarios.isEmpty) {
            return const Center(child: Text("Nenhum usuário encontrado."));
          }

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final user = usuarios[index];
              final photoBytes = _decodeBase64(user.avatar);

              return Slidable(
                key: ValueKey(user.id ?? index),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FormUserPage(user: user)),
                        );
                        if (result == true) _reload();
                      },
                      backgroundColor: Colors.blue,
                      icon: Icons.edit,
                      label: 'Editar',
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        await _confirmAndDeleteSingle(user);
                      },
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                      label: 'Excluir',
                    ),
                    SlidableAction(
                      onPressed: (context) {
                        if (user.name != null &&
                            user.name!.isNotEmpty &&
                            user.contact != null &&
                            user.contact!.isNotEmpty) {
                          final qrData = "MECARD:N:${user.name};TEL:${user.contact};;";
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("QR Code de Contato"),
                              content: SizedBox(
                                width: 200,
                                height: 200,
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 200,
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("❌ Nome ou contato ausente para gerar QR Code")),
                          );
                        }
                      },
                      backgroundColor: Colors.green,
                      icon: Icons.qr_code,
                      label: 'QR Contato',
                    ),
                  ],
                ),
                child: ListTile(
                  leading: photoBytes != null
                      ? CircleAvatar(backgroundImage: MemoryImage(photoBytes))
                      : CircleAvatar(
                          child: Text(
                            (user.name != null && user.name!.isNotEmpty)
                                ? user.name!.substring(0, 1).toUpperCase()
                                : '?',
                          ),
                        ),
                  title: Text(user.name ?? "Sem nome"),
                  subtitle: Text("${user.email ?? "Sem email"}\nContato: ${user.contact ?? "Sem contato"}"),
                  isThreeLine: true,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FormUserPage(user: user)),
                    );
                    if (result == true) _reload();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormUserPage()),
          );
          if (result == true) _reload();
        },
      ),
    );
  }
}
