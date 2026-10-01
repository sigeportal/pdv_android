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
  final pdvBackgroundHex = ValueNotifier<String>('FFBB00');
  final primaryColorHex = ValueNotifier<String>('FFBB00');
  final secondaryColorHex = ValueNotifier<String>('2E8B57');
  final pdvLogoPath = ValueNotifier<String>('');
  final loginLogoPath = ValueNotifier<String>('');
  final pdvTitle = ValueNotifier<String>('PDV Lanchonete');
  final pdv = ValueNotifier<int>(1);

  Future<String> getUrlBase() async {
    if (baseURL.value != null && baseURL.value!.isNotEmpty) {
      return baseURL.value!;
    }
    await getConfig();
    return baseURL.value ?? 'http://localhost:9000';
  }

  ConfigController._() {
    getConfig();
  }

  Future<void> getConfig() async {
    // Busca a URL do Servidor
    var url = await storage.get('urlBase');
    if (url != null) {
      baseURL.value = url.toString();
    }

    // Título do PDV
    var savedPdvTitle = await storage.get('pdvTitle');
    if (savedPdvTitle != null && savedPdvTitle.toString().trim().isNotEmpty) {
      pdvTitle.value = savedPdvTitle.toString().trim();
    } else {
      pdvTitle.value = 'PDV Lanchonete';
    }

    // Configuração de Mesas
    var savedUseTables = await storage.get('useTables');
    if (savedUseTables != null) {
      useTables.value = savedUseTables == true || savedUseTables == 'true';
    }

    // Quantidade de Mesas
    var savedTableCount = await storage.get('tableCount');
    if (savedTableCount != null) {
      tableCount.value = int.tryParse(savedTableCount.toString()) ?? 0;
    }

    // TEF PayGo
    var savedUseTef = await storage.get('useTef');
    if (savedUseTef != null) {
      useTef.value = savedUseTef == true || savedUseTef == 'true';
    }

    // Cores e Identidade Visual
    var savedPdvBackgroundHex = await storage.get('pdvBackgroundHex');
    if (savedPdvBackgroundHex != null) {
      final value = savedPdvBackgroundHex.toString().trim();
      pdvBackgroundHex.value = value.isEmpty ? 'FFBB00' : value;
    }

    var savedPrimaryColorHex = await storage.get('primaryColorHex');
    if (savedPrimaryColorHex != null) {
      final value = savedPrimaryColorHex.toString().trim();
      primaryColorHex.value = value.isEmpty ? 'FFBB00' : value;
    }

    var savedSecondaryColorHex = await storage.get('secondaryColorHex');
    if (savedSecondaryColorHex != null) {
      final value = savedSecondaryColorHex.toString().trim();
      secondaryColorHex.value = value.isEmpty ? '2E8B57' : value;
    }

    var savedPdvLogoPath = await storage.get('pdvLogoPath');
    if (savedPdvLogoPath != null) {
      pdvLogoPath.value = savedPdvLogoPath.toString();
    }

    var savedLoginLogoPath = await storage.get('loginLogoPath');
    if (savedLoginLogoPath != null) {
      loginLogoPath.value = savedLoginLogoPath.toString();
    }

    var savedPdv = await storage.get('pdv');
    if (savedPdv != null) {
      pdv.value = int.tryParse(savedPdv.toString()) ?? 1;
    }
  }

  Future<void> saveConfig(
    String? url,
    bool useTablesValue,
    int tableCountValue,
    bool useTefValue,
    int pdvValue, {
    String pdvTitleValue = 'PDV Lanchonete',
    String pdvBackgroundHexValue = 'FFBB00',
    String primaryColorHexValue = 'FFBB00',
    String secondaryColorHexValue = '2E8B57',
    String pdvLogoPathValue = '',
    String loginLogoPathValue = '',
  }) async {
    // Atualiza a memória
    baseURL.value = url;
    useTables.value = useTablesValue;
    tableCount.value = tableCountValue;
    useTef.value = useTefValue;
    pdv.value = pdvValue <= 0 ? 1 : pdvValue;

    pdvTitle.value = pdvTitleValue.trim().isEmpty ? 'PDV Lanchonete' : pdvTitleValue.trim();
    pdvBackgroundHex.value = pdvBackgroundHexValue.trim().isEmpty ? 'FFBB00' : pdvBackgroundHexValue.trim();
    primaryColorHex.value = primaryColorHexValue.trim().isEmpty ? 'FFBB00' : primaryColorHexValue.trim();
    secondaryColorHex.value = secondaryColorHexValue.trim().isEmpty ? '2E8B57' : secondaryColorHexValue.trim();
    pdvLogoPath.value = pdvLogoPathValue.trim();
    loginLogoPath.value = loginLogoPathValue.trim();

    // Salva no armazenamento local
    await Future.wait([
      storage.put('urlBase', url),
      storage.put('useTables', useTablesValue.toString()),
      storage.put('tableCount', tableCountValue.toString()),
      storage.put('useTef', useTefValue.toString()),
      storage.put('pdv', pdv.value.toString()),
      storage.put('pdvTitle', pdvTitle.value),
      storage.put('pdvBackgroundHex', pdvBackgroundHex.value),
      storage.put('primaryColorHex', primaryColorHex.value),
      storage.put('secondaryColorHex', secondaryColorHex.value),
      storage.put('pdvLogoPath', pdvLogoPath.value),
      storage.put('loginLogoPath', loginLogoPath.value),
    ]);
  }
}
