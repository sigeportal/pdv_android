import 'package:lanchonete/Components/payment_option_tile.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Controller/Tef/paygo_tefcontroller.dart';
import 'package:lanchonete/Controller/Tef/types/tef_provider.dart';
import 'package:lanchonete/Models/venda_model.dart';
import 'package:lanchonete/Models/cliente_model.dart';
import 'package:lanchonete/Pages/Tela_carregamento_page.dart';
import 'package:lanchonete/Pages/ReimpressaoCupom_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_venda.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/card_type.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/currency_code.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/fin_type.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/payment_mode.dart';

import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Pages/Principal_page.dart';
import 'package:lanchonete/Services/ComandaService.dart'; // --- IMPORT ADICIONADO PARA FECHAR COMANDA ---

import '../Services/CupomFiscalService.dart';
import '../Services/PrinterService.dart';
import '../Services/ClienteService.dart';

class PaymentModePage extends StatefulWidget {
  final double valorPagamento;
  final int? mesaId; // --- NOVO: RECEBE A MESA PARA ENCERRAMENTO ---

  const PaymentModePage({
    Key? key,
    required this.valorPagamento,
    this.mesaId,
  }) : super(key: key);

  @override
  _PaymentModePageState createState() => _PaymentModePageState();
}

class _PaymentModePageState extends State<PaymentModePage> {
  final TefController _tefController = Get.find<TefController>();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<PFParcela> _pagamentos = [];
  Cliente? _clienteSelecionado;

  bool _isParaLevar = false;
  bool _tefEmAndamento = false;

  double get _totalPago => _pagamentos.fold(0, (sum, p) => sum + p.valor);
  double get _valorRestante =>
      (widget.valorPagamento - _totalPago).clamp(0, double.infinity);
  bool get _podeFinalizar => _valorRestante <= 0.01;
  bool get _useTef => ConfigController.instance.useTef.value;

