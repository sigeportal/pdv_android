import 'package:dio/dio.dart';

import '../Controller/Config.Controller.dart';
import '../Models/fluxo_caixa_model.dart';

class FluxoCaixaService {
  static String _formatarErro(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Tempo de conexao esgotado. Tente novamente.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Servidor indisponivel. Verifique sua conexao e URL configurada.';
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }

      if (error.response?.statusCode != null) {
        return 'Erro no servidor (HTTP ${error.response?.statusCode}).';
      }
    }

    return error.toString();
  }

  static Future<FluxoCaixaResumo> listar({
    required DateTime dataInicio,
    required DateTime dataFim,
    int pdv = 1,
  }) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: 50000),
        receiveTimeout: const Duration(milliseconds: 50000),
        headers: {'Content-Type': 'application/json'},
      ));

      final response = await dio.get(
        '/v1/fluxo-caixa',
        queryParameters: {
          'dataInicio': _todmY(dataInicio),
          'dataFim': _todmY(dataFim),
          'pdv': pdv,
        },
      );

      final root = response.data as Map<String, dynamic>;
      final data =
          (root['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final totais =
          (data['totais'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final itensJson = (data['itens'] ?? <dynamic>[]) as List<dynamic>;

      final itens = itensJson
          .map((e) => FluxoCaixaLancamento.fromJson(e as Map<String, dynamic>))
          .toList();

      return FluxoCaixaResumo(
        totalCredito: (totais['total_credito'] ?? 0).toDouble(),
        totalDebito: (totais['total_debito'] ?? 0).toDouble(),
        saldo: (totais['saldo'] ?? 0).toDouble(),
        itens: itens,
      );
    } on DioException catch (e) {
      throw Exception(_formatarErro(e));
    } catch (e) {
      throw Exception('Falha ao carregar fluxo de caixa: $e');
    }
  }

  static Future<void> lancar({
    required String tipo,
    required double valor,
    String descricao = '',
    int pdv = 1,
  }) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: 50000),
        receiveTimeout: const Duration(milliseconds: 50000),
        headers: {'Content-Type': 'application/json'},
      ));

      await dio.post('/v1/fluxo-caixa/lancamentos', data: {
        'tipo': tipo,
        'valor': valor,
        'descricao': descricao,
        'pdv': pdv,
      });
    } on DioException catch (e) {
      throw Exception(_formatarErro(e));
    } catch (e) {
      throw Exception('Falha ao lancar movimentacao: $e');
    }
  }

  static Future<CaixaStatus> status({int pdv = 1}) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      headers: {'Content-Type': 'application/json'},
    ));

    final response = await dio.get(
      '/v1/caixa/status',
      queryParameters: {'pdv': pdv},
    );
    final root = response.data as Map<String, dynamic>;
    return CaixaStatus.fromJson(root['data'] as Map<String, dynamic>);
  }

  static Future<void> abrir({int pdv = 1, int funcionario = 1}) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      headers: {'Content-Type': 'application/json'},
    ));
    await dio.post('/v1/caixa/abrir', data: {'pdv': pdv, 'fun': funcionario});
  }

  static Future<void> fechar({int pdv = 1, int funcionario = 1}) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      headers: {'Content-Type': 'application/json'},
    ));
    await dio.post('/v1/caixa/fechar', data: {'pdv': pdv, 'fun': funcionario});
  }

  static String _todmY(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}
