import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PersonalDizimosScreen extends StatefulWidget {
  const PersonalDizimosScreen({super.key});

  @override
  State<PersonalDizimosScreen> createState() => _PersonalDizimosScreenState();
}

class _PersonalDizimosScreenState extends State<PersonalDizimosScreen> {
  String _selectedFilter = 'Todos';

  // Chaves oficiais da igreja
  final String _pixKey = 'contato@ipbcampoverde.org.br';
  final String _banco = 'Banco do Brasil (001)';
  final String _agencia = '1234-5';
  final String _conta = '98765-4';
  final String _favorecido = 'Igreja Presbiteriana do Brasil';
  final String _cnpj = '00.000.000/0001-00';

  // Histórico demonstrativo validado pela tesouraria
  final List<Map<String, dynamic>> _historico = [
    {
      'data': '01/11/2026',
      'tipo': 'Dízimo',
      'valor': 450.00,
      'status': 'Validado pela Tesouraria',
      'recibo': 'REC-2026-1101',
    },
    {
      'data': '18/10/2026',
      'tipo': 'Oferta Missionária',
      'valor': 100.00,
      'status': 'Validado pela Tesouraria',
      'recibo': 'REC-2026-1018',
    },
    {
      'data': '04/10/2026',
      'tipo': 'Dízimo',
      'valor': 450.00,
      'status': 'Validado pela Tesouraria',
      'recibo': 'REC-2026-1004',
    },
  ];

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado para a área de transferência!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _selectedFilter == 'Todos'
        ? _historico
        : _historico.where((h) => h['tipo'] == _selectedFilter).toList();

    final total = filtered.fold<double>(0.0, (acc, item) => acc + (item['valor'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dízimos & Ofertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CARD PIX OFICIAL DA IGREJA
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pix_rounded, color: Color(0xFF047857), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chave Pix Oficial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Contribuição direta à conta da igreja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _pixKey,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF047857), size: 20),
                          tooltip: 'Copiar Chave Pix',
                          onPressed: () => _copyToClipboard(_pixKey, 'Chave Pix'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // DADOS BANCÁRIOS OFICIAIS
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transferência Bancária (TED/DOC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF047857)),
                        label: const Text('Copiar dados', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
                        onPressed: () => _copyToClipboard(
                          'Banco: $_banco\nAgência: $_agencia\nConta Corrente: $_conta\nFavorecido: $_favorecido\nCNPJ: $_cnpj',
                          'Dados bancários',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDataRow('Banco:', _banco),
                  _buildDataRow('Agência:', _agencia),
                  _buildDataRow('Conta Corrente:', _conta),
                  _buildDataRow('Favorecido:', _favorecido),
                  _buildDataRow('CNPJ:', _cnpj),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // SEÇÃO DE HISTÓRICO CONSOLIDADO PELA TESOURARIA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Meu Histórico de Contribuições', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              DropdownButton<String>(
                value: _selectedFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Dízimo', child: Text('Dízimos', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'Oferta Missionária', child: Text('Ofertas', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedFilter = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total consolidado no período: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 13),
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('Nenhuma contribuição registrada no filtro selecionado.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...filtered.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFECFDF5),
                    foregroundColor: Color(0xFF047857),
                    child: Icon(Icons.receipt_long_rounded),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['tipo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'R\$ ${(item['valor'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Data: ${item['data']} • Recibo: ${item['recibo']}', style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(item['status'], style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

