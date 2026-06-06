import 'package:dio/dio.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/empresa_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmpresaService {
  /// Busca dados da empresa na API
  /// Se der erro (sem internet), tenta buscar do cache local (SharedPreferences)
  static Future<Empresa> fetchDadosEmpresa() async {
    try {
      final url = await ConfigController.instance.getUrlBase();

      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(
            milliseconds: 5000), // Timeout curto para não travar impressão
        receiveTimeout: const Duration(milliseconds: 5000),
      );

      Dio dio = Dio(options);

      // Busca dados da empresa ID 1
      final response = await dio.get('/v1/empresa/1');

      // Converte
      final empresa = Empresa.fromJson(response.data);

      // SALVA NO CACHE PARA USAR SE FICAR OFFLINE
      final prefs = await SharedPreferences.getInstance();
      if (empresa.titulo1 != null) {
        await prefs.setString('empresa_titulo1', empresa.titulo1!);
      }
      if (empresa.titulo2 != null) {
        await prefs.setString('empresa_titulo2', empresa.titulo2!);
      }

      return empresa;
    } catch (e) {
      print("Erro ao buscar empresa na API (usando cache): $e");

      // FALHA NA API: Tenta recuperar do cache local
      final prefs = await SharedPreferences.getInstance();
      return Empresa(
        titulo1: prefs.getString('empresa_titulo1') ?? 'LANCHONETE',
        titulo2:
            prefs.getString('empresa_titulo2') ?? 'Endereco nao configurado',
      );
    }
  }
}
