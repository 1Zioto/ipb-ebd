import 'package:flutter/material.dart';
import '../../core/ebd_service.dart';
import '../../models/ebd_models.dart';

class ChamadaScreen extends StatefulWidget {
  final int classId;
  final String className;
  final bool canReopen;

  const ChamadaScreen({
    super.key,
    required this.classId,
    required this.className,
    this.canReopen = true,
  });

  @override
  State<ChamadaScreen> createState() => _ChamadaScreenState();
}

class _ChamadaScreenState extends State<ChamadaScreen> {
  bool _loading = true;
  EbdSessionDetailsModel? _session;
  final _offerController = TextEditingController();
  final _teacherController = TextEditingController();
  final _biblesAggController = TextEditingController();
  final _magazinesAggController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _teacherController.dispose();
    _biblesAggController.dispose();
    _magazinesAggController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() => _loading = true);
    final session = await EbdService.instance.getSessionForClass(widget.classId);
    if (!mounted) return;

    if (session != null) {
      _teacherController.text = session.teacherName;
      _offerController.text = session.offerAmount > 0 ? session.offerAmount.toStringAsFixed(2) : '';
      _biblesAggController.text = session.biblesTotal.toString();
      _magazinesAggController.text = session.magazinesTotal.toString();
    }

    setState(() {
      _session = session;
      _loading = false;
    });
  }

  bool get _isReadOnly => _session?.status == 'finalizada';

  void _togglePresent(AttendanceRecordModel record) {
    if (_isReadOnly) {
      _showReadOnlyAlert();
      return;
    }
    setState(() {
      record.isPresent = !record.isPresent;
      if (!record.isPresent) {
        // Se ficou ausente, zera Bíblia e Revista
        record.broughtBible = false;
        record.broughtMagazine = false;
      } else {
        // Por padrão ao marcar presença, marca Bíblia
        record.broughtBible = true;
      }
    });
    _autoSavePartial();
  }

  void _toggleBible(AttendanceRecordModel record) {
    if (_isReadOnly) {
      _showReadOnlyAlert();
      return;
    }
    if (!record.isPresent) return;
    setState(() {
      record.broughtBible = !record.broughtBible;
    });
    _autoSavePartial();
  }

  void _toggleMagazine(AttendanceRecordModel record) {
    if (_isReadOnly) {
      _showReadOnlyAlert();
      return;
    }
    if (!record.isPresent) return;
    setState(() {
      record.broughtMagazine = !record.broughtMagazine;
    });
    _autoSavePartial();
  }

  void _markAllPresent() {
    if (_isReadOnly) return;
    setState(() {
      for (final r in _session!.records) {
        r.isPresent = true;
        r.broughtBible = true;
        r.broughtMagazine = true;
      }
    });
    _autoSavePartial();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos os alunos marcados como presentes!')),
    );
  }

  Future<void> _autoSavePartial() async {
    if (_session == null) return;
    final offer = double.tryParse(_offerController.text.replaceAll(',', '.')) ?? 0.0;
    final biblesAgg = int.tryParse(_biblesAggController.text) ?? 0;
    final magAgg = int.tryParse(_magazinesAggController.text) ?? 0;

    await EbdService.instance.saveAttendance(
      classId: widget.classId,
      records: _session!.records,
      teacherName: _teacherController.text.trim(),
      materialMode: _session!.materialMode,
      biblesAgg: biblesAgg,
      magazinesAgg: magAgg,
      offerAmount: offer,
    );
  }

  Future<void> _handleFinalize() async {
    if (_session == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Chamada?'),
        content: Text(
          'Deseja fechar a chamada da ${widget.className}?\n\n'
          '• Presentes: ${_session!.presentCount} de ${_session!.totalStudents}\n'
          '• Bíblias: ${_session!.biblesCount}\n'
          '• Revistas: ${_session!.magazinesCount}\n\n'
          'Após finalizar, a chamada ficará bloqueada contra edições acidentais (RN-15).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Revisar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar & Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    await _autoSavePartial();
    await EbdService.instance.finalizeSession(widget.classId);
    if (!mounted) return;

    setState(() {
      _session!.status = 'finalizada';
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chamada finalizada com sucesso! Dados sincronizados.'),
        backgroundColor: Color(0xFF047857),
      ),
    );
  }

  Future<void> _handleReopen() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir Chamada?'),
        content: const Text(
          'A chamada será reaberta para edição e todas as alterações serão registradas no log de auditoria (RN-14 / RN-18).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await EbdService.instance.reopenSession(widget.classId);
    if (!mounted) return;

    setState(() {
      _session!.status = 'em_andamento';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chamada reaberta para edição.'),
        backgroundColor: Color(0xFFD97706),
      ),
    );
  }

  void _showReadOnlyAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chamada finalizada. Para alterar, solicite a reabertura pelo superintendente.'),
        backgroundColor: Color(0xFF64748B),
      ),
    );
  }

  void _editTeacherDialog() {
    if (_isReadOnly) return;
    final controller = TextEditingController(text: _teacherController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Professor do Dia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A escala sugere o professor titular, mas você pode registrar a substituição real de hoje (RN-13):',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nome do Professor que Ministrou',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _teacherController.text = controller.text.trim();
              });
              _autoSavePartial();
              Navigator.of(ctx).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.className)),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF047857))),
      );
    }

    final totalAlunos = _session!.totalStudents;
    final presentes = _session!.presentCount;
    final percent = totalAlunos > 0 ? (presentes / totalAlunos * 100).toInt() : 0;
    final isFinalized = _session!.status == 'finalizada';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.className,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
            Text(
              _session!.eventDate,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (isFinalized && widget.canReopen)
            IconButton(
              tooltip: 'Reabrir Chamada',
              icon: const Icon(Icons.lock_open, color: Color(0xFFD97706)),
              onPressed: _handleReopen,
            ),
          if (!isFinalized)
            IconButton(
              tooltip: 'Marcar todos presentes',
              icon: const Icon(Icons.done_all, color: Color(0xFF047857)),
              onPressed: _markAllPresent,
            ),
        ],
      ),
      body: Column(
        children: [
          // HUD DINÂMICO FIXO NO TOPO (TOTALIZADOR DE PRESENÇA)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FREQUÊNCIA DA CLASSE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$presentes / $totalAlunos',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF047857),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                '$percent%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Badges de Bíblias e Revistas
                    Row(
                      children: [
                        _buildMetricPill('📖 ${_session!.biblesCount}', 'Bíblias'),
                        const SizedBox(width: 6),
                        _buildMetricPill('📚 ${_session!.magazinesCount}', 'Revistas'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Professor do dia e Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _isReadOnly ? null : _editTeacherDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Color(0xFF047857)),
                            const SizedBox(width: 6),
                            Text(
                              'Prof: ${_teacherController.text}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                            if (!_isReadOnly) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 11, color: Color(0xFF94A3B8)),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFinalized
                            ? const Color(0xFFECFDF5)
                            : (_session!.status == 'em_andamento' ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFinalized
                              ? const Color(0xFFA7F3D0)
                              : (_session!.status == 'em_andamento' ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFinalized ? Icons.check_circle : Icons.pending,
                            size: 12,
                            color: isFinalized ? const Color(0xFF047857) : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFinalized ? 'FINALIZADA' : (_session!.status == 'em_andamento' ? 'EM ANDAMENTO' : 'PENDENTE'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isFinalized ? const Color(0xFF047857) : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE ALUNOS COM TOQUE ÁGIL (ABRIR -> MARCAR -> SALVAR)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _session!.records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = _session!.records[index];
                return _buildStudentCard(r);
              },
            ),
          ),

          // RODAPÉ COM OFERTA DA CLASSE E BOTÃO DE FINALIZAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de Oferta da Classe
                  Row(
                    children: [
                      const Text(
                        'Oferta da Classe:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _offerController,
                            enabled: !_isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              prefixText: 'R\$ ',
                              hintText: '0,00',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _autoSavePartial(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Botão de Finalizar Chamada
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFinalized ? const Color(0xFF64748B) : const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isFinalized ? 0 : 2,
                      ),
                      onPressed: (_isSaving || isFinalized) ? (_isSaving ? null : _showReadOnlyAlert) : _handleFinalize,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(isFinalized ? Icons.lock : Icons.check_circle_outline),
                      label: Text(
                        _isSaving ? 'Finalizando Chamada...' : (isFinalized ? 'Chamada Finalizada (Bloqueada)' : 'Salvar & Finalizar Chamada Dominical'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(AttendanceRecordModel r) {
    final isPresent = r.isPresent;

    return Container(
      decoration: BoxDecoration(
        color: isPresent ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          width: isPresent ? 1.5 : 1.0,
        ),
        boxShadow: isPresent
            ? [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _togglePresent(r),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Checkbox grande / Botão de presença fácil
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPresent ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPresent ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Icon(
                    isPresent ? Icons.check : Icons.close,
                    color: isPresent ? Colors.white : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Nome do Aluno e Indicadores
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.studentName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isPresent ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (r.isBirthdayToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF2F8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFBCFE8)),
                              ),
                              child: const Text('🎂 Hoje!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDB2777))),
                            )
                          else if (r.isBirthdayWeek)
                            const Text('🎂', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.envelopeNumber != null ? 'Envelope #${r.envelopeNumber}' : 'Aluno Regular',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Toggles de Bíblia e Revista (só ativos se presente)
                Row(
                  children: [
                    _buildMaterialChip(
                      icon: Icons.menu_book,
                      label: 'Bíblia',
                      active: r.broughtBible,
                      enabled: isPresent && !_isReadOnly,
                      onTap: () => _toggleBible(r),
                    ),
                    const SizedBox(width: 6),
                    _buildMaterialChip(
                      icon: Icons.book,
                      label: 'Revista',
                      active: r.broughtMagazine,
                      enabled: isPresent && !_isReadOnly,
                      onTap: () => _toggleMagazine(r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialChip({
    required IconData icon,
    required String label,
    required bool active,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? const Color(0xFF047857) : (enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? const Color(0xFF065F46) : (enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String val, String lbl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          Text(lbl, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
