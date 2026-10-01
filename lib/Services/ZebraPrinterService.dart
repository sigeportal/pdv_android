import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ZebraPrinterService {
  static final NumberFormat _moneyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Gera código de barras EAN-13 válido com dígito verificador
  static String gerarEan13({required int proCodigo, int? tamCodigo, int? graCodigo}) {
    if (proCodigo <= 0 && (tamCodigo == null || tamCodigo <= 0) && (graCodigo == null || graCodigo <= 0)) {
      return '7896000000026';
    }
    String base12;
    if (graCodigo != null && graCodigo > 0) {
      final graStr = graCodigo.toString().padLeft(9, '0');
      base12 = '789$graStr';
    } else if (tamCodigo != null && tamCodigo > 0) {
      final proStr = proCodigo.toString().padLeft(6, '0');
      final tamStr = tamCodigo.toString().padLeft(3, '0');
      base12 = '789$proStr$tamStr';
    } else {
      final proStr = proCodigo.toString().padLeft(9, '0');
      base12 = '789$proStr';
    }

    if (base12.length > 12) {
      base12 = base12.substring(0, 12);
    }

    int oddSum = 0;
    int evenSum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(base12[i]);
      if (i % 2 == 0) {
        oddSum += digit;
      } else {
        evenSum += digit;
      }
    }
    int total = oddSum + (evenSum * 3);
    int checkDigit = (10 - (total % 10)) % 10;
    return '$base12$checkDigit';
  }

  /// Remove acentos e caracteres não suportados pelo codepage ZPL padrão
  static String _sanitizeZplText(String str) {
    if (str.isEmpty) return "";
    var comAcento =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var semAcento =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = str;
    for (int i = 0; i < comAcento.length; i++) {
      result = result.replaceAll(comAcento[i], semAcento[i]);
    }
    return result.replaceAll('^', ' ').replaceAll('~', ' ').trim();
  }

  /// Gera a string de código ZPL (Zebra Programming Language) no formato 2 COLUNAS
  static String generateZplString(
    List<Map<String, dynamic>> items, {
    bool duasColunas = true,
  }) {
    if (!duasColunas) {
      return _generateZplString1Coluna(items);
    }
    return generateZpl2ColunasConfeccoes(items);
  }

  /// Gera layout de 2 Colunas
  static String generateZpl2ColunasConfeccoes(
      List<Map<String, dynamic>> items) {
    final StringBuffer zpl = StringBuffer();

    List<Map<String, dynamic>> listaExpandida = [];
    for (final item in items) {
      final int qtd = (item['qtd'] ?? item['quantidade'] ?? 1) as int;
      for (int i = 0; i < qtd; i++) {
        listaExpandida.add(item);
      }
    }

    for (int i = 0; i < listaExpandida.length; i += 2) {
      final prod1 = listaExpandida[i];
      final prod2 = (i + 1 < listaExpandida.length) ? listaExpandida[i + 1] : null;

      zpl.writeln('^XA');
      zpl.writeln('^MMT');
      zpl.writeln('^MCY');
      zpl.writeln('~SD15');
      zpl.writeln('^POI');
      zpl.writeln('^CI13');

      _escreverColunaZpl(zpl, prod1, posX: 20, posBarraX: 115);

      if (prod2 != null) {
        _escreverColunaZpl(zpl, prod2, posX: 440, posBarraX: 535);
      }

      zpl.writeln('^PQ1');
      zpl.writeln('^XZ');
      zpl.writeln('^PH');
      zpl.writeln('^MCY');
    }

    return zpl.toString();
  }

  static void _escreverColunaZpl(
    StringBuffer zpl,
    Map<String, dynamic> item, {
    required int posX,
    required int posBarraX,
  }) {
    final String nomeBruto =
        (item['nome'] ?? item['productName'] ?? item['descricao'] ?? 'PRODUTO')
            .toString();
    String nome = _sanitizeZplText(nomeBruto).trim();
    String tamanho = _sanitizeZplText((item['tamanho'] ??
            item['tam'] ??
            item['TAM_TAMANHO'] ??
            item['TAM_SIGLA'] ??
            '')
        .toString())
        .trim();

    if (tamanho.isEmpty) {
      final match = RegExp(
              r'\b(TAM(?:ANHO)?[\s:]*)?([0-9]{1,3}|PP|P|M|G|GG|XG|XGG|G[1-9]|MEDIO|PEQUENO|GRANDE|UNICO)\b$',
              caseSensitive: false)
          .firstMatch(nome);
      if (match != null) {
        tamanho = match.group(2) ?? '';
        nome = nome.substring(0, match.start).trim();
        if (nome.endsWith('-') || nome.endsWith('/')) {
          nome = nome.substring(0, nome.length - 1).trim();
        }
      }
    } else {
      final pattern = RegExp('\\b' + RegExp.escape(tamanho) + '\$', caseSensitive: false);
      if (pattern.hasMatch(nome)) {
        nome = nome.replaceFirst(pattern, '').trim();
        if (nome.endsWith('-') || nome.endsWith('/')) {
          nome = nome.substring(0, nome.length - 1).trim();
        }
      }
    }

    final String codbarra = (item['codbarra'] ??
            item['barcode'] ??
            item['codigo'] ??
            '7896000000000')
        .toString()
        .trim();

    final double precoBase =
        (item['preco'] ?? item['valor'] ?? item['price'] ?? 0.0).toDouble();

    final double valorPrazo = (item['valorPrazo'] != null)
        ? (item['valorPrazo'] as num).toDouble()
        : (precoBase > 0 ? precoBase : 0.0);

    final double valorVista = (item['valorVista'] != null)
        ? (item['valorVista'] as num).toDouble()
        : (precoBase > 0 ? precoBase * 0.95 : 0.0);

    final double valorDinheiro = (item['valorDinheiro'] != null)
        ? (item['valorDinheiro'] as num).toDouble()
        : (precoBase > 0 ? precoBase * 0.90 : 0.0);

    final double parcela10x = valorPrazo > 0 ? (valorPrazo / 10.0) : 0.0;

    final String parcela10xStr =
        parcela10x.toStringAsFixed(2).replaceAll('.', ',');
    final String vistaStr = valorVista.toStringAsFixed(2).replaceAll('.', ',');
    final String dinStr = valorDinheiro.toStringAsFixed(2).replaceAll('.', ',');

    final int valPrazoX = posX + 145;
    final int valVistaX = posX + 115;
    final int valDinX = posX + 115;
    final int rotulo10xX = posX + 35;

    if (tamanho.isNotEmpty) {
      String rotuloTamanho;
      if (tamanho.toUpperCase().startsWith('TAM')) {
        rotuloTamanho = tamanho.toUpperCase();
      } else if (tamanho.length <= 3 && int.tryParse(tamanho) == null) {
        rotuloTamanho = 'TAM: ${tamanho.toUpperCase()}';
      } else {
        rotuloTamanho = 'TAMANHO: ${tamanho.toUpperCase()}';
      }

      zpl.writeln('^FO$posX,14^FB380,1,0,C,0^A0N,26,24^FD$rotuloTamanho^FS');
      zpl.writeln('^FO$posX,44^FB380,1,0,C,0^A0N,20,18^FD$nome^FS');
    } else {
      zpl.writeln('^FO$posX,26^FB380,2,2,C,0^A0N,22,22^FD$nome^FS');
    }

    if (codbarra.isNotEmpty) {
      if (codbarra.length == 13 && int.tryParse(codbarra) != null) {
        zpl.writeln('^FO$posBarraX,74^BY2,,52^BEN,52,Y,N^FD$codbarra^FS');
      } else {
        zpl.writeln('^FO$posBarraX,74^BY2,,52^BCN,52,Y,N,N^FD$codbarra^FS');
      }
    }

    zpl.writeln('^FO$posX,168^FB380,1,0,C,0^A0N,16,18^FH\\^FDNO CART\\C7O / A PRAZO^FS');
    zpl.writeln('^FO$rotulo10xX,205^A0N,30,25^FD10 X R\$^FS');
    zpl.writeln('^FO$valPrazoX,190^A0N,70,60^FD$parcela10xStr^FS');

    zpl.writeln('^FO$posX,270^FB380,1,0,C,0^A0N,16,18^FDC/ DESCONTO DEBITO / PIX^FS');
    zpl.writeln('^FO$rotulo10xX,310^A0N,20,20^FDR\$^FS');
    zpl.writeln('^FO$valVistaX,294^A0N,70,60^FD$vistaStr^FS');

    zpl.writeln('^FO$posX,370^FB380,1,0,C,0^A0N,16,18^FH\\^FDC/ DESCONTO NO DINHEIRO (ESP\\90CIE)^FS');
    zpl.writeln('^FO$rotulo10xX,410^A0N,20,20^FDR\$^FS');
    zpl.writeln('^FO$valDinX,394^A0N,70,60^FD$dinStr^FS');
  }

  static String _generateZplString1Coluna(List<Map<String, dynamic>> items) {
    final StringBuffer zplBuffer = StringBuffer();

    for (final item in items) {
      final String nomeBruto =
          (item['nome'] ?? item['productName'] ?? 'PRODUTO').toString();
      String nome = _sanitizeZplText(nomeBruto).trim();
      String tamanho = _sanitizeZplText((item['tamanho'] ??
              item['tam'] ??
              item['TAM_TAMANHO'] ??
              item['TAM_SIGLA'] ??
              '')
          .toString())
          .trim();

      if (tamanho.isEmpty) {
        final match = RegExp(
                r'\b(TAM(?:ANHO)?[\s:]*)?([0-9]{1,3}|PP|P|M|G|GG|XG|XGG|G[1-9]|MEDIO|PEQUENO|GRANDE|UNICO)\b$',
                caseSensitive: false)
            .firstMatch(nome);
        if (match != null) {
          tamanho = match.group(2) ?? '';
          nome = nome.substring(0, match.start).trim();
          if (nome.endsWith('-') || nome.endsWith('/')) {
            nome = nome.substring(0, nome.length - 1).trim();
          }
        }
      }

      final double preco =
          (item['preco'] ?? item['valor'] ?? item['price'] ?? 0.0).toDouble();
      final String codbarra = (item['codbarra'] ??
              item['barcode'] ??
              item['codigo'] ??
              '7890000000000')
          .toString();
      final String sku = (item['sku'] ?? item['codbarra'] ?? '').toString();
      final int qtd = (item['qtd'] ?? item['quantidade'] ?? 1) as int;
      final String precoFormatado = _moneyFormat.format(preco);

      for (int i = 0; i < qtd; i++) {
        zplBuffer.writeln('^XA');
        zplBuffer.writeln('^PW440');
        zplBuffer.writeln('^LL320');
        zplBuffer.writeln('^LH10,10');

        if (tamanho.isNotEmpty) {
          String rotuloTamanho = tamanho.toUpperCase().startsWith('TAM')
              ? tamanho.toUpperCase()
              : 'TAM: ${tamanho.toUpperCase()}';
          zplBuffer.writeln('^FO10,10^A0N,26,24^FD$rotuloTamanho^FS');
          final String nomeTruncado =
              nome.length > 28 ? nome.substring(0, 28) : nome;
          zplBuffer.writeln('^FO10,40^A0N,20,20^FD$nomeTruncado^FS');
        } else {
          final String nomeTruncado =
              nome.length > 26 ? nome.substring(0, 26) : nome;
          zplBuffer.writeln('^FO10,15^A0N,26,26^FD$nomeTruncado^FS');
        }

        if (sku.isNotEmpty) {
          zplBuffer.writeln('^FO10,65^A0N,18,18^FDSKU: $sku^FS');
        }

        if (codbarra.isNotEmpty) {
          zplBuffer.writeln('^FO10,88^BY2,2,65^BCN,65,Y,N,N^FD$codbarra^FS');
        }

        zplBuffer.writeln('^FO10,185^A0N,34,34^FD$precoFormatado^FS');
        zplBuffer.writeln('^XZ');
      }
    }

    return zplBuffer.toString();
  }

  static Future<List<String>> getInstalledWindowsPrinters() async {
    if (!Platform.isWindows) {
      return [];
    }
    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-Command', 'Get-Printer | Select-Object -ExpandProperty Name'],
      );
      if (result.exitCode == 0) {
        final lines = result.stdout
            .toString()
            .split(RegExp(r'[\r\n]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return lines;
      }
      return [];
    } catch (e) {
      debugPrint('ZebraPrinterService: Erro ao listar impressoras Windows: $e');
      return [];
    }
  }

  static Future<bool> sendToWindowsSpooler(String printerName, List<int> bytes) async {
    if (!Platform.isWindows) {
      throw Exception('Impressão USB/Spooler disponível apenas no Windows.');
    }
    if (printerName.trim().isEmpty) {
      throw Exception('Nome da impressora USB/Windows não informado.');
    }

    final tempDir = await Directory.systemTemp.createTemp('zebra_raw_');
    final tempFile = File('${tempDir.path}\\label.zpl');
    try {
      await tempFile.writeAsBytes(bytes);

      if (printerName.startsWith('\\\\')) {
        try {
          final copyResult = await Process.run('cmd.exe', ['/c', 'copy', '/b', tempFile.path, printerName]);
          if (copyResult.exitCode == 0) {
            return true;
          }
        } catch (e) {
          debugPrint('ZebraPrinterService: Falha na cópia direta UNC: $e');
        }
      }

      final escapedPath = tempFile.path.replaceAll('\\', '\\\\');
      final escapedPrinter = printerName.replaceAll('"', '`"');

      final script = '''
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
    public class DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
    }
    [DllImport("winspool.Drv", EntryPoint="OpenPrinterA", SetLastError=true, CharSet=CharSet.Ansi, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string szPrinter, out IntPtr hPrinter, IntPtr pd);
    [DllImport("winspool.Drv", EntryPoint="ClosePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool ClosePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint="StartDocPrinterA", SetLastError=true, CharSet=CharSet.Ansi, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, Int32 level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);
    [DllImport("winspool.Drv", EntryPoint="EndDocPrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint="StartPagePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint="EndPagePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint="WritePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, Int32 dwCount, out Int32 dwWritten);

    public static bool SendBytesToPrinter(string szPrinterName, byte[] bytes) {
        IntPtr pUnmanagedBytes = Marshal.AllocCoTaskMem(bytes.Length);
        Marshal.Copy(bytes, 0, pUnmanagedBytes, bytes.Length);
        IntPtr hPrinter = new IntPtr(0);
        DOCINFOA di = new DOCINFOA();
        di.pDocName = "PDV Zebra ZPL";
        di.pDataType = "RAW";
        bool bSuccess = false;
        if (OpenPrinter(szPrinterName.Normalize(), out hPrinter, IntPtr.Zero)) {
            if (StartDocPrinter(hPrinter, 1, di)) {
                if (StartPagePrinter(hPrinter)) {
                    int dwWritten = 0;
                    bSuccess = WritePrinter(hPrinter, pUnmanagedBytes, bytes.Length, out dwWritten);
                    EndPagePrinter(hPrinter);
                }
                EndDocPrinter(hPrinter);
            }
            ClosePrinter(hPrinter);
        }
        Marshal.FreeCoTaskMem(pUnmanagedBytes);
        return bSuccess;
    }
}
"@
\$bytes = [System.IO.File]::ReadAllBytes("$escapedPath")
\$result = [RawPrinterHelper]::SendBytesToPrinter("$escapedPrinter", \$bytes)
if (\$result) { Write-Output "SUCCESS" } else { Write-Error "Falha ao enviar RAW para a impressora $escapedPrinter" }
''';

      final res = await Process.run('powershell', ['-NoProfile', '-Command', script]);
      if (res.exitCode == 0 && res.stdout.toString().contains('SUCCESS')) {
        return true;
      }
      throw Exception(res.stderr.toString().isNotEmpty ? res.stderr.toString().trim() : 'Falha no Spooler Windows');
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  static Future<Map<String, dynamic>> testZebraConnection({
    String tipoConexao = 'REDE',
    String ip = '192.168.1.200',
    int port = 9100,
    String nomeImpressoraUsb = '',
  }) async {
    final String testZpl = '''
^XA
^PW440
^LL320
^LH10,10
^FO10,15^A0N,28,28^FDTESTE ZEBRA PDV LANCHONETE^FS
^FO10,50^A0N,20,20^FDSTATUS: CONECTADO COM SUCESSO^FS
^FO10,80^BY2,2,60^BCN,60,Y,N,N^FD7891234567890^FS
^FO10,180^A0N,30,30^FDR\$ 99,90^FS
^XZ
''';

    try {
      if (tipoConexao.toUpperCase() == 'USB' || tipoConexao.toUpperCase() == 'SPOOLER') {
        if (nomeImpressoraUsb.trim().isEmpty) {
          return {
            'success': false,
            'message': 'Nome da impressora USB não selecionado',
            'error': 'Selecione ou informe a impressora USB instalada no Windows'
          };
        }
        await sendToWindowsSpooler(nomeImpressoraUsb, utf8.encode(testZpl));
        return {
          'success': true,
          'message': 'Etiqueta de teste enviada para $nomeImpressoraUsb via USB/Spooler!',
          'error': null
        };
      } else {
        if (ip.trim().isEmpty) {
          return {
            'success': false,
            'message': 'IP não configurado',
            'error': 'Informe o endereço IP da impressora Zebra'
          };
        }
        await sendRawZpl(testZpl, ip, port);
        return {
          'success': true,
          'message': 'Etiqueta de teste enviada para $ip:$port via TCP/IP!',
          'error': null
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao comunicar com a impressora Zebra',
        'error': e.toString().replaceAll('Exception:', '').trim()
      };
    }
  }

  static Future<bool> sendRawZpl(String zplCode, String ip, [int port = 9100]) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(utf8.encode(zplCode));
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      if (socket != null) {
        try {
          socket.destroy();
        } catch (_) {}
      }
      throw Exception('Falha de comunicação com impressora Zebra ($ip:$port): $e');
    }
  }
}
