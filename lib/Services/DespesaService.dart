import 'package:dio/dio.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/despesa_model.dart';

class DespesaService {
  Future<List<SubDespesa>> buscarSubDespesas({String busca = ''}) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    ));

    try {
      final response = await dio.get(
        '/v1/despesas/subdespesas',
        queryParameters: {
          if (busca.trim().isNotEmpty) 'busca': busca.trim(),
        },
      );
      final resposta = response.data;
      final data = resposta is Map ? resposta['data'] : resposta;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => SubDespesa.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(e.message ?? 'Falha ao consultar subdespesas.');
    }
  }

  Future<Map<String, dynamic>> lancar(DespesaLancamento despesa) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      headers: {'Content-Type': 'application/json'},
    ));

    try {
      final response = await dio.post('/v1/despesas', data: despesa.toJson());
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
