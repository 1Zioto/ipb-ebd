import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedRoleFilter = 'Todos';

  final List<Map<String, dynamic>> _usuarios = [
    {
      'id': 1,
      'nome': 'Rev. Antônio Carlos Silva',
      'username': 'pastor.antonio',
      'email': 'antonio.carlos@ipb.org.br',
      'cargo': 'Pastor Titular',
      'perfil': 'Pastor',
      'status': 'Ativo',
      'ultimoAcesso': 'Hoje às 10:15',
      'permissoes': ['Acesso Total', 'Conselho', 'Dossiê Membros', 'Púlpito'],
      'doisFatores': true,
    },
    {
      'id': 2,
      'nome': 'Presb. Paulo Roberto Albuquerque',
      'username': 'pb.paulo',
      'email': 'paulo.roberto@ipb.org.br',
      'cargo': 'Presbítero Regente',
      'perfil': 'Presbítero',
      'status': 'Ativo',
      'ultimoAcesso': 'Hoje às 09:40',
      'permissoes': ['Atas do Conselho', 'Rol Canônico', 'Disciplina', 'EBD'],
      'doisFatores': true,
    },
    {
      'id': 3,
      'nome': 'Diác. Carlos Eduardo Nogueira',
      'username': 'diac.carlos',
      'email': 'carlos.eduardo@ipb.org.br',
      'cargo': 'Diácono de Plantão',
      'perfil': 'Diaconia',
      'status': 'Ativo',
      'ultimoAcesso': 'Ontem às 21:45',
      'permissoes': ['Conferência de Envelopes', 'Contagem de Cédulas', 'POS Bluetooth'],
      'doisFatores': false,
    },
    {
      'id': 4,
      'nome': 'Presb. Silas Rodrigues',
      'username': 'silas.ebd',
      'email': 'silas.rodrigues@ipb.org.br',
      'cargo': 'Superintendente Geral EBD',
      'perfil': 'Superintendente',
      'status': 'Ativo',
      'ultimoAcesso': 'Domingo às 11:30',
      'permissoes': ['Painel Geral EBD', 'Escalas', 'Diários de Classe', 'Revistas'],
      'doisFatores': true,
    },
    {
      'id': 5,
      'nome': 'Profª Débora Neves de Lima',
      'username': 'debora.prof',
      'email': 'debora.lima@ipb.org.br',
      'cargo': 'Professora Cordeirinhos',
      'perfil': 'Professor',
      'status': 'Ativo',
      'ultimoAcesso': 'Domingo às 09:10',
      'permissoes': ['Chamada Dominical', 'Lista de Alunos', 'Visitantes'],
      'doisFatores': false,
    },
    {
      'id': 6,
      'nome': 'Lucas Ferreira (TI)',
      'username': 'admin',
      'email': 'ti@ipb.org.br',
      'cargo': 'Administrador do Sistema',
      'perfil': 'Programador / Admin',
      'status': 'Ativo',
      'ultimoAcesso': 'Hoje às 08:00',
      'permissoes': ['RBAC Master', 'Auditoria Total', 'Backups', 'APIs'],
      'doisFatores': true,
    },
    {
      'id': 7,
      'nome': 'Marcos Vinícius Santos',
      'username': 'marcos.aux',
      'email': 'marcos.santos@email.com',
      'cargo': 'Auxiliar da Tesouraria',
      'perfil': 'Operador',
      'status': 'Inativo',
      'ultimoAcesso': 'Há 15 dias',
      'permissoes': ['Lançamento de Despesas'],
      'doisFatores': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsuarios {
    var list = _usuarios;
    if (_selectedRoleFilter != 'Todos') {
      list = list.where((u) => u['perfil'].toString().contains(_selectedRoleFilter)).toList();
    }
    if (_searchTerm.isEmpty) return list;
    final term = _searchTerm.toLowerCase();
    return list.where((u) {
      final nome = u['nome'].toString().toLowerCase();
      final username = u['username'].toString().toLowerCase();
      final cargo = u['cargo'].toString().toLowerCase();
      return nome.contains(term) || username.contains(term) || cargo.contains(term);
    }).toList();
  }

  // Modal para Criar ou Editar Usuário
  void _openUserModal({Map<String, dynamic>? user}) {
    final isEditing = user != null;
    final nomeCtrl = TextEditingController(text: isEditing ? user['nome'] : '');
    final userCtrl = TextEditingController(text: isEditing ? user['username'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? user['email'] : '');
    final cargoCtrl = TextEditingController(text: isEditing ? user['cargo'] : '');
    String perfilVal = isEditing ? user['perfil'] : 'Professor';
    bool statusAtivo = isEditing ? (user['status'] == 'Ativo') : true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 18,
                right: 18,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Editar Usuário do Sistema' : 'Novo Operador / Usuário',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const Text(
                                'Controle de credenciais, papel institucional e permissões',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                    const Divider(height: 22),
                    Expanded(
                      child: ListView(
                        children: [
                          TextField(
                            controller: nomeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nome do Oficial / Membro',
                              prefixIcon: const Icon(Icons.badge_rounded, size: 20, color: Color(0xFF2563EB)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: userCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Login / Usuário',
                                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20, color: Color(0xFF2563EB)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: cargoCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Cargo Eclesiástico',
                                    prefixIcon: const Icon(Icons.church_rounded, size: 20, color: Color(0xFF2563EB)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'E-mail de Notificação',
                              prefixIcon: const Icon(Icons.email_rounded, size: 20, color: Color(0xFF2563EB)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: perfilVal,
                            decoration: InputDecoration(
                              labelText: 'Papel RBAC no Sistema',
                              prefixIcon: const Icon(Icons.security_rounded, size: 20, color: Color(0xFF2563EB)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Pastor', child: Text('Pastor (Acesso Amplo & Conselho)')),
                              DropdownMenuItem(value: 'Presbítero', child: Text('Presbítero (Atas, ROL & Membresia)')),
                              DropdownMenuItem(value: 'Diaconia', child: Text('Diaconia (Coleta de Culto & POS)')),
                              DropdownMenuItem(value: 'Superintendente', child: Text('Superintendente EBD')),
                              DropdownMenuItem(value: 'Professor', child: Text('Professor EBD (Chamada & Turmas)')),
                              DropdownMenuItem(value: 'Programador / Admin', child: Text('Programador / Administrador')),
                              DropdownMenuItem(value: 'Operador', child: Text('Operador Básico')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => perfilVal = val);
                            },
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Usuário Ativo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            subtitle: const Text('Permitir login e autenticação com token no sistema', style: TextStyle(fontSize: 11)),
                            value: statusAtivo,
                            activeTrackColor: const Color(0xFF047857),
                            onChanged: (v) => setModalState(() => statusAtivo = v),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (nomeCtrl.text.trim().isEmpty) return;
                        setState(() {
                          if (isEditing) {
                            user['nome'] = nomeCtrl.text.trim();
                            user['username'] = userCtrl.text.trim();
                            user['email'] = emailCtrl.text.trim();
                            user['cargo'] = cargoCtrl.text.trim();
                            user['perfil'] = perfilVal;
                            user['status'] = statusAtivo ? 'Ativo' : 'Inativo';
                          } else {
                            _usuarios.add({
                              'id': _usuarios.length + 1,
                              'nome': nomeCtrl.text.trim(),
                              'username': userCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'cargo': cargoCtrl.text.trim(),
                              'perfil': perfilVal,
                              'status': statusAtivo ? 'Ativo' : 'Inativo',
                              'ultimoAcesso': 'Novo usuário',
                              'permissoes': ['Acesso Padrão'],
                              'doisFatores': false,
                            });
                          }
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Usuário atualizado com sucesso!' : 'Novo usuário criado com sucesso!'),
                            backgroundColor: const Color(0xFF047857),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(isEditing ? 'Salvar Usuário' : 'Cadastrar Usuário', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              'Gestão de Usuários (RBAC)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF047857)),
            tooltip: 'Novo Usuário',
            onPressed: () => _openUserModal(),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'usuarios'),
      body: Column(
        children: [
          // Banner Informativo de Segurança
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFEFF6FF),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Controle de Acesso Baseado em Papéis (RBAC). Senhas criptografadas com tokens Sanctum e permissões granulares.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),

          // Barra de Busca
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, login ou cargo...',
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

          // Pílulas de Filtro por Perfil
          Container(
            height: 42,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRoleFilterChip('Todos'),
                const SizedBox(width: 8),
                _buildRoleFilterChip('Pastor'),
                const SizedBox(width: 8),
                _buildRoleFilterChip('Presbítero'),
                const SizedBox(width: 8),
                _buildRoleFilterChip('Diaconia'),
                const SizedBox(width: 8),
                _buildRoleFilterChip('Superintendente'),
                const SizedBox(width: 8),
                _buildRoleFilterChip('Professor'),
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
                  '${_filteredUsuarios.length} USUÁRIOS REGISTRADOS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const Text('Segurança IPB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
              ],
            ),
          ),

          // Lista de Usuários
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _filteredUsuarios.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final u = _filteredUsuarios[idx];
                final isAtivo = u['status'] == 'Ativo';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFECFDF5),
                            child: Text(
                              u['nome'].toString().substring(0, 1),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857), fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['nome'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '@${u['username']}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${u['cargo']}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                            onPressed: () => _openUserModal(user: u),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildProfileBadge(u['perfil']),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAtivo ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              u['status'],
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isAtivo ? const Color(0xFF047857) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          if (u['doisFatores'] == true) ...[
                            const SizedBox(width: 8),
                            const Row(
                              children: [
                                Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF047857)),
                                SizedBox(width: 3),
                                Text('2FA Ativo', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                              ],
                            ),
                          ],
                          const Spacer(),
                          Text(
                            'Último: ${u['ultimoAcesso']}',
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
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

  Widget _buildRoleFilterChip(String label) {
    final isSelected = _selectedRoleFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = label),
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

  Widget _buildProfileBadge(String perfil) {
    Color cor = const Color(0xFF475569);
    Color bg = const Color(0xFFF1F5F9);

    if (perfil.contains('Pastor')) {
      cor = const Color(0xFF7C3AED);
      bg = const Color(0xFFF5F3FF);
    } else if (perfil.contains('Presbítero')) {
      cor = const Color(0xFF2563EB);
      bg = const Color(0xFFEFF6FF);
    } else if (perfil.contains('Diaconia')) {
      cor = const Color(0xFF047857);
      bg = const Color(0xFFECFDF5);
    } else if (perfil.contains('Programador')) {
      cor = const Color(0xFFDC2626);
      bg = const Color(0xFFFEF2F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        perfil,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: cor),
      ),
    );
  }
}
