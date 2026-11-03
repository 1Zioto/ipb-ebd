import 'package:flutter/material.dart';

class PersonalSolicitacoesScreen extends StatefulWidget {
  const PersonalSolicitacoesScreen({super.key});

  @override
  State<PersonalSolicitacoesScreen> createState() => _PersonalSolicitacoesScreenState();
}

class _PersonalSolicitacoesScreenState extends State<PersonalSolicitacoesScreen> {
  final List<Map<String, dynamic>> _solicitacoes = [
    {
      'protocolo': 'SEC-2026-089',
      'categoria': 'Certidão de Batismo',
      'data': '28/10/2026',
      'status': 'Concluída',
      'descricao': 'Solicitação de 2ª via da certidão de batismo para fins civis.',
      'resposta': 'Certidão expedida e enviada para o seu e-mail cadastrado.',
    },
    {
      'protocolo': 'SEC-2026-104',
      'categoria': 'Atualização de Endereço',
      'data': '02/11/2026',
      'status': 'Em análise',
      'descricao': 'Comprovante de nova residência anexado para atualização cadastral no rol de membros.',
      'resposta': null,
    },
  ];

  void _novaSolicitacao() {
    String categoria = 'Atualização Cadastral';
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nova Solicitação à Secretaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Categoria da Solicitação', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: categoria,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Atualização Cadastral', child: Text('Atualização Cadastral')),
                  DropdownMenuItem(value: 'Certidão de Batismo', child: Text('Certidão de Batismo')),
                  DropdownMenuItem(value: 'Certidão de Casamento Religioso', child: Text('Certidão de Casamento Religioso')),
                  DropdownMenuItem(value: 'Carta de Transferência', child: Text('Carta de Transferência')),
                  DropdownMenuItem(value: 'Declaração de Membresia', child: Text('Declaração de Membresia')),
                  DropdownMenuItem(value: 'Outras Solicitações', child: Text('Outras Solicitações')),
                ],
                onChanged: (v) {
                  if (v != null) setModalState(() => categoria = v);
                },
              ),
              const SizedBox(height: 12),
              const Text('Descrição da Solicitação', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Descreva detalhadamente o que você necessita...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar Solicitação', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (descCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    final prot = 'SEC-2026-${(105 + _solicitacoes.length)}';
                    setState(() {
                      _solicitacoes.insert(0, {
                        'protocolo': prot,
                        'categoria': categoria,
                        'data': '03/11/2026',
                        'status': 'Aberta',
                        'descricao': descCtrl.text.trim(),
                        'resposta': null,
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Solicitação protocolada sob nº $prot')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações à Secretaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Solicitação', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _novaSolicitacao,
      ),
      body: _solicitacoes.isEmpty
          ? const Center(child: Text('Nenhuma solicitação em andamento.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              itemCount: _solicitacoes.length,
              itemBuilder: (ctx, i) {
                final s = _solicitacoes[i];
                final status = s['status'] as String;

                Color statusColor = const Color(0xFFD97706);
                if (status == 'Concluída') statusColor = const Color(0xFF059669);
                if (status == 'Indeferida' || status == 'Cancelada') statusColor = const Color(0xFFDC2626);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s['protocolo'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s['categoria'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s['descricao'],
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                        if (s['resposta'] != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Despacho da Secretaria: ${s['resposta']}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text('Protocolado em: ${s['data']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

