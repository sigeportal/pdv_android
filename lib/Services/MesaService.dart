import 'dart:async';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/mesa_model.dart';
import 'package:dio/dio.dart';

class MesaService {
  late Dio dio;

  // Busca todas as mesas cadastradas no banco (Rota: GET /mesas)
  Future<List<Mesa>> fetchMesas() async {
    final url = await ConfigController.instance.getUrlBase();
    dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    ));

    try {
      final response = await dio.get('/v1/mesas');
      List<dynamic> data = response.data;
      return data.map((json) => Mesa.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar mesas: $e');
      return [];
    }
  }

  // Cria ou Atualiza a Mesa no Banco
  Future<bool> salvarMesa(Mesa mesa) async {
    final url = await ConfigController.instance.getUrlBase();
    dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
      // validateStatus permite que o Dio não quebre o app caso a mesa não exista (Retorne 404)
      validateStatus: (status) => status != null && status < 500,
    ));

    // O Swagger define o "MesaSchema" estritamente como: codigo, nome, estado.
    Map<String, dynamic> mesaPayload = {
      'codigo': mesa.codigo,
      'nome': mesa.nome,
      'estado': mesa.estado,
    };

    try {
      // 1. Tenta buscar a mesa para ver se ela já existe na tabela (GET /mesas/{codigo})
      final response = await dio.get('/v1/mesas/${mesa.codigo}');

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        // 2. A mesa JÁ EXISTE! Fazemos um PUT para atualizá-la (PUT /mesas/{codigo})
        final putResponse =
            await dio.put('/v1/mesas/${mesa.codigo}', data: mesaPayload);
        return putResponse.statusCode == 200 || putResponse.statusCode == 204;
      } else {
        // 3. A mesa NÃO EXISTE (retornou 404), então criamos do zero via POST /mesas
        final postResponse = await dio.post('/v1/mesas', data: mesaPayload);
        return postResponse.statusCode == 201 || postResponse.statusCode == 200;
      }
    } catch (e) {
      print('Erro crítico ao salvar mesa: $e');
      return false;
    }
  }

  // Método adicional utilizando a rota oficial do Swagger para mudar apenas o status
  Future<bool> atualizarStatusMesa(int codigoMesa, String estado) async {
    final url = await ConfigController.instance.getUrlBase();
    dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(milliseconds: 50000),
      receiveTimeout: const Duration(milliseconds: 50000),
    ));

    try {
      // Rota definida no Swagger: POST /mesas/{codigo}/status/{status}
      final response = await dio.post('/v1/mesas/$codigoMesa/status/$estado');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erro ao atualizar status da mesa: $e');
      return false;
    }
  }
}
