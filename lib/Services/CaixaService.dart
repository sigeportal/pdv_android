import 'package:dio/dio.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';

class CaixaService {
  Future<Map<String, dynamic>> consultarStatus({required int pdv}) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      headers: {'Content-Type': 'application/json'},
    ));

    try {
      final response = await dio.get('/v1/caixa/status', queryParameters: {
        'pdv': pdv,
      });

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(e.message ?? 'Falha de comunicacao com o servidor.');
    }
  }

  Future<Map<String, dynamic>> abrirCaixa({
    required int pdv,
    required int fun,
  }) {
    return _post('/v1/caixa/abrir', pdv: pdv, fun: fun);
  }

  Future<Map<String, dynamic>> fecharCaixa({
    required int pdv,
    required int fun,
  }) {
    return _post('/v1/caixa/fechar', pdv: pdv, fun: fun);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required int pdv,
    required int fun,
  }) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      headers: {'Content-Type': 'application/json'},
    ));

    try {
      final response = await dio.post(path, data: {
        'pdv': pdv,
        'fun': fun,
      });

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(e.message ?? 'Falha de comunicacao com o servidor.');
    }
  }
}
