import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/venda_analitico_model.dart';

class RelatorioService {
  Future<VendaAnaliticoResponse> fetchVendasAnalitico({
    required DateTime dataInicio,
    required DateTime dataFim,
    int cliente = 0,
    int grupo = 0,
    String tipoPedido = '',
  }) async {
    final url = await ConfigController.instance.getUrlBase();
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: Duration(milliseconds: 50000),
      receiveTimeout: Duration(milliseconds: 50000),
    ));

    final dateFormat = DateFormat('yyyy-MM-dd');
    final response = await dio.get(
      '/v1/relatorios/vendas-analitico',
      queryParameters: {
        'dataInicio': dateFormat.format(dataInicio),
        'dataFim': dateFormat.format(dataFim),
        if (cliente > 0) 'cliente': cliente,
        if (grupo > 0) 'grupo': grupo,
        if (tipoPedido.isNotEmpty) 'tipoPedido': tipoPedido,
      },
    );

    return VendaAnaliticoResponse.fromJson(response.data);
  }
}
