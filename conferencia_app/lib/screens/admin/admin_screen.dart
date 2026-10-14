import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  final List<Map<String, String>> _logs = const [
    {'acao': 'call.finalized', 'detalhe': 'Chamada finalizada para Classe Infantil', 'user': 'Profª Débora', 'hora': '10:45'},
    {'acao': 'call.opened', 'detalhe': 'Chamada iniciada para Classe Bereanos', 'user': 'Prof. Marcos', 'hora': '09:15'},
    {'acao': 'coleta.fechada', 'detalhe': 'Fechamento de Culto Noturno impresso no POS', 'user': 'Diác. Carlos', 'hora': '21:30'},
    {'acao': 'user.login', 'detalhe': 'Autenticação com token Sanctum', 'user': 'admin', 'hora': '08:00'},
    {'acao': 'events.generated', 'detalhe': 'Calendário mensal de domingos gerado via cron', 'user': 'Sistema', 'hora': '00:00'},
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
              'Administração & Auditoria',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Gestão de Usuários
            Container(
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.manage_accounts, color: Color(0xFF047857)),
                      SizedBox(width: 8),
                      Text(
                        'PAPÉIS & PERMISSÕES (RBAC)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF047857), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Perfis ativos no sistema: Programador, Pastor, Superintendente, Professor, Diaconia e Membro. Cada perfil tem suas políticas validadas na API Laravel.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildRoleBadge('Admin', Colors.red),
                      const SizedBox(width: 6),
                      _buildRoleBadge('Pastor', Colors.purple),
                      const SizedBox(width: 6),
                      _buildRoleBadge('Super', Colors.blue),
                      const SizedBox(width: 6),
                      _buildRoleBadge('Prof', const Color(0xFF047857)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Trilha de Auditoria (RN-18)
            const Text(
              'LOGS DE AUDITORIA EM TEMPO REAL (RN-18)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final l = _logs[idx];
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l['acao']!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l['detalhe']!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Por: ${l['user']} às ${l['hora']}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                            ),
                          ],
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

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
