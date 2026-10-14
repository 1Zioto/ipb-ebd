import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'main_menu_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final List<WelcomeSlideData> _slides = [
    const WelcomeSlideData(
      tag: 'BEM-VINDO',
      tagColor: Color(0xFFD97706),
      icon: Icons.account_balance_rounded,
      iconColor: Color(0xFF10B981),
      metric: 'Gestão Integrada & Eclesiástica',
      title: 'Excelência no Ministério Local',
      subtitle:
          'Um aplicativo desenvolvido sob medida para a diaconia, professores da EBD, oficiais e conselho da Igreja Presbiteriana do Brasil.',
      verse: '“Mas faça-se tudo decentemente e com ordem.”',
      verseRef: '1 Coríntios 14:40',
    ),
    const WelcomeSlideData(
      tag: 'DIACONIA & CULTO',
      tagColor: Color(0xFF059669),
      icon: Icons.payments_rounded,
      iconColor: Color(0xFF34D399),
      metric: 'Fechamento de Culto em Minutos',
      title: 'Conferência de Dízimos & Ofertas',
      subtitle:
          'Contagem de cédulas em tempo real, lançamento de envelopes lacrados e impressão imediata de comprovante em mini-impressoras Bluetooth.',
      verse:
          '“Cada um contribua segundo propôs no seu coração... porque Deus ama quem dá com alegria.”',
      verseRef: '2 Coríntios 9:7',
    ),
    const WelcomeSlideData(
      tag: 'ENSINO BÍBLICO',
      tagColor: Color(0xFF2563EB),
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF60A5FA),
      metric: 'Chamada Rápida & Gestão de Classes',
      title: 'Escola Dominical na Palma da Mão',
      subtitle:
          'Realize a frequência dominical em segundos, registre novos alunos e visitantes e consulte o histórico de lições diretamente no celular.',
      verse:
          '“Instrui o menino no caminho em que deve andar, e até quando envelhecer não se desviará dele.”',
      verseRef: 'Provérbios 22:6',
    ),
    const WelcomeSlideData(
      tag: 'TRANSPARÊNCIA',
      tagColor: Color(0xFF7C3AED),
      icon: Icons.verified_user_rounded,
      iconColor: Color(0xFFA78BFA),
      metric: 'Auditoria & Segurança Reforçada',
      title: 'Confiabilidade & Prestação de Contas',
      subtitle:
          'Total integração com o Livro Caixa da Tesouraria, trilha de auditoria completa e criptografia em conformidade com as normas da IPB.',
      verse:
          '“Pois zelamos pelo que é honesto, não só diante do Senhor, mas também diante dos homens.”',
      verseRef: '2 Coríntios 8:21',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _savePreferenceAndNavigate(Widget destination) async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_welcome_screen', true);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _onEnterLogin() {
    _savePreferenceAndNavigate(const LoginScreen());
  }

  Future<void> _onOfflineQuickAccess() async {
    await ApiService.instance.loginOffline('Diaconia IPB');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo Conferência Offline iniciado com sucesso.'),
        backgroundColor: Color(0xFF047857),
      ),
    );
    _savePreferenceAndNavigate(const MainMenuScreen());
  }

  void _showServerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF064E3B),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF34D399), size: 22),
            SizedBox(width: 8),
            Text(
              'Servidor da Igreja',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endpoint ativo da API em nuvem / rede IPB:',
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF022C22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link_rounded, color: Color(0xFF34D399), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ApiService.baseUrl,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Status: Online e sincronizado com o sistema central da IPB.',
              style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: const Color(0xFF022C22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022C22),
      body: Stack(
        children: [
          // Fundo em Gradiente Verde Presbiteriano Profundo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF065F46),
                  Color(0xFF022C22),
                  Color(0xFF011A14),
                ],
              ),
            ),
          ),

          // Luzes decorativas sutis
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withValues(alpha: 0.10),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Top Bar com Logo Oficial da IPB e Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/ipb-logo.png',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.church_rounded,
                            color: Color(0xFF047857),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Igreja Presbiteriana',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'SISTEMA INTEGRADO MOBILE',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: Color(0xFF10B981),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'v1.0',
                              style: TextStyle(
                                color: Color(0xFFA7F3D0),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. PageView de Carrossel de Boas-Vindas
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),

                            // Art Card com Ilustração / Ícone
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Tag do Slide
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: slide.tagColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: slide.tagColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      slide.tag,
                                      style: TextStyle(
                                        color: slide.tagColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Bolha de Ícone
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: Colors.white.withValues(alpha: 0.08),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: Icon(
                                      slide.icon,
                                      size: 42,
                                      color: slide.iconColor,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Pílula com Métrica / Benefício
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Color(0xFF34D399),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          slide.metric,
                                          style: const TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Título & Descrição
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Card de Versículo Bíblico Reformado
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: const Border(
                                  left: BorderSide(color: Color(0xFFF59E0B), width: 3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide.verse,
                                    style: const TextStyle(
                                      color: Color(0xFFFEF3C7),
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      slide.verseRef,
                                      style: const TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 3. Indicador de Paginação (Dots)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(_slides.length, (idx) {
                          final isCurrent = idx == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: isCurrent ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF10B981)
                                  : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                      Text(
                        '0${_currentPage + 1} / 0${_slides.length}',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Ações Inferiores (Botão Principal, Modo Offline, Checkbox, Config)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF011A14).withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Botão 1: Acessar Minha Conta (Login)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF047857),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFF10B981)),
                            ),
                          ),
                          onPressed: _onEnterLogin,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Acessar com Credenciais',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botão 2: Conferência Offline Rápida
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE2E8F0),
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _onOfflineQuickAccess,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Conferência de Culto Offline',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Checkbox "Não mostrar novamente" e Botão "Configurar Servidor"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _dontShowAgain = !_dontShowAgain);
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _dontShowAgain,
                                    activeColor: const Color(0xFF10B981),
                                    checkColor: const Color(0xFF022C22),
                                    side: const BorderSide(color: Colors.white38),
                                    onChanged: (val) {
                                      setState(() => _dontShowAgain = val ?? false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Não mostrar na próxima',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6EE7B7),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _showServerDialog,
                            icon: const Icon(Icons.settings_outlined, size: 14),
                            label: const Text(
                              'Servidor Local',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeSlideData {
  final String tag;
  final Color tagColor;
  final IconData icon;
  final Color iconColor;
  final String metric;
  final String title;
  final String subtitle;
  final String verse;
  final String verseRef;

  const WelcomeSlideData({
    required this.tag,
    required this.tagColor,
    required this.icon,
    required this.iconColor,
    required this.metric,
    required this.title,
    required this.subtitle,
    required this.verse,
    required this.verseRef,
  });
}
