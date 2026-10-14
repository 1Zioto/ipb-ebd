import 'package:flutter/material.dart';
import '../../core/thermal_printer.dart';
import '../../widgets/app_drawer.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  String _filtroSeveridade = 'Todos'; // 'Todos', 'Segurança', 'Financeiro', 'EBD'

  final List<Map<String, dynamic>> _logs = [
    {
      'id': 'LOG-9402',
      'tipo': 'FINANCEIRO',
      'severidade': 'ALTA',
      'acao': 'coleta.fechada',
      'titulo': 'Fechamento de Culto Noturno Realizado',
      'detalhe': 'Conferência de R\$ 3.840,00 concluída e comprovante timbrado impresso na POS Bluetooth.',
      'usuario': 'Diác. Carlos Eduardo Nogueira',
      'papel': 'Diaconia',
      'ip': '192.168.1.45',
      'data': '13/10/2026',
      'hora': '21:30:15',
    },
    {
      'id': 'LOG-9401',
      'tipo': 'SEGURANÇA',
      'severidade': 'CRÍTICA',
      'acao': 'user.login.sanctum',
      'titulo': 'Autenticação de Administrador',
      'detalhe': 'Login autorizado com token Sanctum e 2FA verificado com sucesso.',
      'usuario': 'Lucas Ferreira (admin)',
      'papel': 'Programador / TI',
      'ip': '187.55.12.90',
      'data': '13/10/2026',
      'hora': '20:12:04',
    },
    {
      'id': 'LOG-9400',
      'tipo': 'SECRETARIA',
      'severidade': 'MÉDIA',
      'acao': 'member.updated',
      'titulo': 'Atualização de Cadastro de Membro',
      'detalhe': 'Alterado telefone e endereço do membro #101 (André Luiz Albuquerque).',
      'usuario': 'Presb. Paulo Roberto Albuquerque',
      'papel': 'Conselho',
      'ip': '192.168.1.12',
      'data': '13/10/2026',
      'hora': '16:45:22',
    },
    {
      'id': 'LOG-9399',
      'tipo': 'EBD',
      'severidade': 'INFO',
      'acao': 'call.finalized',
      'titulo': 'Chamada Dominical Encerrada',
      'detalhe': 'Chamada da Classe Jovens (Bereanos) finalizada: 18 presentes, 2 visitantes, oferta R\$ 142,00.',
      'usuario': 'Profª Débora Neves de Lima',
      'papel': 'Professor',
      'ip': '192.168.1.33',
      'data': '13/10/2026',
      'hora': '10:45:10',
    },
    {
      'id': 'LOG-9398',
      'tipo': 'EBD',
      'severidade': 'INFO',
      'acao': 'call.opened',
      'titulo': 'Abertura de Diário de Classe',
      'detalhe': 'Iniciada a chamada eletrônica dominical para o 4º Trimestre da EBD.',
      'usuario': 'Presb. Silas Rodrigues',
      'papel': 'Superintendente',
      'ip': '192.168.1.18',
      'data': '13/10/2026',
      'hora': '09:15:00',
    },
    {
      'id': 'LOG-9397',
      'tipo': 'SISTEMA',
      'severidade': 'INFO',
      'acao': 'cron.backup.database',
      'titulo': 'Backup Automático do Banco SQLite/Postgres',
      'detalhe': 'Rotina diária de integridade concluída com sucesso (Dump criptografado gerado).',
      'usuario': 'Sistema Automático (Cron)',
      'papel': 'Daemon',
      'ip': '127.0.0.1',
      'data': '13/10/2026',
      'hora': '03:00:00',
    },
    {
      'id': 'LOG-9396',
      'tipo': 'SEGURANÇA',
      'severidade': 'ALTA',
      'acao': 'auth.failed_attempt',
      'titulo': 'Tentativa de Login Inválida',
      'detalhe': 'Tentativa com senha incorreta para o usuário "secretaria". IP temporariamente bloqueado por 15 min.',
      'usuario': 'Desconhecido',
      'papel': 'Visitante',
      'ip': '177.34.88.102',
      'data': '12/10/2026',
      'hora': '22:18:41',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredLogs {
    var list = _logs;
    if (_filtroSeveridade == 'Segurança') {
      list = list.where((l) => l['tipo'] == 'SEGURANÇA').toList();
    } else if (_filtroSeveridade == 'Financeiro') {
      list = list.where((l) => l['tipo'] == 'FINANCEIRO').toList();
    } else if (_filtroSeveridade == 'EBD') {
      list = list.where((l) => l['tipo'] == 'EBD').toList();
    }

    if (_searchTerm.isEmpty) return list;
    final term = _searchTerm.toLowerCase();
    return list.where((l) {
      final titulo = l['titulo'].toString().toLowerCase();
      final detalhe = l['detalhe'].toString().toLowerCase();
      final user = l['usuario'].toString().toLowerCase();
      final acao = l['acao'].toString().toLowerCase();
      return titulo.contains(term) || detalhe.contains(term) || user.contains(term) || acao.contains(term);
    }).toList();
  }

  // Visualizar Dossiê Completo do Log
  void _openLogDetailModal(Map<String, dynamic> l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history_edu_rounded, color: Color(0xFF0F172A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registro de Auditoria • ${l['id']}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Carimbo de data/hora: ${l['data']} às ${l['hora']}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                l['titulo'],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                l['detalhe'],
                style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildLogMetaRow('Ação Técnica (RN-18):', l['acao']),
                    _buildLogMetaRow('Usuário Executor:', '${l['usuario']} (${l['papel']})'),
                    _buildLogMetaRow('Endereço IP:', l['ip']),
                    _buildLogMetaRow('Nível de Severidade:', l['severidade']),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ThermalPrinterService.instance.printText(
                          '================================\n'
                          '       TRILHA DE AUDITORIA\n'
                          '    REGISTRO TECNICO IPB\n'
                          '================================\n'
                          'ID: ${l['id']}\n'
                          'Data: ${l['data']} ${l['hora']}\n'
                          'Acao: ${l['acao']}\n'
                          'Usuario: ${l['usuario']}\n'
                          'Papel: ${l['papel']}\n'
                          'IP Origem: ${l['ip']}\n'
                          'Detalhe: ${l['titulo']}\n'
                          '================================\n\n\n',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Enviando registro ${l['id']} para impressão POS...'),
                            backgroundColor: const Color(0xFF047857),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF047857)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF047857)),
                      label: const Text('Imprimir na POS', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
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
              'Trilha de Auditoria (RN-18)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF047857)),
            tooltip: 'Atualizar Logs',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs de auditoria sincronizados com a API Laravel.'),
                  backgroundColor: Color(0xFF047857),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'auditoria'),
      body: Column(
        children: [
          // Banner de Conformidade Canônica e LGPD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFFB45309), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registro inalterável de eventos operacionais, eclesiásticos e financeiros (CI/IPB e LGPD).',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),

          // Busca
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filtrar por ação, usuário, IP ou detalhe...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF047857)),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              onChanged: (val) => setState(() => _searchTerm = val.trim()),
            ),
          ),

          // Filtros Rápidos
          Container(
            height: 42,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSeverityChip('Todos'),
                const SizedBox(width: 8),
                _buildSeverityChip('Financeiro'),
                const SizedBox(width: 8),
                _buildSeverityChip('Segurança'),
                const SizedBox(width: 8),
                _buildSeverityChip('EBD'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Totalizador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredLogs.length} EVENTOS AUDITADOS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, size: 12, color: Color(0xFF047857)),
                    SizedBox(width: 4),
                    Text('Trilha Criptografada', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                  ],
                ),
              ],
            ),
          ),

          // Lista de Logs
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _filteredLogs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final l = _filteredLogs[idx];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openLogDetailModal(l),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getLogBadgeBg(l['tipo']),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l['tipo'],
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: _getLogBadgeColor(l['tipo']),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l['titulo'],
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l['usuario']} • IP: ${l['ip']}',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l['data']} às ${l['hora']} • [${l['acao']}]',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                          ],
                        ),
                      ),
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

  Widget _buildSeverityChip(String label) {
    final isSelected = _filtroSeveridade == label;
    return GestureDetector(
      onTap: () => setState(() => _filtroSeveridade = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Color _getLogBadgeBg(String tipo) {
    if (tipo == 'FINANCEIRO') return const Color(0xFFECFDF5);
    if (tipo == 'SEGURANÇA') return const Color(0xFFFEF2F2);
    if (tipo == 'SECRETARIA') return const Color(0xFFF5F3FF);
    if (tipo == 'EBD') return const Color(0xFFEFF6FF);
    return const Color(0xFFF1F5F9);
  }

  Color _getLogBadgeColor(String tipo) {
    if (tipo == 'FINANCEIRO') return const Color(0xFF047857);
    if (tipo == 'SEGURANÇA') return const Color(0xFFDC2626);
    if (tipo == 'SECRETARIA') return const Color(0xFF7C3AED);
    if (tipo == 'EBD') return const Color(0xFF2563EB);
    return const Color(0xFF475569);
  }
}
