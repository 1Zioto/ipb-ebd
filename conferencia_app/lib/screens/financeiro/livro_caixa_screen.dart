import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class LivroCaixaScreen extends StatelessWidget {
  const LivroCaixaScreen({super.key});

  final List<Map<String, dynamic>> _lancamentos = const [
    {'data': '13/10', 'desc': 'Coleta de Dízimos e Ofertas (Culto Manhã/EBD)', 'tipo': 'entrada', 'valor': 4850.00, 'cat': 'Dízimos'},
    {'data': '10/10', 'desc': 'Pagamento Energia Elétrica (Templo Sede)', 'tipo': 'saida', 'valor': 1240.50, 'cat': 'Manutenção'},
    {'data': '08/10', 'desc': 'Oferta Missionária — APMT / Junta de Missões', 'tipo': 'saida', 'valor': 800.00, 'cat': 'Missões'},
    {'data': '06/10', 'desc': 'Coleta de Dízimos e Ofertas (Culto Noturno)', 'tipo': 'entrada', 'valor': 6120.00, 'cat': 'Dízimos'},
    {'data': '05/10', 'desc': 'Repasse Pastoral e Previdenciário', 'tipo': 'saida', 'valor': 4500.00, 'cat': 'Ministério'},
    {'data': '02/10', 'desc': 'Aquisição de Revistas da EBD (Editora Cultura Cristã)', 'tipo': 'saida', 'valor': 650.00, 'cat': 'EBD'},
  ];

  @override
  Widget build(BuildContext context) {
    const double entradasMes = 18640.00;
    const double saidasMes = 9820.50;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/images/ipb-logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857), size: 22),
            ),
            const SizedBox(width: 8),
            const Text(
              'Livro Caixa (Tesouraria)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'livro_caixa'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Principal de Saldo da Tesouraria
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SALDO CONSOLIDADO EM CAIXA', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    'R\$ 28.450,80',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Entradas no Mês', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text('+R\$ ${entradasMes.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Saídas no Mês', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text('-R\$ ${saidasMes.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'ÚLTIMOS LANÇAMENTOS DO MÊS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lancamentos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final l = _lancamentos[idx];
                final isEntrada = l['tipo'] == 'entrada';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isEntrada ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isEntrada ? const Color(0xFF047857) : Colors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l['desc']!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${l['data']} • Categoria: ${l['cat']}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isEntrada ? '+' : '-'}R\$ ${(l['valor'] is num ? (l['valor'] as num).toDouble() : (double.tryParse(l['valor']?.toString() ?? '0') ?? 0.0)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isEntrada ? const Color(0xFF047857) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
