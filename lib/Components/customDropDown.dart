import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';

import '../Models/usuario_model.dart';
import '../Services/Local_storage.Service.dart';
import '../repositories/usuario_repository.dart';

class CustomDropDown extends StatefulWidget {
  final ValueChanged<String>? onChanged;

  const CustomDropDown({Key? key, this.onChanged}) : super(key: key);

  @override
  State<CustomDropDown> createState() => _CustomDropDownState();
}

class _CustomDropDownState extends State<CustomDropDown> {
  var dropdownValue = '';
  var listaUsuarios = <UsuarioModel>[];
  var isLoading = true;
  var isError = false;

  final localStorage = LocalStorageService();
  final repository = UsuarioRepository();

  Color _getDynamicColor(String hexString, Color fallbackColor) {
    final cleaned = hexString.trim().replaceAll('#', '').toUpperCase();
    if (cleaned.isEmpty) return fallbackColor;

    final normalized = cleaned.length == 6 ? 'FF$cleaned' : 'FFFFBB00';
    final value = int.tryParse(normalized, radix: 16);

    return value != null ? Color(value) : fallbackColor;
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      setState(() {
        isLoading = true;
        isError = false;
      });

      final usuarioSalvo = await localStorage.get('usuario') ?? '';
      final usuariosApi = await repository.fetchUsuario();

      if (usuariosApi.isNotEmpty) {
        listaUsuarios = usuariosApi;

        bool usuarioAindaExiste =
            listaUsuarios.any((u) => u.login == usuarioSalvo);

        if (usuarioAindaExiste) {
          dropdownValue = usuarioSalvo.toString();
        } else {
          dropdownValue = listaUsuarios[0].login;
        }

        await localStorage.put('usuario', dropdownValue);
        widget.onChanged?.call(dropdownValue);
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      log('Erro ao buscar dados do dropdown: $e');
      if (!mounted) return;
      setState(() {
        listaUsuarios = [];
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (isError) return _buildError();
    if (listaUsuarios.isEmpty) return _buildEmpty();

    return _buildSuccess();
  }

  Widget _buildLoading() {
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.all(14.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
          ),
        ),
        hintText: 'Carregando usuários...',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildError() {
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.error_outline, color: Colors.red[700]),
        hintText: 'Erro ao carregar usuários!',
        hintStyle: TextStyle(color: Colors.red[800]),
        filled: true,
        fillColor: Colors.red[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade200, width: 1),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person_off_outlined, color: Colors.grey),
        hintText: 'Nenhum usuário encontrado.',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final primaryColor = _getDynamicColor(
        ConfigController.instance.primaryColorHex.value, Constants.primaryColor);

    return DropdownButtonFormField<String>(
      initialValue: dropdownValue,
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
      elevation: 4,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      items: listaUsuarios.map((model) {
        return DropdownMenuItem<String>(
          value: model.login,
          child: Text(model.login),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            dropdownValue = newValue;
          });
          localStorage.put('usuario', dropdownValue);
          widget.onChanged?.call(dropdownValue);
        }
      },
    );
  }
}
