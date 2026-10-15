import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';

class FechamentoTab extends StatefulWidget {
  final List<EnvelopeEntry> entries;
  final Map<double, int> cashCounts;
  final VoidCallback onResetSession;
  final VoidCallback onClearSession;
  final ColetaModel? coleta;
  final Function(ColetaModel)? onColetaUpdated;

  const FechamentoTab({
    super.key,
    required this.entries,
    required this.cashCounts,
    required this.onResetSession,
    required this.onClearSession,
    this.coleta,
    this.onColetaUpdated,
  });

  @override
  State<FechamentoTab> createState() => _FechamentoTabState();
}

class _FechamentoTabState extends State<FechamentoTab> {
  final _conf1Controller = TextEditingController();
  final _conf2Controller = TextEditingController(text: 'Diaconato');
  final _cultoController = TextEditingController();

  bool _printing = false;

  @override
  void initState() {
    super.initState();
    final loggedName =
        ApiService.instance.currentUser?.name ?? 'Diácono Responsável';
    _conf1Controller.text =
        widget.coleta?.closerName ?? widget.coleta?.creatorName ?? loggedName;
    _cultoController.text = widget.coleta?.serviceMeeting ?? 'Culto de Domingo';
  }

  @override
  void dispose() {
    _conf1Controller.dispose();
    _conf2Controller.dispose();
    _cultoController.dispose();
    super.dispose();
  }

  double get totalFisico {
    double t = 0.0;
    widget.cashCounts.forEach((val, qty) => t += val * qty);
    return t;
  }

