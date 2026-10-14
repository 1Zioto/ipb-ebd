import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class InstituicoesScreen extends StatefulWidget {
  const InstituicoesScreen({super.key});

  @override
  State<InstituicoesScreen> createState() => _InstituicoesScreenState();
}

class _InstituicoesScreenState extends State<InstituicoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: const AppDrawer(currentRoute: 'instituicoes'),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/ipb-logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.church_rounded,
                  color: Color(0xFF047857),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estrutura Institucional',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF065F46),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'GOVERNO PRESBITERIANO & MINISTÉRIOS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF047857),
          indicatorWeight: 3,
          labelColor: const Color(0xFF047857),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_rounded, size: 18), text: 'Concílios'),
            Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'Conselho & Diaconia'),
            Tab(icon: Icon(Icons.stars_rounded, size: 18), text: 'Sociedades Internas'),
            Tab(icon: Icon(Icons.location_city_rounded, size: 18), text: 'Congregações'),
          ],
        ),
      ),
      body: Column(
        children: [
          // HEADER INSTITUCIONAL COMPACTO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF047857),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Igreja Presbiteriana do Brasil • Sede',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Presbitério Metropolitano (PMET) • Sínodo Pernambuco (SPE)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ORGANIZADA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF065F46),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTEÚDO DAS ABAS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConciliosTab(),
                _buildConselhoDiaconiaTab(),
                _buildSociedadesTab(),
                _buildCongregacoesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ABA 1: CONCÍLIOS & HIERARQUIA ====================
  Widget _buildConciliosTab() {
    final concilios = [
      {
        'nivel': 'Supremo Concílio (SC-IPB)',
        'sigla': 'SC',
        'sub': 'Órgão Máximo da Denominação',
        'desc': 'Concílio superior com jurisdição sobre todo o território nacional. Reúne-se ordinariamente de 4 em 4 anos para deliberar sobre a Constituição, doutrina e relações eclesiásticas.',
        'presidencia': 'Rev. Roberto Brasileiro (Pres. SC-IPB)',
        'sede': 'Brasília - DF • Sede Administrativa',
        'color': const Color(0xFF047857),
        'bg': const Color(0xFFECFDF5),
        'isAtual': false,
      },
      {
        'nivel': 'Sínodo Pernambuco (SPE)',
        'sigla': 'SPE',
        'sub': 'Concílio Regional Intermediário',
        'desc': 'Jurisdição regional que congrega os presbitérios do estado de Pernambuco. Reúne-se anualmente para julgar recursos e promover a união e expansão sinodal.',
        'presidencia': 'Rev. Marcos Albuquerque (Presidente)',
        'sede': 'Recife - PE • Jurisdição Regional',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'isAtual': false,
      },
      {
        'nivel': 'Presbitério Metropolitano (PMET)',
        'sigla': 'PMET',
        'sub': 'Concílio Jurisdicional Direto',
        'desc': 'Concílio intermediário que supervisiona diretamente as igrejas locais e os ministros da região. Responsável por ordenar pastores, fiscalizar os Conselhos e fundar congregações.',
        'presidencia': 'Rev. José Cláudio (Presidente do PMET)',
        'sede': 'Região Metropolitana • Reunião semestral',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'isAtual': false,
      },
      {
        'nivel': 'Conselho da Igreja Local (Sede)',
        'sigla': 'CON',
        'sub': 'Governo Espiritual & Administrativo Local',
        'desc': 'Constituído pelo(s) pastor(es) e presbíteros regentes eleitos pela Assembleia da Igreja. Governa a vida espiritual, admissão e disciplina de membros, e zela pelo rebanho.',
        'presidencia': 'Rev. Carlos Alexandre (Pastor Titular)',
        'sede': 'Templo Central • Reunião mensal ordinária',
        'color': const Color(0xFF047857),
        'bg': const Color(0xFFD1FAE5),
        'isAtual': true,
      },
      {
        'nivel': 'Congregação Presbiteriana Esperança',
        'sigla': 'CONG',
        'sub': 'Campo Missionário Vinculado',
        'desc': 'Comunidade missionária sob a tutela espiritual e financeira da Igreja Sede, em processo de crescimento para futura organização em igreja autônoma.',
        'presidencia': 'Seminarista Lucas & Pb. Marcos Vinicius',
        'sede': 'Bairro Novo • Cultos semanais',
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
        'isAtual': false,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: concilios.length,
      itemBuilder: (context, idx) {
        final c = concilios[idx];
        final isLast = idx == concilios.length - 1;
        final color = c['color'] as Color;
        final bg = c['bg'] as Color;
        final isAtual = c['isAtual'] as bool;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isAtual ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  width: isAtual ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAtual
                        ? const Color(0xFF047857).withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            c['sigla'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    c['nivel'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (isAtual) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF047857),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'SUA IGREJA',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c['sub'] as String,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c['desc'] as String,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c['presidencia'] as String,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c['sede'] as String,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
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
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 18,
                  child: Center(
                    child: Container(
                      width: 2.5,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ==================== ABA 2: CONSELHO & DIACONIA ====================
  Widget _buildConselhoDiaconiaTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. MINISTRO DA PALAVRA (PASTOR)
        _buildSectionHeader('MINISTRO DA PALAVRA E SACRAMENTOS', Icons.menu_book_rounded, const Color(0xFF047857)),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Rev. Carlos Alexandre',
          role: 'Pastor Titular da Igreja',
          mandato: 'Mandato Quadrienal (2024 - 2028)',
          contact: 'gabinete@ipbcentral.org.br • (81) 98877-6655',
          avatarBg: const Color(0xFFECFDF5),
          avatarColor: const Color(0xFF047857),
          badge: 'PASTOR TITULAR',
          badgeColor: const Color(0xFF047857),
        ),
        const SizedBox(height: 20),

        // 2. CONSELHO DE PRESBÍTEROS REGENTES
        _buildSectionHeader('CONSELHO DE PRESBÍTEROS (GOVERNO LOCAL)', Icons.groups_rounded, const Color(0xFF2563EB)),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Pb. Roberto Silva',
          role: 'Vice-Presidente do Conselho',
          mandato: 'Mandato Canônico 2024 - 2029',
          contact: 'Comissão de Doutrina e Educação Bíblica',
          avatarBg: const Color(0xFFEFF6FF),
          avatarColor: const Color(0xFF2563EB),
          badge: 'VICE-PRESIDENTE',
          badgeColor: const Color(0xFF2563EB),
        ),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Pb. Antônio Mendes',
          role: 'Secretário do Conselho',
          mandato: 'Mandato Canônico 2022 - 2027',
          contact: 'Livro de Atas, Rol de Membros e Correspondência',
          avatarBg: const Color(0xFFEFF6FF),
          avatarColor: const Color(0xFF2563EB),
          badge: 'SECRETÁRIO',
          badgeColor: const Color(0xFF1D4ED8),
        ),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Pb. Marcos Vinicius',
          role: 'Presbítero Regente',
          mandato: 'Mandato Canônico 2023 - 2028',
          contact: 'Superintendência da EBD e Congregação Esperança',
          avatarBg: const Color(0xFFEFF6FF),
          avatarColor: const Color(0xFF2563EB),
          badge: 'PRESBÍTERO',
          badgeColor: const Color(0xFF475569),
        ),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Pb. Eduardo Santos',
          role: 'Presbítero Regente',
          mandato: 'Mandato Canônico 2025 - 2030',
          contact: 'Comissão de Finanças, Contabilidade e Patrimônio',
          avatarBg: const Color(0xFFEFF6FF),
          avatarColor: const Color(0xFF2563EB),
          badge: 'PRESBÍTERO',
          badgeColor: const Color(0xFF475569),
        ),
        const SizedBox(height: 20),

        // 3. JUNTA DIACONAL
        _buildSectionHeader('JUNTA DIACONAL (BENEFICÊNCIA & TEMPLO)', Icons.volunteer_activism_rounded, const Color(0xFFD97706)),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Dc. Carlos Eduardo',
          role: 'Presidente da Junta Diaconal',
          mandato: 'Mandato 2024 - 2027',
          contact: 'Coordenação geral de plantões, escalas e conferência de cultos',
          avatarBg: const Color(0xFFFFFBEB),
          avatarColor: const Color(0xFFD97706),
          badge: 'PRES. DIACONAL',
          badgeColor: const Color(0xFFD97706),
        ),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Dc. Marcos Paulo',
          role: 'Secretário da Junta Diaconal',
          mandato: 'Mandato 2024 - 2027',
          contact: 'Atas diaconais, tesouraria dos pobres e relatórios',
          avatarBg: const Color(0xFFFFFBEB),
          avatarColor: const Color(0xFFD97706),
          badge: 'SECRETÁRIO',
          badgeColor: const Color(0xFFB45309),
        ),
        const SizedBox(height: 8),
        _buildOfficerCard(
          name: 'Dc. João Batista & Dc. Samuel Rocha',
          role: 'Diáconos de Plantão & Ação Social',
          mandato: 'Mandato 2023 - 2026',
          contact: 'Cestas básicas, socorro a famílias e recepção nos cultos',
          avatarBg: const Color(0xFFFFFBEB),
          avatarColor: const Color(0xFFD97706),
          badge: 'DIÁCONOS',
          badgeColor: const Color(0xFF64748B),
        ),
      ],
    );
  }

  // ==================== ABA 3: SOCIEDADES INTERNAS ====================
  Widget _buildSociedadesTab() {
    final sociedades = [
      {
        'sigla': 'SAF',
        'nome': 'Sociedade Auxiliadora Feminina',
        'lema': '"Sejamos Verdadeiras Auxiliadoras"',
        'publico': 'Mulheres da Igreja Presbiteriana',
        'socias': '48 sócias ativas',
        'reuniao': 'Terças-feiras às 15:00 • Salão Social',
        'presidencia': 'Sra. Maria Helena Costa',
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'icon': Icons.spa_rounded,
        'atividades': 'Visitação a enfermos, bazares missionários, apoio a lares carentes e oração pelas vocações.',
      },
      {
        'sigla': 'UPH',
        'nome': 'União Presbiteriana de Homens',
        'lema': '"Confiança em Jesus, Entusiasmo na Ação"',
        'publico': 'Homens da Igreja Presbiteriana',
        'socias': '42 sócios ativos',
        'reuniao': '1º Sábado do Mês às 07:30 (Café com Oração)',
        'presidencia': 'Ir. Fernando Albuquerque',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'icon': Icons.shield_rounded,
        'atividades': 'Manutenção e reformas do templo, evangelismo pessoal e suporte às atividades dos oficiais.',
      },
      {
        'sigla': 'UMP',
        'nome': 'União de Mocidade Presbiteriana',
        'lema': '"Alegres na Esperança, Fortes na Fé, Dedicados no Amor"',
        'publico': 'Jovens a partir de 18 anos',
        'socias': '38 jovens ativos',
        'reuniao': 'Sábados às 19:30 • Auditório Jovem',
        'presidencia': 'Gabriel Souza',
        'color': const Color(0xFF047857),
        'bg': const Color(0xFFECFDF5),
        'icon': Icons.local_fire_department_rounded,
        'atividades': 'Congressos da mocidade, viagens missionárias, discipulado bíblico e grupo de louvor.',
      },
      {
        'sigla': 'UPA',
        'nome': 'União Presbiteriana de Adolescentes',
        'lema': '"Ao Mestre Servindo"',
        'publico': 'Adolescentes de 12 a 17 anos',
        'socias': '25 adolescentes',
        'reuniao': 'Sábados às 17:00 • Sala UPA',
        'presidencia': 'Mariana Lima',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'icon': Icons.bolt_rounded,
        'atividades': 'Acampamentos de férias, gincanas bíblicas, projetos sociais e formação de liderança cristã.',
      },
      {
        'sigla': 'UCP',
        'nome': 'União de Crianças Presbiterianas',
        'lema': '"Batalhando por Cristo"',
        'publico': 'Crianças até 11 anos',
        'socias': '34 crianças cadastradas',
        'reuniao': 'Domingos às 09:00 durante a EBD',
        'presidencia': 'Profa. Renata Vasconcelos (Conselheira)',
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'icon': Icons.child_care_rounded,
        'atividades': 'Escola Bíblica de Férias (EBF), corais infantis, memorização bíblica e teatrinhos bíblicos.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: sociedades.length,
      itemBuilder: (context, idx) {
        final s = sociedades[idx];
        final color = s['color'] as Color;
        final bg = s['bg'] as Color;
        final icon = s['icon'] as IconData;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s['sigla'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s['nome'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s['lema'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Presidente: ',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                        Expanded(
                          child: Text(
                            s['presidencia'] as String,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Público: ',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                        Expanded(
                          child: Text(
                            '${s['publico']} • ${s['socias']}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s['reuniao'] as String,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s['atividades'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== ABA 4: CONGREGAÇÕES & CAMPOS ====================
  Widget _buildCongregacoesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // TEMPLO CENTRAL
        _buildLocationCard(
          title: 'Igreja Presbiteriana Sede (Templo Central)',
          type: 'SEDE ADMINISTRATIVA & ECLESIÁSTICA',
          typeColor: const Color(0xFF047857),
          typeBg: const Color(0xFFD1FAE5),
          address: 'Av. Principal da Fé, nº 500 • Centro',
          pastor: 'Rev. Carlos Alexandre',
          services: 'Dom: 09h (EBD) & 19h (Culto Solene) • Qua: 19h30 (Oração)',
          stats: '342 membros cadastrados • 450 lugares',
          icon: Icons.church_rounded,
        ),
        const SizedBox(height: 14),

        // CONGREGAÇÃO ESPERANÇA
        _buildLocationCard(
          title: 'Congregação Presbiteriana Esperança',
          type: 'CAMPO MISSIONÁRIO VINCULADO',
          typeColor: const Color(0xFF2563EB),
          typeBg: const Color(0xFFDBEAFE),
          address: 'Rua da Paz, nº 120 • Bairro Novo',
          pastor: 'Seminarista Lucas & Pb. Marcos Vinicius',
          services: 'Dom: 18h (Culto) • Qui: 19h30 (Estudo Bíblico)',
          stats: '52 membros comungantes • 120 lugares',
          icon: Icons.home_work_rounded,
        ),
        const SizedBox(height: 14),

        // PONTO DE PREGAÇÃO BETHEL
        _buildLocationCard(
          title: 'Ponto de Pregação Bethel',
          type: 'PONTO MISSIONÁRIO EM FORMAÇÃO',
          typeColor: const Color(0xFFD97706),
          typeBg: const Color(0xFFFEF3C7),
          address: 'Comunidade Boa Vista, s/n • Zona Norte',
          pastor: 'Evangelista Tiago & Diaconia de Plantão',
          services: 'Sábado: 19h (Culto Evangelístico & Ação Social)',
          stats: '28 freqüentadores assíduos • Cestas básicas',
          icon: Icons.alt_route_rounded,
        ),
        const SizedBox(height: 20),

        // DADOS CADASTRAIS DA ENTIDADE
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_rounded, size: 16, color: Color(0xFF047857)),
                  SizedBox(width: 6),
                  Text(
                    'DADOS CADASTRAIS & REGISTRO ECLESIÁSTICO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Razão Social:', 'Igreja Presbiteriana do Brasil em Cidade Central'),
              _buildInfoRow('CNPJ:', '00.123.456/0001-78'),
              _buildInfoRow('Código Eclesiástico:', 'SC-SPE-PMET-042'),
              _buildInfoRow('Data de Organização:', '12 de Outubro de 1978 (48 anos de fundação)'),
              _buildInfoRow('Constituição Vigente:', 'Constituição da Igreja Presbiteriana do Brasil (CI/IPB)'),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET HELPER: SEÇÃO DE TÍTULO
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // WIDGET HELPER: CARD DE OFICIAL
  Widget _buildOfficerCard({
    required String name,
    required String role,
    required String mandato,
    required String contact,
    required Color avatarBg,
    required Color avatarColor,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarBg,
            child: Icon(Icons.person_rounded, color: avatarColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mandato,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER: CARD DE CONGREGAÇÃO
  Widget _buildLocationCard({
    required String title,
    required String type,
    required Color typeColor,
    required Color typeBg,
    required String address,
    required String pastor,
    required String services,
    required String stats,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: typeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Endereço:', address),
          _buildInfoRow('Liderança:', pastor),
          _buildInfoRow('Cultos:', services),
          _buildInfoRow('Estatísticas:', stats),
        ],
      ),
    );
  }

  // WIDGET HELPER: LINHA DE INFORMAÇÃO CHAVE-VALOR
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
