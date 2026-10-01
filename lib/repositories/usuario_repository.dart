import 'package:dio/dio.dart';

import '../Controller/Config.Controller.dart';
import '../Models/usuario_model.dart';

class UsuarioRepository {
  Future<List<UsuarioModel>> fetchUsuario() async {
    final url = await ConfigController.instance.getUrlBase();

    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    Dio dio = Dio(options);
    try {
      final response = await dio.get('/v1/usuarios');
      final list = response.data as List;
      return list.map((e) => UsuarioModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<UsuarioModel> fetchLogin(String login, String senha) async {
    final url = await ConfigController.instance.getUrlBase();

    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    Dio dio = Dio(options);
    try {
      final response = await dio.post('/v1/login', data: {
        'login': login.trim(),
        'senha': senha,
      });

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        String userLogin = (data['login'] ?? '').toString().trim();
        int userCodigo = int.tryParse(data['codigo']?.toString() ?? '0') ?? 0;
        int funCodigo = int.tryParse(data['fun_codigo']?.toString() ?? '0') ?? 0;

        if (userLogin.isEmpty) {
          userLogin = login.trim();
        }

        // Se o backend omitiu o código no json de resposta do login, resolve via lista de usuários
        if (userCodigo == 0) {
          try {
            final usuarios = await fetchUsuario();
            final encontrado = usuarios.firstWhere(
              (u) => u.login.trim().toUpperCase() == userLogin.toUpperCase(),
              orElse: () => UsuarioModel(
                codigo: (userLogin.toUpperCase() == 'ADM' || userLogin.toUpperCase() == 'ADMIN') ? 1 : 0,
                login: userLogin,
              ),
            );
            userCodigo = encontrado.codigo;
            funCodigo = encontrado.funCodigo;
          } catch (_) {
            if (userLogin.toUpperCase() == 'ADM' || userLogin.toUpperCase() == 'ADMIN') {
              userCodigo = 1;
            }
          }
        }

        return UsuarioModel(
          codigo: userCodigo,
          login: userLogin,
          funCodigo: funCodigo,
        );
      } else {
        throw Exception('Usuario não autorizado');
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}
