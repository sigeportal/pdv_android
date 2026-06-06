import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/grade_produto_model.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';
import 'package:dio/dio.dart';
import 'package:lanchonete/repositories/dataset_repository.dart';

class ProdutosService {
  BaseOptions? options;
  late Dio dio;

  Future<List<Produtos>> fetchProdutos(String filtro) async {
    String url = '';
    try {
      final baseurl = await ConfigController.instance.getUrlBase();
      BaseOptions options = new BaseOptions(
        baseUrl: baseurl,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );

      dio = new Dio(options);
      if (filtro != '') {
        url = '/v1/produtos$filtro';
      } else {
        url = '/v1/produtos';
      }
      final response = await dio.get<List>(url);
      final resultado =
          response.data!.map((json) => Produtos.fromJson(json)).toList();
      return resultado;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Produtos> fetchProduto(int codigo) async {
    final url = await ConfigController.instance.getUrlBase();
    BaseOptions options = new BaseOptions(
      baseUrl: url,
      connectTimeout: Duration(milliseconds: 50000),
      receiveTimeout: Duration(milliseconds: 50000),
    );

    dio = new Dio(options);
    try {
      final response = await dio.get('/v1/produtos/$codigo');
      return Produtos.fromJson(response.data);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<String?> fetchFotoProduto(int? codigo) async {
    String url = '';
    try {
      url = '/v1/produtos/$codigo/foto';
      final baseurl = await ConfigController.instance.getUrlBase();
      BaseOptions options = new BaseOptions(
        baseUrl: baseurl,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );

      dio = new Dio(options);
      final response = await dio.get(url);
      final resultado = Map<String, dynamic>.from(response.data);
      return resultado['url'];
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<List<GradeProduto>> fetchGradesProduto(int codigo) async {
    String url = '';
    try {
      url = '/v1/produtos/grades/$codigo';
      final baseurl = await ConfigController.instance.getUrlBase();
      BaseOptions options = new BaseOptions(
        baseUrl: baseurl,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );

      dio = new Dio(options);
      final response = await dio.get(url);
      final gradeList = response.data as List;
      return gradeList.map((grade) => GradeProduto.fromMap(grade)).toList();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<GradeProduto> fetchGradeProduto(int codProduto, String tamanho) async {
    String url = '';
    try {
      url = '/v1/produtos/grades/$codProduto/$tamanho';
      final baseurl = await ConfigController.instance.getUrlBase();
      BaseOptions options = new BaseOptions(
        baseUrl: baseurl,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );

      dio = new Dio(options);
      final response = await dio.get(url);
      return GradeProduto.fromMap(response.data);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<List<Nivel>> getNiveis(int codProduto) async {
    String url = '';
    try {
      url = '/v1/produtos/$codProduto/niveis';
      final baseurl = await ConfigController.instance.getUrlBase();
      BaseOptions options = new BaseOptions(
        baseUrl: baseurl,
        connectTimeout: Duration(milliseconds: 50000),
        receiveTimeout: Duration(milliseconds: 50000),
      );

      dio = new Dio(options);
      final response = await dio.get(url);
      final nivelList = response.data as List;
      return nivelList.map((nivel) => Nivel.fromJson(nivel)).toList();
    } catch (e) {
      throw Exception(e);
    }
  }
}
