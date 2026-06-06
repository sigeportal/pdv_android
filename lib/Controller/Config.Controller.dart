import 'package:lanchonete/Interfaces/Local_Storage.Interface.dart';
import 'package:lanchonete/Services/Local_storage.Service.dart';
import 'package:flutter/material.dart';

class ConfigController {
  static final ConfigController instance = ConfigController._();
  final ILocalStorage storage = LocalStorageService();

  final baseURL = ValueNotifier<String?>('');
  final useTables = ValueNotifier<bool>(false);
  final tableCount = ValueNotifier<int>(0);
  final useTef = ValueNotifier<bool>(true);
  final pdv = ValueNotifier<int>(1);

  Future<String> getUrlBase() async {
    if (baseURL.value != '') {
      // return 'http://${baseURL.value}:9000';
      return baseURL.value!;
    }
    await getConfig();
    // return 'http://${baseURL.value}:9000';
    return baseURL.value!;
  }

  ConfigController._() {
    getConfig();
  }

  getConfig() async {
    // Busca o IP
    var url = await storage.get('urlBase');
    if (url != null) {
      baseURL.value = url.toString();
    }

    // Busca a configuração de mesas
    var savedUseTables = await storage.get('useTables');
    if (savedUseTables != null) {
      useTables.value = savedUseTables == true || savedUseTables == 'true';
    }

    // Busca a quantidade de mesas
    var savedTableCount = await storage.get('tableCount');
    if (savedTableCount != null) {
      tableCount.value = int.tryParse(savedTableCount.toString()) ?? 0;
    }

    var savedUseTef = await storage.get('useTef');
    if (savedUseTef != null) {
      useTef.value = savedUseTef == true || savedUseTef == 'true';
    }

    var savedPdv = await storage.get('pdv');
    if (savedPdv != null) {
      pdv.value = int.tryParse(savedPdv.toString()) ?? 1;
    }
  }

  saveConfig(
    String? url,
    bool useTablesValue,
    int tableCountValue,
    bool useTefValue,
    int pdvValue,
  ) {
    // Atualiza a memória
    baseURL.value = url;
    useTables.value = useTablesValue;
    tableCount.value = tableCountValue;
    useTef.value = useTefValue;
    pdv.value = pdvValue <= 0 ? 1 : pdvValue;

    // Salva no armazenamento local (convertendo para string para evitar erros no DB local)
    storage.put('urlBase', url);
    storage.put('useTables', useTablesValue.toString());
    storage.put('tableCount', tableCountValue.toString());
    storage.put('useTef', useTefValue.toString());
    storage.put('pdv', pdv.value.toString());
  }
}
