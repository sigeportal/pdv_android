import 'package:lanchonete/Models/complementos_model.dart';
import 'package:lanchonete/Models/grade_produto_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';

class Itens {
  int? codigo;
  int? produto;
  double? valor;
  double? quantidade;
  String? estado;
  String? obs;
  String? nome;
  int? grade;
  int? codGrupo;
  List<Complementos>? complementos;
  List<OpcaoNivel>? opcoesNiveis;
  int? id;
  GradeProduto? gradeProduto;
  int? usuario;
  String? idAgrupamento;
  bool? isBebida;
  bool? isPastel;

  Itens(
      {this.id,
      this.produto,
      this.valor,
      this.quantidade,
      this.estado,
      this.obs,
      this.nome,
      this.complementos,
      this.opcoesNiveis,
      this.codigo,
      this.grade,
      this.codGrupo,
      this.gradeProduto,
      this.usuario,
      this.idAgrupamento,
      this.isBebida,
      this.isPastel}) {
    if (this.complementos == null) {
      this.complementos = <Complementos>[];
    }
    if (this.opcoesNiveis == null) {
      this.opcoesNiveis = <OpcaoNivel>[];
    }
  }

  factory Itens.fromJson(Map<String, dynamic> json) {
    // --- FUNÇÕES DE CONVERSÃO À PROVA DE BALAS ---
    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String)
        return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // 1. Processamento Blindado de Niveis/Opcoes
    List<OpcaoNivel> listaOpcoes = [];
    var rawOpcoes = json['OpcoesNiveis'] ??
        json['opcoesNiveis'] ??
        json['opcoesNivel'] ??
        [];
    if (rawOpcoes is List) {
      for (var e in rawOpcoes) {
        if (e is Map<String, dynamic>) {
          Map<String, dynamic> safeMap = Map<String, dynamic>.from(e);
          // Pega o valor e injeta nas duas chaves possíveis para o seu OpcaoNivel não se perder
          double val = parseDoubleSafe(e['valor'] ?? e['valorAdicional']);
          double qtd = parseDoubleSafe(e['quantidade'] ?? 1);
          safeMap['valor'] = val;
          safeMap['valorAdicional'] = val;
          safeMap['quantidade'] = qtd;
          listaOpcoes.add(OpcaoNivel.fromJson(safeMap));
        }
      }
    }

    // 2. Processamento Blindado de Complementos
    List<Complementos> listaComplementos = [];
    var rawComp = json['complementos'] ?? json['Complementos'] ?? [];
    if (rawComp is List) {
      for (var c in rawComp) {
        if (c is Map<String, dynamic>) {
          Map<String, dynamic> safeMap = Map<String, dynamic>.from(c);
          safeMap['valor'] = parseDoubleSafe(c['valor']);
          safeMap['quantidade'] = parseDoubleSafe(c['quantidade'] ?? 1);
          listaComplementos.add(Complementos.fromJson(safeMap));
        }
      }
    }

    return Itens(
      codigo: parseIntSafe(json['cpCodigo']),
      produto: parseIntSafe(json['cpPro']),
      estado: json['cpEstado']?.toString() ?? '',
      valor: parseDoubleSafe(json['cpValor']),
      quantidade: parseDoubleSafe(json['cpQuantidade']),
      obs: json['cpObs']?.toString() ?? '',
      grade: parseIntSafe(json['cpGra']),
      nome: json['nome']?.toString() ?? '',
      gradeProduto: (json['gradeProduto'] != null &&
              json['gradeProduto'] is Map &&
              json['gradeProduto'].isNotEmpty)
          ? GradeProduto.fromMap(json['gradeProduto'])
          : GradeProduto(codigo: 0, valor: 0, tamanho: ''),
      complementos: listaComplementos,
      opcoesNiveis: listaOpcoes,
      usuario: parseIntSafe(json['usuario']),
      idAgrupamento: json['idAgrupamento']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "codigo": codigo ?? 0,
      "produto": produto ?? 0,
      "estado": estado ?? '',
      "valor": valor ?? 0.0,
      "quantidade": quantidade ?? 0.0,
      "obs": obs ?? '',
      "grade": grade ?? 0,
      "codGrupo": codGrupo ?? 0,
      "nome": nome ?? '',
      "gradeProduto": gradeProduto != null ? gradeProduto!.toJson() : {},
      "complementos": complementos != null
          ? complementos!.map((c) => c.toJson()).toList()
          : [],
      "opcoesNiveis": opcoesNiveis != null
          ? opcoesNiveis!.map((c) => c.toJson()).toList()
          : [],
      "usuario": usuario ?? 0,
      "idAgrupamento": idAgrupamento ?? '',
    };
  }
}
