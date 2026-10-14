import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';
import 'home_screen.dart';

class ConferenciaDetalhesScreen extends StatefulWidget {
  final ColetaModel coleta;

  const ConferenciaDetalhesScreen({
    super.key,
    required this.coleta,
  });

  @override
  State<ConferenciaDetalhesScreen> createState() => _ConferenciaDetalhesScreenState();
}

class _ConferenciaDetalhesScreenState extends State<ConferenciaDetalhesScreen> {
  late ColetaModel _coleta;
  List<EnvelopeEntry> _entries = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFormaFilter = 'todos'; // 'todos', 'dinheiro', 'pix', 'transferencia'
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _coleta = widget.coleta;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.instance.getConferenciaDetails(_coleta.id);
      if (!mounted) return;

      if (data['coleta'] != null) {
        _coleta = data['coleta'] as ColetaModel;
      }
      if (data['entries'] != null && data['entries'] is List<EnvelopeEntry>) {
        _entries = data['entries'] as List<EnvelopeEntry>;
      }
    } catch (e) {
      if (!mounted) return;
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<EnvelopeEntry> get _filteredEntries {
    return _entries.where((e) {
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          e.membro.toLowerCase().contains(q) ||
          (e.envelopeNumber != null && e.envelopeNumber!.toLowerCase().contains(q)) ||
          e.valor.toStringAsFixed(2).contains(q);

      final matchForma = _selectedFormaFilter == 'todos' ||
          e.forma.toLowerCase() == _selectedFormaFilter.toLowerCase();

      return matchQuery && matchForma;
    }).toList();
  }

  double get _totalDinheiroEnvelopes {
    return _entries
        .where((e) => e.forma.toLowerCase().contains('dinheiro'))
        .fold(0.0, (acc, e) => acc + e.valor);
  }

  double get _totalPixEnvelopes {
    return _entries
        .where((e) => e.forma.toLowerCase().contains('pix'))
        .fold(0.0, (acc, e) => acc + e.valor);
  }

  double get _totalTransfEnvelopes {
    return _entries
        .where((e) =>
            e.forma.toLowerCase().contains('transf') ||
            e.forma.toLowerCase().contains('cart'))
        .fold(0.0, (acc, e) => acc + e.valor);
  }

  Future<void> _imprimirDuasVias() async {
    setState(() => _printing = true);
    try {
      Map<String, dynamic> comp = {};
      try {
        comp = await ApiService.instance.getComprovante(_coleta.id);
      } catch (_) {}

      if (comp.isEmpty) {
        comp = _buildLocalComprovante();
      }

      await ThermalPrinterService.instance.printDuasViasConferencia(comp);
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
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _imprimirEnvelopeIndividual(EnvelopeEntry entry) async {
    try {
      await ThermalPrinterService.instance.printEnvelope(
        membro: entry.membro,
        destinacao: entry.destinacao,
        forma: entry.forma,
        valor: entry.valor,
        id: entry.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recibo do envelope de ${entry.membro} impresso!'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao imprimir envelope: $e'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  Map<String, dynamic> _buildLocalComprovante() {
    final itens = _entries.map((e) => {
      'id': e.id,
      'envelope': e.envelopeNumber,
      'contribuinte': e.membro,
      'membro': e.membro,
      'valor': e.valor,
      'amount': e.valor,
      'forma': e.forma.toUpperCase(),
      'payment_method': e.forma.toLowerCase(),
    }).toList();

    final totDiz = _coleta.totalDizimos > 0 ? _coleta.totalDizimos : _entries.fold(0.0, (acc, e) => acc + e.valor);
    final totGeral = _coleta.totalGeral > 0 ? _coleta.totalGeral : totDiz + _coleta.totalOfertas;

    return {
      'conferencia': {
        'id': _coleta.id,
        'code': _coleta.code,
        'date': _coleta.date,
        'data': _coleta.date,
        'culto': _coleta.serviceMeeting,
        'service_meeting': _coleta.serviceMeeting,
        'status': _coleta.status,
        'entry_count': _entries.length,
        'opened_at': _coleta.openedAt ?? '',
        'closed_at': _coleta.closedAt ?? '',
        'responsavel_abertura': _coleta.creatorName ?? 'Diácono Responsável',
        'responsavel_encerramento': _coleta.closerName ?? _coleta.creatorName ?? 'Diácono Responsável',
        'closer_name': _coleta.closerName ?? _coleta.creatorName ?? 'Diácono Responsável',
        'creator_name': _coleta.creatorName ?? 'Diácono Responsável',
        'total_dizimos': totDiz,
        'total_ofertas': _coleta.totalOfertas,
        'total_geral': totGeral,
      },
      'instituicao': {
        'nome': 'Igreja Presbiteriana do Brasil',
      },
      'church_name': 'Igreja Presbiteriana do Brasil',
      'lancamentos': itens,
      'dizimos': {
        'itens': itens,
        'quantidade_envelopes': _entries.length,
        'total_dinheiro': _totalDinheiroEnvelopes,
        'total_pix': _totalPixEnvelopes,
        'total_transferencia': _totalTransfEnvelopes,
        'total': totDiz,
      },
      'ofertas_avulsas': {
        'dinheiro': _coleta.ofertaDinheiro,
        'pix': _coleta.ofertaPix,
        'transferencia': _coleta.ofertaTransferencia,
        'total': _coleta.totalOfertas,
      },
      'totais': {
        'dizimos': totDiz,
        'ofertas': _coleta.totalOfertas,
        'geral': totGeral,
      },
      'resumo_geral': {
        'total_dizimos': totDiz,
        'total_ofertas': _coleta.totalOfertas,
        'total_geral': totGeral,
      },
      'por_recebimento': {
        'dinheiro': _totalDinheiroEnvelopes + _coleta.ofertaDinheiro,
        'pix': _totalPixEnvelopes + _coleta.ofertaPix,
        'transferencia': _totalTransfEnvelopes + _coleta.ofertaTransferencia,
        'geral': totGeral,
      },
      'consolidado_recebimento': {
        'dinheiro': _totalDinheiroEnvelopes + _coleta.ofertaDinheiro,
        'pix': _totalPixEnvelopes + _coleta.ofertaPix,
        'transferencia': _totalTransfEnvelopes + _coleta.ofertaTransferencia,
        'total_geral': totGeral,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final isAberta = _coleta.isAberta;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _coleta.code,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${_coleta.date} • ${_coleta.serviceMeeting}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadDetails,
          ),
          IconButton(
            tooltip: 'Imprimir 2 Vias (POS)',
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.print),
            onPressed: _printing ? null : _imprimirDuasVias,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF047857)),
                  SizedBox(height: 14),
                  Text('Carregando envelopes da conferência...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDetails,
              color: const Color(0xFF047857),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aviso ao buscar dados online: $_error',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // CABEÇALHO COM STATUS E METADADOS
                  _buildHeaderCard(isAberta),
                  const SizedBox(height: 16),

                  // CARDS DE RESUMO FINANCEIRO
                  _buildFinancialSummary(),
                  const SizedBox(height: 16),

                  // OFERTAS AVULSAS (se houver)
                  if (_coleta.totalOfertas > 0) ...[
                    _buildOfertasAvulsasCard(),
                    const SizedBox(height: 16),
                  ],

                  // BARRA DE PESQUISA E FILTROS DE ENVELOPES
                  _buildSearchAndFilters(),
                  const SizedBox(height: 12),

                  // CABEÇALHO DA LISTAGEM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Envelopes Lançados (${_filteredEntries.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (_entries.isNotEmpty && _filteredEntries.length != _entries.length)
                        Text(
                          'Total: ${_entries.length}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // LISTA DOS ENVELOPES
                  if (_filteredEntries.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredEntries.map(_buildEnvelopeCard),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(isAberta),
    );
  }

  Widget _buildHeaderCard(bool isAberta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      _coleta.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _coleta.date,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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
                      size: 12,
                      color: isAberta ? const Color(0xFF047857) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAberta ? 'EM ANDAMENTO' : 'ENCERRADA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAberta ? const Color(0xFF047857) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.church_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _coleta.serviceMeeting,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Responsável: ${_coleta.closerName ?? _coleta.creatorName ?? 'Diácono Responsável'}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          if (_coleta.openedAt != null || _coleta.closedAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Aberto: ${_coleta.openedAt ?? '-'} • Fechado: ${_coleta.closedAt ?? '-'}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final totDiz = _coleta.totalDizimos > 0 ? _coleta.totalDizimos : _entries.fold(0.0, (acc, e) => acc + e.valor);
    final totGeral = _coleta.totalGeral > 0 ? _coleta.totalGeral : totDiz + _coleta.totalOfertas;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO FINANCEIRO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),

          // TOTAL GERAL BANNER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL GERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF047857))),
                    Text('Arrecadação total', style: TextStyle(fontSize: 10.5, color: Color(0xFF065F46))),
                  ],
                ),
                Text(
                  'R\$ ${totGeral.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // SUBTOTAIS (DÍZIMOS E OFERTAS)
          Row(
            children: [
              Expanded(
                child: _buildMiniTotalBox(
                  label: 'Dízimos (Envelopes)',
                  sublabel: '${_entries.length} envelopes',
                  value: 'R\$ ${totDiz.toStringAsFixed(2).replaceAll('.', ',')}',
                  color: const Color(0xFF047857),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniTotalBox(
                  label: 'Ofertas Avulsas',
                  sublabel: 'Salva / Gazofilácio',
                  value: 'R\$ ${_coleta.totalOfertas.toStringAsFixed(2).replaceAll('.', ',')}',
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // CONSOLIDADO POR FORMA
          const Text(
            'Consolidado por Meio de Pagamento:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFormaBadge('💵 Dinheiro', _totalDinheiroEnvelopes + _coleta.ofertaDinheiro),
              const SizedBox(width: 8),
              _buildFormaBadge('📱 Pix', _totalPixEnvelopes + _coleta.ofertaPix),
              const SizedBox(width: 8),
              _buildFormaBadge('🏦 Transf', _totalTransfEnvelopes + _coleta.ofertaTransferencia),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTotalBox({
    required String label,
    required String sublabel,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          Text(sublabel, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildFormaBadge(String label, double val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              'R\$ ${val.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfertasAvulsasCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.volunteer_activism_outlined, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'OFERTAS AVULSAS DA SALVA',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_coleta.ofertaDinheiro > 0)
                Text('Espécie: R\$ ${_coleta.ofertaDinheiro.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
              if (_coleta.ofertaPix > 0)
                Text('Pix: R\$ ${_coleta.ofertaPix.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
              if (_coleta.ofertaTransferencia > 0)
                Text('Transf: R\$ ${_coleta.ofertaTransferencia.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // CAMPO DE BUSCA
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por membro, envelope ou valor...',
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 8),

        // FILTROS DE FORMA
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Todos', 'todos'),
              const SizedBox(width: 6),
              _buildFilterChip('Dinheiro', 'dinheiro'),
              const SizedBox(width: 6),
              _buildFilterChip('Pix', 'pix'),
              const SizedBox(width: 6),
              _buildFilterChip('Transferência', 'transferencia'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFormaFilter == value;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF047857),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF047857) : const Color(0xFFCBD5E1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (_) => setState(() => _selectedFormaFilter = value),
    );
  }

  Widget _buildEnvelopeCard(EnvelopeEntry entry) {
    final formaLower = entry.forma.toLowerCase();
    Color formaColor = const Color(0xFF047857);
    IconData formaIcon = Icons.payments_outlined;
    String formaLabel = 'Dinheiro';

    if (formaLower.contains('pix')) {
      formaColor = const Color(0xFF7C3AED);
      formaIcon = Icons.qr_code;
      formaLabel = 'Pix';
    } else if (formaLower.contains('transf') || formaLower.contains('cart')) {
      formaColor = const Color(0xFF0284C7);
      formaIcon = Icons.account_balance;
      formaLabel = 'Transf.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // BADGE DO ENVELOPE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mail_outline, size: 16, color: Color(0xFF047857)),
                  const SizedBox(height: 2),
                  Text(
                    entry.envelopeNumber != null && entry.envelopeNumber!.isNotEmpty
                        ? '#${entry.envelopeNumber}'
                        : 'Ident.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // DADOS DO MEMBRO E DETALHES
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.membro,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // FORMA DE PAGAMENTO CHIP
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: formaColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(formaIcon, size: 11, color: formaColor),
                            const SizedBox(width: 4),
                            Text(
                              formaLabel,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: formaColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // DESTINAÇÃO
                      Text(
                        entry.destinacao.toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      if (entry.timestamp.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${entry.timestamp.contains('T') ? entry.timestamp.split('T')[1].substring(0, 5) : entry.timestamp}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // VALOR + BOTÃO IMPRIMIR RECIBO INDIVIDUAL
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${entry.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: Color(0xFF047857),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _imprimirEnvelopeIndividual(entry),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print_outlined, size: 12, color: Color(0xFF475569)),
                        SizedBox(width: 2),
                        Text('Recibo', style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Nenhum envelope corresponde à sua busca.'
                : 'Nenhum envelope lançado nesta conferência.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _searchQuery = ''),
              child: const Text('Limpar busca'),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildBottomBar(bool isAberta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (isAberta) ...[
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HomeScreen(coleta: _coleta)),
                    );
                    _loadDetails();
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Continuar Lançando', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _printing ? null : _imprimirDuasVias,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('2 Vias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _printing ? null : _imprimirDuasVias,
                  icon: _printing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print, size: 18),
                  label: Text(
                    _printing ? 'Imprimindo...' : 'Imprimir Comprovante Completo (2 Vias)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