  String _formatPayment(double val) {
    return _currencyFormat.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isHorizontal = orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagamento", style: TextStyle(fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                      child: _buildInfoCard(
                          "Total", widget.valorPagamento, Colors.black87)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildInfoCard(
                          "Pago", _totalPago, Colors.green[700]!)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildInfoCard(
                          "Falta", _valorRestante, Colors.red[700]!)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: const Color(0xFFF5F5F7),
                      padding: const EdgeInsets.all(8),
                      child: _buildPaymentOptionsGrid(isHorizontal),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border(left: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: _isParaLevar
                                    ? Colors.orange[50]
                                    : Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _isParaLevar
                                        ? Colors.orange
                                        : Colors.blue,
                                    width: 1)),
                            child: SwitchListTile(
                              title: Text(
                                _isParaLevar
                                    ? "PARA LEVAR (Viagem)"
                                    : "COMER NO LOCAL",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isParaLevar
                                        ? Colors.deepOrange
                                        : Colors.blue[800],
                                    fontSize: 14),
                              ),
                              secondary: Icon(
                                _isParaLevar
                                    ? Icons.motorcycle
                                    : Icons.restaurant,
                                color: _isParaLevar
                                    ? Colors.deepOrange
                                    : Colors.blue[800],
                              ),
                              value: _isParaLevar,
                              activeColor: Colors.deepOrange,
                              onChanged: (bool value) {
                                setState(() {
                                  _isParaLevar = value;
                                });
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.grey[100],
                            width: double.infinity,
                            child: const Text("Lançamentos",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            child: _pagamentos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.touch_app,
                                            size: 30, color: Colors.grey[300]),
                                        const SizedBox(height: 8),
                                        Text("Selecione o pagamento",
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _pagamentos.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final p = _pagamentos[index];
                                      return ListTile(
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                        leading: Icon(_getIconForType(p.tp),
                                            color: Colors.blue[700], size: 20),
                                        title: Text(_getNomePagamento(p.tp),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        subtitle: p.tp == 1 &&
                                                _clienteSelecionado != null
                                            ? Text(_clienteSelecionado!.nome,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 11))
                                            : null,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatPayment(p.valor),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.green),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red,
                                                  size: 20),
                                              onPressed: () {
                                                setState(() {
                                                  _pagamentos.removeAt(index);
                                                  if (!_pagamentos.any(
                                                      (item) => item.tp == 1)) {
                                                    _clienteSelecionado = null;
                                                  }
                                                });
                                              },
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _podeFinalizar
                                    ? _prepararFinalizacao
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  _podeFinalizar
                                      ? "CONCLUIR"
                                      : "FALTA ${_formatPayment(_valorRestante)}",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _podeFinalizar
                                          ? Colors.white
                                          : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: navegarParaTelaAnterior,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Cancelar",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title,
              maxLines: 1,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_formatPayment(value),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionsGrid(bool isHorizontal) {
    final options = [
      PaymentOptionTile(
        icon: Icons.monetization_on_sharp,
        title: "Dinheiro",
        subtitle: "Á Vista",
        color: Colors.blue,
        onPressed: () => _adicionarPagamentoDinheiro(),
      ),
      PaymentOptionTile(
        icon: Icons.credit_card,
        title: "Débito",
        subtitle: "Cartão",
        color: Colors.blueAccent,
        onPressed: () => _adicionarPagamentoDebitoTef(),
      ),
      PaymentOptionTile(
        icon: Icons.credit_card,
        title: "Crédito",
        subtitle: "Cartão",
        color: Colors.green,
        onPressed: () => _adicionarPagamentoCreditoTef(),
      ),
      PaymentOptionTile(
        icon: Icons.qr_code,
        title: "PIX",
        subtitle: "Digital",
        color: Colors.indigo,
        onPressed: () => _adicionarPagamentoCarteiraDigitalTef(),
      ),
      PaymentOptionTile(
        icon: Icons.card_giftcard,
        title: "Voucher",
        subtitle: "Vale",
        color: Colors.orange,
        onPressed: () => _adicionarPagamentoVoucherTef(),
      ),
      PaymentOptionTile(
        icon: Icons.person_search,
        title: "A Prazo",
        subtitle: "Fiado",
        color: Colors.red,
        onPressed: () => _adicionarPagamentoPedido(),
      ),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) => options[index],
    );
  }

  // --- LÓGICA DE PAGAMENTO ---

  Future<void> _adicionarPagamentoDinheiro() async {
    if (_valorRestante <= 0.01) {
      Fluttertoast.showToast(msg: "Total já atingido!");
      return;
    }
    await _exibirCalculadoraTroco();
  }

  Future<void> _adicionarPagamentoPedido() async {
    if (_valorRestante <= 0.01) {
      Fluttertoast.showToast(msg: "Total já atingido!");
      return;
    }
    if (_clienteSelecionado == null) {
      final cli = await showDialog<Cliente?>(
        context: context,
        builder: (_) => const _ClienteSelectionDialog(),
      );
      if (cli == null) return;
      setState(() => _clienteSelecionado = cli);
    }
    double? valor = await _solicitarValorManual(
        "Valor para ${_clienteSelecionado!.nome}?", _valorRestante);
    if (valor != null && valor > 0) {
      _adicionarParcela('pedido', valor);
    }
  }

  Future<void> _adicionarPagamentoDebitoTef() async {
    if (!_useTef) {
      await _adicionarPagamentoGenerico("Valor no debito", 'debito');
      return;
    }

    final transacao = TransacaoRequisicaoVenda(
      amount: _valorRestante,
      currencyCode: CurrencyCode.iso4217Real,
    )
      ..provider = _tefController.configuracoes.provider.toValue()
      ..cardType = CardType.cartaoDebito
      ..finType = FinType.aVista;

    await _processarPagamentoTef(transacao, 'debito');
  }

  Future<void> _adicionarPagamentoCreditoTef() async {
    if (!_useTef) {
      await _adicionarPagamentoGenerico("Valor no credito", 'credito');
      return;
    }

    final transacao = TransacaoRequisicaoVenda(
      amount: _valorRestante,
      currencyCode: CurrencyCode.iso4217Real,
    )
      ..provider = _tefController.configuracoes.provider.toValue()
      ..cardType = CardType.cartaoCredito;

    final finType = await _selecionarFinanciamento();
    if (finType == null) return;

    transacao.finType = finType;
    if (finType == FinType.parceladoEmissor ||
        finType == FinType.parceladoEstabelecimento) {
      final parcelas = await _selecionarParcelas(_valorRestante);
      if (parcelas == null) return;
      transacao.installments = parcelas.toDouble();
    }

    await _processarPagamentoTef(transacao, 'credito');
  }

  Future<void> _adicionarPagamentoCarteiraDigitalTef() async {
    if (!_useTef) {
      await _adicionarPagamentoGenerico("Valor no PIX", 'pix');
      return;
    }

    final transacao = TransacaoRequisicaoVenda(
      amount: _valorRestante,
      currencyCode: CurrencyCode.iso4217Real,
    )
      ..provider = TefProvider.NENHUM.toValue()
      ..finType = FinType.aVista
      ..paymentMode = PaymentMode.pagamentoCarteiraVirtual;

    await _processarPagamentoTef(transacao, 'pix');
  }

  Future<void> _adicionarPagamentoVoucherTef() async {
    if (!_useTef) {
      await _adicionarPagamentoGenerico("Valor no voucher", 'voucher');
      return;
    }

    final transacao = TransacaoRequisicaoVenda(
      amount: _valorRestante,
      currencyCode: CurrencyCode.iso4217Real,
    )
      ..provider = _tefController.configuracoes.provider.toValue()
      ..cardType = CardType.cartaoVoucher
      ..finType = FinType.aVista;

    await _processarPagamentoTef(transacao, 'voucher');
  }

  Future<void> _processarPagamentoTef(
      TransacaoRequisicaoVenda transacao, String tipoString) async {
    if (!_useTef) {
      Fluttertoast.showToast(msg: "TEF desativado nas configuracoes.");
      return;
    }

    if (_valorRestante < TefController.VALOR_MINIMO_VENDA) {
      Fluttertoast.showToast(msg: "Valor minimo TEF: R\$ 1,00");
      return;
    }
    if (_valorRestante > TefController.VALOR_MAXIMO_VENDA) {
      Fluttertoast.showToast(msg: "Valor maximo TEF: R\$ 100.000,00");
      return;
    }
    if (_tefEmAndamento) return;

    setState(() => _tefEmAndamento = true);
    try {
      await _tefController.vender(transacao);
      if (!mounted) return;
      _adicionarParcela(tipoString, transacao.amount);
    } catch (e) {
      Fluttertoast.showToast(msg: "TEF nao aprovado: $e");
    } finally {
      if (mounted) setState(() => _tefEmAndamento = false);
    }
  }

  Future<FinType?> _selecionarFinanciamento() async {
    return showDialog<FinType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Forma de financiamento'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, FinType.aVista),
            child: const Text('A vista'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, FinType.parceladoEmissor),
            child: const Text('Parcelado emissor'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, FinType.parceladoEstabelecimento),
            child: const Text('Parcelado estabelecimento'),
          ),
        ],
      ),
    );
  }

  Future<int?> _selecionarParcelas(double valor) async {
    if (valor < 10) {
      Fluttertoast.showToast(msg: "Valor minimo para parcelar: R\$ 10,00");
      return null;
    }

    final maxParcelas = (valor / 5).floor().clamp(2, 99).toInt();
    return showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Quantidade de parcelas'),
        children: List.generate(maxParcelas - 1, (index) {
          final parcela = index + 2;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, parcela),
            child: Text('$parcela x'),
          );
        }),
      ),
    );
  }

  Future<void> _adicionarPagamentoGenerico(
      String titulo, String tipoKey) async {
    if (_valorRestante <= 0.01) {
      Fluttertoast.showToast(msg: "Total já atingido!");
      return;
    }
    double? valor = await _solicitarValorManual(titulo, _valorRestante);
    if (valor != null && valor > 0) {
      _adicionarParcela(tipoKey, valor);
    }
  }

  void _adicionarParcela(String tipoString, double valor) {
    int tp = _getFormaPagtoId(tipoString);
    setState(() {
      _pagamentos.add(PFParcela(
        codigo: 0,
        duplicata: "1-1/1",
        pf: 0,
        valor: valor,
        valorpg: valor,
        vencimento: DateTime.now(),
        juros: 0,
        tp: tp,
        descontos: 0,
        estado: 1,
        tipoPagamento: null,
      ));
    });
  }

  Future<double?> _solicitarValorManual(
      String titulo, double valorSugerido) async {
    TextEditingController controller = TextEditingController(
        text: valorSugerido.toStringAsFixed(2).replaceAll('.', ','));

    return showDialog<double>(
      context: context,
      builder: (context) {
        void _confirmarValor() {
          String text =
              controller.text.replaceAll('.', '').replaceAll(',', '.');
          double? val = double.tryParse(text);
          if (val != null) {
            if (val > _valorRestante + 0.05) {
              Fluttertoast.showToast(
                  msg: "Valor não pode ser maior que o restante!");
              return;
            }
            Navigator.pop(context, val);
          }
        }

        return AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Valor",
              prefixText: "R\$ ",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _confirmarValor(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar",
                    style: TextStyle(color: Colors.red))),
            ElevatedButton(
              onPressed: _confirmarValor,
              child: const Text("Confirmar"),
            )
          ],
        );
      },
    );
  }

  Future<void> _exibirCalculadoraTroco() async {
    final TextEditingController _valorRecebidoController =
        TextEditingController();
    double troco = 0.0;
    List<String> sugestaoCedulas = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 800),
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) {
                void _calcularTroco(String value) {
                  if (value.isEmpty) {
                    setState(() {
                      troco = 0.0;
                      sugestaoCedulas = [];
                    });
                    return;
                  }
                  String cleanValue =
                      value.replaceAll('.', '').replaceAll(',', '.');
                  double? recebido = double.tryParse(cleanValue);

                  if (recebido != null) {
                    setState(() {
                      troco = recebido - _valorRestante;
                      if (troco > 0) {
                        sugestaoCedulas = _gerarSugestaoCedulas(troco);
                      } else {
                        sugestaoCedulas = [];
                      }
                    });
                  }
                }

                bool podeConfirmar = false;
                String cleanText = _valorRecebidoController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '.');
                double? valorDigitado = double.tryParse(cleanText);
                if (valorDigitado != null && valorDigitado > 0) {
                  podeConfirmar = true;
                }

                return Column(
                  children: [
                    const Text("Dinheiro / Troco",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Falta Pagar: ${_formatPayment(_valorRestante)}",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[800])),
                                const SizedBox(height: 20),
                                const Text("Valor Recebido"),
                                TextField(
                                  controller: _valorRecebidoController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 24),
                                  decoration: const InputDecoration(
                                    prefixText: "R\$ ",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: _calcularTroco,
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1,
                              color: Colors.grey[300],
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Troco: ${_formatPayment(troco < 0 ? 0 : troco)}",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        troco >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                if (sugestaoCedulas.isNotEmpty) ...[
                                  const Divider(),
                                  Expanded(
                                    child: ListView(
                                      children: sugestaoCedulas
                                          .map((e) => Text("• $e",
                                              style: const TextStyle(
                                                  fontSize: 16)))
                                          .toList(),
                                    ),
                                  )
                                ] else
                                  const Spacer()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar",
                                style: TextStyle(color: Colors.red))),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: podeConfirmar
                              ? () {
                                  Navigator.pop(context);
                                  double recebido = double.tryParse(
                                          _valorRecebidoController.text
                                              .replaceAll('.', '')
                                              .replaceAll(',', '.')) ??
                                      0;
                                  double valorAPagar =
                                      recebido >= _valorRestante
                                          ? _valorRestante
                                          : recebido;
                                  _adicionarParcela('dinheiro', valorAPagar);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15)),
                          child: const Text("CONFIRMAR"),
                        )
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _prepararFinalizacao() {
    String nomeCliente = 'CONSUMIDOR';
    int codCli = 1;

    if (_clienteSelecionado != null) {
      nomeCliente = _clienteSelecionado!.nome;
      codCli = _clienteSelecionado!.codigo;
    }

    final comandaController =
        Provider.of<ComandaController>(context, listen: false);

    final pedFatFinal = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: _totalPago,
      cliente: nomeCliente,
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: _pagamentos.length,
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: codCli,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: _pagamentos,
    );

    _enviarVendaParaAPI(pedFatFinal);
  }

  Future<void> _enviarVendaParaAPI(PedFat pedFatFinal) async {
    try {
      final comandaController =
          Provider.of<ComandaController>(context, listen: false);
      final now = DateTime.now();

      List<ItemVenda> itensVenda = comandaController.itens.map((item) {
        final valorUnitario = item.valor ?? 0.0;
        final quantidade = (item.quantidade ?? 1.0).toInt();
        return ItemVenda(
          codigo: 0,
          valor: valorUnitario * quantidade,
          quantidade: quantidade,
          ven: 0,
          pro: item.produto ?? 0,
          lucro: 10,
          valorr: valorUnitario * 0.8,
          valorl: valorUnitario * 0.9,
          valorf: valorUnitario,
          diferenca: 0,
          liquido: 0,
          valor2: valorUnitario * quantidade,
          valorcm: 0,
          aliquota: 0,
          gtin: "",
          embalagem: "PC",
          valorb: valorUnitario * quantidade,
          desconto: 0,
          valorc: valorUnitario * 0.7,
          obs: item.obs ?? "",
          gra: item.grade ?? 0,
          semente_tratada: "N",
          valor_partida: 0,
          variacao: 0,
          usu: 1,
          complementos: [],
          opcoesNivel: item.opcoesNiveis,
        );
      }).toList();

      final venda = Venda(
        codigo: 0,
        data: now,
        valor: comandaController.valorComanda,
        hora: now.hour + (now.minute / 60) + (now.second / 3600),
        fun: 1,
        nf: 0,
        diferenca: 0,
        datac: now.day,
        fat: 0,
        dav: 0,
        cli: pedFatFinal.cod_cli,
        devolucao_p: "N",
        tipo_pedido: "VENDA",
        taxa_entrega: 0,
        forma_pgto: 0,
        nome_cliente: pedFatFinal.cliente,
        id_pedido: '',
        itens: itensVenda,
        pedFat: pedFatFinal,
      );

      Map<String, dynamic> vendaData = venda.toJson();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) {
          return TelaCarregamento(
            messageAwait: 'Processando...',
            messageSuccess: 'Venda Sucesso!',
            messageError: 'Erro.',
            finalization: true,
            onFinalization: () async {
              final itens = comandaController.itens;
              final valorComanda = comandaController.valorComanda;
              final success = await comandaController.inserirVenda(vendaData);

              if (success['codigo'] != 0) {
                // --- NOVA LÓGICA: FECHAR MESA E COMANDA NA API ---
                if (widget.mesaId != null) {
                  final cService = ComandaService();
                  try {
                    // 1. Busca a comanda para obter o ID real dela para dar baixa na Data/Hora
                    final comandaDb =
                        await cService.fetchComanda(widget.mesaId!);

                    if (comandaDb.codigo != null && comandaDb.codigo! > 0) {
                      String dataStr =
                          DateFormat('yyyy-MM-dd').format(DateTime.now());
                      String horaStr =
                          DateFormat('HH:mm:ss').format(DateTime.now());

                      // Dá baixa com data e hora
                      await cService.fecharComanda(
                          comandaDb.codigo!, dataStr, horaStr);
                    }

                    // 2. Encerra a mesa na rota dedicada para isso
                    await cService.encerrarComanda(widget.mesaId!);
                  } catch (e) {
                    print("Erro ao encerrar mesa/comanda na finalização: $e");
                  }
                }
                // --------------------------------------------------

                int numeroPedido =
                    await OrderNumberService.generateNextOrderNumber();

                await PrinterService.printOrder(
                    itens: itens,
                    orderNumber: numeroPedido,
                    totalValue: valorComanda,
                    isParaLevar: _isParaLevar);

                if (mounted) {
                  await Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => ReimpressaoCupomPage(
                            itens: itens,
                            numeroPedido: numeroPedido,
                            totalValue: valorComanda)),
                    (route) => false,
                  );
                }

                comandaController.clear();
              }
            },
          );
        }),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Erro: $e");
    }
  }

  void navegarParaTelaAnterior() {
    bool usarMesas = ConfigController.instance.useTables.value;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalPage(
          paginas: usarMesas ? Paginas.mesas : Paginas.categorias,
        ),
      ),
      (route) => false,
    );
  }

  int _getFormaPagtoId(String formaPagto) {
    switch (formaPagto.toLowerCase()) {
      case 'dinheiro':
        return 0;
      case 'pedido':
        return 1;
      case 'credito':
        return 2;
      case 'debito':
        return 3;
      case 'pix':
        return 4;
      case 'voucher':
        return 5;
      default:
        return 0;
    }
  }

  String _getNomePagamento(int tp) {
    switch (tp) {
      case 0:
        return "Dinheiro";
      case 1:
        return "A Prazo";
      case 2:
        return "Crédito";
      case 3:
        return "Débito";
      case 4:
        return "PIX";
      case 5:
        return "Voucher";
      default:
        return "Outro";
    }
  }

  IconData _getIconForType(int tp) {
    switch (tp) {
      case 0:
        return Icons.monetization_on;
      case 1:
        return Icons.person;
      case 2:
      case 3:
        return Icons.credit_card;
      case 4:
        return Icons.qr_code;
      case 5:
        return Icons.card_giftcard;
      default:
        return Icons.payment;
    }
  }

  List<String> _gerarSugestaoCedulas(double valorTroco) {
    List<String> resultado = [];
    int centavos = (valorTroco * 100).round();
    final Map<int, String> cedulas = {
      10000: "Nota de R\$ 100,00",
      5000: "Nota de R\$ 50,00",
      2000: "Nota de R\$ 20,00",
      1000: "Nota de R\$ 10,00",
      500: "Nota de R\$ 5,00",
      200: "Nota de R\$ 2,00",
      100: "Moeda de R\$ 1,00",
      50: "Moeda de R\$ 0,50",
      25: "Moeda de R\$ 0,25",
      10: "Moeda de R\$ 0,10",
      5: "Moeda de R\$ 0,05"
    };
    for (var valor in cedulas.keys) {
      if (centavos >= valor) {
        int qtd = centavos ~/ valor;
        centavos %= valor;
        resultado.add("$qtd x ${cedulas[valor]}");
      }
    }
    return resultado;
  }
}

