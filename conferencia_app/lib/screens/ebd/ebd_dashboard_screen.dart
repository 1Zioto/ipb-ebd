import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/ebd_service.dart';
import '../../models/ebd_models.dart';
import '../../widgets/app_drawer.dart';
import 'classes_list_screen.dart';
import 'chamada_screen.dart';

class EbdDashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchToConference;

  const EbdDashboardScreen({super.key, this.onSwitchToConference});

  @override
  State<EbdDashboardScreen> createState() => _EbdDashboardScreenState();
}

class _EbdDashboardScreenState extends State<EbdDashboardScreen> {
  EbdDashboardStats? _stats;
  List<EbdClassModel> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stats = await EbdService.instance.getDashboardStats();
    final classes = await EbdService.instance.getClasses();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _classes = classes;
      _loading = false;
    });
  }

  bool get _isProfessor {
    final role = ApiService.instance.currentUser?.role.toLowerCase() ?? '';
    return role.contains('prof') || role.contains('professor');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stats == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF047857))),
      );
    }

    final user = ApiService.instance.currentUser;
    final userName = user?.name ?? 'Oficial IPB';
    final userRole = user?.role ?? 'Professor / Superintendente';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: 'dashboard_ebd'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/images/ipb-logo.png',
              width: 28,
              height: 28,
              errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IPB • Escola Bíblica Dominical',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                Text(
                  '$userName ($userRole)',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh, color: Color(0xFF047857)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF047857),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNER DE DESTAQUE DO DOMINGO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EBD DOMINICAL REGULAR',
                          style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('AO VIVO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stats!.dataDomingo,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),

                    // Grid de Indicadores no Card Principal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBannerStat(
                          '${_stats!.totalPresentes}/${_stats!.totalMatriculados}',
                          'Presentes',
                          '${_stats!.frequenciaPercent.toInt()}%',
                        ),
                        _buildBannerStat(
                          '${_stats!.totalBiblias}',
                          'Bíblias',
                          '📖',
                        ),
                        _buildBannerStat(
                          '${_stats!.totalRevistas}',
                          'Revistas',
                          '📚',
                        ),
                        _buildBannerStat(
                          'R\$ ${_stats!.totalOfertas.toStringAsFixed(0)}',
                          'Ofertas',
                          '💰',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ATALHO RÁPIDO PARA PROFESSOR OU CLASSES
              if (_isProfessor) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Vai direto para a chamada da classe dos Jovens
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChamadaScreen(
                          classId: 1,
                          className: 'Classe dos Jovens — Bereanos',
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Realizar Chamada da Minha Classe (Jovens)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // SEÇÃO: MONITORAMENTO DAS CLASSES AO VIVO (RN-20)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CLASSES DA EBD',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClassesListScreen()),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF047857)),
                    label: const Text('Ver Todas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                  ),
                ],
              ),

              // Lista resumida de cards das classes
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _classes.take(4).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final c = _classes[idx];
                  return _buildMiniClassTile(c);
                },
              ),

              const SizedBox(height: 18),

              // ANIVERSARIANTES DA SEMANA
              const Text(
                '🎂 ANIVERSARIANTES DA SEMANA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: _stats!.aniversariantes.map((b) => _buildBirthdayTile(b)).toList(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerStat(String val, String lbl, String extra) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              val,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'monospace'),
            ),
            const SizedBox(width: 3),
            Text(extra, style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          lbl,
          style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildMiniClassTile(EbdClassModel c) {
    Color stColor = c.isFinalized ? const Color(0xFF047857) : (c.isInProgress ? const Color(0xFF1D4ED8) : Colors.orange[800]!);
    String stText = c.isFinalized ? 'FINALIZADA' : (c.isInProgress ? 'EM ANDAMENTO' : 'PENDENTE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.teacherName} • ${c.studentsCount} alunos',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: stColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stText,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: stColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayTile(BirthdayModel b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: b.isToday ? const Color(0xFFFDF2F8) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(b.isToday ? '🎉' : '🎂', style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  b.className,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: b.isToday ? const Color(0xFFFCE7F3) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              b.dateFormatted,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: b.isToday ? const Color(0xFFBE185D) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
