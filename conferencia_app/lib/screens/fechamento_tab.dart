import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';

class FechamentoTab extends StatefulWidget {
  final List<EnvelopeEntry> entries;
  final Map<double, int> cashCounts;
  final VoidCallback onResetSession;

  const FechamentoTab({
    super.key,
    required this.entries,
    required this.cashCounts,
    required this.onResetSession,
  });

  @override
  State<FechamentoTab> createState() => _FechamentoTabState();
}

class _FechamentoTabState extends State<FechamentoTab> {
  final _conf1Controller = TextEditingController(text: 'Diác. Carlos Eduardo');
  final _conf2Controller = TextEditingController(text: 'Diác. Marcos Vinícius');
  final _cultoController = TextEditingController(text: 'Culto Noturno Dominical');

  bool _syncing = false;
  bool _printing = false;

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

  double get totalEnvelopesDinheiro {
    return widget.entries
        .where((e) => e.forma == 'dinheiro')
        .fold(0.0, (sum, e) => sum + e.valor);
  }

  double get diferencaDinheiro => totalFisico - totalEnvelopesDinheiro;

  double get totalPix {
    return widget.entries
        .where((e) => e.forma == 'pix')
        .fold(0.0, (sum, e) => sum + e.valor);
  }

  double get totalCartao {
    return widget.entries
        .where((e) => e.forma == 'cartao')
        .fold(0.0, (sum, e) => sum + e.valor);
  }

  double get totalGeral => totalFisico + totalPix + totalCartao;

  double get totDizimo => widget.entries
      .where((e) => e.destinacao == 'dizimo')
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totOferta => widget.entries
      .where((e) => e.destinacao == 'oferta')
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totMissoes => widget.entries
      .where((e) => e.destinacao == 'missoes')
      .fold(0.0, (sum, e) => sum + e.valor);

  double get totConstrucao => widget.entries
      .where((e) => e.destinacao == 'construcao')
      .fold(0.0, (sum, e) => sum + e.valor);