class _ClienteSelectionDialog extends StatefulWidget {
  const _ClienteSelectionDialog();
  @override
  State<_ClienteSelectionDialog> createState() =>
      _ClienteSelectionDialogState();
}

class _ClienteSelectionDialogState extends State<_ClienteSelectionDialog> {
  late Future<List<Cliente>> _futureClientes;
  List<Cliente> _clientesFiltrados = [];
  List<Cliente> _clientesOriginais = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureClientes = ClienteService.obterClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarClientes(String termo) {
    setState(() {
      if (termo.isEmpty) {
        _clientesFiltrados = _clientesOriginais;
      } else {
        _clientesFiltrados = _clientesOriginais
            .where((cliente) =>
                cliente.nome.toLowerCase().contains(termo.toLowerCase()) ||
                cliente.cnpj_cpf.contains(termo))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Cliente'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Cliente>>(
          future: _futureClientes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum cliente encontrado'));
            }
            if (_clientesOriginais.isEmpty) {
              _clientesOriginais = snapshot.data!;
              _clientesFiltrados = snapshot.data!;
            }
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: _filtrarClientes,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cli = _clientesFiltrados[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(cli.nome),
                        subtitle: Text("Limite: R\$ ${cli.limite}"),
                        onTap: () => Navigator.pop(context, cli),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'))
      ],
    );
  }
}
