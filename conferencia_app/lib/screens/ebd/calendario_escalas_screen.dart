import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class CalendarioEscalasScreen extends StatefulWidget {
  final int initialTab;

  const CalendarioEscalasScreen({super.key, this.initialTab = 0});

  @override
  State<CalendarioEscalasScreen> createState() => _CalendarioEscalasScreenState();
}

class _CalendarioEscalasScreenState extends State<CalendarioEscalasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
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
      drawer: const AppDrawer(currentRoute: 'calendario'),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendário & Escalas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'EBD • DIACONIA • CULTOS • MINISTÉRIOS',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
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
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Escala EBD'),
            Tab(icon: Icon(Icons.volunteer_activism_rounded, size: 18), text: 'Plantão Diaconal'),
            Tab(icon: Icon(Icons.music_note_rounded, size: 18), text: 'Louvor & Mídia'),
            Tab(icon: Icon(Icons.event_note_rounded, size: 18), text: 'Agenda da Igreja'),
          ],
        ),
      ),
      body: Column(
        children: [
          // BANNER DO MÊS VIGENTE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Text(
                      'MÊS ATUAL: OUTUBRO / NOVEMBRO 2026',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text(
                    '● ATUALIZADO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
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
                _buildEscalaEbdTab(),
                _buildPlantaoDiaconalTab(),
                _buildLouvorMidiaTab(),
                _buildAgendaIgrejaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ABA 1: ESCALA DE PROFESSORES EBD ====================
  Widget _buildEscalaEbdTab() {
    final domingos = [
      {
        'data': 'DOMINGO, 18 DE OUTUBRO DE 2026',
        'isHoje': true,
        'superintendente': 'Pb. Marcos Vinicius',
        'licao': 'Lição 07: "A Justificação pela Fé em Romanos"',
        'classes': [
          {'classe': 'Jovens (Bereanos)', 'sala': 'Sala 04', 'titular': 'Prof. Marcos Vinícius', 'sub': 'Gabriel Souza'},
          {'classe': 'Adultos (Bereia)', 'sala': 'Nave Principal', 'titular': 'Pb. Paulo Roberto', 'sub': 'Pb. Antônio Mendes'},
          {'classe': 'Mulheres (Déboras)', 'sala': 'Sala Social', 'titular': 'Sra. Maria Helena Costa', 'sub': 'Débora Neves'},
          {'classe': 'Adolescentes (Gideões)', 'sala': 'Sala UPA', 'titular': 'Jovem Lucas', 'sub': 'Mariana Lima'},
          {'classe': 'Crianças (Cordeirinhos)', 'sala': 'Sala Infantil 01', 'titular': 'Profª. Débora Neves', 'sub': 'Tia Renata'},
        ]
      },
      {
        'data': 'DOMINGO, 25 DE OUTUBRO DE 2026',
        'isHoje': false,
        'superintendente': 'Pb. Roberto Silva',
        'licao': 'Lição 08: "A Paz com Deus e a Esperança da Glória"',
        'classes': [
          {'classe': 'Jovens (Bereanos)', 'sala': 'Sala 04', 'titular': 'Gabriel Souza', 'sub': 'Prof. Marcos Vinícius'},
          {'classe': 'Adultos (Bereia)', 'sala': 'Nave Principal', 'titular': 'Pb. Antônio Mendes', 'sub': 'Pb. Paulo Roberto'},
          {'classe': 'Mulheres (Déboras)', 'sala': 'Sala Social', 'titular': 'Débora Neves', 'sub': 'Sra. Maria Helena'},
          {'classe': 'Adolescentes (Gideões)', 'sala': 'Sala UPA', 'titular': 'Mariana Lima', 'sub': 'Jovem Lucas'},
          {'classe': 'Crianças (Cordeirinhos)', 'sala': 'Sala Infantil 01', 'titular': 'Tia Renata', 'sub': 'Profª. Débora Neves'},
        ]
      },
      {
        'data': 'DOMINGO, 01 DE NOVEMBRO DE 2026',
        'isHoje': false,
        'superintendente': 'Pb. Eduardo Santos',
        'licao': 'Lição 09: "A Lei, o Pecado e a Graça em Cristo"',
        'classes': [
          {'classe': 'Jovens (Bereanos)', 'sala': 'Sala 04', 'titular': 'Prof. Marcos Vinícius', 'sub': 'Gabriel Souza'},
          {'classe': 'Adultos (Bereia)', 'sala': 'Nave Principal', 'titular': 'Pb. Paulo Roberto', 'sub': 'Pb. Roberto Silva'},
          {'classe': 'Mulheres (Déboras)', 'sala': 'Sala Social', 'titular': 'Sra. Maria Helena', 'sub': 'Débora Neves'},
          {'classe': 'Adolescentes (Gideões)', 'sala': 'Sala UPA', 'titular': 'Jovem Lucas', 'sub': 'Mariana Lima'},
          {'classe': 'Crianças (Cordeirinhos)', 'sala': 'Sala Infantil 01', 'titular': 'Profª. Débora Neves', 'sub': 'Tia Renata'},
        ]
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: domingos.length,
      itemBuilder: (context, idx) {
        final d = domingos[idx];
        final isHoje = d['isHoje'] as bool;
        final classes = d['classes'] as List<Map<String, String>>;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHoje ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isHoje ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHoje
                    ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABEÇALHO DO DOMINGO
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isHoje ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d['data'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isHoje ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                          ),
                        ),
                        if (isHoje)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRÓXIMO DOMINGO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF047857)),
                        const SizedBox(width: 4),
                        Text(
                          'Superintendente: ',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          d['superintendente'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            d['licao'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // LISTAGEM DAS CLASSES E PROFESSORES
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: classes.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.school_outlined, size: 16, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['classe']!,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c['sala']!,
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                    children: [
                                      const TextSpan(text: 'Titular: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                      TextSpan(text: c['titular'], style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                                      const TextSpan(text: ' • Sub: '),
                                      TextSpan(text: c['sub'], style: const TextStyle(color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== ABA 2: PLANTÃO DIACONAL & CULTOS ====================
  Widget _buildPlantaoDiaconalTab() {
    final plantoes = [
      {
        'data': 'Domingo, 18 de Outubro de 2026 • CULTO NOTURNO',
        'horario': '19:00',
        'tipo': 'Culto Solene de Adoração & Pregação',
        'isHoje': true,
        'diaconosPlantao': 'Dc. Carlos Eduardo & Dc. Marcos Paulo',
        'funcaoConferencia': 'Conferência de Dízimos & Fechamento POS',
        'portaria': 'Dc. João Batista (Acolhimento & Boletins)',
        'reuniaoConselho': 'Reunião de Oração Pré-Culto às 18:30',
      },
      {
        'data': 'Quarta-feira, 21 de Outubro de 2026',
        'horario': '19:30',
        'tipo': 'Culto de Oração & Estudo Bíblico',
        'isHoje': false,
        'diaconosPlantao': 'Dc. Samuel Rocha',
        'funcaoConferencia': 'Recolhimento de Ofertas & Fechamento',
        'portaria': 'Diaconia de Apoio',
        'reuniaoConselho': 'Gabinete pastoral aberto das 18h às 19h15',
      },
      {
        'data': 'Domingo, 25 de Outubro de 2026 • CULTO NOTURNO',
        'horario': '19:00',
        'tipo': 'Culto Solene com Celebração da Santa Ceia',
        'isHoje': false,
        'diaconosPlantao': 'Dc. João Batista & Dc. Samuel Rocha',
        'funcaoConferencia': 'Distribuição dos Elementos da Ceia & Dízimos',
        'portaria': 'Dc. Lucas Ferreira',
        'reuniaoConselho': 'Reunião da Junta Diaconal após o Culto',
      },
      {
        'data': 'Domingo, 01 de Novembro de 2026 • CULTO NOTURNO',
        'horario': '19:00',
        'tipo': 'Culto Solene em Comemoração da Reforma Protestante',
        'isHoje': false,
        'diaconosPlantao': 'Dc. Lucas Ferreira & Dc. Carlos Eduardo',
        'funcaoConferencia': 'Conferência de Dízimos & Contagem de Cédulas',
        'portaria': 'Dc. Marcos Paulo',
        'reuniaoConselho': 'Coral da Igreja escalado',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plantoes.length,
      itemBuilder: (context, idx) {
        final p = plantoes[idx];
        final isHoje = p['isHoje'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHoje ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
              width: isHoje ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHoje
                    ? const Color(0xFFD97706).withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHoje ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHoje ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.alarm_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(height: 2),
                        Text(
                          p['horario'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['data'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isHoje ? const Color(0xFFB45309) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['tipo'] as String,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildEscalaLine(
                      Icons.volunteer_activism_rounded,
                      'Plantão de Diáconos:',
                      p['diaconosPlantao'] as String,
                      const Color(0xFF047857),
                    ),
                    const SizedBox(height: 4),
                    _buildEscalaLine(
                      Icons.payments_rounded,
                      'Conferência:',
                      p['funcaoConferencia'] as String,
                      const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 4),
                    _buildEscalaLine(
                      Icons.door_front_door_rounded,
                      'Portaria & Acolhida:',
                      p['portaria'] as String,
                      const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== ABA 3: LOUVOR, MÍDIA & MINISTÉRIOS ====================
  Widget _buildLouvorMidiaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMinistryCard(
          title: 'Ministério de Louvor & Instrumentistas',
          badge: 'DOMINGO 18/OUT',
          badgeColor: const Color(0xFF047857),
          icon: Icons.music_note_rounded,
          iconColor: const Color(0xFF047857),
          iconBg: const Color(0xFFECFDF5),
          items: const [
            {'funcao': 'Dirigente de Cânticos', 'nome': 'Ir. Thiago Meireles'},
            {'funcao': 'Teclado / Piano', 'nome': 'Lívia Vasconcelos'},
            {'funcao': 'Violão / Guitarra', 'nome': 'Felipe Ramos'},
            {'funcao': 'Bateria', 'nome': 'Davi Santos'},
            {'funcao': 'Hinos do Hinário', 'nome': 'HNC 15, HNC 98 e HNC 240'},
          ],
        ),
        const SizedBox(height: 14),

        _buildMinistryCard(
          title: 'Equipe de Mídia, Som & Transmissão',
          badge: 'DOMINGO 18/OUT',
          badgeColor: const Color(0xFF2563EB),
          icon: Icons.podcasts_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEFF6FF),
          items: const [
            {'funcao': 'Mesa de Som (Áudio)', 'nome': 'Lucas Medeiros'},
            {'funcao': 'Projeção de Letras', 'nome': 'Beatriz Lima'},
            {'funcao': 'Transmissão ao Vivo (YouTube)', 'nome': 'Gabriel Silveira'},
            {'funcao': 'Fotografia & Mídias Sociais', 'nome': 'Carolina Melo'},
          ],
        ),
        const SizedBox(height: 14),

        _buildMinistryCard(
          title: 'Ministério Infantil & Berçário',
          badge: 'CULTOS DOMINICAIS',
          badgeColor: const Color(0xFF7C3AED),
          icon: Icons.child_friendly_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFFF5F3FF),
          items: const [
            {'funcao': 'Berçário (0 a 3 anos)', 'nome': 'Irmã Cláudia & Tia Fernanda'},
            {'funcao': 'Culto Infantil (4 a 8 anos)', 'nome': 'Tia Renata & Auxiliares'},
            {'funcao': 'Lanche das Crianças', 'nome': 'Equipe da SAF'},
          ],
        ),
      ],
    );
  }

  // ==================== ABA 4: AGENDA GERAL DA IGREJA ====================
  Widget _buildAgendaIgrejaTab() {
    final eventos = [
      {
        'data': 'DOM 18/OUT',
        'hora': '19:00',
        'titulo': 'Culto Solene de Adoração',
        'sub': 'Pregação: Rev. Carlos Alexandre • Dízimos & Ofertas',
        'tag': 'CULTO',
        'tagColor': const Color(0xFF047857),
      },
      {
        'data': 'TER 20/OUT',
        'hora': '15:00',
        'titulo': 'Reunião de Oração & Estudo da SAF',
        'sub': 'Salão Social • Sociedade Auxiliadora Feminina',
        'tag': 'SAF',
        'tagColor': const Color(0xFFEC4899),
      },
      {
        'data': 'QUA 21/OUT',
        'hora': '19:30',
        'titulo': 'Reunião de Oração & Doutrina',
        'sub': 'Estudo no livro de Romanos com a igreja toda',
        'tag': 'ESTUDO',
        'tagColor': const Color(0xFF2563EB),
      },
      {
        'data': 'SÁB 24/OUT',
        'hora': '19:30',
        'titulo': 'Encontro Geral da UMP (Mocidade)',
        'sub': 'Tema: "Juventude e Vocação no Reino de Deus"',
        'tag': 'UMP',
        'tagColor': const Color(0xFF047857),
      },
      {
        'data': 'DOM 25/OUT',
        'hora': '19:00',
        'titulo': 'Celebração da Santa Ceia do Senhor',
        'sub': 'Culto com Comunhão dos Membros Comungantes',
        'tag': 'SANTA CEIA',
        'tagColor': const Color(0xFF7C3AED),
      },
      {
        'data': 'SÁB 31/OUT',
        'hora': '19:30',
        'titulo': 'Culto da Reforma Protestante (509 Anos)',
        'sub': 'Sola Scriptura, Sola Gratia, Sola Fide, Solus Christus, Soli Deo Gloria',
        'tag': 'SOLENE',
        'tagColor': const Color(0xFFD97706),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eventos.length,
      itemBuilder: (context, idx) {
        final ev = eventos[idx];
        final tagColor = ev['tagColor'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      ev['data'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: tagColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ev['hora'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: tagColor,
                      ),
                    ),
                  ],
                ),
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
                            ev['titulo'] as String,
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
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            ev['tag'] as String,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: tagColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ev['sub'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
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
  }

  // WIDGET HELPER: LINHA DE ESCALA
  Widget _buildEscalaLine(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  // WIDGET HELPER: CARD DE MINISTÉRIO
  Widget _buildMinistryCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<Map<String, String>> items,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: items.map((it) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        it['funcao']!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        it['nome']!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
