import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Controller/usuario_controller.dart';
import 'package:lanchonete/Models/despesa_model.dart';
import 'package:lanchonete/Services/DespesaService.dart';
import 'package:provider/provider.dart';

class DespesaPage extends StatefulWidget {
  const DespesaPage({Key? key}) : super(key: key);

  @override
  State<DespesaPage> createState() => _DespesaPageState();
}

class _DespesaPageState extends State<DespesaPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = DespesaService();
  final _valorController = TextEditingController();
  final _documentoController = TextEditingController();
  final _historicoController = TextEditingController();
  final _contaController = TextEditingController(text: '0');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime _data = DateTime.now();
  SubDespesa? _subDespesa;
  bool _salvando = false;

  @override
  void dispose() {
    _valorController.dispose();
    _documentoController.dispose();
    _historicoController.dispose();
    _contaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdv = ConfigController.instance.pdv.value;
    final funcionario =
        Provider.of<UsuarioController>(context, listen: false)
            .usuarioLogado
            .codigo;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _cabecalho(pdv, funcionario),
                const SizedBox(height: 20),
                _campoSubDespesa(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final valor = _parseValor(value);
                          if (valor == null || valor <= 0) {
                            return 'Informe um valor maior que zero';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _campoData()),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _historicoController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Historico',
                    hintText: 'LANCAMENTO DE DESPESA',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _documentoController,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          labelText: 'Documento',
                          hintText: 'Opcional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _campoInteiro(
                        controller: _contaController,
                        label: 'Codigo da conta',
                        helperText: '0 para debitar somente o caixa',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _lancar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                    _salvando ? 'Lancando...' : 'Lancar despesa',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(int pdv, int funcionario) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 40, color: Constants.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nova despesa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pagamento em dinheiro | PDV $pdv | '
                    'Funcionario $funcionario',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoInteiro({
    required TextEditingController controller,
    required String label,
    String? helperText,
    bool obrigatorio = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final numero = int.tryParse(value?.trim() ?? '');
        if (obrigatorio && (numero == null || numero <= 0)) {
          return 'Informe um codigo valido';
        }
        if (!obrigatorio && numero != null && numero < 0) {
          return 'Informe zero ou um codigo valido';
        }
        return null;
      },
    );
  }

  Widget _campoSubDespesa() {
    return InkWell(
      onTap: _selecionarSubDespesa,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Subdespesa',
          hintText: 'Toque para pesquisar',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _subDespesa == null
              ? const Icon(Icons.arrow_drop_down)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _subDespesa = null),
                ),
        ),
        child: Text(
          _subDespesa?.nome ?? 'Pesquisar subdespesa',
          style: TextStyle(
            color: _subDespesa == null ? Colors.grey[600] : null,
          ),
        ),
      ),
    );
  }

  Future<void> _selecionarSubDespesa() async {
    final selecionada = await showSearch<SubDespesa?>(
      context: context,
      delegate: _SubDespesaSearchDelegate(_service),
    );
    if (selecionada != null && mounted) {
      setState(() => _subDespesa = selecionada);
    }
  }

  Widget _campoData() {
    return InkWell(
      onTap: _selecionarData,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(_dateFormat.format(_data)),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selecionada != null && mounted) {
      setState(() => _data = selecionada);
    }
  }

  Future<void> _lancar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subDespesa == null) {
      _mostrarMensagem('Selecione uma subdespesa.');
      return;
    }

    final usuario = Provider.of<UsuarioController>(context, listen: false);
    final despesa = DespesaLancamento(
      subDespesa: _subDespesa!.codigo,
      subDespesaNome: _subDespesa!.nome,
      valor: _parseValor(_valorController.text)!,
      data: _data,
      documento: _documentoController.text.trim(),
      historico: _historicoController.text.trim(),
      funcionario: usuario.usuarioLogado.codigo,
      pdv: ConfigController.instance.pdv.value,
      conta: int.tryParse(_contaController.text.trim()) ?? 0,
    );

    setState(() => _salvando = true);
    try {
      final resposta = await _service.lancar(despesa);
      final data = resposta['data'];
      final codigo = data is Map ? data['codigo'] ?? data['Codigo'] : null;
      _mostrarMensagem(
        codigo == null
            ? 'Despesa lancada com sucesso.'
            : 'Despesa $codigo lancada com sucesso.',
        sucesso: true,
      );
      _limpar();
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  double? _parseValor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var texto = value.trim();
    if (texto.contains(',')) {
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(texto);
  }

  void _limpar() {
    _valorController.clear();
    _documentoController.clear();
    _historicoController.clear();
    _contaController.text = '0';
    setState(() {
      _subDespesa = null;
      _data = DateTime.now();
    });
  }

  void _mostrarMensagem(String mensagem, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: sucesso ? Colors.green[700] : Colors.red[700],
      ),
    );
  }
}

class _SubDespesaSearchDelegate extends SearchDelegate<SubDespesa?> {
  final DespesaService service;

  _SubDespesaSearchDelegate(this.service);

  @override
  String get searchFieldLabel => 'Buscar subdespesa';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _resultado();

  @override
  Widget buildSuggestions(BuildContext context) => _resultado();

  Widget _resultado() {
    return FutureBuilder<List<SubDespesa>>(
      future: service.buscarSubDespesas(busca: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final itens = snapshot.data ?? [];
        if (itens.isEmpty) {
          return const Center(child: Text('Nenhuma subdespesa encontrada.'));
        }
        return ListView.separated(
          itemCount: itens.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = itens[index];
            return ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(item.nome),
              onTap: () => close(context, item),
            );
          },
        );
      },
    );
  }
}
