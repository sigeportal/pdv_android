import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Constants.dart';
import '../Controller/usuario_controller.dart';
import '../Models/fluxo_caixa_model.dart';
import '../Services/FluxoCaixaService.dart';

class FluxoCaixaPage extends StatefulWidget {
  const FluxoCaixaPage({Key? key}) : super(key: key);

  @override
  State<FluxoCaixaPage> createState() => _FluxoCaixaPageState();
}

class _FluxoCaixaPageState extends State<FluxoCaixaPage> {
  final NumberFormat _money = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final DateFormat _date = DateFormat('dd/MM/yyyy');

  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dataFim = DateTime.now();

  bool _carregando = false;
  CaixaStatus? _caixaStatus;
  FluxoCaixaResumo _resumo = FluxoCaixaResumo(
    totalCredito: 0,
    totalDebito: 0,
    saldo: 0,
    itens: <FluxoCaixaLancamento>[],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usuarioController =
          Provider.of<UsuarioController>(context, listen: false);
      if (!usuarioController.isAdmin) {
        Get.offAllNamed('/principal');
        Fluttertoast.showToast(
          msg: "Acesso restrito ao administrador.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }
      _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resultados = await Future.wait([
        FluxoCaixaService.listar(dataInicio: _dataInicio, dataFim: _dataFim),
        FluxoCaixaService.status(),
      ]);
      if (!mounted) return;
      setState(() {
        _resumo = resultados[0] as FluxoCaixaResumo;
        _caixaStatus = resultados[1] as CaixaStatus;
      });
    } catch (e) {
      _erro(e.toString());
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _alterarCaixa() async {
    try {
      if (_caixaStatus?.aberto == true) {
        await FluxoCaixaService.fechar();
        _sucesso('Caixa fechado com sucesso.');
      } else {
        await FluxoCaixaService.abrir();
        _sucesso('Caixa aberto com sucesso.');
      }
      await _carregar();
    } catch (e) {
      _erro(e.toString());
    }
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final atual = inicio ? _dataInicio : _dataFim;
    final picked = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (inicio) {
        _dataInicio = picked;
      } else {
        _dataFim = picked;
      }
    });

    _carregar();
  }

  Future<void> _novoLancamento(String tipo) async {
    final valorController = TextEditingController();
    final descricaoController = TextEditingController(
      text: tipo == 'SUPRIMENTO' ? 'SUPRIMENTO PDV 1' : 'SANGRIA PDV 1',
    );

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tipo == 'SUPRIMENTO' ? 'Novo Suprimento' : 'Nova Sangria'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Valor *'),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descricao'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final valor = double.tryParse(
                valorController.text.trim().replaceAll(',', '.'),
              );
              if (valor == null || valor <= 0) {
                _erro('Informe um valor valido.');
                return;
              }

              try {
                await FluxoCaixaService.lancar(
                  tipo: tipo,
                  valor: valor,
                  descricao: descricaoController.text.trim(),
                  pdv: 1,
                );
                if (!mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                _erro(e.toString());
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    valorController.dispose();
    descricaoController.dispose();

    if (confirmado == true) {
      _sucesso('Lancamento realizado com sucesso.');
      _carregar();
    }
  }

  void _erro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(msg.replaceFirst('Exception: ', '')),
      ),
    );
  }

  void _sucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(msg)));
  }

  Widget _buildCardsTotais() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _cardTotal('Entradas', _resumo.totalCredito, Colors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _cardTotal('Saidas', _resumo.totalDebito, Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(child: _cardTotal('Saldo', _resumo.saldo, Colors.blue)),
        ],
      ),
    );
  }

  Widget _cardTotal(String titulo, double valor, Color cor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(color: cor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _money.format(valor),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_carregando) {
      return Center(
        child: CircularProgressIndicator(
          backgroundColor: Constants.primaryColor,
        ),
      );
    }

    if (_resumo.itens.isEmpty) {
      return const Center(
        child: Text('Nenhum lancamento no periodo selecionado.'),
      );
    }

    return ListView.separated(
      itemCount: _resumo.itens.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = _resumo.itens[index];
        final entrada = item.credito > 0;
        final valor = entrada ? item.credito : item.debito;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: entrada ? Colors.green : Colors.red,
            child: Icon(
              entrada ? Icons.add : Icons.remove,
              color: Colors.white,
            ),
          ),
          title: Text(item.descricao),
          subtitle: Text(
            '${_date.format(DateTime.parse(item.data))} ${item.dataHora.length >= 16 ? item.dataHora.substring(11, 16) : ''} | ${item.nome}',
          ),
          trailing: Text(
            _money.format(valor),
            style: TextStyle(
              color: entrada ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioController = Provider.of<UsuarioController>(context);
    if (!usuarioController.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Acesso restrito ao administrador.',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fluxo de Caixa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selecionarData(inicio: true),
                    icon: const Icon(Icons.date_range),
                    label: Text('Inicio: ${_date.format(_dataInicio)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selecionarData(inicio: false),
                    icon: const Icon(Icons.date_range),
                    label: Text('Fim: ${_date.format(_dataFim)}'),
                  ),
                ),
              ],
            ),
          ),
          _buildCardsTotais(),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              child: ListTile(
                leading: Icon(
                  _caixaStatus?.aberto == true
                      ? Icons.lock_open
                      : Icons.lock_outline,
                  color: _caixaStatus?.aberto == true
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(
                  _caixaStatus?.aberto == true
                      ? 'Caixa aberto'
                      : 'Caixa fechado',
                ),
                subtitle: Text(
                  _caixaStatus?.caixa == null
                      ? 'PDV 1'
                      : 'PDV 1 | Caixa ${_caixaStatus!.caixa}',
                ),
                trailing: ElevatedButton(
                  onPressed: _alterarCaixa,
                  child: Text(
                    _caixaStatus?.aberto == true ? 'Fechar' : 'Abrir',
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _novoLancamento('SUPRIMENTO'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Suprimento'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _novoLancamento('SANGRIA'),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Sangria'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }
}
