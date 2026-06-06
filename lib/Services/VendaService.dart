import 'package:dio/dio.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';

class VendaService {
  late Dio dio;

  // Inserir venda
  Future<Map<String, dynamic>> inserirVenda(
      Map<String, dynamic> vendaData) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );
      dio = Dio(options);

      final response = await dio.post(
        '/v1/vendas',
        data: vendaData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Erro ao inserir venda: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na requisição: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  // Buscar venda por ID
  Future<Map<String, dynamic>> buscarVenda(int vendaId) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );
      dio = Dio(options);

      final response = await dio.get(
        '/v1/vendas/$vendaId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Erro ao buscar venda: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na requisição: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  // Listar vendas
  Future<List<Map<String, dynamic>>> listarVendas() async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );
      dio = Dio(options);

      final response = await dio.get(
        '/v1/vendas',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> vendas = [];
        for (var venda in response.data as List) {
          vendas.add(venda as Map<String, dynamic>);
        }
        return vendas;
      } else {
        throw Exception('Erro ao listar vendas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na requisição: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  // Atualizar venda
  Future<Map<String, dynamic>> atualizarVenda(
    int vendaId,
    Map<String, dynamic> vendaData,
  ) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );
      dio = Dio(options);

      final response = await dio.put(
        '/v1/vendas/$vendaId',
        data: vendaData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Erro ao atualizar venda: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na requisição: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  // Deletar venda
  Future<bool> deletarVenda(int vendaId) async {
    try {
      final url = await ConfigController.instance.getUrlBase();
      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );
      dio = Dio(options);

      final response = await dio.delete(
        '/v1/vendas/$vendaId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Erro ao deletar venda: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na requisição: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
