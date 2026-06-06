import 'dart:async';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/comanda_model.dart';
import 'package:lanchonete/Models/itemComPro_model.dart';
import 'package:dio/dio.dart';

class ComandaService {
  late Dio dio;

  Future<List<Comanda>> fetchComandas() async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    try {
      final response = await dio.get<List>('/v1/comandas');
      if (response.data != null) {
        return response.data!.map((json) => Comanda.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar comandas: $e');
      return [];
    }
  }

  Future<bool> criaComanda(Comanda comanda) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    try {
      final response = await dio.post('/v1/comandas', data: comanda.toJson());
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erro ao criar comanda: $e');
      return false;
    }
  }

  Future<Comanda> fetchComanda(int? codigo) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      validateStatus: (status) => status != null && status < 500,
    );

    dio = Dio(options);
    Comanda resultado = Comanda();
    try {
      final response = await dio.get('/v1/comandas/$codigo');

      if (response.statusCode == 200 && response.data != null) {
        var jsonData = response.data;

        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('comanda')) {
          jsonData = jsonData['comanda'];
        }

        resultado = Comanda.fromJson(jsonData);
      }
    } catch (e) {
      print('Erro ao consultar a comanda (fetchComanda): $e');
    }
    return resultado;
  }

  Future<bool> encerrarComanda(int? codigoMesa) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    try {
      final response = await dio.put('/v1/comandas/$codigoMesa/encerrar');
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao encerrar comanda: $e');
      return false;
    }
  }

  Future<bool> fecharComanda(
      int codigoComanda, String dataFechamento, String horaFechamento) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    try {
      final response = await dio.put('/v1/comandas/$codigoComanda', data: {
        "COM_DATA_FECHAMENTO": dataFechamento,
        "COM_HORA_FECHAMENTO": horaFechamento,
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erro ao fechar comanda com data/hora: $e');
      return false;
    }
  }

  Future<bool> atualizarComanda(Comanda comanda) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    try {
      final response =
          await dio.put('/v1/comandas/${comanda.mesa}', data: comanda.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao atualizar comanda: $e');
      return false;
    }
  }

  Future<ItemComPro> fetchItemComPro(int codigo) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    ItemComPro resultado = ItemComPro();
    try {
      final response = await dio.get('/v1/comandas/item/$codigo');
      if (response.data != null) {
        resultado = ItemComPro.fromJson(response.data);
      }
    } catch (e) {
      print('Erro ao buscar item da comanda: $e');
    }
    return resultado;
  }

  Future<bool> deletarItemComanda(int? codigo) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    );

    dio = Dio(options);
    try {
      final response = await dio.delete('/v1/comandas/$codigo/itens');
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao deletar item da comanda: $e');
      return false;
    }
  }
}
