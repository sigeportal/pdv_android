import 'package:dio/dio.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OrderNumberService {
  /// Gera o próximo número do pedido consultando o servidor.
  /// Reseta a numeração se detectar mudança de dia.
  static Future<int> generateNextOrderNumber() async {
    final prefs = await SharedPreferences.getInstance();

    // Data de hoje (AAAA-MM-DD)
    final String hojeStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Última data que este tablet processou uma venda
    final String? ultimaDataStr = prefs.getString('last_check_date');

    // Verifica se virou o dia
    bool ehNovoDia = ultimaDataStr != hojeStr;

    try {
      final url = await ConfigController.instance.getUrlBase();

      BaseOptions options = BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 5000),
      );

      Dio dio = Dio(options);

      // --- LÓGICA DE RESET DIÁRIO ---
      if (ehNovoDia) {
        // Antes de mandar resetar cegamente, consultamos a senha atual.
        // Motivo: Se outro tablet já abriu a loja hoje e resetou, a senha já será 1, 2, 3...
        // Não queremos resetar de novo se o dia já começou.
        try {
          final checkResponse = await dio.get('/v1/controle_senhas');
          int senhaNoServidor = _parseSenha(checkResponse.data);

          // Se a senha for alta (ex: > 20) ou zero, assumimos que é do dia anterior e resetamos.
          // Se for baixa (ex: 5), assumimos que o dia já foi aberto por outro caixa.
          if (senhaNoServidor > 20 || senhaNoServidor == 0) {
            await dio.post('/v1/controle_senhas', data: {});
            // Retorna 1 para o pedido atual
            await prefs.setString('last_check_date', hojeStr);
            return 1;
          }
        } catch (e) {
          // Se falhar a verificação inteligente, força o reset para garantir
          await dio.post('/v1/controle_senhas', data: {});
          await prefs.setString('last_check_date', hojeStr);
          return 1;
        }

        // Se caiu aqui, é novo dia mas a senha já estava baixa (outro tablet resetou).
        // Apenas atualizamos a data local e seguimos o fluxo normal.
        await prefs.setString('last_check_date', hojeStr);
      }

      // --- FLUXO NORMAL (Obter Senha) ---
      final response = await dio.get('/v1/controle_senhas');
      int senhaAtual = _parseSenha(response.data);

      // Validação básica
      if (senhaAtual <= 0) {
        // Se vier 0, tenta resetar/iniciar
        await dio.post('/v1/controle_senhas', data: {});
        return 1;
      }

      // Atualiza data local para manter sincronia
      if (ultimaDataStr != hojeStr) {
        await prefs.setString('last_check_date', hojeStr);
      }

      return senhaAtual;
    } catch (e) {
      print("ERRO ao obter senha do servidor (tentando novamente): $e");
      return await generateNextOrderNumber();
    }
  }

  // Auxiliar para extrair o inteiro da resposta
  static int _parseSenha(dynamic data) {
    if (data is int) return data;
    if (data is Map)
      return int.tryParse(
              data['senha']?.toString() ?? data['id']?.toString() ?? '0') ??
          0;
    if (data is String) return int.tryParse(data) ?? 0;
    return 0;
  }

  /// Fallback: Gera senha localmente caso o servidor esteja offline.
  static Future<int> _generateLocalOrderNumber(
      bool novoDia, String hojeStr, SharedPreferences prefs) async {
    int lastOrderNumber = prefs.getInt('last_order_number') ?? 0;

    // Se mudou o dia e estamos sem internet, resetamos localmente
    if (novoDia) {
      lastOrderNumber = 0;
      await prefs.setString('last_check_date', hojeStr);
    }

    int nextOrderNumber = lastOrderNumber + 1;
    await prefs.setInt('last_order_number', nextOrderNumber);
    return nextOrderNumber;
  }
}
