import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/image_utils.dart'; // import utilitário novo

class FormUserPage extends StatefulWidget {
  final UserModel? user;

  const FormUserPage({super.key, this.user});

  @override
  State<FormUserPage> createState() => _FormUserPageState();
}

class _FormUserPageState extends State<FormUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = UserService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;

  String? _avatarBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? "");
    _emailController = TextEditingController(text: widget.user?.email ?? "");
    _contactController = TextEditingController(text: widget.user?.contact ?? "");
    _avatarBase64 = widget.user?.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final resizedBase64 = await resizeAndConvertToBase64(bytes); // usa compressão
        setState(() {
          _avatarBase64 = resizedBase64;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final usuarios = await _service.carregarUsuarios();

    if (widget.user == null) {
      usuarios.add(UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        avatar: _avatarBase64,
        createdAt: DateTime.now().toIso8601String(),
      ));
    } else {
      final index = usuarios.indexWhere((u) => u.id == widget.user!.id);
      if (index != -1) {
        usuarios[index] = UserModel(
          id: widget.user!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          contact: _contactController.text.trim(),
          avatar: _avatarBase64 ?? widget.user!.avatar,
          createdAt: widget.user!.createdAt,
        );
      }
    }

    final ok = await _service.salvarUsuarios(usuarios);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBytes = _decodeBase64(_avatarBase64);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? "Novo Usuário" : "Editar Usuário"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                  child: avatarBytes == null ? const Icon(Icons.add_a_photo, size: 30) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nome"),
                validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: "Contato"),
                validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _saveUser,
                child: Text(widget.user == null ? "Cadastrar" : "Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
