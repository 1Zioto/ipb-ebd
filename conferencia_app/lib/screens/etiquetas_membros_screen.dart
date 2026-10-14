import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';

class EtiquetasMembrosScreen extends StatefulWidget {
  final List<MemberModel> members;

  const EtiquetasMembrosScreen({super.key, required this.members});

  @override
  State<EtiquetasMembrosScreen> createState() => _EtiquetasMembrosScreenState();
}

class _EtiquetasMembrosScreenState extends State<EtiquetasMembrosScreen> {
  final _searchController = TextEditingController();
  String _filter = '';
  bool _isPrinting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MemberModel> get _filteredMembers {
    if (_filter.trim().isEmpty) return widget.members;
    final f = _filter.toLowerCase();
    return widget.members.where((m) {
      final nameMatches = m.fullName.toLowerCase().contains(f);
      final envMatches = m.envelopeNumber?.toLowerCase().contains(f) ?? false;
      return nameMatches || envMatches;
    }).toList();
  }

  Future<void> _printLabel(MemberModel member) async {
    setState(() => _isPrinting = true);
    try {
      await ThermalPrinterService.instance.printMemberQrLabel(
        memberName: member.fullName,
        envelopeNumber: member.envelopeNumber ?? member.id.toString(),
        qrData: member.qrCodePayload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Etiqueta de ${member.fullName} impressa com sucesso!'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao imprimir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showQrDialog(MemberModel member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF047857).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Envelope #${member.envelopeNumber ?? member.id}',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: QrImageView(
                data: member.qrCodePayload,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF047857),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Código: ${member.qrCodePayload}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _printLabel(member);
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir na POS'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportHtmlLabels() async {
    // Gera página HTML pronta para impressão em papel A4 (estilo folhas de etiquetas)
    final buffer = StringBuffer();
    for (final m in widget.members) {
      final env = m.envelopeNumber ?? m.id.toString();
      final qrApi =
          'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${Uri.encodeComponent(m.qrCodePayload)}';
      buffer.write('''
      <div class="label-card">
        <div class="church-title">IGREJA PRESBITERIANA DO BRASIL</div>
        <div class="env-num">ENVELOPE #$env</div>
        <div class="member-name">${m.fullName}</div>
        <div class="qr-box">
          <img src="$qrApi" alt="QR Code" />
        </div>
        <div class="footer-note">Cole no envelope de dizimo</div>
      </div>
''');
    }
    final cardsHtml = buffer.toString();

    final htmlContent = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Etiquetas de Dizimos - IPB</title>
  <style>
    @page { size: A4; margin: 10mm; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 0; }
    .grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8mm;
    }
    .label-card {
      border: 1px dashed #94a3b8;
      border-radius: 8px;
      padding: 10px;
      text-align: center;
      page-break-inside: avoid;
      background: #fafafa;
    }
    .church-title { font-size: 10px; font-weight: 800; color: #047857; letter-spacing: 0.5px; }
    .env-num { font-size: 16px; font-weight: 900; color: #0f172a; margin: 4px 0; }
    .member-name { font-size: 11px; font-weight: 600; color: #334155; margin-bottom: 6px; }
    .qr-box { margin: 0 auto; display: inline-block; }
    .qr-box img { width: 90px; height: 90px; }
    .footer-note { font-size: 8px; color: #64748b; margin-top: 4px; }
    @media print {
      .no-print { display: none; }
      body { background: white; }
    }
  </style>
</head>
<body>
  <div class="no-print" style="padding: 16px; background: #047857; color: white; margin-bottom: 16px; border-radius: 8px; display: flex; justify-content: space-between; align-items: center;">
    <div>
      <h2 style="margin: 0; font-size: 16px;">Folha de Etiquetas para Envelopes - IPB</h2>
      <p style="margin: 4px 0 0 0; font-size: 12px; opacity: 0.9;">Total de ${widget.members.length} etiquetas geradas. Pressione Ctrl+P para imprimir em folha A4.</p>
    </div>
    <button onclick="window.print()" style="background: white; color: #047857; border: none; padding: 8px 16px; font-weight: bold; border-radius: 6px; cursor: pointer;">Imprimir Folha</button>
  </div>

  <div class="grid">
    $cardsHtml
  </div>
</body>
</html>
''';

    final uri = Uri.dataFromString(
      htmlContent,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o navegador: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredMembers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetas de Envelopes'),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Gerar Folha A4 de Etiquetas',
            onPressed: _exportHtmlLabels,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Informativo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFECFDF5),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, color: Color(0xFF047857), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR Codes dos Membros',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Imprima na maquininha POS ou gere a folha A4 para colar nos envelopes.',
                        style: TextStyle(
                          color: const Color(0xFF047857).withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _filter = v),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou número do envelope...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF047857)),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // Lista de Membros
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum membro encontrado.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = list[index];
                      final env = member.envelopeNumber ?? member.id.toString();

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: GestureDetector(
                            onTap: () => _showQrDialog(member),
                            child: Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: QrImageView(
                                data: member.qrCodePayload,
                                version: QrVersions.auto,
                                size: 40,
                              ),
                            ),
                          ),
                          title: Text(
                            member.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Envelope #$env  •  Código: ${member.qrCodePayload}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Color(0xFF047857)),
                                tooltip: 'Ver QR Code',
                                onPressed: () => _showQrDialog(member),
                              ),
                              IconButton(
                                icon: const Icon(Icons.print, color: Color(0xFF047857)),
                                tooltip: 'Imprimir na POS',
                                onPressed: _isPrinting ? null : () => _printLabel(member),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
