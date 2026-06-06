class Complementos {
  int? codigo;
  String? nome;
  dynamic valor;
  bool? selecionado;
  int? quantidade;

  Complementos(
      {this.codigo, this.nome, this.valor, this.quantidade, this.selecionado}) {
    if (this.selecionado == null) this.selecionado = false;
    if (this.quantidade == null) this.quantidade = 0;
  }

  factory Complementos.fromJson(Map<String, dynamic> json) {
    double valorConvertido =
        double.tryParse((json['valor'] ?? json['Valor'] ?? 0).toString()) ??
            0.0;
    int qtdConvertida = int.tryParse(
            (json['quantidade'] ?? json['Quantidade'] ?? 1).toString()) ??
        1;

    return Complementos(
      // Busca chaves minúsculas e maiúsculas
      codigo:
          int.tryParse((json['codigo'] ?? json['Codigo'] ?? 0).toString()) ?? 0,
      nome: json['nome'] ?? json['Nome'] ?? '',
      valor: valorConvertido,
      quantidade: qtdConvertida,
      selecionado: json['selecionado'] ?? json['Selecionado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Impede envios nulos de volta para o backend
      "codigo": codigo ?? 0,
      "nome": nome ?? '',
      "valor": valor ?? 0.0,
      "quantidade": quantidade ?? 0,
      "selecionado": selecionado ?? false,
    };
  }
}
