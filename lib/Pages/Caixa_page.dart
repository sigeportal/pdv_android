import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Constants.dart';
import '../Controller/Config.Controller.dart';
import '../Controller/usuario_controller.dart';
import '../Models/fluxo_caixa_model.dart';
import '../Services/CaixaService.dart';
import '../Services/FluxoCaixaService.dart';

class CaixaPage extends StatefulWidget {
  final bool aberturaInicial;
  final VoidCallback? onStatusChanged;

  const CaixaPage({
    Key? key,
    this.aberturaInicial = false,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<CaixaPage> createState() => _CaixaPageState();
}

class _CaixaPageState extends State<CaixaPage> {
  final CaixaService _caixaService = CaixaService();
  final NumberFormat _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  bool _loading = false;
  bool _carregandoResumo = false;
  CaixaStatus? _caixaStatus;
  FluxoCaixaResumo? _resumoFluxo;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  int get _pdv => ConfigController.instance.pdv.value;

  int _obterCodigoFuncionario() {
    final usuarioCtrl = Provider.of<UsuarioController>(context, listen: false);
    final codigo = usuarioCtrl.usuarioLogado.codigo;
    return codigo > 0 ? codigo : 1;
  }

  String _obterNomeFuncionario() {
    final usuarioCtrl = Provider.of<UsuarioController>(context, listen: false);
    final login = usuarioCtrl.usuarioLogado.login.trim();
    return login.isNotEmpty ? login : 'Operador';
  }

  Future<void> _carregarDados() async {
    setState(() => _carregandoResumo = true);
    try {
      final status = await FluxoCaixaService.status(pdv: _pdv);
      FluxoCaixaResumo? resumo;

      if (status.aberto) {
        final hoje = DateTime.now();
        DateTime dataInicio = hoje;
        if (status.dataAbertura != null && status.dataAbertura!.trim().isNotEmpty) {
          try {
            final dtParsed = DateTime.parse(status.dataAbertura!.trim());
            if (dtParsed.isBefore(hoje)) {
              dataInicio = dtParsed;
            }
          } catch (_) {
            dataInicio = hoje;
          }
        }

        resumo = await FluxoCaixaService.listar(
          dataInicio: dataInicio,
          dataFim: hoje,
          pdv: _pdv,
        );
      }

      if (mounted) {
        setState(() {
          _caixaStatus = status;
          _resumoFluxo = resumo;
          _carregandoResumo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregandoResumo = false);
        _mostrarMensagem('Erro ao carregar dados do caixa: $e', isError: true);
      }
    }
  }

  double get _totalSuprimentos {
    if (_resumoFluxo == null) return 0.0;
    return _resumoFluxo!.itens
        .where((item) =>
            item.credito > 0 &&
            (item.descricao.toUpperCase().contains('SUPRIMENTO') ||
                item.nome.toUpperCase().contains('SUPRIMENTO')))
        .fold(0.0, (acc, item) => acc + item.credito);
  }

  double get _totalSangrias {
    if (_resumoFluxo == null) return 0.0;
    return _resumoFluxo!.itens
        .where((item) =>
            item.debito > 0 &&
            (item.descricao.toUpperCase().contains('SANGRIA') ||
                item.nome.toUpperCase().contains('SANGRIA')))
        .fold(0.0, (acc, item) => acc + item.debito);
  }

  double get _totalVendas {
    if (_resumoFluxo == null) return 0.0;
    return _resumoFluxo!.itens
        .where((item) =>
            item.credito > 0 &&
            !item.descricao.toUpperCase().contains('SUPRIMENTO') &&
            !item.nome.toUpperCase().contains('SUPRIMENTO'))
        .fold(0.0, (acc, item) => acc + item.credito);
  }

  double get _totalOutrosDebitos {
    if (_resumoFluxo == null) return 0.0;
    return _resumoFluxo!.itens
        .where((item) =>
            item.debito > 0 &&
            !item.descricao.toUpperCase().contains('SANGRIA') &&
            !item.nome.toUpperCase().contains('SANGRIA'))
        .fold(0.0, (acc, item) => acc + item.debito);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAberto = _caixaStatus?.aberto ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.aberturaInicial ? 'Abertura de Caixa' : 'Gerenciamento de Caixa',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Constants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Atualizar informações',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregandoResumo ? null : _carregarDados,
          ),
        ],
      ),
      body: SafeArea(
        child: _carregandoResumo && _caixaStatus == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _carregarDados,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCardIdentificacao(isAberto),
                          const SizedBox(height: 16),
                          if (!isAberto) ...[
                            _buildCardCaixaFechado(),
                          ] else ...[
                            _buildPainelResumoFechamento(),
                            const SizedBox(height: 20),
                            _buildBotoesOperacoes(),
                            const SizedBox(height: 24),
                            _buildExtratoMovimentacoes(),
                          ],
                          if (_loading) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCardIdentificacao(bool isAberto) {
    final String nomeFuncionario = _obterNomeFuncionario();
    final int codFuncionario = _obterCodigoFuncionario();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isAberto
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.point_of_sale,
                    size: 30,
                    color: isAberto ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terminal PDV $_pdv',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Operador: $nomeFuncionario (Cód. $codFuncionario)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAberto ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAberto ? Colors.green : Colors.red,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAberto ? Icons.check_circle : Icons.lock,
                        size: 16,
                        color: isAberto ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAberto ? 'CAIXA ABERTO' : 'CAIXA FECHADO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAberto ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAberto && _caixaStatus != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Caixa Nº: ${_caixaStatus!.caixa ?? "-"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Aberto em: ${_formatarDataAbertura(_caixaStatus!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatarDataAbertura(CaixaStatus status) {
    if (status.dataAbertura == null) return '-';
    final data = status.dataAbertura!;
    final hora = status.horaAbertura ?? '';
    return '$data $hora'.trim();
  }

  Widget _buildCardCaixaFechado() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Icon(Icons.lock_clock, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            const Text(
              'O caixa deste terminal está FECHADO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Para iniciar os registros de vendas, sangrias e suprimentos, efetue a abertura do caixa para o PDV $_pdv.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _executarAbertura,
                icon: const Icon(Icons.lock_open, size: 22),
                label: const Text(
                  'ABRIR CAIXA AGORA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPainelResumoFechamento() {
    final double saldo = _resumoFluxo?.saldo ?? 0.0;
    final double totalCredito = _resumoFluxo?.totalCredito ?? 0.0;
    final double totalDebito = _resumoFluxo?.totalDebito ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resumo do Caixa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_carregandoResumo)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Card Principal com o Saldo em Gaveta
        Card(
          elevation: 2,
          color: saldo >= 0 ? Colors.green[50] : Colors.red[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: saldo >= 0 ? Colors.green[300]! : Colors.red[300]!,
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: saldo >= 0 ? Colors.green[700] : Colors.red[700],
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALDO DISPONÍVEL EM GAVETA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: saldo >= 0 ? Colors.green[900] : Colors.red[900],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _moneyFormat.format(saldo),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: saldo >= 0 ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Cards detalhados de Totais de Entradas e Saídas
        Row(
          children: [
            Expanded(
              child: _buildItemResumo(
                titulo: 'Total Entradas',
                valor: totalCredito,
                cor: Colors.teal[700]!,
                icone: Icons.arrow_downward,
                detalhes: 'Vendas: ${_moneyFormat.format(_totalVendas)}\nSuprimentos: ${_moneyFormat.format(_totalSuprimentos)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildItemResumo(
                titulo: 'Total Saídas',
                valor: totalDebito,
                cor: Colors.deepOrange[700]!,
                icone: Icons.arrow_upward,
                detalhes: 'Sangrias: ${_moneyFormat.format(_totalSangrias)}\nOutras: ${_moneyFormat.format(_totalOutrosDebitos)}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemResumo({
    required String titulo,
    required double valor,
    required Color cor,
    required IconData icone,
    required String detalhes,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: cor),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _moneyFormat.format(valor),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor),
            ),
            const Divider(height: 14),
            Text(
              detalhes,
              style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesOperacoes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operações de Caixa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Realize suprimentos (depósito de troco) e sangrias (saques para cofre/despesas) como no módulo financeiro.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Botão Suprimento / Depósito
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _abrirDialogoOperacao(tipo: 'SUPRIMENTO'),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Depósito (Suprimento)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botão Sangria / Saque
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _abrirDialogoOperacao(tipo: 'SANGRIA'),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    label: const Text(
                      'Saque (Sangria)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Botão Fechar Caixa
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _abrirDialogoFechamento,
                icon: const Icon(Icons.lock, size: 20),
                label: const Text(
                  'FECHAR O CAIXA (RESUMO FINAL)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[800],
                  side: BorderSide(color: Colors.red[700]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtratoMovimentacoes() {
    final itens = _resumoFluxo?.itens ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimas Movimentações',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${itens.length} registro(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(height: 20),
            if (itens.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Nenhuma movimentação registrada no caixa de hoje.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itens.length > 10 ? 10 : itens.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = itens[index];
                  final bool isCredito = item.credito > 0;
                  final valor = isCredito ? item.credito : item.debito;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isCredito
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      child: Icon(
                        isCredito ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 16,
                        color: isCredito ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    title: Text(
                      item.descricao.isNotEmpty ? item.descricao : item.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      item.dataHora.isNotEmpty ? item.dataHora.replaceAll('T', ' ') : item.data,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      '${isCredito ? "+" : "-"} ${_moneyFormat.format(valor)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isCredito ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _executarAbertura() async {
    final pdv = _pdv;
    final fun = _obterCodigoFuncionario();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Abertura'),
        content: Text(
          'Deseja abrir o caixa para o PDV $pdv com o operador ${_obterNomeFuncionario()} (Cód. $fun)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abrir Caixa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _caixaService.abrirCaixa(pdv: pdv, fun: fun);
      _mostrarMensagem('Caixa aberto com sucesso!');
      widget.onStatusChanged?.call();
      await _carregarDados();

      if (widget.aberturaInicial && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirDialogoOperacao({required String tipo}) async {
    final bool isSuprimento = tipo == 'SUPRIMENTO';
    final TextEditingController valorController = TextEditingController();
    final TextEditingController motivoController = TextEditingController(
      text: isSuprimento ? 'Suprimento de troco' : 'Sangria de caixa',
    );

    final double saldoGaveta = _resumoFluxo?.saldo ?? 0.0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double valorDigitado =
                double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
            final bool sangriaMaior = !isSuprimento && valorDigitado > saldoGaveta;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isSuprimento
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.amber.withValues(alpha: 0.15),
                    child: Icon(
                      isSuprimento ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isSuprimento ? Colors.blue[700] : Colors.amber[900],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isSuprimento ? 'Depósito (Suprimento)' : 'Saque (Sangria)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PDV: $_pdv', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Operador: ${_obterNomeFuncionario()}'),
                        ],
                      ),
                    ),
                    if (!isSuprimento) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Saldo atual em gaveta: ${_moneyFormat.format(saldoGaveta)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: saldoGaveta > 0 ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: r'Valor (R$) *',
                        prefixText: r'R$ ',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    if (sangriaMaior) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Atenção: O valor da sangria excede o saldo atual em gaveta!',
                        style: TextStyle(color: Colors.red[700], fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Justificativa / Motivo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sugestões de motivos
                    Wrap(
                      spacing: 6,
                      children: (isSuprimento
                              ? ['Troco inicial', 'Fundo adicional', 'Moedas']
                              : ['Sangria para cofre', 'Pagamento fornecedor', 'Despesa avulsa'])
                          .map(
                            (sugestao) => ActionChip(
                              label: Text(sugestao, style: const TextStyle(fontSize: 11)),
                              onPressed: () {
                                motivoController.text = sugestao;
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuprimento ? Colors.blue[700] : Colors.amber[900],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final valor = double.tryParse(
                      valorController.text.trim().replaceAll(',', '.'),
                    );
                    if (valor == null || valor <= 0) {
                      _mostrarMensagem('Informe um valor válido maior que zero.', isError: true);
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Confirmar Operação'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    final valor = double.tryParse(valorController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final motivo = motivoController.text.trim();

    setState(() => _loading = true);
    try {
      await FluxoCaixaService.lancar(
        tipo: tipo,
        valor: valor,
        descricao: motivo,
        pdv: _pdv,
      );

      _mostrarMensagem(
        '${isSuprimento ? "Suprimento" : "Sangria"} de ${_moneyFormat.format(valor)} realizado com sucesso!',
      );
      await _carregarDados();
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirDialogoFechamento() async {
    final double saldoEsperado = _resumoFluxo?.saldo ?? 0.0;
    final double totalEntradas = _resumoFluxo?.totalCredito ?? 0.0;
    final double totalSaidas = _resumoFluxo?.totalDebito ?? 0.0;

    final TextEditingController gavetaController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double valorGaveta =
                double.tryParse(gavetaController.text.trim().replaceAll(',', '.')) ?? 0.0;
            final bool informouGaveta = gavetaController.text.trim().isNotEmpty;
            final double diferenca = valorGaveta - saldoEsperado;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    child: Icon(Icons.lock, color: Colors.red[800], size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Fechamento de Caixa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho da sessão
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Terminal: PDV $_pdv',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Caixa: #${_caixaStatus?.caixa ?? "-"}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Operador: ${_obterNomeFuncionario()} (Cód. ${_obterCodigoFuncionario()})'),
                            Text('Abertura: ${_formatarDataAbertura(_caixaStatus!)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Resumo dos Totais (UnitFechamentoCaixa.pas)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildLinhaTotaisFechamento('(+) Total de Entradas', totalEntradas, Colors.teal[800]!),
                            const SizedBox(height: 6),
                            _buildLinhaTotaisFechamento('(-) Total de Saídas', totalSaidas, Colors.red[800]!),
                            const Divider(height: 16),
                            _buildLinhaTotaisFechamento(
                              '(=) Saldo Calculado do Sistema',
                              saldoEsperado,
                              Colors.black87,
                              isDestaque: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Campo de Conferência de Gaveta Física
                      const Text(
                        'Conferência da Gaveta Física (Opcional):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: gavetaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: r'Valor Contado em Gaveta (R$)',
                          prefixText: r'R$ ',
                          border: const OutlineInputBorder(),
                          hintText: '0,00',
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      if (informouGaveta) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: diferenca.abs() < 0.01
                                ? Colors.green[50]
                                : (diferenca > 0 ? Colors.blue[50] : Colors.red[50]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: diferenca.abs() < 0.01
                                  ? Colors.green
                                  : (diferenca > 0 ? Colors.blue : Colors.red),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                diferenca.abs() < 0.01
                                    ? '✓ Gaveta confere com o sistema'
                                    : (diferenca > 0 ? 'Sobra em gaveta:' : 'Falta em gaveta:'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: diferenca.abs() < 0.01
                                      ? Colors.green[800]
                                      : (diferenca > 0 ? Colors.blue[800] : Colors.red[800]),
                                ),
                              ),
                              Text(
                                _moneyFormat.format(diferenca.abs()),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: diferenca.abs() < 0.01
                                      ? Colors.green[800]
                                      : (diferenca > 0 ? Colors.blue[800] : Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  label: const Text('Confirmar Fechamento'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    final pdv = _pdv;
    final fun = _obterCodigoFuncionario();

    setState(() => _loading = true);
    try {
      await _caixaService.fecharCaixa(pdv: pdv, fun: fun);
      _mostrarMensagem('Caixa fechado com sucesso!');
      widget.onStatusChanged?.call();
      await _carregarDados();

      if (widget.aberturaInicial && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildLinhaTotaisFechamento(
    String label,
    double valor,
    Color cor, {
    bool isDestaque = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDestaque ? 14 : 13,
            fontWeight: isDestaque ? FontWeight.bold : FontWeight.w500,
            color: isDestaque ? Colors.black87 : Colors.grey[800],
          ),
        ),
        Text(
          _moneyFormat.format(valor),
          style: TextStyle(
            fontSize: isDestaque ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red[800] : Colors.green[800],
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
