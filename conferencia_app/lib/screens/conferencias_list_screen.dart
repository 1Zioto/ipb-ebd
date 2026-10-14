import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';
import '../widgets/app_drawer.dart';
import 'conferencia_detalhes_screen.dart';
import 'home_screen.dart';

class ConferenciasListScreen extends StatefulWidget {
  const ConferenciasListScreen({super.key});

  @override
  State<ConferenciasListScreen> createState() => _ConferenciasListScreenState();
}

class _ConferenciasListScreenState extends State<ConferenciasListScreen> {
  final _searchController = TextEditingController();
  List<ColetaModel> _conferencias = [];
  bool _loading = true;
  String _statusFilter = 'todos'; // 'todos', 'em_andamento', 'encerrada'
  int _totalAbertas = 0;
  int _totalEncerradas = 0;
  double _totalArrecadadoGeral = 0.0;

  @override
  void initState() {
    super.initState();
    _loadConferencias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConferencias() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.getConferencias(
        status: _statusFilter,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _conferencias = list;
          if (_statusFilter == 'todos') {
            _totalAbertas = list.where((c) => c.isAberta).length;
            _totalEncerradas = list.where((c) => !c.isAberta).length;
            _totalArrecadadoGeral = list.fold(0.0, (sum, c) => sum + c.totalGeral);
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar conferências: $e')),
        );
      }
    }
  }

  void _openNovaConferenciaDialog() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final dateDisplay = DateFormat('dd/MM/yyyy').format(now);
    final cultoController = TextEditingController(text: 'Culto de Domingo');
    final descController = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline, color: Color(0xFF047857)),
              ),
              const SizedBox(width: 12),
              const Text('Nova Conferência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data da Conferência', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Text(dateDisplay, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      const Text('(Hoje)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Culto / Evento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(
                  controller: cultoController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Culto Noturno, Escola Dominical',
                    prefixIcon: const Icon(Icons.church_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Observações / Finalidade (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Anotações da comissão ou diaconato',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setDlgState(() => saving = true);
                      try {
                        final nova = await ApiService.instance.createConferencia(
                          date: dateStr,
                          serviceMeeting: cultoController.text.trim().isEmpty ? 'Culto de Domingo' : cultoController.text.trim(),
                          description: descController.text.trim(),
                        );
                        if (!mounted) return;
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        // Abrir diretamente a conferência para lançamento
                        _abrirConferencia(nova);
                      } catch (e) {
                        setDlgState(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Criar e Iniciar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirConferencia(ColetaModel conf) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeScreen(coleta: conf),
      ),
    );
    _loadConferencias();
  }

  void _verDetalhesConferencia(ColetaModel conf) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConferenciaDetalhesScreen(coleta: conf),
      ),
    );
    _loadConferencias();
  }

  Future<void> _verComprovante(ColetaModel conf, {bool reimprimir = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final comprovante = await ApiService.instance.getComprovante(conf.id, reimprimir: reimprimir);
      if (!mounted) return;
      Navigator.of(context).pop(); // fecha loading

      if (comprovante.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comprovante não disponível no servidor.')),
        );
        return;
      }

      _showComprovanteDialog(conf, comprovante);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar comprovante: $e')),
      );
    }
  }

  void _showComprovanteDialog(ColetaModel conf, Map<String, dynamic> comprovante) {
    bool printing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final totais = comprovante['totais'] is Map ? comprovante['totais'] as Map<String, dynamic> : <String, dynamic>{};
          final resumo = comprovante['resumo_geral'] is Map ? comprovante['resumo_geral'] as Map<String, dynamic> : <String, dynamic>{};
          final dizimos = comprovante['dizimos'] is Map ? comprovante['dizimos'] as Map<String, dynamic> : <String, dynamic>{};
          final ofertas = comprovante['ofertas_avulsas'] is Map ? comprovante['ofertas_avulsas'] as Map<String, dynamic> : <String, dynamic>{};
          final totDiz = asDouble(resumo['total_dizimos'] ?? dizimos['total'] ?? totais['dizimos'], conf.totalDizimos);
          final totOf = asDouble(resumo['total_ofertas'] ?? ofertas['total'] ?? totais['ofertas'], conf.totalOfertas);
          final totGeral = asDouble(resumo['total_geral'] ?? totais['geral'], conf.totalGeral);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF047857)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Comprovante ${conf.code}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'IGREJA PRESBITERIANA DO BRASIL',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Center(
                            child: Text(
                              'CONFERÊNCIA DE ARRECADAÇÃO',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          const Divider(height: 18),
                          _buildReceiptRow('Conferência:', conf.code),
                          _buildReceiptRow('Data:', conf.date),
                          _buildReceiptRow('Culto:', conf.serviceMeeting),
                          _buildReceiptRow('Responsável:', conf.closerName ?? conf.creatorName ?? 'Diácono'),
                          _buildReceiptRow('Envelopes:', '${conf.entryCount} envelopes'),
                          const Divider(height: 18),
                          _buildReceiptRow('Total Dízimos:', 'R\$ ${totDiz.toStringAsFixed(2).replaceAll('.', ',')}', isBold: true),
                          _buildReceiptRow('Total Ofertas:', 'R\$ ${totOf.toStringAsFixed(2).replaceAll('.', ',')}', isBold: true),
                          const Divider(height: 18),
                          _buildReceiptRow('TOTAL GERAL:', 'R\$ ${totGeral.toStringAsFixed(2).replaceAll('.', ',')}', isBold: true, color: const Color(0xFF047857)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Impressão obrigatória em 2 vias (1ª Via Tesouraria / 2ª Via Arquivo da Igreja).',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: printing
                    ? null
                    : () async {
                        setDlgState(() => printing = true);
                        try {
                          await ThermalPrinterService.instance.printDuasViasConferencia(comprovante);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comprovante em 2 vias impresso com sucesso!'),
                              backgroundColor: Color(0xFF047857),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Impressão POS: $e'),
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        } finally {
                          setDlgState(() => printing = false);
                        }
                      },
                icon: printing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.print, size: 18),
                label: Text(printing ? 'Imprimindo...' : 'Imprimir 2 Vias (POS)'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _conferencias.where((c) {
      if (_statusFilter == 'em_andamento' || _statusFilter == 'aberta') {
        return c.isAberta;
      } else if (_statusFilter == 'encerrada' || _statusFilter == 'fechada') {
        return !c.isAberta;
      }
      return true;
    }).toList();

    final abertas = _statusFilter == 'todos' && _totalAbertas > 0
        ? _totalAbertas
        : _conferencias.where((c) => c.isAberta).length;
    final encerradas = _statusFilter == 'todos' && _totalEncerradas > 0
        ? _totalEncerradas
        : _conferencias.where((c) => !c.isAberta).length;
    final totalGeral = _statusFilter == 'todos' && _totalArrecadadoGeral > 0
        ? _totalArrecadadoGeral
        : _conferencias.fold(0.0, (sum, c) => sum + c.totalGeral);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: 'conferencia'),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conferências', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Dízimos e Ofertas da Igreja', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadConferencias,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Nova Conferência', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openNovaConferenciaDialog,
      ),
      body: Column(
        children: [
          // CARDS COM INDICADORES
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Em Andamento',
                    value: '$abertas',
                    color: const Color(0xFF047857),
                    icon: Icons.timelapse,
                    isSelected: _statusFilter == 'em_andamento',
                    onTap: () {
                      setState(() => _statusFilter = _statusFilter == 'em_andamento' ? 'todos' : 'em_andamento');
                      _loadConferencias();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Encerradas',
                    value: '$encerradas',
                    color: const Color(0xFF64748B),
                    icon: Icons.check_circle_outline,
                    isSelected: _statusFilter == 'encerrada',
                    onTap: () {
                      setState(() => _statusFilter = _statusFilter == 'encerrada' ? 'todos' : 'encerrada');
                      _loadConferencias();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Arrecadado',
                    value: 'R\$ ${NumberFormat.compactCurrency(locale: 'pt_BR', symbol: '').format(totalGeral)}',
                    color: const Color(0xFF0284C7),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ),

          // FILTROS & BUSCA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadConferencias(),
                    decoration: InputDecoration(
                      hintText: 'Buscar código, culto ou responsável...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadConferencias();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // STATUS TABS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildStatusChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildStatusChip('Em Andamento', 'em_andamento'),
                const SizedBox(width: 8),
                _buildStatusChip('Encerradas', 'encerrada'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // LISTAGEM DE CONFERÊNCIAS
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : displayedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _statusFilter == 'todos'
                                  ? 'Nenhuma conferência encontrada'
                                  : (_statusFilter == 'em_andamento'
                                      ? 'Nenhuma conferência em andamento'
                                      : 'Nenhuma conferência encerrada'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            if (_statusFilter != 'todos')
                              TextButton(
                                onPressed: () {
                                  setState(() => _statusFilter = 'todos');
                                  _loadConferencias();
                                },
                                child: const Text('Ver todas as conferências'),
                              )
                            else
                              const Text(
                                'Clique no botão abaixo para abrir a primeira conferência.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConferencias,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: displayedList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final conf = displayedList[index];
                            return _buildConferenciaCard(conf);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? color : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF047857),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF047857) : const Color(0xFFCBD5E1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _loadConferencias();
        }
      },
    );
  }

  Widget _buildConferenciaCard(ColetaModel conf) {
    final isAberta = conf.isAberta;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAberta ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          width: isAberta ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _verDetalhesConferencia(conf);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOPO: CÓDIGO + STATUS BADGE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            conf.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conf.date,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAberta ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAberta ? const Color(0xFF34D399) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAberta ? Icons.radio_button_checked : Icons.lock_outline,
                            size: 11,
                            color: isAberta ? const Color(0xFF047857) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAberta ? 'EM ANDAMENTO' : 'ENCERRADA',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isAberta ? const Color(0xFF047857) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // CULTO E RESPONSÁVEL
                Row(
                  children: [
                    const Icon(Icons.church_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conf.serviceMeeting,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      'Resp: ${conf.closerName ?? conf.creatorName ?? 'Diácono Responsável'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),

                const Divider(height: 20),

                // DADOS FINANCEIROS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Envelopes', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        Text(
                          '${conf.entryCount} un',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dízimos', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        Text(
                          'R\$ ${conf.totalDizimos.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ofertas Avulsas', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        Text(
                          'R\$ ${conf.totalOfertas.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Geral', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        Text(
                          'R\$ ${conf.totalGeral.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BOTÕES DE AÇÃO
                Row(
                  children: [
                    if (isAberta) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _verDetalhesConferencia(conf),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Ver Envelopes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                          ),
                          onPressed: () => _abrirConferencia(conf),
                          icon: const Icon(Icons.qr_code_scanner, size: 16),
                          label: const Text('Lançar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _verDetalhesConferencia(conf),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Ver Envelopes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                          ),
                          onPressed: () => _verComprovante(conf, reimprimir: true),
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Reimprimir', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
