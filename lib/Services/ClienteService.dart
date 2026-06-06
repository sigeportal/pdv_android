import 'package:dio/dio.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/cliente_model.dart';

class ClienteService {
  /// Busca todos os clientes da API
  /// Retorna uma lista de Cliente
  static Future<List<Cliente>> obterClientes() async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: 50000),
        receiveTimeout: const Duration(milliseconds: 50000),
      );

      Dio dio = Dio(options);
      final response = await dio.get('/v1/clientes');

      if (response.statusCode == 200) {
        // Se a resposta for uma lista
        if (response.data is List) {
          return (response.data as List)
              .map((json) => Cliente.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        // Se a resposta for um objeto com uma chave de lista
        else if (response.data is Map<String, dynamic>) {
          final dynamic json = response.data;
          // Procura por uma chave comum que possa conter a lista
          final dynamic data = json['data'] ??
              json['clientes'] ??
              json['items'] ??
              json['result'] ??
              json;

          if (data is List) {
            return data
                .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
                .toList();
          } else if (data is Map<String, dynamic>) {
            return [Cliente.fromJson(data)];
          }
        }
        return [];
      } else {
        throw Exception(
          'Erro ao buscar clientes: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar clientes: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao buscar clientes: $e');
    }
  }

  /// Busca um cliente específico pelo código
  /// Retorna um Cliente ou null se não encontrado
  static Future<Cliente?> obterClientePorCodigo(int codigo) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: 50000),
        receiveTimeout: const Duration(milliseconds: 50000),
      );

      Dio dio = Dio(options);
      final response = await dio.get('/v1/clientes/$codigo');

      if (response.statusCode == 200) {
        return Cliente.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Erro ao buscar cliente: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Erro ao buscar cliente: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao buscar cliente: $e');
    }
  }

  /// Busca clientes por nome (filtro)
  /// Retorna uma lista de Cliente que correspondem ao filtro
  static Future<List<Cliente>> buscarClientesPorNome(String nome) async {
    try {
      final clientes = await obterClientes();
      return clientes
          .where((cliente) =>
              cliente.nome.toLowerCase().contains(nome.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar clientes por nome: $e');
    }
  }
}
