import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/context_controller.dart';
import '../screens/admin/auditoria_screen.dart';
import '../screens/admin/usuarios_screen.dart';
import '../screens/conferencias_list_screen.dart';
import '../screens/ebd/calendario_escalas_screen.dart';
import '../screens/ebd/classes_list_screen.dart';
import '../screens/ebd/ebd_dashboard_screen.dart';
import '../screens/financeiro/livro_caixa_screen.dart';
import '../screens/instituicoes/instituicoes_screen.dart';
import '../screens/intelligence_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/personal/personal_aniversariantes_screen.dart';
import '../screens/personal/personal_biblia_screen.dart';
import '../screens/personal/personal_carteirinha_screen.dart';
import '../screens/personal/personal_dispositivos_screen.dart';
import '../screens/personal/personal_dizimos_screen.dart';
import '../screens/personal/personal_hinario_screen.dart';
import '../screens/personal/personal_igreja_screen.dart';
import '../screens/personal/personal_shell_screen.dart';
import '../screens/personal/personal_solicitacoes_screen.dart';
import '../screens/secretaria/boletim_screen.dart';
import '../screens/secretaria/pessoas_screen.dart';
import '../screens/secretaria/rol_membros_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, this.currentRoute = 'home'});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final userName = user?.name ?? 'Membro IPB';
    final userRole = user?.role ?? 'Membro Comungante';
    final isPersonalContext = ContextController.instance.isPersonal || !(user?.hasManagementAccess ?? false);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // CABEÇALHO OFICIAL DO MENU (IPB)
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/images/ipb-logo.png',
                          width: 36,
                          height: 36,
                          errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857), size: 30),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Concilia-IPB',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            Text(
                              isPersonalContext ? 'Área do Membro • IPB' : 'Gestão Oficial • IPB',
                              style: const TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w600, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      userRole.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w800, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),

            // MENU ESPECÍFICO DEPENDENDO DO CONTEXTO ATIVO
            if (isPersonalContext) ...[
              // -------------------------------------------------------------
              // MENU EXCLUSIVO DO MEMBRO (12 MÓDULOS PRESBITERIANOS)
              // -------------------------------------------------------------
              _buildSectionHeader('VIDA DA IGREJA'),
              _buildMenuItem(
                context,
                icon: Icons.home_outlined,
                title: 'Início (Mural & Avisos)',
                selected: currentRoute == 'personal' || currentRoute == 'personal_inicio',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PersonalShellScreen(initialIndex: 0)),
                    (route) => false,
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.church_outlined,
                title: 'Minha Igreja & Liderança',
                selected: currentRoute == 'personal_igreja',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalIgrejaScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.calendar_month_outlined,
                title: 'Agenda & Eventos Oficiais',
                selected: currentRoute == 'personal_agenda',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PersonalShellScreen(initialIndex: 3)),
                    (route) => false,
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.newspaper_outlined,
                title: 'Avisos & Boletim Semanal',
                selected: currentRoute == 'personal_boletim',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BoletimScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.cake_outlined,
                title: 'Aniversariantes da Membresia',
                selected: currentRoute == 'personal_aniversariantes',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalAniversariantesScreen()),
                  );
                },
              ),

              _buildSectionHeader('CRESCIMENTO ESPIRITUAL'),
              _buildMenuItem(
                context,
                icon: Icons.school_outlined,
                title: 'Escola Bíblica Dominical (EBD)',
                selected: currentRoute == 'personal_ebd',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PersonalShellScreen(initialIndex: 1)),
                    (route) => false,
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.menu_book_outlined,
                title: 'Bíblia Sagrada',
                selected: currentRoute == 'personal_biblia',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalBibliaScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.music_note_outlined,
                title: 'Hinário Novo Cântico',
                selected: currentRoute == 'personal_hinario',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalHinarioScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.auto_stories_outlined,
                title: 'Vida Cristã & Devocionais',
                selected: currentRoute == 'personal_vida_crista',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PersonalShellScreen(initialIndex: 4)),
                    (route) => false,
                  );
                },
              ),

              _buildSectionHeader('DADOS ECLESIÁSTICOS & FIDELIDADE'),
              _buildMenuItem(
                context,
                icon: Icons.wallet_outlined,
                title: 'Dízimos e Ofertas (Extrato & PIX)',
                selected: currentRoute == 'personal_dizimos',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalDizimosScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.mark_email_read_outlined,
                title: 'Solicitações à Secretaria',
                selected: currentRoute == 'personal_solicitacoes',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalSolicitacoesScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.badge_outlined,
                title: 'Meus Dados & Carteirinha',
                selected: currentRoute == 'personal_carteirinha',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalCarteirinhaScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.phonelink_lock_outlined,
                title: 'Dispositivos Conectados',
                selected: currentRoute == 'personal_dispositivos',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PersonalDispositivosScreen()),
                  );
                },
              ),

              // SE POSSUIR ACESSO ADMINISTRATIVO, EXIBE BOTÃO DE TRANSIÇÃO PARA GESTÃO
              if (user?.hasManagementAccess == true) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF047857)),
                    title: const Text(
                      'Alternar para Gestão Oficial',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                    ),
                    subtitle: const Text('Painel administrativo, EBD, diaconia e finanças', style: TextStyle(fontSize: 10)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF047857), size: 18),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ContextController.instance.switchContext('management');
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              // -------------------------------------------------------------
              // MENU DE GESTÃO ADMINISTRATIVA (PARA OFICIAIS E PASTORES)
              // -------------------------------------------------------------
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person_rounded, color: Color(0xFF2563EB)),
                  title: const Text(
                    'Ir para Área do Membro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                  ),
                  subtitle: const Text('Devocionais, Bíblia, dízimos e igreja', style: TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB), size: 18),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ContextController.instance.switchContext('personal');
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PersonalShellScreen(initialIndex: 0)),
                    );
                  },
                ),
              ),

              // GRUPO 1: VISÃO GERAL & IGREJA
              _buildSectionHeader('VISÃO GERAL & IGREJA'),
              _buildMenuItem(
                context,
                icon: Icons.grid_view_rounded,
                title: 'Painel Principal (Android)',
                selected: currentRoute == 'home',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                    (route) => false,
                  );
                },
              ),
              if (ApiService.instance.isScreenEnabled('classes') || ApiService.instance.isScreenEnabled('relatorios_ebd'))
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard EBD',
                  selected: currentRoute == 'dashboard_ebd',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EbdDashboardScreen()),
                    );
                  },
                ),
              _buildMenuItem(
                context,
                icon: Icons.analytics_outlined,
                title: 'Inteligência Eclesiástica',
                selected: currentRoute == 'inteligencia',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const IntelligenceScreen()),
                  );
                },
              ),
              if (ApiService.instance.isScreenEnabled('instituicoes'))
                _buildMenuItem(
                  context,
                  icon: Icons.account_tree_outlined,
                  title: 'Estrutura Institucional',
                  selected: currentRoute == 'instituicoes',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InstituicoesScreen()),
                    );
                  },
                ),

              // GRUPO 2: EDUCAÇÃO & MINISTÉRIOS (EBD)
              if (ApiService.instance.isScreenEnabled('classes') || ApiService.instance.isScreenEnabled('calendario') || ApiService.instance.isScreenEnabled('escalas')) ...[
                _buildSectionHeader('EDUCAÇÃO & MINISTÉRIOS'),
                if (ApiService.instance.isScreenEnabled('classes'))
                  _buildMenuItem(
                    context,
                    icon: Icons.school_outlined,
                    title: 'Classes da EBD & Chamada',
                    selected: currentRoute == 'classes_ebd',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClassesListScreen()),
                      );
                    },
                  ),
                if (ApiService.instance.isScreenEnabled('calendario') || ApiService.instance.isScreenEnabled('escalas'))
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: 'Calendário & Escalas EBD',
                    selected: currentRoute == 'calendario',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CalendarioEscalasScreen()),
                      );
                    },
                  ),
              ],

              // GRUPO 3: SECRETARIA & MEMBRESIA
              if (ApiService.instance.isScreenEnabled('pessoas') || ApiService.instance.isScreenEnabled('membros') || ApiService.instance.isScreenEnabled('boletim')) ...[
                _buildSectionHeader('SECRETARIA & MEMBRESIA'),
                if (ApiService.instance.isScreenEnabled('pessoas'))
                  _buildMenuItem(
                    context,
                    icon: Icons.people_outline,
                    title: 'Pessoas & Famílias',
                    selected: currentRoute == 'pessoas',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PessoasScreen()),
                      );
                    },
                  ),
                if (ApiService.instance.isScreenEnabled('membros'))
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: 'Rol de Membros',
                    selected: currentRoute == 'rol_membros',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RolMembrosScreen()),
                      );
                    },
                  ),
                if (ApiService.instance.isScreenEnabled('boletim'))
                  _buildMenuItem(
                    context,
                    icon: Icons.newspaper_outlined,
                    title: 'Boletim Informativo Semanal',
                    selected: currentRoute == 'boletim',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BoletimScreen()),
                      );
                    },
                  ),
              ],

              // GRUPO 4: FINANÇAS & DIACONIA
              if (ApiService.instance.isScreenEnabled('dizimos') || ApiService.instance.isScreenEnabled('financeiro')) ...[
                _buildSectionHeader('FINANÇAS & DIACONIA'),
                if (ApiService.instance.isScreenEnabled('dizimos'))
                  _buildMenuItem(
                    context,
                    icon: Icons.point_of_sale_outlined,
                    title: 'Conferência de Dízimos & Culto',
                    selected: currentRoute == 'conferencia',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ConferenciasListScreen()),
                      );
                    },
                  ),
                if (ApiService.instance.isScreenEnabled('financeiro'))
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Livro Caixa (Tesouraria)',
                    selected: currentRoute == 'livro_caixa',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LivroCaixaScreen()),
                      );
                    },
                  ),
              ],

              // GRUPO 5: ADMINISTRAÇÃO & SISTEMA
              if (ApiService.instance.isScreenEnabled('usuarios') || ApiService.instance.isScreenEnabled('auditoria')) ...[
                _buildSectionHeader('ADMINISTRAÇÃO & SISTEMA'),
                if (ApiService.instance.isScreenEnabled('usuarios'))
                  _buildMenuItem(
                    context,
                    icon: Icons.manage_accounts_outlined,
                    title: 'Gestão de Usuários (RBAC)',
                    selected: currentRoute == 'usuarios',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                      );
                    },
                  ),
                if (ApiService.instance.isScreenEnabled('auditoria'))
                  _buildMenuItem(
                    context,
                    icon: Icons.history_edu_outlined,
                    title: 'Trilha de Auditoria (RN-18)',
                    selected: currentRoute == 'auditoria',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuditoriaScreen()),
                      );
                    },
                  ),
              ],
            ],

            const Divider(),

            // LOGOUT
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair do Sistema',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ApiService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF047857) : const Color(0xFF475569),
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 12.5,
          color: selected ? const Color(0xFF047857) : const Color(0xFF1E293B),
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFECFDF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
