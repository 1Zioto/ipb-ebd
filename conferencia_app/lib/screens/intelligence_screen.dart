import 'package:flutter/material.dart';
import '../core/api_service.dart';

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  int _selectedYear = 2026;
  bool _consolidated = false;
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getIntelligenceOverview(
      year: _selectedYear,
      consolidated: _consolidated,
    );
    if (mounted) {
      setState(() {
        _data = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _data?['kpis'] as Map<String, dynamic>? ?? {};
    final ageDist = _data?['age_distribution'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Inteligência Eclesiástica',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF047857)),
            tooltip: 'Atualizar Dados',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. BARRA DE FILTRO
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Ano: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                            DropdownButton<int>(
                              value: _selectedYear,
                              underline: const SizedBox(),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 14),
                              items: [2024, 2025, 2026, 2027].map((y) {
                                return DropdownMenuItem(value: y, child: Text(y.toString()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedYear = val);
                                  _loadData();
                                }
                              },
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _consolidated = !_consolidated);
                            _loadData();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _consolidated ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _consolidated ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.hub_outlined, size: 14, color: _consolidated ? const Color(0xFF047857) : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  _consolidated ? 'Consolidado' : 'Igreja Local',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _consolidated ? const Color(0xFF047857) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. GRID DE CARDS PRINCIPAIS
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Membros no Rol',
                          value: '${kpis['total_membros'] ?? 0}',
                          subtitle: '${kpis['total_pessoas'] ?? 0} cadastradas',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Comungantes',
                          value: '${kpis['comungantes'] ?? 0}',
                          subtitle: 'Membros comungantes',
                          icon: Icons.church_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Famílias',
                          value: '${kpis['total_familias'] ?? 0}',
                          subtitle: 'Núcleos familiares',
                          icon: Icons.home_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Alunos na EBD',
                          value: '${kpis['total_alunos_ebd'] ?? 0}',
                          subtitle: '${kpis['frequencia_ebd_media'] ?? 0}% presença média',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. MOVIMENTAÇÃO DO ANO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Movimentação do Rol no Ano',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Admissões', '+${kpis['admissoes_ano'] ?? 0}', const Color(0xFF047857)),
                            _buildStatItem('Saídas', '-${kpis['saidas_ano'] ?? 0}', const Color(0xFFEF4444)),
                            _buildStatItem(
                              'Saldo Líquido',
                              '${((kpis['crescimento_liquido'] ?? 0) as num) >= 0 ? '+' : ''}${kpis['crescimento_liquido'] ?? 0}',
                              ((kpis['crescimento_liquido'] ?? 0) as num) >= 0 ? const Color(0xFF047857) : const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. COMPOSIÇÃO DE FAIXAS ETÁRIAS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Distribuição por Faixa Etária',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Média: ${kpis['media_idade'] ?? 0} anos',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildAgeBar('Infantil (0 a 11 anos)', ageDist['infantil'] ?? 0, Colors.pink),
                        _buildAgeBar('Adolescentes (12 a 17)', ageDist['adolescentes'] ?? 0, Colors.orange),
                        _buildAgeBar('Jovens (18 a 35 anos)', ageDist['jovens'] ?? 0, Colors.blue),
                        _buildAgeBar('Adultos (36 a 59 anos)', ageDist['adultos'] ?? 0, const Color(0xFF047857)),
                        _buildAgeBar('60+ Anos (Melhor Idade)', ageDist['melhor_idade'] ?? 0, Colors.purple),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildAgeBar(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: count > 0 ? (count / 100).clamp(0.05, 1.0) : 0,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
