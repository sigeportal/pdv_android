import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/empresa_model.dart';
import 'package:lanchonete/Services/EmpresaService.dart';
import 'package:lanchonete/repositories/dataset_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PrinterServicePDF.dart';

class PrinterService {
  static const int _printerPort = 9100;
  static const Duration _connectionTimeout = Duration(seconds: 4);

  static final _formatMoeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // --- FORMATAÇÃO MANUAL ---
  static String _formatarMoedaManual(double valor) {
    String temp = valor.toStringAsFixed(2);
    temp = temp.replaceAll('.', ',');
    return "R\$ $temp";
  }

  // --- REMOVE ACENTOS ---
  static String _semAcentos(String str) {
    if (str.isEmpty) return "";
    var comAcento =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var semAcento =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < comAcento.length; i++) {
      str = str.replaceAll(comAcento[i], semAcento[i]);
    }
    return str;
  }

  // --- LÓGICA DE ORDENAÇÃO DE EXTRAS (Tamanho/Unidade Primeiro) ---
  static List<Map<String, dynamic>> _getExtrasOrdenados(Itens item) {
    List<Map<String, dynamic>> extras = [];

    // Adiciona Complementos
    if (item.complementos != null) {
      for (var c in item.complementos!) {
        extras
            .add({'nome': c.nome, 'qtd': c.quantidade, 'tipo': 'complemento'});
      }
    }

    // Adiciona Opções de Nível
    if (item.opcoesNiveis != null) {
      for (var op in item.opcoesNiveis!) {
        extras.add({'nome': op.nome, 'qtd': op.quantidade, 'tipo': 'opcao'});
      }
    }

    // Palavras-chave que indicam prioridade (Tamanho ou Unidade)
    final prioridades = [
      'TAMANHO', 'TAM', 'UNIDADE', 'UN', 'UNID',
      'PEQUENO', 'MEDIO', 'MÉDIO', 'GRANDE', 'GIGANTE', 'FAMILIA',
      ' P ', ' M ', ' G ', ' GG ', // Espaços para evitar falsos positivos
      '(P)', '(M)', '(G)', '(GG)',
      ' P', ' M', ' G', ' GG' // Fim de frase
    ];

    // Verifica se uma string é prioritária
    bool isPrioridade(String nome) {
      String n = _semAcentos(nome.toUpperCase());
      // Verifica igualdade exata para letras soltas
      if (['P', 'M', 'G', 'GG'].contains(n)) return true;

      // Verifica conter palavras-chave
      for (var p in prioridades) {
        if (n.contains(p)) return true;
      }
      return false;
    }

    // Ordena: Prioritários primeiro, o resto mantém a ordem de inserção (estável)
    extras.sort((a, b) {
      bool aPri = isPrioridade(a['nome'] ?? '');
      bool bPri = isPrioridade(b['nome'] ?? '');

      if (aPri && !bPri) return -1; // A vem primeiro
      if (!aPri && bPri) return 1; // B vem primeiro
      return 0; // Mantém ordem original
    });

    return extras;
  }

  static Future<bool> printOrder(
      {required List<Itens> itens,
      required int orderNumber,
      required double totalValue,
      bool isParaLevar = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final ipCaixa = prefs.getString('printer_ip_caixa');
    final ipCozinha = prefs.getString('printer_ip_cozinha');

    if (!kIsWeb & (ipCaixa == null || ipCaixa.isEmpty)) {
      print("ERRO: IP da impressora do caixa não configurado.");
      return false;
    }

    Empresa dadosEmpresa = await EmpresaService.fetchDadosEmpresa();
    CapabilityProfile profile = await CapabilityProfile.load();

    bool temPastel = itens.any((item) => item.isPastel!);
    List<Itens> itensGeral = [];
    List<Itens> itensPastel = [];

    if (temPastel) {
      itensPastel =
          itens.where((item) => item.isPastel! || item.isBebida!).toList();
      itensGeral =
          itens.where((item) => !item.isPastel! && !item.isBebida!).toList();
    } else {
      itensGeral = List.from(itens);
    }

    bool sucesso = false;

    // 1. IMPRESSORA CAIXA
    try {
      late Socket socketCaixa;
      if (!kIsWeb) {
        socketCaixa = await Socket.connect(ipCaixa, _printerPort,
            timeout: _connectionTimeout);
      }

      List<int> bytes = await _generateReceiptBytes(
          itens, orderNumber, totalValue, profile, dadosEmpresa);

      if (itensGeral.isNotEmpty) {
        bytes.addAll(await _generateKitchenBytes(
            itensGeral, orderNumber, profile,
            tituloSetor: "COZINHA (GERAL)", isParaLevar: isParaLevar));
      }

      if (!kIsWeb) {
        socketCaixa.add(Uint8List.fromList(bytes));
        await socketCaixa.flush();
        await socketCaixa.close();
      } else {
        printPdfFromBytes(Uint8List.fromList(bytes));
      }
      sucesso = true;
    } catch (e) {
      print("Erro Caixa: $e");
    }

    // 2. IMPRESSORA COZINHA
    if (itensPastel.isNotEmpty) {
      try {
        late Socket socketCozinha;
        if (!kIsWeb) {
          socketCozinha = await Socket.connect(ipCozinha, _printerPort,
              timeout: _connectionTimeout);
        }

        List<int> bytes = await _generateKitchenBytes(
            itensPastel, orderNumber, profile,
            tituloSetor: "COZINHA (PASTEL)", isParaLevar: isParaLevar);
        if (!kIsWeb) {
          socketCozinha.add(Uint8List.fromList(bytes));
          await socketCozinha.flush();
          await socketCozinha.close();
        } else {
          printPdfFromBytes(Uint8List.fromList(bytes));
        }
      } catch (e) {
        print("Erro Cozinha: $e");
      }
    }

    return sucesso;
  }

  // --- GERADOR CUPOM CLIENTE ---
  static Future<List<int>> _generateReceiptBytes(
      List<Itens> itens,
      int orderNumber,
      double totalValue,
      CapabilityProfile profile,
      Empresa empresa) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.reset();

    bytes += generator.text(
        _semAcentos(empresa.titulo1?.toUpperCase() ?? 'LANCHONETE'),
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));

    bytes += generator.text(_semAcentos(empresa.titulo2 ?? ''),
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.feed(1);
    bytes += generator.text('SENHA / PEDIDO',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(orderNumber.toString().padLeft(3, '0'),
        styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size3,
            width: PosTextSize.size3,
            bold: true));

    bytes += generator.feed(1);
    bytes += generator.text(
        "Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Qtd', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'Total',
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    for (var item in itens) {
      double qtd = item.quantidade ?? 1;
      double valorTotalItem = (item.valor ?? 0);
      if (item.complementos != null) {
        for (var c in item.complementos!)
          valorTotalItem += (c.valor * c.quantidade);
      }
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!)
          valorTotalItem += (op.valorAdicional * op.quantidade);
      }
      double totalLinha = valorTotalItem * qtd;

      String nomeItem = _semAcentos(item.nome ?? '');

      bytes += generator.row([
        PosColumn(
            text: '${qtd.toInt()}x',
            width: 2,
            styles: const PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(
            text: nomeItem,
            width: 6,
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            text: _formatarMoedaManual(totalLinha).replaceAll('R\$ ', ''),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      // --- USANDO A LISTA ORDENADA ---
      List<Map<String, dynamic>> extras = _getExtrasOrdenados(item);

      for (var extra in extras) {
        bytes += generator.text(
            " + ${extra['qtd']}x ${_semAcentos(extra['nome'])}",
            styles: const PosStyles(fontType: PosFontType.fontB));
      }
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
      PosColumn(
          text: _formatarMoedaManual(totalValue),
          width: 6,
          styles: const PosStyles(
              bold: true,
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2)),
    ]);

    bytes += generator.feed(2);
    bytes += generator.text('*** VIA CLIENTE ***',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // --- VIA COZINHA ---
  static Future<List<int>> _generateKitchenBytes(
      List<Itens> itens, int orderNumber, CapabilityProfile profile,
      {String tituloSetor = "COZINHA", bool isParaLevar = false}) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.reset();
    //espaços em branco
    bytes += generator.feed(6);
    if (isParaLevar) {
      bytes += generator.text('* VIAGEM / PARA LEVAR *',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              reverse: true));
      bytes += generator.feed(1);
    } else {
      bytes += generator.text('CONSUMO NO LOCAL (MESA)',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              reverse: true));
      bytes += generator.feed(1);
    }

    bytes += generator.text(_semAcentos(tituloSetor),
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            reverse: true));

    bytes += generator.feed(1);
    bytes += generator.text('PEDIDO: ${orderNumber.toString().padLeft(3, '0')}',
        styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size3,
            width: PosTextSize.size3,
            bold: true));

    bytes += generator.text(DateFormat('HH:mm').format(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '=');

    for (var item in itens) {
      double qtd = item.quantidade ?? 1;
      // Sanitiza nome do item
      String nomeItem = _semAcentos(item.nome?.toUpperCase() ?? "");

      bytes += generator.text(
        '${qtd.toInt()}x $nomeItem',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size1,
          bold: true,
        ),
      );

      // --- USANDO A LISTA ORDENADA NA COZINHA ---
      List<Map<String, dynamic>> extras = _getExtrasOrdenados(item);

      for (var extra in extras) {
        bytes += generator.text(
            "  [+] ${extra['qtd']}x ${_semAcentos(extra['nome'])}",
            styles: const PosStyles(bold: true));
      }

      if (item.obs != null && item.obs!.isNotEmpty) {
        bytes += generator.text("  OBS: ${_semAcentos(item.obs!)}",
            styles: const PosStyles(bold: true, reverse: true));
      }
      bytes += generator.hr(ch: '-');
    }

    bytes += generator.feed(2);
    bytes += generator.text('*** VIA PRODUCAO ***',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // --- TESTE DE COMUNICAÇÃO COM IMPRESSORA ---
  static Future<Map<String, dynamic>> testPrinterConnection(
      String printerIp) async {
    try {
      if (printerIp.isEmpty) {
        return {
          'success': false,
          'message': 'IP não configurado',
          'error': 'Por favor, configure um IP válido'
        };
      }

      final socket = await Socket.connect(
        printerIp,
        _printerPort,
        timeout: _connectionTimeout,
      );

      // Se conseguiu conectar, envia um comando simples de teste
      try {
        final testCommand = [0x1B, 0x40]; // ESC @ - Reset da impressora
        socket.add(testCommand);
        await socket.flush();
      } catch (e) {
        print("Erro ao enviar comando de teste: $e");
      }

      await socket.close();

      return {
        'success': true,
        'message': 'Impressora encontrada e respondendo',
        'error': null,
        'ip': printerIp
      };
    } on SocketException catch (e) {
      String errorMessage = 'Erro desconhecido';

      if (e.osError?.message.contains('Connection refused') ?? false) {
        errorMessage =
            'Conexão recusada - Impressora offline ou porta incorreta';
      } else if (e.osError?.message.contains('Host unreachable') ?? false) {
        errorMessage =
            'Host não alcançável - IP incorreto ou impressora desligada';
      } else if (e.osError?.message.contains('Connection timed out') ?? false) {
        errorMessage = 'Timeout - Impressora não responde no tempo limite';
      } else if (e.message.contains('Failed to lookup')) {
        errorMessage = 'IP inválido ou não resolvível';
      } else {
        errorMessage = e.message;
      }

      return {
        'success': false,
        'message': 'Falha na comunicação',
        'error': errorMessage,
        'ip': printerIp
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar',
        'error': e.toString(),
        'ip': printerIp
      };
    }
  }

  // --- TESTE DE AMBAS AS IMPRESSORAS ---
  static Future<Map<String, Map<String, dynamic>>> testAllPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final ipCaixa = prefs.getString('printer_ip_caixa') ?? '';
    final ipCozinha = prefs.getString('printer_ip_cozinha') ?? '';

    final resultCaixa = await testPrinterConnection(ipCaixa);
    final resultCozinha = await testPrinterConnection(ipCozinha);

    return {
      'caixa': resultCaixa,
      'cozinha': resultCozinha,
    };
  }
}
