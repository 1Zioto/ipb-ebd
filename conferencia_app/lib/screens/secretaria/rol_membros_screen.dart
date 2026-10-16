import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_service.dart';
import '../../widgets/app_drawer.dart';

class RolMembrosScreen extends StatefulWidget {
  const RolMembrosScreen({super.key});

  @override
  State<RolMembrosScreen> createState() => _RolMembrosScreenState();
}

class _RolMembrosScreenState extends State<RolMembrosScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedStatusFilter = 'todos'; // 'todos', 'comungante', 'nao_comungante', 'sob_disciplina', 'jurisdicao_especial', 'falecido'

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _membros = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'comungantes': 0,
    'nao_comungantes': 0,
    'sob_disciplina': 0,
    'jurisdicao_especial': 0,
    'falecidos': 0,
  };

  @override
  void initState() {
    super.initState();
    _carregarMembros();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarMembros() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.getRolMembros(
        status: _selectedStatusFilter == 'todos' ? null : _selectedStatusFilter,
        search: _searchTerm.isEmpty ? null : _searchTerm,
        perPage: 300,
      );

      final list = (res['membros'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      final statsMap = res['stats'] is Map ? Map<String, dynamic>.from(res['stats'] as Map) : <String, dynamic>{};

      if (mounted) {
        setState(() {
          _membros = list;
          _stats = statsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Não foi possível carregar os membros. Verifique sua conexão.';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembros {
    var list = _membros;

    if (_selectedStatusFilter != 'todos') {
      list = list.where((m) {
        final st = (m['canonical_status'] ?? m['status'] ?? '').toString().toLowerCase();
        return st == _selectedStatusFilter;
      }).toList();
    }

    if (_searchTerm.trim().isNotEmpty) {
      final query = _searchTerm.trim().toLowerCase();
      list = list.where((m) {
        final nome = (m['full_name'] ?? m['nome'] ?? '').toString().toLowerCase();
        final rol = (m['roll_number'] ?? m['rol'] ?? '').toString().toLowerCase();
        final cpf = (m['cpf'] ?? '').toString().toLowerCase();
        final phone = (m['phone'] ?? m['tel'] ?? '').toString().toLowerCase();
        return nome.contains(query) || rol.contains(query) || cpf.contains(query) || phone.contains(query);
      }).toList();
    }

    return list;
  }

  // Formatação de data amigável
  String _formatDate(dynamic dateVal) {
    if (dateVal == null || dateVal.toString().trim().isEmpty) return '—';
    final str = dateVal.toString().trim();
    if (str.contains('/')) return str;
    try {
      final dt = DateTime.parse(str);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return str;
    }
  }

  // Informações de condição eclesiástica
  Map<String, dynamic> _getStatusConfig(String? rawStatus) {
    final st = (rawStatus ?? 'comungante').toLowerCase();
    switch (st) {
      case 'comungante':
        return {
          'label': 'Comungante',
          'color': const Color(0xFF047857),
          'bg': const Color(0xFFECFDF5),
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'nao_comungante':
        return {
          'label': 'Não-Comungante',
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFEFF6FF),
          'icon': Icons.child_care_rounded,
        };
      case 'sob_disciplina':
        return {
          'label': 'Sob Disciplina',
          'color': const Color(0xFFE11D48),
          'bg': const Color(0xFFFFF1F2),
          'icon': Icons.gavel_rounded,
        };
      case 'jurisdicao_especial':
        return {
          'label': 'Jurisdição Esp.',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFFFBEB),
          'icon': Icons.shield_outlined,
        };
      case 'falecido':
        return {
          'label': 'Falecido',
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF1F5F9),
          'icon': Icons.bookmark_border_rounded,
        };
      default:
        return {
          'label': rawStatus ?? 'Comungante',
          'color': const Color(0xFF047857),
          'bg': const Color(0xFFECFDF5),
          'icon': Icons.person_outline_rounded,
        };
    }
  }

  String _getModoRecepcaoLabel(dynamic rawModo) {
    if (rawModo == null || rawModo.toString().isEmpty) return 'Não informado';
    final m = rawModo.toString();
    switch (m) {
      case 'profissao_fe_batismo':
        return 'Profissão de Fé e Batismo';
      case 'profissao_fe':
        return 'Profissão de Fé';
      case 'transferencia':
        return 'Carta de Transferência';
      case 'batismo_infantil':
        return 'Batismo Infantil';
      case 'jurisdicao':
        return 'Jurisdição Especial';
      default:
        return m;
    }
  }

  String _getIniciais(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'MB';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Future<void> _abrirWhatsApp(String? telefone) async {
    if (telefone == null || telefone.trim().isEmpty) return;
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final fullNumber = digits.startsWith('55') ? digits : '55$digits';
    final url = Uri.parse('https://wa.me/$fullNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o WhatsApp para $telefone')),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // MODAL DE VISUALIZAÇÃO COMPLETA (DOSSIÊ DO MEMBRO)
  // -------------------------------------------------------------
  void _mostrarDetalhesMembro(Map<String, dynamic> m) {
    final nome = m['full_name'] ?? m['nome'] ?? 'Membro';
    final rol = m['roll_number'] ?? m['rol'] ?? 'S/N';
    final stConfig = _getStatusConfig(m['canonical_status'] ?? m['status']);
    final modo = _getModoRecepcaoLabel(m['reception_type'] ?? m['modo']);
    final admissao = _formatDate(m['reception_date'] ?? m['admissao']);
    final batismo = _formatDate(m['baptism_date']);
    final profissao = _formatDate(m['profession_date']);
    final phone = (m['phone'] ?? m['tel'] ?? '').toString();
    final email = (m['email'] ?? '').toString();
    final cpf = (m['cpf'] ?? '').toString();
    final estadoCivil = (m['marital_status'] ?? m['estadoCivil'] ?? '').toString();
    final conjuge = (m['spouse_name'] ?? m['conjuge'] ?? '').toString();
    final notes = (m['notes'] ?? m['observacoes'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Indicador de arraste
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // Header do Membro
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: stConfig['bg'],
                      child: Text(
                        _getIniciais(nome),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: stConfig['color']),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stConfig['bg'],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: (stConfig['color'] as Color).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  stConfig['label'],
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: stConfig['color']),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ROL #$rol',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Conteúdo em rolagem
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Botões de Ação Rápida
                    Row(
                      children: [
                        if (phone.isNotEmpty) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirWhatsApp(phone),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _mostrarEditarMembro(m);
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            label: const Text('Editar Dados', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF047857),
                              side: const BorderSide(color: Color(0xFF047857)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Seção 1: Dados Eclesiásticos
                    _buildSectionTitle('DADOS ECLESIÁSTICOS & ROL', Icons.menu_book_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Nº do ROL Oficial', '#$rol', isHighlighted: true),
                          const Divider(height: 16),
                          _buildDetailRow('Condição Eclesiástica', stConfig['label']),
                          const Divider(height: 16),
                          _buildDetailRow('Modo de Recepção', modo),
                          const Divider(height: 16),
                          _buildDetailRow('Data da Admissão', admissao),
                          const Divider(height: 16),
                          _buildDetailRow('Data do Batismo', batismo),
                          const Divider(height: 16),
                          _buildDetailRow('Profissão de Fé', profissao),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seção 2: Pessoal & Família
                    _buildSectionTitle('CONTATO & FAMÍLIA', Icons.people_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Telefone / Celular', phone.isNotEmpty ? phone : 'Não informado', onCopy: phone.isNotEmpty ? () => _copiar(phone) : null),
                          const Divider(height: 16),
                          _buildDetailRow('E-mail', email.isNotEmpty ? email : 'Não informado', onCopy: email.isNotEmpty ? () => _copiar(email) : null),
                          const Divider(height: 16),
                          _buildDetailRow('CPF', cpf.isNotEmpty ? cpf : 'Não informado'),
                          const Divider(height: 16),
                          _buildDetailRow('Estado Civil', estadoCivil.isNotEmpty ? estadoCivil : 'Não informado'),
                          if (conjuge.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildDetailRow('Cônjuge', conjuge),
                          ],
                        ],
                      ),
                    ),

                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('OBSERVAÇÕES DA SECRETARIA', Icons.notes_rounded),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          notes,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // MODAL DE EDIÇÃO DE MEMBRO
  // -------------------------------------------------------------
  void _mostrarEditarMembro(Map<String, dynamic> m) {
    final id = m['id'] is int ? m['id'] as int : int.tryParse(m['id']?.toString() ?? '0') ?? 0;
    final nomeCtrl = TextEditingController(text: (m['full_name'] ?? m['nome'] ?? '').toString());
    final rolCtrl = TextEditingController(text: (m['roll_number'] ?? m['rol'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (m['phone'] ?? m['tel'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (m['email'] ?? '').toString());
    final cpfCtrl = TextEditingController(text: (m['cpf'] ?? '').toString());
    final admissaoCtrl = TextEditingController(text: (m['reception_date'] ?? m['admissao'] ?? '').toString());
    final batismoCtrl = TextEditingController(text: (m['baptism_date'] ?? '').toString());
    final profissaoCtrl = TextEditingController(text: (m['profession_date'] ?? '').toString());
    final estadoCivilCtrl = TextEditingController(text: (m['marital_status'] ?? m['estadoCivil'] ?? 'Casado').toString());
    final conjugeCtrl = TextEditingController(text: (m['spouse_name'] ?? m['conjuge'] ?? '').toString());
    final obsCtrl = TextEditingController(text: (m['notes'] ?? m['observacoes'] ?? '').toString());

    String canonicalStatus = (m['canonical_status'] ?? m['status'] ?? 'comungante').toString().toLowerCase();
    if (!['comungante', 'nao_comungante', 'sob_disciplina', 'jurisdicao_especial', 'falecido'].contains(canonicalStatus)) {
      canonicalStatus = 'comungante';
    }

    String modoRecepcao = (m['reception_type'] ?? m['modo'] ?? 'profissao_fe_batismo').toString();
    if (!['profissao_fe_batismo', 'profissao_fe', 'transferencia', 'batismo_infantil', 'jurisdicao'].contains(modoRecepcao)) {
      modoRecepcao = 'profissao_fe_batismo';
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Barra de arraste
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Header Edição
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Color(0xFF047857), size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Editar Dados Eclesiásticos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Formulário
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInputField(controller: nomeCtrl, label: 'Nome Completo', icon: Icons.person_rounded),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildInputField(controller: rolCtrl, label: 'Nº do ROL', icon: Icons.numbers_rounded, hint: '001'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 5,
                              child: _buildDropdownField<String>(
                                label: 'Condição Eclesiástica',
                                value: canonicalStatus,
                                items: const [
                                  DropdownMenuItem(value: 'comungante', child: Text('Comungante')),
                                  DropdownMenuItem(value: 'nao_comungante', child: Text('Não-Comungante')),
                                  DropdownMenuItem(value: 'sob_disciplina', child: Text('Sob Disciplina')),
                                  DropdownMenuItem(value: 'jurisdicao_especial', child: Text('Jurisdição Especial')),
                                  DropdownMenuItem(value: 'falecido', child: Text('Falecido')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => canonicalStatus = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildDropdownField<String>(
                          label: 'Modo de Recepção',
                          value: modoRecepcao,
                          items: const [
                            DropdownMenuItem(value: 'profissao_fe_batismo', child: Text('Profissão de Fé e Batismo')),
                            DropdownMenuItem(value: 'profissao_fe', child: Text('Profissão de Fé')),
                            DropdownMenuItem(value: 'transferencia', child: Text('Carta de Transferência')),
                            DropdownMenuItem(value: 'batismo_infantil', child: Text('Batismo Infantil')),
                            DropdownMenuItem(value: 'jurisdicao', child: Text('Jurisdição Especial')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => modoRecepcao = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePickerField(
                                context: context,
                                controller: admissaoCtrl,
                                label: 'Data Recepção',
                                icon: Icons.event_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDatePickerField(
                                context: context,
                                controller: batismoCtrl,
                                label: 'Data Batismo',
                                icon: Icons.water_drop_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePickerField(
                                context: context,
                                controller: profissaoCtrl,
                                label: 'Profissão de Fé',
                                icon: Icons.verified_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInputField(controller: estadoCivilCtrl, label: 'Estado Civil', icon: Icons.favorite_border_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildInputField(controller: conjugeCtrl, label: 'Nome do Cônjuge', icon: Icons.people_outline_rounded),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(controller: phoneCtrl, label: 'Telefone / WhatsApp', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInputField(controller: cpfCtrl, label: 'CPF', icon: Icons.badge_outlined, keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildInputField(controller: emailCtrl, label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 14),

                        _buildInputField(controller: obsCtrl, label: 'Observações da Secretaria', icon: Icons.note_alt_outlined, maxLines: 3),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Botão Salvar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final nomeNovo = nomeCtrl.text.trim();
                                    if (nomeNovo.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Por favor, informe o nome do membro.')),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSaving = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);

                                    final payload = <String, dynamic>{
                                      'full_name': nomeNovo,
                                      'canonical_status': canonicalStatus,
                                      'roll_number': rolCtrl.text.trim(),
                                      'reception_type': modoRecepcao,
                                      'reception_date': admissaoCtrl.text.trim().isEmpty ? null : admissaoCtrl.text.trim(),
                                      'baptism_date': batismoCtrl.text.trim().isEmpty ? null : batismoCtrl.text.trim(),
                                      'profession_date': profissaoCtrl.text.trim().isEmpty ? null : profissaoCtrl.text.trim(),
                                      'marital_status': estadoCivilCtrl.text.trim(),
                                      'spouse_name': conjugeCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                      'email': emailCtrl.text.trim(),
                                      'cpf': cpfCtrl.text.trim(),
                                      'notes': obsCtrl.text.trim(),
                                    };

                                    try {
                                      if (id > 0) {
                                        await ApiService.instance.updateMembroCanonical(id, payload);
                                      }

                                      if (!mounted) return;

                                      // Atualizar localmente
                                      setState(() {
                                        final idx = _membros.indexWhere((item) => (item['id'] ?? 0) == id);
                                        if (idx != -1) {
                                          _membros[idx] = {
                                            ..._membros[idx],
                                            ...payload,
                                            'nome': nomeNovo,
                                            'rol': rolCtrl.text.trim(),
                                          };
                                        }
                                      });

                                      navigator.pop();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Membro "$nomeNovo" atualizado com sucesso!'),
                                          backgroundColor: const Color(0xFF047857),
                                        ),
                                      );
                                    } catch (err) {
                                      setModalState(() => isSaving = false);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao salvar: $err'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_rounded, size: 20),
                            label: Text(
                              isSaving ? 'Salvando...' : 'Salvar Alterações',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$texto" copiado para a área de transferência!'), duration: const Duration(seconds: 2)),
    );
  }

  // -------------------------------------------------------------
  // BUILD PRINCIPAL DA TELA
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembros;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rol de Membros',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                Text(
                  '${_membros.length} membros no rol oficial',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar Lista',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF047857)),
            onPressed: _carregarMembros,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'rol_membros'),
      body: Column(
        children: [
          // Banner Oficial IPB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFECFDF5),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF047857), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Livro Oficial do Conselho da Igreja Presbiteriana do Brasil (Constituição da IPB, Art. 12).',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                  ),
                ),
              ],
            ),
          ),

          // Barra de Busca
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchTerm = val);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nome, ROL, CPF ou telefone...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF047857), size: 20),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Chips de Filtro por Status
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _buildFilterChip('todos', 'Todos', _stats['total'] ?? _membros.length),
                  const SizedBox(width: 6),
                  _buildFilterChip('comungante', 'Comungantes', _stats['comungantes']),
                  const SizedBox(width: 6),
                  _buildFilterChip('nao_comungante', 'Não-Comungantes', _stats['nao_comungantes']),
                  const SizedBox(width: 6),
                  _buildFilterChip('sob_disciplina', 'Sob Disciplina', _stats['sob_disciplina']),
                  const SizedBox(width: 6),
                  _buildFilterChip('jurisdicao_especial', 'Jurisdição Esp.', _stats['jurisdicao_especial']),
                  const SizedBox(width: 6),
                  _buildFilterChip('falecido', 'Falecidos', _stats['falecidos']),
                ],
              ),
            ),
          ),

          // Lista de Membros
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF047857)),
                        SizedBox(height: 12),
                        Text('Carregando membros da igreja...', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _carregarMembros,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Tentar Novamente'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF047857),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Nenhum membro encontrado.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _searchTerm.isNotEmpty
                                        ? 'Tente ajustar os termos da sua busca.'
                                        : 'Não há registros para o status selecionado.',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _carregarMembros,
                            color: const Color(0xFF047857),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final m = filtered[idx];
                                return _buildMemberCard(m);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD DE CADA MEMBRO NA LISTA
  // -------------------------------------------------------------
  Widget _buildMemberCard(Map<String, dynamic> m) {
    final nome = m['full_name'] ?? m['nome'] ?? 'Membro Sem Nome';
    final rol = m['roll_number'] ?? m['rol'] ?? 'S/N';
    final stConfig = _getStatusConfig(m['canonical_status'] ?? m['status']);
    final modo = _getModoRecepcaoLabel(m['reception_type'] ?? m['modo']);
    final admissao = _formatDate(m['reception_date'] ?? m['admissao']);
    final phone = (m['phone'] ?? m['tel'] ?? '').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _mostrarDetalhesMembro(m),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge ROL
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ROL',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#$rol',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Informações do Membro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stConfig['bg'],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stConfig['label'],
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: stConfig['color']),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            modo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admissão: $admissao',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              // Botões de Ação
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 19),
                      tooltip: 'WhatsApp',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _abrirWhatsApp(phone),
                    ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: Color(0xFF047857), size: 20),
                    tooltip: 'Ver Dossiê',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _mostrarDetalhesMembro(m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 19),
                    tooltip: 'Editar Membro',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _mostrarEditarMembro(m),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGETS AUXILIARES
  // -------------------------------------------------------------
  Widget _buildFilterChip(String key, String label, dynamic count) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF475569)),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatusFilter = key);
      },
      selectedColor: const Color(0xFF047857),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide.none),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF047857)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF047857), letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false, VoidCallback? onCopy}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onCopy,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
                      color: isHighlighted ? const Color(0xFF047857) : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            DateTime initial = DateTime.now();
            try {
              if (controller.text.isNotEmpty) {
                initial = DateTime.parse(controller.text);
              }
            } catch (_) {}

            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              controller.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            hintText: 'AAAA-MM-DD',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
