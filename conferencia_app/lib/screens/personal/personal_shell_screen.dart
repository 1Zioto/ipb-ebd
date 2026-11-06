import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/context_controller.dart';
import '../../core/theme_controller.dart';
import '../../widgets/app_drawer.dart';
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
  final int initialIndex;
  const PersonalShellScreen({super.key, this.initialIndex = 0});

  @override
  State<PersonalShellScreen> createState() => _PersonalShellScreenState();
}

class _PersonalShellScreenState extends State<PersonalShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      _buildHomeTab(context, user, isDark),
      _buildEbdTab(context, isDark),
      const PersonalBibliaScreen(),
      _buildAgendaTab(context, isDark),
      _buildMenuTab(context, user, isDark),
    ];

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'personal'),
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
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'EBD',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Bíblia',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Mais',
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

  Widget _buildEbdTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Escola Bíblica Dominical',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Aluno Matriculado',
                style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // CARD DA MINHA CLASSE
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      foregroundColor: Color(0xFF2563EB),
                      radius: 18,
                      child: Icon(Icons.school_rounded, size: 20),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Minha Classe: Adultos & Família',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Professor(a): Presb. Responsável da Turma\nHorário: Todos os Domingos às 09:00h • Sala 02',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // LIÇÃO DO PRÓXIMO DOMINGO
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIÇÃO DO DOMINGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF2563EB))),
                ),
                const SizedBox(height: 8),
                const Text('A Soberania de Deus na Providência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text(
                  'Texto Básico: Romanos 8:28-39\nEstudo sobre a preservação e o governo soberano de Deus sobre todas as coisas.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // MURAL DA CLASSE
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Mural da Minha Turma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 6),
                Text(
                  '“Amados irmãos, lembrem-se de trazer suas Bíblias e revistas no próximo domingo. Teremos confraternização especial ao final da aula!”',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarVidaCristaModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Vida Cristã & Devocionais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Recursos espirituais para comunhão diária com Deus', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),

              Card(
                color: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plano de Leitura Bíblica Anual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                      SizedBox(height: 4),
                      Text('Leitura de hoje: Salmos 119:105-128 e Romanos 8:28-39', style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              const Text('Devocionais Reformados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.book_rounded, color: Color(0xFF047857), size: 20),
                ),
                title: const Text('Mananciais no Deserto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Meditação matinal para edificação da fé', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devocional do dia aberto no Início.')),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB45309), size: 20),
                ),
                title: const Text('Dia a Dia com Spurgeon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Reflexões bíblicas profundas e práticas', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarBibliotecaModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Biblioteca & Documentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Símbolos de Fé da IPB e materiais da Escola Bíblica', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),

              _buildBibliotecaItem('Confissão de Fé de Westminster', 'Padrão doutrinário oficial adotado pela IPB', Icons.verified_user_rounded),
              _buildBibliotecaItem('Breve Catecismo de Westminster', 'Fundamentos bíblicos em perguntas e respostas', Icons.quiz_rounded),
              _buildBibliotecaItem('Catecismo Maior de Westminster', 'Exposição teológica aprofundada dos mandamentos', Icons.menu_book_rounded),
              _buildBibliotecaItem('Revista da EBD do Trimestre', 'Lições sistemáticas para todas as faixas etárias', Icons.school_rounded),
              _buildBibliotecaItem('Manual Presbiteriano da IPB', 'Constituição, Código de Disciplina e Princípios de Liturgia', Icons.gavel_rounded),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildBibliotecaItem(String titulo, String subtitulo, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF047857)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.file_download_outlined, size: 20),
        onTap: () {},
      ),
    );
  }

  void _mostrarContatosIgrejaModal(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final churchName = user?.churchName ?? 'Igreja Presbiteriana do Brasil';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contatos da Igreja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(churchName, style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone_rounded, color: Color(0xFF047857)),
                title: Text('Secretaria da Igreja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('(27) 3345-1200 • Horário de Atendimento: Terça a Sexta 13h às 17h', style: TextStyle(fontSize: 11)),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF047857)),
                title: Text('WhatsApp Institucional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('(27) 99876-5432 • Avisos e comunicados oficiais', style: TextStyle(fontSize: 11)),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.location_on_outlined, color: Color(0xFF047857)),
                title: Text('Templo Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Cultos: Domingos às 09h (EBD) e 19h (Culto Solene). Quartas às 19h30.', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarPrestacaoContasModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prestação de Contas Anual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Exercício Financeiro — Demonstrativo Consolidado', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),

              Card(
                color: const Color(0xFFECFDF5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Parecer da Comissão de Exame de Contas:\n“Livros, extratos e comprovantes examinados e aprovados sem ressalvas pelo Conselho da Igreja.”',
                    style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildResumoFinanceiroItem('Receitas Totais', 'Dízimos, ofertas e doações', '+ R\$ 248.520,00', const Color(0xFF047857)),
              _buildResumoFinanceiroItem('Despesas Operacionais', 'Manutenção, pessoal, missões', '- R\$ 198.310,00', const Color(0xFFDC2626)),
              const Divider(height: 20),
              _buildResumoFinanceiroItem('Superávit / Saldo Acumulado', 'Saldo final em contas bancárias', 'R\$ 50.210,00', const Color(0xFF1E293B)),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildResumoFinanceiroItem(String titulo, String subtitulo, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitulo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cor)),
        ],
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context, dynamic user, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CABEÇALHO DO MEMBRO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                child: Text(
                  (user?.name != null && user!.name.isNotEmpty) ? user.name[0].toUpperCase() : 'M',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Membro da Igreja',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.role ?? 'Membro Comungante',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      user?.churchName ?? 'Igreja Presbiteriana do Brasil',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // SEÇÃO: VIDA DA IGREJA
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'VIDA DA IGREJA',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
        ),
        _buildMenuItem(
          icon: Icons.church_rounded,
          title: 'Minha Igreja',
          subtitle: 'História, liderança pastoral e congregações',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalIgrejaScreen())),
        ),
        _buildMenuItem(
          icon: Icons.newspaper_rounded,
          title: 'Avisos & Boletim Semanal',
          subtitle: 'Liturgia dominical, avisos pastorais e escala',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoletimScreen())),
        ),
        _buildMenuItem(
          icon: Icons.cake_rounded,
          title: 'Aniversariantes do Mês',
          subtitle: 'Irmãos da membresia que celebram aniversário',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAniversariantesScreen())),
        ),
        _buildMenuItem(
          icon: Icons.contact_phone_rounded,
          title: 'Contatos da Igreja & Secretaria',
          subtitle: 'Telefones, WhatsApp e horários de atendimento',
          onTap: () => _mostrarContatosIgrejaModal(context),
        ),

        const SizedBox(height: 14),

        // SEÇÃO: CRESCIMENTO ESPIRITUAL
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'CRESCIMENTO ESPIRITUAL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
        ),
        _buildMenuItem(
          icon: Icons.auto_stories_rounded,
          title: 'Vida Cristã & Devocionais',
          subtitle: 'Plano de leitura bíblica anual e edificação pessoal',
          onTap: () => _mostrarVidaCristaModal(context),
        ),
        _buildMenuItem(
          icon: Icons.local_library_rounded,
          title: 'Biblioteca & Estudos',
          subtitle: 'Símbolos de Fé de Westminster e revistas da EBD',
          onTap: () => _mostrarBibliotecaModal(context),
        ),
        _buildMenuItem(
          icon: Icons.music_note_rounded,
          title: 'Novo Cântico (Hinário)',
          subtitle: 'Letras e hinos históricos da IPB',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalHinarioScreen())),
        ),

        const SizedBox(height: 14),

        // SEÇÃO: DADOS ECLESIÁSTICOS & CONTRIBUIÇÃO
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'DADOS ECLESIÁSTICOS & CONTRIBUIÇÃO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
        ),
        _buildMenuItem(
          icon: Icons.badge_rounded,
          title: 'Carteirinha Digital do Membro',
          subtitle: 'Identificação eclesiástica oficial da IPB',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalCarteirinhaScreen())),
        ),
        _buildMenuItem(
          icon: Icons.pix_rounded,
          title: 'Dízimos & Ofertas',
          subtitle: 'Chave Pix oficial e extrato individual de doações',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDizimosScreen())),
        ),
        _buildMenuItem(
          icon: Icons.pie_chart_rounded,
          title: 'Prestação de Contas Anual',
          subtitle: 'Demonstrativo anual homologado pelo Conselho',
          onTap: () => _mostrarPrestacaoContasModal(context),
        ),
        _buildMenuItem(
          icon: Icons.assignment_rounded,
          title: 'Solicitações à Secretaria',
          subtitle: 'Certidões de batismo, casamento e declarações',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalSolicitacoesScreen())),
        ),
        _buildMenuItem(
          icon: Icons.devices_rounded,
          title: 'Meus Dispositivos & Segurança',
          subtitle: 'Gerenciar aparelhos e sessões ativas',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDispositivosScreen())),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // SAIR DO APLICATIVO
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
          title: const Text('Sair do Aplicativo', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          subtitle: const Text('Encerrar sessão no aparelho com segurança', style: TextStyle(fontSize: 11)),
          onTap: () async {
            await ApiService.instance.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        const SizedBox(height: 20),
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

