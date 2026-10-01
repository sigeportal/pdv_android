import 'dart:convert';

class UsuarioModel {
  final int codigo;
  final String login;
  final int funCodigo;

  UsuarioModel({
    required this.codigo,
    required this.login,
    this.funCodigo = 0,
  });

  bool get isAdmin {
    if (codigo == 1) return true;
    final l = login.trim().toUpperCase();
    return l == 'ADMIN' || l == 'ADM';
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'login': login,
      'fun_codigo': funCodigo,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      codigo: int.tryParse(map['codigo']?.toString() ?? '') ?? 0,
      login: (map['login'] ?? '').toString().trim(),
      funCodigo: int.tryParse(map['fun_codigo']?.toString() ?? '') ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UsuarioModel.fromJson(String source) =>
      UsuarioModel.fromMap(json.decode(source));
}
