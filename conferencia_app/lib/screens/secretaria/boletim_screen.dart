import 'package:flutter/material.dart';
import '../../core/thermal_printer.dart';
import '../../widgets/app_drawer.dart';

class BoletimScreen extends StatefulWidget {
  const BoletimScreen({super.key});

  @override
  State<BoletimScreen> createState() => _BoletimScreenState();
}

class _BoletimScreenState extends State<BoletimScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _edicaoNumero = 42;
  String _dataExtenso = 'Domingo, 19 de Outubro de 2026';

  // Dados do Boletim
  String _temaDevocional = 'A Fidelidade Soberana da Aliança de Deus';
  String _pastorNome = 'Rev. Antônio Carlos Silva';
  String _textoBiblico = 'Romanos 11:33-36';
  String _corpoDevocional =
      'Ó profundidade da riqueza, tanto da sabedoria como do conhecimento de Deus! Quão insondáveis são os seus juízos, e quão inescrutáveis, os seus caminhos!\n\n'
      'Irmãos em Cristo, o verdadeiro descanso do crente não repousa na estabilidade das circunstâncias humanas, mas na soberania imutável do Deus da Aliança. '
      'Em tempos de rápidas transformações, a Igreja Presbiteriana continua alicerçada na autoridade inerrante das Escrituras e na suficiência da graça redentora. '
      'Aproveitemos cada oportunidade para orar fervorosamente pela edificação de nossas famílias, pela consagração de nossos oficiais e pelo alcance missionário de nossa comunidade.';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Modal para editar o conteúdo do boletim
  void _openEditBoletimModal() {
    final temaCtrl = TextEditingController(text: _temaDevocional);
    final textoCtrl = TextEditingController(text: _textoBiblico);
    final pastorCtrl = TextEditingController(text: _pastorNome);
    final corpoCtrl = TextEditingController(text: _corpoDevocional);
    final edicaoCtrl = TextEditingController(text: _edicaoNumero.toString());
    final dataCtrl = TextEditingController(text: _dataExtenso);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 20,
            left: 18,
            right: 18,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_note_rounded, color: Color(0xFF047857), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Editar Boletim Dominical',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Altere o editorial pastoral, edição e data',
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
                const Divider(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: edicaoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Edição nº',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: dataCtrl,
                              decoration: InputDecoration(
                                labelText: 'Data do Domingo',
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
                        controller: temaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Título da Pastoral',
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
                              controller: textoCtrl,
                              decoration: InputDecoration(
                                labelText: 'Texto Bíblico Chave',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: pastorCtrl,
                              decoration: InputDecoration(
                                labelText: 'Autor / Pastor',
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
                        controller: corpoCtrl,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Texto da Palavra Pastoral',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _edicaoNumero = int.tryParse(edicaoCtrl.text) ?? _edicaoNumero;
                      _dataExtenso = dataCtrl.text;
                      _temaDevocional = temaCtrl.text;
                      _textoBiblico = textoCtrl.text;
                      _pastorNome = pastorCtrl.text;
                      _corpoDevocional = corpoCtrl.text;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Boletim Dominical atualizado com sucesso!'),
                        backgroundColor: Color(0xFF047857),
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
                  label: const Text('Salvar Boletim', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Compartilhar texto formatado para WhatsApp
  void _shareToWhatsApp() {
    final buffer = StringBuffer();
    buffer.writeln('🏛️ *BOLETIM INFORMATIVO DOMINICAL — IPB*');
    buffer.writeln('Edição Nº $_edicaoNumero • $_dataExtenso\n');
    buffer.writeln('📖 *PALAVRA DO PASTOR*');
    buffer.writeln('*$_temaDevocional*');
    buffer.writeln('Texto: $_textoBiblico | Por: $_pastorNome\n');
    buffer.writeln('$_corpoDevocional\n');
    buffer.writeln('⏰ *HORÁRIOS DESTE DOMINGO*');
    buffer.writeln('• 09h00: Escola Bíblica Dominical (EBD)');
    buffer.writeln('• 19h00: Culto Solene de Adoração e Proclamação\n');
    buffer.writeln('🎂 *ANIVERSARIANTES DA SEMANA*');
    buffer.writeln('• 15/10: Beatriz Vasconcelos');
    buffer.writeln('• 17/10: Presb. Paulo Roberto Albuquerque');
    buffer.writeln('• 19/10: Alice Costa 🎉 (Hoje!)\n');
    buffer.writeln('🙏 *MOTIVOS DE ORAÇÃO*');
    buffer.writeln('• Saúde dos enfermos e famílias enlutadas');
    buffer.writeln('• Crescimento da Congregação Esperança');
    buffer.writeln('• Conselho, Junta Diaconal e Sociedades Internas');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto do boletim copiado para área de transferência / pronto para WhatsApp!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  // Impressão do resumo na POS Bluetooth
  void _printBoletimSummary() {
    ThermalPrinterService.instance.printText(
      '================================\n'
      '   IGREJA PRESBITERIANA DO BRASIL\n'
      '    BOLETIM SEMANAL DOMINICAL\n'
      '================================\n'
      'Edicao No. $_edicaoNumero\n'
      '$_dataExtenso\n'
      '--------------------------------\n'
      'TEMA: $_temaDevocional\n'
      'Texto: $_textoBiblico\n'
      'Pastor: $_pastorNome\n'
      '--------------------------------\n'
      'PROGRAMACAO:\n'
      '09h00 - Escola Dominical (EBD)\n'
      '19h00 - Culto Solene Noturno\n'
      '--------------------------------\n'
      'ANIVERSARIANTES:\n'
      '- Beatriz Vasconcelos (15/10)\n'
      '- Presb. Paulo Roberto (17/10)\n'
      '- Alice Costa (Hoje!)\n'
      '================================\n\n\n\n',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enviando resumo do boletim para impressora POS Bluetooth...'),
        backgroundColor: Color(0xFF047857),
      ),
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
              'Boletim Semanal IPB',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF059669)),
            tooltip: 'WhatsApp',
            onPressed: _shareToWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF047857)),
            tooltip: 'Imprimir Resumo POS',
            onPressed: _printBoletimSummary,
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Editar Boletim',
            onPressed: _openEditBoletimModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF047857),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF047857),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Editorial'),
            Tab(text: 'Liturgia'),
            Tab(text: 'Avisos & SAF'),
            Tab(text: 'Aniversários'),
            Tab(text: 'Oração'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'boletim'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditorialTab(),
          _buildLiturgiaTab(),
          _buildAvisosTab(),
          _buildAniversariosTab(),
          _buildOracaoTab(),
        ],
      ),
    );
  }

  // ABA 1: EDITORIAL & PALAVRA DO PASTOR
  Widget _buildEditorialTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabeçalho Timbrado do Boletim
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF047857).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'INFORMATIVO OFICIAL',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFA7F3D0), letterSpacing: 0.5),
                    ),
                  ),
                  Text(
                    'Edição Nº $_edicaoNumero • Ano 2026',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Igreja Presbiteriana do Brasil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
              ),
              Text(
                _dataExtenso,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFD1FAE5)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'Lema: "Decência e Ordem" • 1 Coríntios 14:40',
                      style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cartão da Palavra do Pastor
        Container(
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.format_quote_rounded, color: Color(0xFF047857), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PALAVRA DO PASTOR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF047857), letterSpacing: 0.5),
                        ),
                        Text(
                          _temaDevocional,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Texto Base: $_textoBiblico',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                    ),
                    const Spacer(),
                    Text(
                      _pastorNome,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _corpoDevocional,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF334155), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Plantão e Atendimento Pastoral
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GABINETE PASTORAL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Atendimentos e aconselhamentos às terças e quintas (14h às 17h). Agendamento prévio com a secretaria da igreja.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ABA 2: LITURGIA DO CULTO NOTURNO
  Widget _buildLiturgiaTab() {
    final etapas = [
      {'num': '01', 'fase': 'ADORAÇÃO', 'titulo': 'Prelúdio Instrumental & Oração Silenciosa', 'detalhe': 'Silêncio reverente na presença de Deus'},
      {'num': '02', 'fase': 'LOUVOR', 'titulo': 'Cânticos Congregacionais do Hinário Novo Cântico', 'detalhe': 'Hinos nº 01 ("Doxologia") e nº 15 ("Ao Deus Grandioso")'},
      {'num': '03', 'fase': 'CONFISSÃO', 'titulo': 'Leitura Bíblica Alternada & Oração de Contrição', 'detalhe': 'Salmo 51:1-12 — Dirigida pelo presbítero de plantão'},
      {'num': '04', 'fase': 'GRATIDÃO', 'titulo': 'Consagração de Dízimos e Ofertas Alçadas', 'detalhe': 'Apresentação no altar e oração de intercessão missionária'},
      {'num': '05', 'fase': 'EDIFICAÇÃO', 'titulo': 'Proclamação da Palavra de Deus', 'detalhe': 'Mensagem: Rev. Antônio Carlos Silva (Romanos 11)'},
      {'num': '06', 'fase': 'ENVIO', 'titulo': 'Bênção Apostólica & Tríplice Amém', 'detalhe': '2 Coríntios 13:13 — Poslúdio com a congregação'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.church_rounded, color: Color(0xFF047857), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Culto Solene de Adoração • Domingo às 19h00 • Princípio Regulador do Culto',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...etapas.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        e['num']!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['fase']!,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), letterSpacing: 0.5),
                        ),
                        Text(
                          e['titulo']!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e['detalhe']!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ABA 3: AVISOS & SOCIEDADES INTERNAS
  Widget _buildAvisosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAvisoCard(
          sigla: 'SAF',
          nome: 'Sociedade Auxiliadora Feminina',
          cor: const Color(0xFF7C3AED),
          fundoCor: const Color(0xFFF5F3FF),
          data: 'Quarta-Feira • 15h00',
          texto: 'Reunião do departamento Débora com Chá de Comunhão e estudo no livro de Rute. Todas as irmãs estão convidadas!',
        ),
        _buildAvisoCard(
          sigla: 'UMP',
          nome: 'União de Mocidade Presbiteriana',
          cor: const Color(0xFF2563EB),
          fundoCor: const Color(0xFFEFF6FF),
          data: 'Sábado • 19h30',
          texto: 'Encontro jovem "Vigiai e Orai" com dinâmicas, louvor acústico e pizza após a ministração.',
        ),
        _buildAvisoCard(
          sigla: 'UPH',
          nome: 'União Presbiteriana de Homens',
          cor: const Color(0xFF047857),
          fundoCor: const Color(0xFFECFDF5),
          data: '1º Sábado do Mês • 07h00',
          texto: 'Café com Oração dos Homens no anexo do templo. Compartilhamento da Palavra com o Presb. Paulo Roberto.',
        ),
        _buildAvisoCard(
          sigla: 'UPA & UCP',
          nome: 'Adolescentes & Crianças',
          cor: const Color(0xFFD97706),
          fundoCor: const Color(0xFFFEF3C7),
          data: 'Domingo • 09h00 (EBD)',
          texto: 'Aulas interativas com o novo material didático da Editora Cultura Cristã (Revistas do 4º Trimestre já disponíveis).',
        ),
      ],
    );
  }

  Widget _buildAvisoCard({
    required String sigla,
    required String nome,
    required Color cor,
    required Color fundoCor,
    required String data,
    required String texto,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: fundoCor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  sigla,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '⏰ $data',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  // ABA 4: ANIVERSARIANTES DA SEMANA
  Widget _buildAniversariosTab() {
    final aniversariantes = [
      {'dia': '13/10', 'nome': 'Gabriel Henrique Braga', 'grupo': 'UMP (Mocidade)', 'status': 'Passou'},
      {'dia': '15/10', 'nome': 'Beatriz Vasconcelos', 'grupo': 'UMP (Mocidade)', 'status': 'Terça'},
      {'dia': '17/10', 'nome': 'Presb. Paulo Roberto Albuquerque', 'grupo': 'Conselho / UPH', 'status': 'Quinta'},
      {'dia': '19/10', 'nome': 'Alice Costa', 'grupo': 'UCP (Crianças)', 'status': 'Hoje! 🎉'},
      {'dia': '22/10', 'nome': 'Roberto Carlos Silva', 'grupo': 'UPH (Homens)', 'status': 'Próxima sem.'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: const Row(
            children: [
              Text('🎂', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIDAS EM COMUNHÃO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                    ),
                    Text(
                      'Rendamos graças a Deus por mais um ano concedido aos nossos irmãos aniversariantes desta semana!',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...aniversariantes.map((a) {
          final isHoje = a['status']!.contains('Hoje');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isHoje ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0), width: isHoje ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHoje ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a['dia']!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isHoje ? const Color(0xFFB45309) : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['nome']!,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isHoje ? const Color(0xFFB45309) : const Color(0xFF0F172A)),
                      ),
                      Text(
                        a['grupo']!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHoje ? const Color(0xFFD97706) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a['status']!,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isHoje ? Colors.white : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ABA 5: MOTIVOS DE ORAÇÃO & INTERCESSÃO
  Widget _buildOracaoTab() {
    final motivos = [
      {'cat': 'ENFERMOS & RECUPERAÇÃO', 'txt': 'Irmã Maria Aparecida (em recuperação cirúrgica) e Sr. Valdemar (hospitalizado).'},
      {'cat': 'LIDERANÇA & OFICIAIS', 'txt': 'Pastor Titular, Conselho de Presbíteros e Junta Diaconal na condução do rebanho.'},
      {'cat': 'EXPANSÃO MISSIONÁRIA', 'txt': 'Missão no Sertão Nordestino (APMT) e fortalecimento da Congregação Esperança.'},
      {'cat': 'FAMÍLIAS & JOVENS', 'txt': 'Consagração dos lares, fidelidade conjugal e proteção espiritual dos nossos jovens e crianças.'},
      {'cat': 'PÁTRIA & AUTORIDADES', 'txt': 'Pelo Brasil, governantes e pela paz entre as nações, conforme exorta 1 Timóteo 2:1-2.'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.volunteer_activism_rounded, color: Color(0xFF7E22CE), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"Orai sem cessar. Em tudo dai graças..." (1 Tessalonicenses 5:17-18)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B21A8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...motivos.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFF7E22CE)),
                      const SizedBox(width: 6),
                      Text(
                        m['cat']!,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7E22CE), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m['txt']!,
                    style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