  // Total de Dízimos apurados nos lançamentos
  double get totalDizimos => widget.entries
      .where(
        (e) => e.destinacao.toLowerCase() == 'dizimo' || e.destinacao.isEmpty,
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totalDizimosDinheiro => widget.entries
      .where(
        (e) =>
            (e.destinacao.toLowerCase() == 'dizimo' || e.destinacao.isEmpty) &&
            e.forma == 'dinheiro',
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totalDizimosPix => widget.entries
      .where(
        (e) =>
            (e.destinacao.toLowerCase() == 'dizimo' || e.destinacao.isEmpty) &&
            e.forma == 'pix',
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totalDizimosTransf => widget.entries
      .where(
        (e) =>
            (e.destinacao.toLowerCase() == 'dizimo' || e.destinacao.isEmpty) &&
            (e.forma == 'transferencia' || e.forma == 'cartao'),
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  // Total de Ofertas apuradas nos lançamentos (com ou sem pessoa declarada)
  double get totalOfertas => widget.entries
      .where(
        (e) =>
            e.destinacao.toLowerCase() != 'dizimo' && e.destinacao.isNotEmpty,
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  double get ofertaDinheiro => widget.entries
      .where(
        (e) =>
            e.destinacao.toLowerCase() != 'dizimo' &&
            e.destinacao.isNotEmpty &&
            e.forma == 'dinheiro',
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  double get ofertaPix => widget.entries
      .where(
        (e) =>
            e.destinacao.toLowerCase() != 'dizimo' &&
            e.destinacao.isNotEmpty &&
            e.forma == 'pix',
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  double get ofertaTransf => widget.entries
      .where(
        (e) =>
            e.destinacao.toLowerCase() != 'dizimo' &&
            e.destinacao.isNotEmpty &&
            (e.forma == 'transferencia' || e.forma == 'cartao'),
      )
      .fold(0.0, (sum, e) => sum + e.valor);

  // Totais Gerais Arrecadados
  double get totalGeralArrecadado =>
      widget.entries.fold(0.0, (sum, e) => sum + e.valor);

  double get totalGeralDinheiro => widget.entries
      .where((e) => e.forma == 'dinheiro')
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totalGeralPix => widget.entries
      .where((e) => e.forma == 'pix')
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totalGeralTransf => widget.entries
      .where((e) => e.forma == 'transferencia' || e.forma == 'cartao')
      .fold(0.0, (sum, e) => sum + e.valor);

  double get diferencaDinheiro => totalFisico - totalGeralDinheiro;

  // WORKFLOW DE ENCERRAMENTO EM 2 ETAPAS (Sem campos manuais de oferta avulsa)
  void _openEncerramentoWorkflow() {
    int currentStep = 0;
    bool processing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // DRAG HANDLE & HEADER
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Encerramento da Conferência',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Etapa ${currentStep + 1} de 2',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: processing
                            ? null
                            : () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: (currentStep + 1) / 2,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF047857),
                ),

                // ETAPAS
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Builder(
                      builder: (_) {
                        switch (currentStep) {
                          case 0:
                            return _buildEtapa1ResumoApuracao();
                          case 1:
                            return _buildEtapa2Confirmacao();
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),

                // BOTTOM CONTROLS
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      if (currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: processing
                                ? null
                                : () => setModalState(() => currentStep--),
                            child: const Text('Voltar'),
                          ),
                        ),
                      if (currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStep == 1
                                ? Colors.red.shade700
                                : const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: processing
                              ? null
                              : () async {
                                  if (currentStep < 1) {
                                    setModalState(() => currentStep++);
                                  } else {
                                    // CONFIRMAR: offline envia um lote para revisão; online
                                    // realiza o encerramento regular da coleta já aberta.
                                    setModalState(() => processing = true);
                                    await _executarEncerramentoDefinitivo(ctx);
                                  }
                                },
                          child: processing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  currentStep == 1
                                      ? (ApiService.instance.isOffline
                                            ? 'Enviar para Aprovação'
                                            : 'Confirmar e Encerrar')
                                      : 'Avançar',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEtapa1ResumoApuracao() {
    final qtdDizimos = widget.entries
        .where(
          (e) => e.destinacao.toLowerCase() == 'dizimo' || e.destinacao.isEmpty,
        )
        .length;
    final qtdOfertas = widget.entries
        .where(
          (e) =>
              e.destinacao.toLowerCase() != 'dizimo' && e.destinacao.isNotEmpty,
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etapa 1 — Resumo da Conferência',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Valores apurados automaticamente através dos lançamentos registrados (dízimos e ofertas).',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildRowModal(
                'Lançamentos Registrados:',
                '${widget.entries.length} itens',
              ),
              const Divider(height: 16),
              _buildRowModal(
                'Dízimos ($qtdDizimos lançamentos):',
                'R\$ ${totalDizimos.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              _buildRowModal(
                'Ofertas ($qtdOfertas lançamentos):',
                'R\$ ${totalOfertas.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              const Divider(height: 20),
              _buildRowModal(
                'TOTAL GERAL APURADO:',
                'R\$ ${totalGeralArrecadado.toStringAsFixed(2).replaceAll('.', ',')}',
                isBold: true,
                color: const Color(0xFF047857),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CONSOLIDADO POR FORMA DE RECEBIMENTO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildRowModal(
                'Dinheiro em Espécie:',
                'R\$ ${totalGeralDinheiro.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              _buildRowModal(
                'Pix:',
                'R\$ ${totalGeralPix.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              _buildRowModal(
                'Transferência / Cartão:',
                'R\$ ${totalGeralTransf.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEtapa2Confirmacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 36,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deseja realmente encerrar?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      ApiService.instance.isOffline
                          ? 'O lote será salvo no dispositivo e, quando houver conexão, enviado para aprovação. Nenhuma coleta será encerrada automaticamente.'
                          : 'Após o encerramento, a conferência será bloqueada para novas edições e 2 vias do comprovante térmico serão impressas automaticamente.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'DADOS DA EMISSÃO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildRowModal(
                'Conferência:',
                widget.coleta?.code ?? 'CONF-000000',
              ),
              _buildRowModal('Culto:', _cultoController.text),
              _buildRowModal('Responsável:', _conf1Controller.text),
              _buildRowModal(
                'Total Geral:',
                'R\$ ${totalGeralArrecadado.toStringAsFixed(2).replaceAll('.', ',')}',
                isBold: true,
              ),
              _buildRowModal('Impressão:', '2 Vias (Tesouraria + Arquivo)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRowModal(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF475569),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executarEncerramentoDefinitivo(
    BuildContext modalContext,
  ) async {
    if (ApiService.instance.isOffline) {
      try {
        final now = DateTime.now();
        final date =
            widget.coleta?.date ??
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final queued = await ApiService.instance.enqueueOfflineColeta(
          entries: widget.entries,
          date: date,
          serviceMeeting: _cultoController.text.trim().isEmpty
              ? 'Culto de Domingo'
              : _cultoController.text.trim(),
          description:
              widget.coleta?.description ?? 'Conferência móvel em contingência',
          notes:
              'Conferentes: ${_conf1Controller.text.trim()} e ${_conf2Controller.text.trim()}. '
              'Total físico: R\$ ${totalFisico.toStringAsFixed(2)}.',
          ofertaDinheiro: ofertaDinheiro,
          ofertaPix: ofertaPix,
          ofertaTransferencia: ofertaTransf,
        );

        if (modalContext.mounted) Navigator.of(modalContext).pop();
        if (!mounted) return;
        widget.onClearSession();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lote ${queued.operationId.substring(0, 8)} salvo. Ele aguarda sincronização e aprovação do Conselho.',
            ),
            backgroundColor: const Color(0xFF047857),
            duration: const Duration(seconds: 6),
          ),
        );
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      } catch (e) {
        if (modalContext.mounted) Navigator.of(modalContext).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível guardar o lote offline: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    final coletaId = widget.coleta?.id;
    if (coletaId == null) {
      Navigator.of(modalContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma conferência aberta selecionada.'),
        ),
      );
      return;
    }

    try {
      // 1. Chamar API para fechar a conferência
      final res = await ApiService.instance.closeConferencia(
        coletaId,
        dinheiro: ofertaDinheiro,
        pix: ofertaPix,
        transferencia: ofertaTransf,
      );

      // Fecha modal de etapas
      if (modalContext.mounted) Navigator.of(modalContext).pop();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conferência encerrada com sucesso!'),
          backgroundColor: Color(0xFF047857),
        ),
      );

      // 2. Buscar comprovante para impressão automática das 2 vias
      try {
        Map<String, dynamic> comprovante = {};
        try {
          comprovante = await ApiService.instance.getComprovante(coletaId);
        } catch (_) {}

        if (comprovante.isEmpty) {
          comprovante = _buildLocalComprovante();
        }

        await ThermalPrinterService.instance.printDuasViasConferencia(
          comprovante,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comprovante em 2 vias impresso com sucesso!'),
              backgroundColor: Color(0xFF047857),
            ),
          );
        }
      } catch (printErr) {
        // Encerramento não falha caso impressora esteja offline
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conferência encerrada, mas a impressora POS não respondeu: $printErr',
              ),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      // Notificar atualização
      if (res['coleta'] != null && widget.onColetaUpdated != null) {
        widget.onColetaUpdated!(ColetaModel.fromJson(res['coleta']));
      }

      // Retornar à listagem de conferências
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao encerrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _buildLocalComprovante() {
    final now = DateTime.now();
    final dataHoje =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final horaAgora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final userLogado =
        ApiService.instance.currentUser?.name ?? 'Diácono Responsável';

    final itens = widget.entries
        .map(
          (e) => {
            'id': e.id,
            'envelope': e.envelopeNumber,
            'contribuinte': e.membro,
            'membro': e.membro,
            'valor': e.valor,
            'amount': e.valor,
            'forma': e.forma.toUpperCase(),
            'payment_method': e.forma.toLowerCase(),
          },
        )
        .toList();

    return {
      'conferencia': {
        'id': widget.coleta?.id ?? 0,
        'code': widget.coleta?.code ?? 'CONF-000000',
        'date': widget.coleta?.date ?? dataHoje,
        'data': widget.coleta?.date ?? dataHoje,
        'culto': _cultoController.text.trim(),
        'service_meeting': _cultoController.text.trim(),
        'status': widget.coleta?.status ?? 'Encerrada',
        'entry_count': widget.entries.length,
        'opened_at': widget.coleta?.openedAt ?? '$dataHoje $horaAgora',
        'closed_at': widget.coleta?.closedAt ?? '$dataHoje $horaAgora',
        'responsavel_abertura': widget.coleta?.creatorName ?? userLogado,
        'responsavel_encerramento': _conf1Controller.text.trim().isNotEmpty
            ? _conf1Controller.text.trim()
            : userLogado,
        'closer_name': _conf1Controller.text.trim().isNotEmpty
            ? _conf1Controller.text.trim()
            : userLogado,
        'creator_name': widget.coleta?.creatorName ?? userLogado,
        'conferente_duplo': _conf2Controller.text.trim(),
        'total_dizimos': totalDizimos,
        'total_ofertas': totalOfertas,
        'total_geral': totalGeralArrecadado,
      },
      'instituicao': {'nome': 'Igreja Presbiteriana do Brasil'},
      'church_name': 'Igreja Presbiteriana do Brasil',
      'lancamentos': itens,
      'dizimos': {
        'itens': itens,
        'quantidade_envelopes': widget.entries.length,
        'total_dinheiro': totalDizimosDinheiro,
        'total_pix': totalDizimosPix,
        'total_transferencia': totalDizimosTransf,
        'total': totalDizimos,
      },
      'ofertas_avulsas': {
        'dinheiro': ofertaDinheiro,
        'pix': ofertaPix,
        'transferencia': ofertaTransf,
        'total': totalOfertas,
      },
      'totais': {
        'dizimos': totalDizimos,
        'ofertas': totalOfertas,
        'geral': totalGeralArrecadado,
      },
      'resumo_geral': {
        'total_dizimos': totalDizimos,
        'total_ofertas': totalOfertas,
        'total_geral': totalGeralArrecadado,
      },
      'por_recebimento': {
        'dinheiro': totalGeralDinheiro,
        'pix': totalGeralPix,
        'transferencia': totalGeralTransf,
        'geral': totalGeralArrecadado,
      },
      'consolidado_recebimento': {
        'dinheiro': totalGeralDinheiro,
        'pix': totalGeralPix,
        'transferencia': totalGeralTransf,
        'total_geral': totalGeralArrecadado,
      },
    };
  }

  Future<void> _handlePrintPOS() async {
    setState(() => _printing = true);
    try {
      Map<String, dynamic> comp = {};
      if (widget.coleta != null) {
        try {
          comp = await ApiService.instance.getComprovante(widget.coleta!.id);
        } catch (_) {}
      }

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

  Future<void> _shareWhatsApp() async {
    final now = DateTime.now();
    final dataHoje =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final text =
        '⛪ *IGREJA PRESBITERIANA DO BRASIL*\n'
        '📋 *TERMO DE CONFERÊNCIA DIACONAL DE DÍZIMOS & OFERTAS*\n'
        '🔖 Conferência: ${widget.coleta?.code ?? "CONF-IPB"}\n'
        '📅 Data: $dataHoje | ${_cultoController.text}\n\n'
        '✉️ *Total de Dízimos (Envelopes):* R\$ ${totalDizimos.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '🧺 *Total de Ofertas:* R\$ ${totalOfertas.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '💰 *TOTAL GERAL ARRECADADO: R\$ ${totalGeralArrecadado.toStringAsFixed(2).replaceAll('.', ',')}*\n\n'
        '📊 Total de Envelopes: ${widget.entries.length} un\n'
        '💵 Em Dinheiro: R\$ ${totalGeralDinheiro.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '📱 Em Pix: R\$ ${totalGeralPix.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '🏛️ Em Transferência: R\$ ${totalGeralTransf.toStringAsFixed(2).replaceAll('.', ',')}\n\n'
        '🛡️ *Comissão de Conferência:*\n'
        '1º: ${_conf1Controller.text}\n'
        '2º: ${_conf2Controller.text}\n\n'
        '_Apurado via App Oficial IPB_';

    final uri = Uri.parse(
      'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAberta = widget.coleta?.isAberta ?? true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BOTÃO DE DESTAQUE: ENCERRAR CONFERÊNCIA
        if (isAberta) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_clock, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Encerramento Oficial',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Revise a apuração dos dízimos e ofertas, valide os totais e imprima automaticamente as 2 vias térmicas.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFD1FAE5),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF047857),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _openEncerramentoWorkflow,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'ENCERRAR CONFERÊNCIA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // CARD DE BATIMENTO & TOTAIS EM TEMPO REAL
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_outlined, color: Color(0xFF047857)),
                        SizedBox(width: 8),
                        Text(
                          'Resumo em Tempo Real',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF047857).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isAberta ? 'ABERTA' : 'ENCERRADA',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                _buildRow(
                  'Responsável:',
                  ApiService.instance.currentUser?.name ??
                      _conf1Controller.text,
                  isBold: true,
                ),
                _buildRow(
                  'Envelopes Registrados:',
                  '${widget.entries.length} envelopes',
                ),
                _buildRow(
                  'Total de Dízimos:',
                  'R\$ ${totalDizimos.toStringAsFixed(2).replaceAll('.', ',')}',
                  isBold: true,
                ),
                _buildRow(
                  'Total de Ofertas:',
                  'R\$ ${totalOfertas.toStringAsFixed(2).replaceAll('.', ',')}',
                  isBold: true,
                ),
                const Divider(height: 16),
                _buildRow(
                  'TOTAL GERAL:',
                  'R\$ ${totalGeralArrecadado.toStringAsFixed(2).replaceAll('.', ',')}',
                  isHighlight: true,
                  color: const Color(0xFF047857),
                ),
                const Divider(height: 20),

                // FORMAS DE RECEBIMENTO
                const Text(
                  'POR FORMA DE RECEBIMENTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _buildRow(
                  'Dinheiro em Espécie:',
                  'R\$ ${totalGeralDinheiro.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                _buildRow(
                  'Pix:',
                  'R\$ ${totalGeralPix.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                _buildRow(
                  'Transferência Bancária:',
                  'R\$ ${totalGeralTransf.toStringAsFixed(2).replaceAll('.', ',')}',
                ),

                const SizedBox(height: 16),

                // BOTÃO DE IMPRESSÃO POS AVULSA
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _printing ? null : _handlePrintPOS,
                  icon: _printing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_outlined),
                  label: Text(
                    _printing ? 'Imprimindo...' : 'Imprimir Comprovante (POS)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // WHATSAPP
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _shareWhatsApp,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text(
                    'Compartilhar Resumo no WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    String val, {
    bool isBold = false,
    bool isHighlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 13 : 12,
              fontWeight: (isBold || isHighlight)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: isHighlight
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF475569),
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontFamily: isHighlight ? 'monospace' : null,
              fontSize: isHighlight ? 16 : 13,
              fontWeight: FontWeight.w900,
              color:
                  color ??
                  (isHighlight
                      ? const Color(0xFF047857)
                      : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
