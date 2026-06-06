import 'package:dio/dio.dart';

import '../Controller/Config.Controller.dart';

class DatasetRepository {
  Future<Map<String, dynamic>> fetchData(String sql) async {
    final url = await ConfigController.instance.getUrlBase();

    BaseOptions options = new BaseOptions(
      baseUrl: url,
      connectTimeout: Duration(milliseconds: 50000),
      receiveTimeout: Duration(milliseconds: 50000),
    );

    Dio dio = new Dio(options);
    try {
      final response = await dio.post('/v1/dataset', data: {'sql': sql});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception(e);
    }
  }
}
