import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Controller/usuario_controller.dart';
import 'package:lanchonete/Models/venda_analitico_model.dart';
import 'package:lanchonete/Services/RelatorioService.dart';
import 'package:provider/provider.dart';

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
  bool verTodosCaixas = false;
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
    final usuarioController =
        Provider.of<UsuarioController>(context, listen: false);
    final bool isAdmin = usuarioController.isAdmin;
    final int pdvAtual = ConfigController.instance.pdv.value;

    if (!isAdmin) {
      verTodosCaixas = false;
      final hoje = DateTime.now();
      dataInicio = DateTime(hoje.year, hoje.month, hoje.day);
      dataFim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    }

    setState(() {
      carregando = true;
      erro = '';
    });

    try {
      final resultado = await service.fetchVendasAnalitico(
        dataInicio: dataInicio,
        dataFim: dataFim,
        pdv: pdvAtual,
        todosCaixas: isAdmin ? verTodosCaixas : false,
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
    final usuarioController =
        Provider.of<UsuarioController>(context, listen: false);
    if (!usuarioController.isAdmin) {
      return;
    }

    final atual = inicio ? dataInicio : dataFim;
    final selecionada = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    final usuarioController = Provider.of<UsuarioController>(context);
    final bool isAdmin = usuarioController.isAdmin;

    return Column(
      children: [
        _filtros(isAdmin),
        if (carregando) const LinearProgressIndicator(),
        if (erro.isNotEmpty) _erro(),
        Expanded(
          child: relatorio == null
              ? const Center(child: Text('Nenhum dado carregado'))
              : _conteudo(relatorio!),
        ),
      ],
    );
  }

  Widget _filtros(bool isAdmin) {
    final int pdvAtual = ConfigController.instance.pdv.value;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      avatar: Icon(
                        Icons.point_of_sale,
                        size: 18,
                        color: !verTodosCaixas ? Colors.black87 : Colors.grey[600],
                      ),
                      label: Text(
                        'Último Caixa (PDV $pdvAtual)',
                        style: TextStyle(
                          fontWeight: !verTodosCaixas ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: !verTodosCaixas,
                      onSelected: (selected) {
                        if (selected && verTodosCaixas) {
                          setState(() => verTodosCaixas = false);
                          carregar();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(
                        Icons.all_inclusive,
                        size: 18,
                        color: verTodosCaixas ? Colors.black87 : Colors.grey[600],
                      ),
                      label: Text(
                        'Todos os Caixas (Geral)',
                        style: TextStyle(
                          fontWeight: verTodosCaixas ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: verTodosCaixas,
                      onSelected: (selected) {
                        if (selected && !verTodosCaixas) {
                          setState(() => verTodosCaixas = true);
                          carregar();
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Visualizando vendas do caixa atual deste PDV ($pdvAtual)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    isAdmin ? Icons.date_range : Icons.lock_outline,
                    color: isAdmin ? null : Colors.grey,
                  ),
                  label: Text(
                    dateFormat.format(dataInicio),
                    style: TextStyle(
                      color: isAdmin ? null : Colors.grey[700],
                    ),
                  ),
                  onPressed: isAdmin ? () => selecionarData(true) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    isAdmin ? Icons.event : Icons.lock_outline,
                    color: isAdmin ? null : Colors.grey,
                  ),
                  label: Text(
                    dateFormat.format(dataFim),
                    style: TextStyle(
                      color: isAdmin ? null : Colors.grey[700],
                    ),
                  ),
                  onPressed: isAdmin ? () => selecionarData(false) : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  onPressed: carregando ? null : carregar,
                ),
              ),
            ],
          ),
          if (relatorio != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: relatorio!.modoTodosCaixas
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: relatorio!.modoTodosCaixas
                        ? Colors.blue.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      relatorio!.modoTodosCaixas
                          ? Icons.public
                          : Icons.check_circle_outline,
                      size: 16,
                      color: relatorio!.modoTodosCaixas
                          ? Colors.blue.shade700
                          : Colors.green.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      relatorio!.modoTodosCaixas
                          ? 'Modo Geral: Visualizando todos os caixas'
                          : 'Vendas do Caixa nº ${relatorio?.caixaAtual ?? '-'} (PDV ${relatorio?.pdv ?? pdvAtual})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: relatorio!.modoTodosCaixas
                            ? Colors.blue.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
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
