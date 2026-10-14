import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class RolCanonicoScreen extends StatelessWidget {
  const RolCanonicoScreen({super.key});

  final List<Map<String, dynamic>> _membros = const [
    {'rol': '001', 'nome': 'Rev. Antônio Carlos Silva', 'admissao': '02/02/2018', 'modo': 'Designação Presbiterial', 'status': 'Pastor'},
    {'rol': '002', 'nome': 'Presb. Paulo Roberto Albuquerque', 'admissao': '15/05/2015', 'modo': 'Profissão de Fé e Batismo', 'status': 'Comungante'},
    {'rol': '003', 'nome': 'Diác. Carlos Eduardo Nogueira', 'admissao': '20/08/2016', 'modo': 'Carta de Transferência', 'status': 'Comungante'},
    {'rol': '004', 'nome': 'Débora Neves de Lima', 'admissao': '12/10/2019', 'modo': 'Profissão de Fé', 'status': 'Comungante'},
    {'rol': '005', 'nome': 'Gabriel Henrique Braga', 'admissao': '14/11/2021', 'modo': 'Profissão de Fé', 'status': 'Comungante'},
    {'rol': '006', 'nome': 'Lucas Ferreira da Silva', 'admissao': '05/03/2022', 'modo': 'Carta de Transferência', 'status': 'Comungante'},
    {'rol': '007', 'nome': 'Beatriz Vasconcelos', 'admissao': '18/06/2020', 'modo': 'Profissão de Fé', 'status': 'Comungante'},
    {'rol': '008', 'nome': 'Esther Ramos Peixoto', 'admissao': '10/01/2023', 'modo': 'Batismo na Infância', 'status': 'Não-Comungante'},
  ];

  @override
  Widget build(BuildContext context) {
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
              'Rol de Membros',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'rol_canonico'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFECFDF5),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF047857), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Livro Oficial do Conselho da Igreja Presbiteriana do Brasil (Constituição da IPB, Art. 12).',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _membros.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final m = _membros[idx];
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ROL\n#${m['rol']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['nome']!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Admissão: ${m['admissao']} (${m['modo']})',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          m['status']!,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                        ),
                      ),
                    ],
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
