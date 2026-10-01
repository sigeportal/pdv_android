import 'package:flutter/cupertino.dart';

import '../Models/usuario_model.dart';
import '../repositories/usuario_repository.dart';

class UsuarioController extends ChangeNotifier {
  final repository = UsuarioRepository();
  UsuarioModel? _usuarioLogado;

  UsuarioModel get usuarioLogado =>
      _usuarioLogado ?? UsuarioModel(codigo: 0, login: '');

  set usuarioLogado(UsuarioModel value) {
    _usuarioLogado = value;
    notifyListeners();
  }

  bool get isAdmin => _usuarioLogado?.isAdmin ?? false;

  Future<bool> logar(String login, String senha) async {
    try {
      final user = await repository.fetchLogin(login, senha);
      usuarioLogado = user;
      return true;
    } catch (e) {
      throw Exception(e);
    }
  }
}
