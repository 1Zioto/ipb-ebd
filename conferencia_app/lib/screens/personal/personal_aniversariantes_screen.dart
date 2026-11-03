import 'package:flutter/material.dart';

class PersonalAniversariantesScreen extends StatelessWidget {
  const PersonalAniversariantesScreen({super.key});

  static const List<Map<String, dynamic>> _aniversariantes = [
    {'nome': 'Ana Paula Ferreira', 'dia': 4, 'mes': 'Novembro'},
    {'nome': 'Carlos Eduardo Silva', 'dia': 9, 'mes': 'Novembro'},
    {'nome': 'Débora Martins Souza', 'dia': 12, 'mes': 'Novembro'},
    {'nome': 'Gabriel Henrique Ramos', 'dia': 18, 'mes': 'Novembro'},
    {'nome': 'Helena Vasconcelos', 'dia': 22, 'mes': 'Novembro'},
    {'nome': 'Lucas Gabriel Rocha', 'dia': 27, 'mes': 'Novembro'},
    {'nome': 'Mariana Castro Silveira', 'dia': 29, 'mes': 'Novembro'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aniversariantes do Mês', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_rounded, color: Color(0xFF2563EB), size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Celebração Comunitária',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E40AF),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Relação de irmãos aniversariantes com autorização de divulgação. Apenas dia e mês são exibidos.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Novembro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ..._aniversariantes.map((a) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        a['dia'].toString().padLeft(2, '0'),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857), fontSize: 15),
                      ),
                      const Text(
                        'NOV',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 8),
                      ),
                    ],
                  ),
                ),
                title: Text(a['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Dia ${a['dia']} de ${a['mes']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

