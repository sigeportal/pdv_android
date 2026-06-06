import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Models/venda_analitico_model.dart';
import 'package:lanchonete/Services/RelatorioService.dart';

class RelatorioVendasAnaliticoPage extends StatefulWidget {
  @override
  _RelatorioVendasAnaliticoPageState createState() =>
      _RelatorioVendasAnaliticoPageState();
}

class _RelatorioVendasAnaliticoPageState
    extends State<RelatorioVendasAnaliticoPage> {
  final RelatorioService service = RelatorioService();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat moneyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  DateTime dataInicio = DateTime.now();
  DateTime dataFim = DateTime.now();
  bool carregando = false;
  String erro = '';
  VendaAnaliticoResponse? relatorio;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    dataInicio = DateTime(hoje.year, hoje.month, hoje.day);
    dataFim = dataInicio;
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = '';
    });

    try {
      final resultado = await service.fetchVendasAnalitico(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      setState(() {
        relatorio = resultado;
      });
    } catch (e) {
      setState(() {
        erro = e.toString();
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  Future<void> selecionarData(bool inicio) async {
    final atual = inicio ? dataInicio : dataFim;
    final selecionada = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (selecionada == null) {
      return;
    }

    setState(() {
      if (inicio) {
        dataInicio = selecionada;
      } else {
        dataFim = selecionada;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filtros(),
        if (carregando) LinearProgressIndicator(),
        if (erro.isNotEmpty) _erro(),
        Expanded(
          child: relatorio == null
              ? Center(child: Text('Nenhum dado carregado'))
              : _conteudo(relatorio!),
        ),
      ],
    );
  }

  Widget _filtros() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.date_range),
              label: Text(dateFormat.format(dataInicio)),
              onPressed: () => selecionarData(true),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.event),
              label: Text(dateFormat.format(dataFim)),
              onPressed: () => selecionarData(false),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              icon: Icon(Icons.search),
              label: Text('Buscar'),
              onPressed: carregando ? null : carregar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _erro() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Text(
        erro,
        style: TextStyle(color: Colors.red.shade900, fontSize: 14),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _conteudo(VendaAnaliticoResponse dados) {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        _totais(dados.totais),
        SizedBox(height: 12),
        _resumoPagamentos(dados.resumoPagamentos),
        SizedBox(height: 12),
        ...dados.vendas.map(_vendaCard).toList(),
      ],
    );
  }

  Widget _totais(TotaisVendaAnalitico totais) {
    final itens = [
      _TotalItem('Subtotal', totais.subtotal),
      _TotalItem('Adicionais', totais.adicionais),
      _TotalItem('Taxa entrega', totais.taxaEntrega),
      _TotalItem('A vista', totais.vendaVista),
      _TotalItem('A prazo', totais.vendaPrazo),
      _TotalItem('Canceladas', totais.canceladas),
      _TotalItem('Lucro', totais.lucro),
      _TotalItem('Total', totais.total),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: itens.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = itens[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.titulo, style: TextStyle(fontSize: 13)),
                SizedBox(height: 4),
                Text(
                  moneyFormat.format(item.valor),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resumoPagamentos(List<ResumoPagamento> resumo) {
    if (resumo.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamentos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...resumo.map((item) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text('${item.tipo} (${item.condicao})')),
                    Text(
                      moneyFormat.format(item.valor),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _vendaCard(VendaAnalitico venda) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ExpansionTile(
        title: Text(
          'Venda ${venda.codigo} - ${venda.cliente}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
            '${dateFormat.format(DateTime.parse(venda.data))} ${venda.hora}'),
        trailing: Text(
          moneyFormat.format(venda.valor),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          ...venda.itens.map(_itemVenda).toList(),
          if (venda.pagamentos.isNotEmpty) Divider(height: 1),
          ...venda.pagamentos.map(_pagamentoVenda).toList(),
        ],
      ),
    );
  }

  Widget _itemVenda(ItemVendaAnalitico item) {
    final totalItem = item.quantidade * item.valorUnitario +
        item.adicionais.fold<double>(
          0,
          (total, adic) => total + adic.valorTotal,
        );

    return ListTile(
      dense: true,
      title: Text(item.descricao),
      subtitle: Text(
        '${item.quantidade.toStringAsFixed(2)} x ${moneyFormat.format(item.valorUnitario)}',
      ),
      trailing: Text(moneyFormat.format(totalItem)),
      onTap: item.adicionais.isEmpty
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _adicionais(item),
              );
            },
    );
  }

  Widget _adicionais(ItemVendaAnalitico item) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            item.descricao,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...item.adicionais.map((adicional) {
            return ListTile(
              title: Text(adicional.descricao),
              subtitle: Text('Qtd. ${adicional.quantidade.toStringAsFixed(2)}'),
              trailing: Text(moneyFormat.format(adicional.valorTotal)),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _pagamentoVenda(PagamentoVenda pagamento) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.payments),
      title: Text(pagamento.tipo),
      subtitle: Text('${pagamento.duplicata} - ${pagamento.vencimento}'),
      trailing: Text(moneyFormat.format(pagamento.valor)),
    );
  }
}

class _TotalItem {
  final String titulo;
  final double valor;

  _TotalItem(this.titulo, this.valor);
}