  Future<void> _handlePrintPOS() async {
    setState(() => _printing = true);
    try {
      await ThermalPrinterService.instance.printFechamento(
        totalFisico: totalFisico,
        totalEnvelopesDinheiro: totalEnvelopesDinheiro,
        diferencaDinheiro: diferencaDinheiro,
        totalPix: totalPix,
        totalCartao: totalCartao,
        totalGeral: totalGeral,
        totalEnvelopes: widget.entries.length,
        totDizimo: totDizimo,
        totOferta: totOferta,
        totMissoes: totMissoes,
        totConstrucao: totConstrucao,
        conferente1: _conf1Controller.text.trim(),
        conferente2: _conf2Controller.text.trim(),
        culto: _cultoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Termo de Fechamento impresso na POS com sucesso!'),
          backgroundColor: Color(0xFF047857),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao imprimir na POS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _handleSyncApi() async {
    if (ApiService.instance.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você está em Modo Offline. Conecte-se online para sincronizar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum envelope lançado nesta sessão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final coletaId = await ApiService.instance.syncColeta(
        entries: widget.entries,
        totalFisico: totalFisico,
        diferencaDinheiro: diferencaDinheiro,
        conferente1: _conf1Controller.text.trim(),
        conferente2: _conf2Controller.text.trim(),
        culto: _cultoController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coleta #$coletaId sincronizada e encerrada no sistema IPB com sucesso!'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sincronizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _shareWhatsApp() async {
    final now = DateTime.now();
    final dataHoje = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final text = '⛪ *IGREJA PRESBITERIANA DO BRASIL*\n'
        '📋 *TERMO DE CONFERÊNCIA DIACONAL DE DÍZIMOS & OFERTAS*\n'
        '📅 Data: $dataHoje | ${_cultoController.text}\n\n'
        '💵 *Dinheiro em Espécie (Contado):* R\$ ${totalFisico.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '✉️ *Envelopes em Dinheiro:* R\$ ${totalEnvelopesDinheiro.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '🧺 *Ofertas Soltas na Salva:* R\$ ${diferencaDinheiro.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '📱 *PIX / Transferências:* R\$ ${totalPix.toStringAsFixed(2).replaceAll('.', ',')}\n'
        '💳 *Cartões / Maquininha:* R\$ ${totalCartao.toStringAsFixed(2).replaceAll('.', ',')}\n\n'
        '💰 *TOTAL GERAL APURADO: R\$ ${totalGeral.toStringAsFixed(2).replaceAll('.', ',')}*\n'
        '📊 Total de Envelopes: ${widget.entries.length}\n'
        '✅ Status: ${diferencaDinheiro.abs() < 0.01 ? "100% Conciliado" : "Conciliado c/ Oferta Solta"}\n\n'
        '🛡️ *Comissão de Conferência:*\n'
        '1º: ${_conf1Controller.text}\n'
        '2º: ${_conf2Controller.text}\n\n'
        '_Apurado via App Oficial IPB_';

    final uri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBatimentoText = diferencaDinheiro.abs() < 0.01
        ? '100% Conciliado (R\$ 0,00)'
        : (diferencaDinheiro > 0
            ? '+ R\$ ${diferencaDinheiro.toStringAsFixed(2).replaceAll('.', ',')} (Oferta Solta)'
            : 'Falta R\$ ${diferencaDinheiro.abs().toStringAsFixed(2).replaceAll('.', ',')}');

    final statusColor = diferencaDinheiro.abs() < 0.01
        ? const Color(0xFF047857)
        : (diferencaDinheiro > 0 ? const Color(0xFF0284C7) : Colors.red);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                          'Batimento & Fechamento Canônico',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusBatimentoText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildRow('Total Dinheiro Físico (Contado):', totalFisico),
                _buildRow('Envelopes em Dinheiro (Lançados):', totalEnvelopesDinheiro),
                _buildRow('Ofertas Soltas na Salva (Sobra):', diferencaDinheiro, isBold: true, color: statusColor),
                _buildRow('Total em PIX / Transferências:', totalPix),
                _buildRow('Total em Cartões:', totalCartao),
                const Divider(height: 20),
                _buildRow('TOTAL GERAL DA APURAÇÃO:', totalGeral, isHighlight: true),
                const SizedBox(height: 16),

                // Comissão Canônica
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
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Comissão Canônica de Conferência (IPB)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mínimo 2 oficiais/irmãos presentes na conferência da apuração.',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _cultoController,
                        decoration: InputDecoration(
                          labelText: 'Culto / Reunião',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _conf1Controller,
                        decoration: InputDecoration(
                          labelText: '1º Conferente (Oficial / Tesoureiro)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _conf2Controller,
                        decoration: InputDecoration(
                          labelText: '2º Conferente (Verificador)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botão Imprimir Termo na POS (Destaque!)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  onPressed: _printing ? null : _handlePrintPOS,
                  icon: _printing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.print_outlined),
                  label: Text(
                    _printing ? 'Imprimindo na POS...' : 'Imprimir Termo na Impressora POS',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),

                // Sincronizar com API
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _syncing ? null : _handleSyncApi,
                  icon: _syncing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _syncing ? 'Sincronizando...' : 'Sincronizar Coleta com Sistema IPB',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),

                // WhatsApp
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _shareWhatsApp,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text(
                    'Compartilhar Relatório no WhatsApp',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.onResetSession,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Iniciar Nova Sessão / Limpar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, double val, {bool isBold = false, bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 13 : 12,
              fontWeight: (isBold || isHighlight) ? FontWeight.w800 : FontWeight.w500,
              color: isHighlight ? const Color(0xFF0F172A) : const Color(0xFF475569),
            ),
          ),
          Text(
            'R\$ ${val.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: isHighlight ? 16 : 13,
              fontWeight: FontWeight.w900,
              color: color ?? (isHighlight ? const Color(0xFF047857) : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
