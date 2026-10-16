import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/models.dart';
import '../widgets/app_drawer.dart';
import 'admin/usuarios_screen.dart';
import 'admin/auditoria_screen.dart';
import 'configuracoes_impressora_screen.dart';
import 'ebd/classes_list_screen.dart';
import 'ebd/calendario_escalas_screen.dart';
import 'ebd/ebd_dashboard_screen.dart';
import 'etiquetas_membros_screen.dart';
import 'financeiro/livro_caixa_screen.dart';
import 'conferencias_list_screen.dart';
import 'instituicoes/instituicoes_screen.dart';
import 'login_screen.dart';
import 'secretaria/boletim_screen.dart';
import 'secretaria/pessoas_screen.dart';
import 'secretaria/rol_membros_screen.dart';
import 'intelligence_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _navIndex = 0;
  List<MemberModel> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _syncScreens();
  }

  Future<void> _syncScreens() async {
    await ApiService.instance.fetchScreenConfigs();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadMembers() async {
    final list = await ApiService.instance.getMembers();
    if (!mounted) return;
    setState(() => _members = list);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Sair do Aplicativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Deseja encerrar a sessão? Seus dados sincronizados continuarão seguros.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.instance.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sim, Sair', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openConferencia({int initialTab = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ConferenciasListScreen(),
      ),
    );
  }

  String _formatDatePtBr(DateTime date) {
    const weekdays = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
      'Sexta-feira', 'Sábado', 'Domingo'
    ];
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    return '$weekday, $day de $month';
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final userName = user?.name ?? 'Oficial IPB';
    final userRole = user?.role ?? 'Diácono / Oficial';
    final isOffline = ApiService.instance.isOffline;

    final now = DateTime.now();
    final capitalizedDate = _formatDatePtBr(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fundo suave Android
      drawer: const AppDrawer(currentRoute: 'home'),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/ipb-logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.church_rounded,
                  color: Color(0xFF047857),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Igreja Presbiteriana',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF065F46),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'PAINEL PRINCIPAL • ANDROID',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botão Logout
          IconButton(
            tooltip: 'Sair',
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadMembers(),
            _syncScreens(),
          ]);
        },
        child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. CARD DE SAUDAÇÃO & PERFIL (Material You Style)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFECFDF5),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF047857),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Graça e Paz, $userName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              userRole.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isOffline)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OFFLINE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        capitalizedDate,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. VERSÍCULO DEVOCIONAL / PALAVRA DO DIA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF047857),
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"Alegrei-me quando me disseram: Vamos à Casa do SENHOR."',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Salmo 122:1 • Devocional IPB',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. INDICADORES DO DASHBOARD EM TEMPO REAL (KPIs)
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildKpiCard(
                  label: 'INTELIGÊNCIA',
                  value: 'IPB',
                  valueExtra: 'Analytics',
                  subtext: 'Central de Indicadores',
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF047857),
                  lightColor: const Color(0xFFECFDF5),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IntelligenceScreen()),
                    );
                  },
                ),
                const SizedBox(width: 10),
                if (ApiService.instance.isScreenEnabled('dizimos')) ...[
                  _buildKpiCard(
                    label: 'ÚLTIMO CULTO',
                    value: 'R\$ 6.040',
                    subtext: '100% Conciliado • 38 env.',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF047857),
                    lightColor: const Color(0xFFECFDF5),
                    onTap: () => _openConferencia(initialTab: 2),
                  ),
                  const SizedBox(width: 10),
                ],
                if (ApiService.instance.isScreenEnabled('classes') || ApiService.instance.isScreenEnabled('relatorios_ebd')) ...[
                  _buildKpiCard(
                    label: 'EBD DOMINGO',
                    value: '142',
                    valueExtra: '(88%)',
                    subtext: '8 classes • 12 novos',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF2563EB),
                    lightColor: const Color(0xFFEFF6FF),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EbdDashboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                if (ApiService.instance.isScreenEnabled('pessoas') || ApiService.instance.isScreenEnabled('membros')) ...[
                  _buildKpiCard(
                    label: 'ROL MEMBROS',
                    value: '${_members.isNotEmpty ? _members.length : 342}',
                    valueExtra: 'ativos',
                    subtext: 'Rol de Membros Atualizado',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF7C3AED),
                    lightColor: const Color(0xFFF5F3FF),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PessoasScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                if (ApiService.instance.isScreenEnabled('financeiro')) ...[
                  _buildKpiCard(
                    label: 'META DO MÊS',
                    value: '88%',
                    valueExtra: 'R\$ 24,8k',
                    subtext: 'Meta: R\$ 28.000 / mês',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFD97706),
                    lightColor: const Color(0xFFFFFBEB),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LivroCaixaScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. BARRA DE ATALHOS RÁPIDOS
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                if (ApiService.instance.isScreenEnabled('dizimos')) ...[
                  _buildQuickActionPill(
                    label: '+ Envelope',
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: const Color(0xFF047857),
                    onTap: () => _openConferencia(initialTab: 0),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionPill(
                    label: 'Contar Cédulas',
                    icon: Icons.pin_outlined,
                    iconColor: const Color(0xFF047857),
                    onTap: () => _openConferencia(initialTab: 1),
                  ),
                  const SizedBox(width: 8),
                ],
                if (ApiService.instance.isScreenEnabled('classes')) ...[
                  _buildQuickActionPill(
                    label: 'Chamada EBD',
                    icon: Icons.assignment_turned_in_outlined,
                    iconColor: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClassesListScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (ApiService.instance.isScreenEnabled('membros') || ApiService.instance.isScreenEnabled('pessoas')) ...[
                  _buildQuickActionPill(
                    label: 'Etiquetas QR',
                    icon: Icons.qr_code_2_rounded,
                    iconColor: const Color(0xFF047857),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EtiquetasMembrosScreen(members: _members),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (ApiService.instance.isScreenEnabled('boletim')) ...[
                  _buildQuickActionPill(
                    label: 'Boletim',
                    icon: Icons.newspaper_rounded,
                    iconColor: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BoletimScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (ApiService.instance.isScreenEnabled('pessoas') || ApiService.instance.isScreenEnabled('membros')) ...[
                  _buildQuickActionPill(
                    label: 'Buscar Membro',
                    icon: Icons.search_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PessoasScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. HERO CARD EM DESTAQUE: CONFERÊNCIA DO CULTO
          if (ApiService.instance.isScreenEnabled('dizimos')) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF065F46), Color(0xFF022C22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars_rounded, color: Color(0xFFFDE68A), size: 14),
                            SizedBox(width: 5),
                            Text(
                              'CULTO & DIACONIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conferência de Dízimos & Ofertas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lançamento ágil de envelopes lacrados, contagem por cédulas e fechamento com impressão de comprovante.',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF047857),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _openConferencia(initialTab: 0),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'Abrir Conferência',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _openConferencia(initialTab: 1),
                        child: const Row(
                          children: [
                            Icon(Icons.calculate_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Cédulas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6. CARD DE ARRECADAÇÃO & DISTRIBUIÇÃO DO MÊS
          if (ApiService.instance.isScreenEnabled('financeiro') || ApiService.instance.isScreenEnabled('dizimos')) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
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
                      const Row(
                        children: [
                          Icon(Icons.pie_chart_rounded, size: 16, color: Color(0xFF047857)),
                          SizedBox(width: 6),
                          Text(
                            'ARRECADAÇÃO DO MÊS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LivroCaixaScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'Ver Livro Caixa',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'R\$ 24.850,00',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'acumulado (88% da meta)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Barra segmentada de progresso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(flex: 75, child: Container(color: const Color(0xFF047857))),
                          const SizedBox(width: 2),
                          Expanded(flex: 18, child: Container(color: const Color(0xFF2563EB))),
                          const SizedBox(width: 2),
                          Expanded(flex: 7, child: Container(color: const Color(0xFF7C3AED))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Legenda da distribuição
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFinanceLegend(
                        color: const Color(0xFF047857),
                        label: 'Dízimos (75%)',
                        value: 'R\$ 18.630',
                      ),
                      _buildFinanceLegend(
                        color: const Color(0xFF2563EB),
                        label: 'Ofertas (18%)',
                        value: 'R\$ 4.480',
                      ),
                      _buildFinanceLegend(
                        color: const Color(0xFF7C3AED),
                        label: 'Missões (7%)',
                        value: 'R\$ 1.740',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 7. CARD DE AGENDA & DIACONIA DE PLANTÃO
          if (ApiService.instance.isScreenEnabled('calendario') || ApiService.instance.isScreenEnabled('escalas')) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarioEscalasScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text(
                                  'PRÓXIMO CULTO & ESCALA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CalendarioEscalasScreen()),
                                );
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'Ver Escalas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF2563EB)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    'DOM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                  Text(
                                    '19:00',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Culto Solene de Adoração',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Plantão Diaconal: Carlos Eduardo & Marcos Paulo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.cake_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Aniversariantes da semana: Alice Costa (Hoje! 🎉) • Roberto Silva (Sex)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // 3. CATEGORIA: DIACONIA & OPERAÇÃO
          ...() {
            final diaconiaCards = [
              if (ApiService.instance.isScreenEnabled('dizimos'))
                _MenuCardItem(
                  title: 'Lançamento Envelopes',
                  subtitle: 'Entrada por QR Code ou Membro',
                  icon: Icons.mark_email_read_rounded,
                  iconColor: const Color(0xFF059669),
                  badge: 'Principal',
                  onTap: () => _openConferencia(initialTab: 0),
                ),
              if (ApiService.instance.isScreenEnabled('dizimos'))
                _MenuCardItem(
                  title: 'Contagem de Cédulas',
                  subtitle: 'Totalizador de notas e moedas',
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF0D9488),
                  onTap: () => _openConferencia(initialTab: 1),
                ),
              if (ApiService.instance.isScreenEnabled('dizimos'))
                _MenuCardItem(
                  title: 'Fechamento do Culto',
                  subtitle: 'Batimento, conciliação e recibo',
                  icon: Icons.verified_rounded,
                  iconColor: const Color(0xFF10B981),
                  onTap: () => _openConferencia(initialTab: 2),
                ),
              if (ApiService.instance.isScreenEnabled('membros') || ApiService.instance.isScreenEnabled('pessoas'))
                _MenuCardItem(
                  title: 'Etiquetas & QR Codes',
                  subtitle: 'Gerar etiquetas dos dizimistas',
                  icon: Icons.qr_code_2_rounded,
                  iconColor: const Color(0xFF047857),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EtiquetasMembrosScreen(members: _members)),
                    );
                  },
                ),
            ];

            if (diaconiaCards.isEmpty) return <Widget>[];

            return <Widget>[
              _buildCategoryHeader('DIACONIA & CULTO', Icons.volunteer_activism_rounded, const Color(0xFF047857)),
              const SizedBox(height: 10),
              _buildCardsGrid(diaconiaCards),
              const SizedBox(height: 22),
            ];
          }(),

          // 4. CATEGORIA: EDUCAÇÃO CRISTÃ (EBD)
          ...() {
            final ebdCards = [
              if (ApiService.instance.isScreenEnabled('classes') || ApiService.instance.isScreenEnabled('relatorios_ebd'))
                _MenuCardItem(
                  title: 'Painel da EBD',
                  subtitle: 'Visão de presenças e métricas',
                  icon: Icons.dashboard_customize_rounded,
                  iconColor: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EbdDashboardScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('classes'))
                _MenuCardItem(
                  title: 'Classes & Chamada',
                  subtitle: 'Diário de classe e frequência',
                  icon: Icons.fact_check_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  badge: 'Dominical',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ClassesListScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('boletim'))
                _MenuCardItem(
                  title: 'Boletim Semanal',
                  subtitle: 'Leitura e escala do domingo',
                  icon: Icons.newspaper_rounded,
                  iconColor: const Color(0xFF60A5FA),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BoletimScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('calendario') || ApiService.instance.isScreenEnabled('escalas'))
                _MenuCardItem(
                  title: 'Calendário & Escalas',
                  subtitle: 'Professores, plantões e cultos',
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF1D4ED8),
                  badge: 'Escalas',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarioEscalasScreen()),
                    );
                  },
                ),
            ];

            if (ebdCards.isEmpty) return <Widget>[];

            return <Widget>[
              _buildCategoryHeader('ESCOLA BÍBLICA DOMINICAL (EBD)', Icons.school_rounded, const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              _buildCardsGrid(ebdCards),
              const SizedBox(height: 22),
            ];
          }(),

          // 5. CATEGORIA: SECRETARIA & MEMBRESIA
          ...() {
            final secretariaCards = [
              if (ApiService.instance.isScreenEnabled('pessoas'))
                _MenuCardItem(
                  title: 'Cadastro de Membros',
                  subtitle: 'Ficha completa e consulta rápida',
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PessoasScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('membros'))
                _MenuCardItem(
                  title: 'Rol de Membros',
                  subtitle: 'Comungantes e não-comungantes',
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RolMembrosScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('instituicoes'))
                _MenuCardItem(
                  title: 'Estrutura & Igreja',
                  subtitle: 'Presbitério, sínodo e congregações',
                  icon: Icons.account_tree_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InstituicoesScreen()),
                    );
                  },
                ),
            ];

            if (secretariaCards.isEmpty) return <Widget>[];

            return <Widget>[
              _buildCategoryHeader('SECRETARIA ECLESIÁSTICA', Icons.folder_shared_rounded, const Color(0xFF7C3AED)),
              const SizedBox(height: 10),
              _buildCardsGrid(secretariaCards),
              const SizedBox(height: 22),
            ];
          }(),

          // 6. CATEGORIA: FINANCEIRO & ADMINISTRAÇÃO
          ...() {
            final financeiroCards = [
              if (ApiService.instance.isScreenEnabled('financeiro'))
                _MenuCardItem(
                  title: 'Livro Caixa',
                  subtitle: 'Entradas, saídas e conciliação',
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LivroCaixaScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('usuarios'))
                _MenuCardItem(
                  title: 'Gestão de Usuários',
                  subtitle: 'Papéis RBAC e credenciais',
                  icon: Icons.manage_accounts_rounded,
                  iconColor: const Color(0xFF2563EB),
                  badge: 'Segurança',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                    );
                  },
                ),
              if (ApiService.instance.isScreenEnabled('auditoria'))
                _MenuCardItem(
                  title: 'Trilha de Auditoria',
                  subtitle: 'Logs e conformidade RN-18',
                  icon: Icons.history_edu_rounded,
                  iconColor: const Color(0xFFD97706),
                  badge: 'Auditoria',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuditoriaScreen()),
                    );
                  },
                ),
              _MenuCardItem(
                title: 'Impressora POS',
                subtitle: 'Configurações de bobina e Bluetooth',
                icon: Icons.print_rounded,
                iconColor: const Color(0xFF10B981),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConfiguracoesImpressoraScreen()),
                  );
                },
              ),
            ];

            return <Widget>[
              _buildCategoryHeader('FINANCEIRO & AUDITORIA', Icons.account_balance_wallet_rounded, const Color(0xFFD97706)),
              const SizedBox(height: 10),
              _buildCardsGrid(financeiroCards),
              const SizedBox(height: 26),
            ];
          }(),

          // RODAPÉ DISCRETO
          Center(
            child: Column(
              children: [
                Text(
                  'Igreja Presbiteriana do Brasil • Sistema Integrado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Versão 1.1.0 • Desenvolvido para Android',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
      ),

      // 7. BARRA INFERIOR DE NAVEGAÇÃO ANDROID (Material 3 NavigationBar Dinâmica)
      bottomNavigationBar: () {
        final navDestinations = <_NavDestinationItem>[
          _NavDestinationItem(
            destination: const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF047857)),
              label: 'Início',
            ),
            onTap: () {},
          ),
          if (ApiService.instance.isScreenEnabled('dizimos'))
            _NavDestinationItem(
              destination: const NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments_rounded, color: Color(0xFF047857)),
                label: 'Conferência',
              ),
              onTap: () => _openConferencia(),
            ),
          if (ApiService.instance.isScreenEnabled('classes'))
            _NavDestinationItem(
              destination: const NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded, color: Color(0xFF047857)),
                label: 'EBD',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EbdDashboardScreen()),
              ),
            ),
          if (ApiService.instance.isScreenEnabled('pessoas') || ApiService.instance.isScreenEnabled('membros'))
            _NavDestinationItem(
              destination: const NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF047857)),
                label: 'Membros',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PessoasScreen()),
              ),
            ),
          _NavDestinationItem(
            destination: const NavigationDestination(
              icon: Icon(Icons.logout_rounded),
              label: 'Sair',
            ),
            onTap: _handleLogout,
          ),
        ];

        final safeIndex = _navIndex.clamp(0, navDestinations.length - 1);

        return NavigationBar(
          selectedIndex: safeIndex,
          elevation: 3,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD1FAE5),
          onDestinationSelected: (idx) {
            if (idx != 0) {
              navDestinations[idx].onTap();
              setState(() => _navIndex = 0);
            } else {
              setState(() => _navIndex = 0);
            }
          },
          destinations: navDestinations.map((e) => e.destination).toList(),
        );
      }(),
    );
  }

  // HEADER DE CATEGORIAS
  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // GRID 2 COLUNAS DE CARDS
  Widget _buildCardsGrid(List<_MenuCardItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, idx) {
            final item = items[idx];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(18),
                splashColor: item.iconColor.withValues(alpha: 0.1),
                highlightColor: item.iconColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 20,
                            ),
                          ),
                          if (item.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                item.badge!,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceLegend({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    String? valueExtra,
    required String subtext,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 13, color: color),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                if (valueExtra != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    valueExtra,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 9, color: color),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    subtext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionPill({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final VoidCallback onTap;

  _MenuCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.badge,
    required this.onTap,
  });
}

class _NavDestinationItem {
  final NavigationDestination destination;
  final VoidCallback onTap;

  const _NavDestinationItem({
    required this.destination,
    required this.onTap,
  });
}
