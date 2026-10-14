import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/ebd_service.dart';
import '../../models/ebd_models.dart';
import '../../widgets/app_drawer.dart';
import 'chamada_screen.dart';

class ClassesListScreen extends StatefulWidget {
  const ClassesListScreen({super.key});

  @override
  State<ClassesListScreen> createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends State<ClassesListScreen> {
  List<EbdClassModel> _classes = [];
  bool _loading = true;
  String _filter = 'todas';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _loading = true);
    final list = await EbdService.instance.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = list;
      _loading = false;
    });
  }

  bool get _isProfessor {
    final role = ApiService.instance.currentUser?.role.toLowerCase() ?? '';
    return role.contains('prof') || role.contains('professor');
  }

  bool get _isSuperOrAdmin {
    final role = ApiService.instance.currentUser?.role.toLowerCase() ?? '';
    return role.contains('super') || role.contains('admin') || role.contains('pastor');
  }

  List<EbdClassModel> get _filteredClasses {
    if (_filter == 'pendente') {
      return _classes.where((c) => c.status == 'pendente').toList();
    } else if (_filter == 'em_andamento') {
      return _classes.where((c) => c.status == 'em_andamento').toList();
    } else if (_filter == 'finalizada') {
      return _classes.where((c) => c.status == 'finalizada').toList();
    }
    return _classes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: 'classes_ebd'),
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
              'Classes da EBD',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh, color: Color(0xFF047857)),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
          : Column(
              children: [
                // Banner Explicativo de Escopo RBAC (RN-16)
                if (_isProfessor)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: const Color(0xFFECFDF5),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Color(0xFF047857)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perfil Professor: acesso liberado para sua classe vinculada (RN-16 / Policy).',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Filtros Rápidos de Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todas (${_classes.length})', 'todas'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Pendentes (${_classes.where((c) => c.status == 'pendente').length})', 'pendente'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Em Andamento (${_classes.where((c) => c.status == 'em_andamento').length})', 'em_andamento'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Finalizadas (${_classes.where((c) => c.status == 'finalizada').length})', 'finalizada'),
                      ],
                    ),
                  ),
                ),

                // Lista de Classes
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF047857),
                    onRefresh: _loadClasses,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: _filteredClasses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = _filteredClasses[index];
                        final canAccess = !_isProfessor || c.isLinkedToUser || _isSuperOrAdmin;
                        return _buildClassCard(c, canAccess);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF047857),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildClassCard(EbdClassModel c, bool canAccess) {
    Color statusBg;
    Color statusColor;
    String statusText;

    if (c.status == 'finalizada') {
      statusBg = const Color(0xFFECFDF5);
      statusColor = const Color(0xFF047857);
      statusText = 'FINALIZADA';
    } else if (c.status == 'em_andamento') {
      statusBg = const Color(0xFFEFF6FF);
      statusColor = const Color(0xFF1D4ED8);
      statusText = 'EM ANDAMENTO';
    } else {
      statusBg = const Color(0xFFFFFBEB);
      statusColor = Colors.orange[800]!;
      statusText = 'PENDENTE';
    }

    return Container(
      decoration: BoxDecoration(
        color: canAccess ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.isLinkedToUser ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          width: c.isLinkedToUser ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Nome da Classe e Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.isLinkedToUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SUA CLASSE VINCULADA',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: canAccess ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.ageRange ?? ''} • ${c.room ?? ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informações do Professor e Métricas
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    c.teacherName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
                Text(
                  '${c.studentsCount} matriculados',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barra de Progresso de Presença se já houver registros
            if (c.studentsCount > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.studentsCount > 0 ? c.presentCount / c.studentsCount : 0,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF047857)),
                  minHeight: 6,
                ),
              ),

            const SizedBox(height: 12),

            // Botão de Ação
            SizedBox(
              width: double.infinity,
              height: 40,
              child: canAccess
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChamadaScreen(
                              classId: c.id,
                              className: c.name,
                              canReopen: _isSuperOrAdmin,
                            ),
                          ),
                        );
                        _loadClasses();
                      },
                      icon: Icon(c.isFinalized ? Icons.visibility : Icons.check_circle_outline, size: 16),
                      label: Text(
                        c.isFinalized ? 'Visualizar Chamada' : 'Fazer Chamada da Classe',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFFCBD5E1), style: BorderStyle.solid),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Acesso restrito ao professor vinculado desta classe (RN-16).'),
                            backgroundColor: Color(0xFF64748B),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text(
                        'Acesso Restrito ao Prof. Titular',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
