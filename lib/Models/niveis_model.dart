class Nivel {
  final int codigo;
  final String titulo;
  final String descricao;
  final int selecaoMin;
  final int selecaoMax;
  final List<OpcaoNivel> opcoes;
  final int codProduto;

  Nivel({
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.selecaoMin,
    required this.selecaoMax,
    required this.opcoes,
    required this.codProduto,
  });

  factory Nivel.fromJson(Map<String, dynamic> json) {
    // Busca a lista de opções de forma flexível (maiúscula ou minúscula)
    var rawOpcoes = json['opcoes'] ?? json['Opcoes'];
    List<OpcaoNivel> listaOpcoes = [];

    if (rawOpcoes != null && rawOpcoes is List) {
      listaOpcoes = rawOpcoes
          .map((e) => OpcaoNivel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Nivel(
      codigo:
          int.tryParse((json['codigo'] ?? json['Codigo'] ?? 0).toString()) ?? 0,
      titulo: json['titulo'] ?? json['Titulo'] ?? '',
      descricao: json['descricao'] ?? json['Descricao'] ?? '',
      selecaoMin: int.tryParse(
              (json['selecaoMin'] ?? json['SelecaoMin'] ?? 1).toString()) ??
          1,
      selecaoMax: int.tryParse(
              (json['selecaoMax'] ?? json['SelecaoMax'] ?? 1).toString()) ??
          1,
      opcoes: listaOpcoes,
      codProduto: int.tryParse(
              (json['codProduto'] ?? json['CodProduto'] ?? 0).toString()) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'titulo': titulo,
      'descricao': descricao,
      'selecaoMin': selecaoMin,
      'selecaoMax': selecaoMax,
      'opcoes': opcoes.map((e) => e.toJson()).toList(),
      'codProduto': codProduto,
    };
  }
}

class OpcaoNivel {
  final int codigo;
  final String nome;
  final double valorAdicional;
  final bool ativo;
  final String ativoStr;
  final int codNivel;
  bool selecionado;
  int quantidade;

  OpcaoNivel({
    required this.codigo,
    required this.nome,
    required this.valorAdicional,
    required this.ativo,
    required this.ativoStr,
    required this.codNivel,
    this.selecionado = false,
    this.quantidade = 0,
  });

  factory OpcaoNivel.fromJson(Map<String, dynamic> json) {
    // Conversões seguras que aceitam Int, Double ou String do backend
    double valorConvertido = double.tryParse((json['valorAdicional'] ??
                json['ValorAdicional'] ??
                json['valor'] ??
                json['Valor'] ??
                0)
            .toString()) ??
        0.0;
    int qtdConvertida = int.tryParse(
            (json['quantidade'] ?? json['Quantidade'] ?? 1).toString()) ??
        1;

    // Tratamento de booleanos (as vezes a API manda "true" como string em vez do booleano primitivo)
    bool isAtivo = json['ativo'] ?? json['Ativo'] ?? false;
    if (json['ativo'] is String) {
      isAtivo = json['ativo'].toString().toLowerCase() == 'true';
    } else if (json['Ativo'] is String) {
      isAtivo = json['Ativo'].toString().toLowerCase() == 'true';
    }

    return OpcaoNivel(
      // --- AQUI ESTÁ A MÁGICA: Procura pelo código em minúsculo ou maiúsculo ---
      codigo:
          int.tryParse((json['codigo'] ?? json['Codigo'] ?? 0).toString()) ?? 0,
      nome: json['nome'] ?? json['Nome'] ?? '',
      valorAdicional: valorConvertido,
      ativo: isAtivo,
      ativoStr: json['ativoStr'] ?? json['AtivoStr'] ?? (isAtivo ? 'S' : 'N'),
      codNivel: int.tryParse(
              (json['codNivel'] ?? json['CodNivel'] ?? 0).toString()) ??
          0,
      selecionado: json['selecionado'] ?? json['Selecionado'] ?? false,
      quantidade: qtdConvertida,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nome': nome,
      'valorAdicional': valorAdicional,
      'ativo': ativo,
      'ativoStr': ativoStr,
      'codNivel': codNivel,
      'selecionado': selecionado,
      'quantidade': quantidade,
    };
  }
}
