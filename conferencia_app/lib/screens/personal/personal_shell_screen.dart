import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/context_controller.dart';
import '../../core/theme_controller.dart';
import '../login_screen.dart';
import '../main_menu_screen.dart';
import '../secretaria/boletim_screen.dart';
import 'personal_aniversariantes_screen.dart';
import 'personal_biblia_screen.dart';
import 'personal_carteirinha_screen.dart';
import 'personal_dispositivos_screen.dart';
import 'personal_dizimos_screen.dart';
import 'personal_hinario_screen.dart';
import 'personal_igreja_screen.dart';
import 'personal_solicitacoes_screen.dart';

class PersonalShellScreen extends StatefulWidget {
  const PersonalShellScreen({super.key});

  @override
  State<PersonalShellScreen> createState() => _PersonalShellScreenState();
}

class _PersonalShellScreenState extends State<PersonalShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      _buildHomeTab(context, user, isDark),
      _buildAgendaTab(context, isDark),
      const PersonalBibliaScreen(),
      const PersonalIgrejaScreen(),
      _buildMenuTab(context, user, isDark),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                ],
              ),
              child: Image.asset(
                'assets/images/ipb-logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857), size: 24),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concilia-IPB',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF047857)),
                ),
                Text(
                  user?.churchName ?? 'Igreja Presbiteriana do Brasil',
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // BOTÃO ALTERNAR TEMA (CLARO / ESCURO)
          IconButton(
            tooltip: isDark ? 'Tema Claro' : 'Tema Escuro',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => ThemeController.instance.toggleTheme(),
          ),

          // CHIP DE ALTERNÂNCIA PARA GESTÃO (SE AUTORIZADO)
          if (user?.hasManagementAccess == true)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: const Color(0xFFECFDF5),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
                avatar: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF047857)),
                label: const Text(
                  'Gestão',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                onPressed: () async {
                  await ContextController.instance.switchContext('management');
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                  );
                },
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Bíblia',
          ),
          NavigationDestination(
            icon: Icon(Icons.church_outlined),
            selectedIcon: Icon(Icons.church_rounded),
            label: 'Igreja',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, dynamic user, bool isDark) {
    final userName = user?.name ?? 'Irmão(ã)';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BOAS-VINDAS E CARD INSTITUCIONAL
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A paz do Senhor, $userName',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                '“Alegrei-me quando me disseram: Vamos à Casa do SENHOR.” — Salmo 122:1',
                style: TextStyle(color: Color(0xFFA7F3D0), fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // DEVOCIONAL DO DIA (LEITURA SÓBRIA)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('DEVOCIONAL DO DIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF047857))),
                    ),
                    const Text('03 de Novembro', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('A Excelência da Graça Soberana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text(
                  '“Porque pela graça sois salvos, mediante a fé; e isto não vem de vós; é dom de Deus.” (Efésios 2:8)\n\nA suficiência da obra redentora de Cristo nos concede a certeza inabalável de que pertencemos ao Senhor em vida e na morte.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // BOLETIM DOMINICAL & LITURGIA
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              foregroundColor: Color(0xFF2563EB),
              child: Icon(Icons.newspaper_rounded),
            ),
            title: const Text('Boletim Informativo Semanal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Liturgia do culto, hinos, avisos e aniversariantes', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BoletimScreen()),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ACESSO RÁPIDO AOS DÍZIMOS E PIX
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFECFDF5),
              foregroundColor: Color(0xFF047857),
              child: Icon(Icons.pix_rounded),
            ),
            title: const Text('Dízimos & Ofertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Chave Pix oficial, contas e histórico pessoal consolidado', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PersonalDizimosScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Agenda da Igreja & Atividades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildAgendaCard('08 de Novembro (Domingo)', '09:00', 'Escola Bíblica Dominical', 'Classes de todas as faixas etárias'),
        _buildAgendaCard('08 de Novembro (Domingo)', '19:00', 'Culto Solene de Adoração', 'Mensagem pastoral e celebração da Ceia'),
        _buildAgendaCard('11 de Novembro (Quarta)', '19:30', 'Reunião de Oração e Doutrina', 'Estudo expositivo na Confissão de Westminster'),
        _buildAgendaCard('14 de Novembro (Sábado)', '16:00', 'Reunião Mensal da SAF', 'Sociedade Auxiliadora Feminina no salão social'),
      ],
    );
  }

  static Widget _buildAgendaCard(String data, String hora, String titulo, String sub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 11)),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub, style: const TextStyle(fontSize: 11)),
            Text(data, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context, dynamic user, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CABEÇALHO DO MEMBRO
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF047857),
            foregroundColor: Colors.white,
            child: Icon(Icons.person, size: 28),
          ),
          title: Text(user?.name ?? 'Membro IPB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(user?.role ?? 'Membro Comungante', style: const TextStyle(fontSize: 12)),
        ),

        const Divider(height: 24),

        // ITENS DO MENU COMPLEMENTAR DA ÁREA PESSOAL
        _buildMenuItem(
          icon: Icons.badge_rounded,
          title: 'Carteirinha Digital',
          subtitle: 'Identificação simples de membro',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalCarteirinhaScreen())),
        ),
        _buildMenuItem(
          icon: Icons.music_note_rounded,
          title: 'Novo Cântico (Hinário)',
          subtitle: 'Letras e hinos da IPB offline',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalHinarioScreen())),
        ),
        _buildMenuItem(
          icon: Icons.payments_rounded,
          title: 'Dízimos & Ofertas',
          subtitle: 'Chave Pix oficial e extrato validado',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDizimosScreen())),
        ),
        _buildMenuItem(
          icon: Icons.assignment_rounded,
          title: 'Solicitações à Secretaria',
          subtitle: 'Certidões e atualizações cadastrais',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalSolicitacoesScreen())),
        ),
        _buildMenuItem(
          icon: Icons.cake_rounded,
          title: 'Aniversariantes do Mês',
          subtitle: 'Irmãos que celebram aniversário',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAniversariantesScreen())),
        ),
        _buildMenuItem(
          icon: Icons.devices_rounded,
          title: 'Meus Dispositivos & Segurança',
          subtitle: 'Gerenciar aparelhos e sessões ativas',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDispositivosScreen())),
        ),

        const Divider(height: 24),

        // SAIR DO APLICATIVO
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
          title: const Text('Sair do Aplicativo', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          onTap: () async {
            await ApiService.instance.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF047857)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}

