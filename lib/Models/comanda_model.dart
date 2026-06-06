import 'package:lanchonete/Models/itens_model.dart';

class Comanda {
  int? codigo;
  int? mesa;
  double? valor;
  List<Itens>? itens;

  Comanda({this.codigo, this.mesa, this.valor, this.itens}) {
    if (this.itens == null) {
      this.itens = <Itens>[];
    }
  }

  factory Comanda.fromJson(Map<String, dynamic> json) {
    Comanda comanda = Comanda(
      codigo: json['comCodigo'] ?? 0,
      mesa: json['comMesa'] ?? 0,
      valor: json['comValor'] != null ? (json['comValor']).toDouble() : 0.0,
      itens: json['itens'] != null
          ? (json['itens'] as List).map((e) => Itens.fromJson(e)).toList()
          : <Itens>[],
    );
    return comanda;
  }

  Map<String, dynamic> toJson() {
    return {
      // Garantindo que enviaremos 0 em vez de null caso não tenha mesa
      "mesa": mesa ?? 0,
      "valor": valor ?? 0.0,
      // Se a lista de itens for nula, envia um array vazio []
      "itens": itens != null ? itens!.map((item) => item.toJson()).toList() : []
    };
  }
}
