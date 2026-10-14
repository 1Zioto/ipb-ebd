import 'package:flutter/material.dart';
import '../../core/thermal_printer.dart';
import '../../widgets/app_drawer.dart';

class PessoasScreen extends StatefulWidget {
  const PessoasScreen({super.key});

  @override
  State<PessoasScreen> createState() => _PessoasScreenState();
}

class _PessoasScreenState extends State<PessoasScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedFilter = 'Todos'; // 'Todos', 'Comungante', 'Não-Comungante', 'Oficiais'

  // Lista dinâmica e editável de pessoas e famílias
  final List<Map<String, dynamic>> _pessoas = [
    {
      'id': 1,
      'nome': 'André Luiz Albuquerque',
      'envelope': '101',
      'tipo': 'Comungante',
      'tel': '(81) 98765-4321',
      'email': 'andre.albuquerque@email.com',
      'classe': 'Jovens (Bereanos)',
      'aniver': '12/03',
      'nascimento': '12/03/1998',
      'cpf': '045.123.789-10',
      'estadoCivil': 'Casado',
      'familia': 'Família Albuquerque',
      'parentesco': 'Chefe da Família',
      'conjuge': 'Camila Vasconcelos Albuquerque',
      'filhos': 'Lucas (4 anos)',
      'endereco': 'Rua das Acácias, 142 - Bairro Nobre',
      'rol': '014',
      'admissao': '15/04/2018',
      'modoAdmissao': 'Profissão de Fé e Batismo',
      'sociedade': 'UMP (Mocidade)',
      'observacoes': 'Diácono em disponibilidade, membro assíduo da EBD.',
    },
    {
      'id': 2,
      'nome': 'Beatriz Vasconcelos',
      'envelope': '102',
      'tipo': 'Comungante',
      'tel': '(81) 99876-5432',
      'email': 'beatriz.vasc@email.com',
      'classe': 'Jovens (Bereanos)',
      'aniver': '15/10',
      'nascimento': '15/10/2001',
      'cpf': '098.765.432-11',
      'estadoCivil': 'Solteira',
      'familia': 'Família Vasconcelos',
      'parentesco': 'Filha',
      'conjuge': '',
      'filhos': '',
      'endereco': 'Av. Rui Barbosa, 850 - Apt 302',
      'rol': '007',
      'admissao': '18/06/2020',
      'modoAdmissao': 'Profissão de Fé',
      'sociedade': 'UMP (Mocidade)',
      'observacoes': 'Auxiliar dos Cordeirinhos de Cristo e tecladista do grupo de louvor.',
    },
    {
      'id': 3,
      'nome': 'Carlos Eduardo Nogueira',
      'envelope': '103',
      'tipo': 'Oficial (Diácono)',
      'tel': '(81) 98123-4567',
      'email': 'carlos.diacono@email.com',
      'classe': 'Adultos (Bereia)',
      'aniver': '24/07',
      'nascimento': '24/07/1982',
      'cpf': '123.456.789-22',
      'estadoCivil': 'Casado',
      'familia': 'Família Nogueira',
      'parentesco': 'Chefe da Família',
      'conjuge': 'Juliana Nogueira',
      'filhos': 'Enzo (12) e Clara (8)',
      'endereco': 'Rua do Bosque, 45 - Casa',
      'rol': '003',
      'admissao': '20/08/2016',
      'modoAdmissao': 'Carta de Transferência (IPB Central)',
      'sociedade': 'UPH (Homens)',
      'observacoes': 'Vice-Presidente da Junta Diaconal, escala de abertura e contagem.',
    },
    {
      'id': 4,
      'nome': 'Débora Neves de Lima',
      'envelope': '104',
      'tipo': 'Comungante (Profª)',
      'tel': '(81) 99234-5678',
      'email': 'debora.lima@email.com',
      'classe': 'Cordeirinhos de Cristo',
      'aniver': '05/11',
      'nascimento': '05/11/1975',
      'cpf': '234.567.890-33',
      'estadoCivil': 'Casada',
      'familia': 'Família Lima',
      'parentesco': 'Esposa / Mãe',
      'conjuge': 'Marcos Paulo Lima',
      'filhos': 'Matheus (16) e Sofia (11)',
      'endereco': 'Rua General Abreu, 210',
      'rol': '004',
      'admissao': '12/10/2019',
      'modoAdmissao': 'Profissão de Fé',
      'sociedade': 'SAF (Senhoras)',
      'observacoes': 'Professora titular do maternal e conselheira da SAF.',
    },
    {
      'id': 5,
      'nome': 'Esther Ramos Peixoto',
      'envelope': '105',
      'tipo': 'Não-Comungante',
      'tel': '(81) 98345-6789',
      'email': 'esther.ramos@email.com',
      'classe': 'Jovens (Bereanos)',
      'aniver': '30/01',
      'nascimento': '30/01/2010',
      'cpf': '345.678.901-44',
      'estadoCivil': 'Solteira',
      'familia': 'Família Ramos Peixoto',
      'parentesco': 'Filha',
      'conjuge': '',
      'filhos': '',
      'endereco': 'Rua Barão de Souza Leão, 99',
      'rol': '008',
      'admissao': '10/01/2023',
      'modoAdmissao': 'Batismo na Infância',
      'sociedade': 'UPA (Adolescentes)',
      'observacoes': 'Em classe de preparação para pública profissão de fé com o Conselho.',
    },
    {
      'id': 6,
      'nome': 'Felipe Augusto Santos',
      'envelope': '106',
      'tipo': 'Comungante',
      'tel': '(81) 99456-7890',
      'email': 'felipe.santos@email.com',
      'classe': 'Jovens (Bereanos)',
      'aniver': '18/08',
      'nascimento': '18/08/1995',
      'cpf': '456.789.012-55',
      'estadoCivil': 'Solteiro',
      'familia': 'Família Santos',
      'parentesco': 'Chefe da Família',
      'conjuge': '',
      'filhos': '',
      'endereco': 'Av. Conselheiro Aguiar, 1500',
      'rol': '019',
      'admissao': '04/09/2017',
      'modoAdmissao': 'Profissão de Fé',
      'sociedade': 'UMP (Mocidade)',
      'observacoes': 'Líder do ministério de multimídia e transmissão de cultos.',
    },
    {
      'id': 7,
      'nome': 'Gabriel Henrique Braga',
      'envelope': '107',
      'tipo': 'Comungante',
      'tel': '(81) 98567-8901',
      'email': 'gabriel.braga@email.com',
      'classe': 'Jovens (Bereanos)',
      'aniver': '13/10',
      'nascimento': '13/10/1999',
      'cpf': '567.890.123-66',
      'estadoCivil': 'Solteiro',
      'familia': 'Família Braga',
      'parentesco': 'Filho',
      'conjuge': '',
      'filhos': '',
      'endereco': 'Rua das Flores, 500',
      'rol': '005',
      'admissao': '14/11/2021',
      'modoAdmissao': 'Profissão de Fé',
      'sociedade': 'UMP (Mocidade)',
      'observacoes': 'Violonista do culto e integrante da comissão de evangelismo.',
    },
    {
      'id': 8,
      'nome': 'Presb. Paulo Roberto',
      'envelope': '108',
      'tipo': 'Oficial (Presbítero)',
      'tel': '(81) 99678-9012',
      'email': 'presb.paulo@email.com',
      'classe': 'Adultos (Bereia)',
      'aniver': '17/10',
      'nascimento': '17/10/1968',
      'cpf': '678.901.234-77',
      'estadoCivil': 'Casado',
      'familia': 'Família Albuquerque',
      'parentesco': 'Patriarca',
      'conjuge': 'Maria Helena Albuquerque',
      'filhos': 'André Luiz e Priscilla',
      'endereco': 'Rua da Harmonia, 330',
      'rol': '002',
      'admissao': '15/05/2015',
      'modoAdmissao': 'Profissão de Fé e Batismo',
      'sociedade': 'UPH (Homens)',
      'observacoes': 'Vice-Presidente do Conselho da IPB, relator de atas e disciplina.',
    },
    {
      'id': 9,
      'nome': 'Rev. Antônio Carlos',
      'envelope': '109',
      'tipo': 'Pastor Titular',
      'tel': '(81) 98789-0123',
      'email': 'pastor.carlos@ipb.org.br',
      'classe': 'Melhor Idade',
      'aniver': '22/04',
      'nascimento': '22/04/1965',
      'cpf': '789.012.345-88',
      'estadoCivil': 'Casado',
      'familia': 'Família Pastoral Silva',
      'parentesco': 'Pastor & Chefe',
      'conjuge': 'Eunice Maria Silva',
      'filhos': 'Ana Clara e Daniel',
      'endereco': 'Casa Pastoral - Rua das Oliveiras, 10',
      'rol': '001',
      'admissao': '02/02/2018',
      'modoAdmissao': 'Designação Presbiterial',
      'sociedade': 'Conselho de Pastores',
      'observacoes': 'Pastor Titular da igreja, moderador do Conselho e ministro do Evangelho.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPessoas {
    var list = _pessoas;

    // Filtro por categoria
    if (_selectedFilter == 'Comungante') {
      list = list.where((p) => p['tipo'].toString().contains('Comungante')).toList();
    } else if (_selectedFilter == 'Não-Comungante') {
      list = list.where((p) => p['tipo'].toString().contains('Não-Comungante')).toList();
    } else if (_selectedFilter == 'Oficiais') {
      list = list.where((p) => p['tipo'].toString().contains('Oficial') || p['tipo'].toString().contains('Pastor')).toList();
    }

    if (_searchTerm.isEmpty) return list;
    final term = _searchTerm.toLowerCase();
    return list.where((p) {
      final nome = p['nome'].toString().toLowerCase();
      final env = p['envelope'].toString();
      final fam = (p['familia'] ?? '').toString().toLowerCase();
      final rol = (p['rol'] ?? '').toString();
      return nome.contains(term) || env.contains(term) || fam.contains(term) || rol.contains(term);
    }).toList();
  }

  // ABRIR MODAL DE VISUALIZAÇÃO COMPLETA (DOSSIÊ DO MEMBRO / FAMÍLIA)
  void _openViewModal(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildViewBottomSheet(p),
    );
  }

  // ABRIR FORMULÁRIO DE EDIÇÃO / CADASTRO DE PESSOA
  void _openEditModal(Map<String, dynamic> p) {
    final nomeCtrl = TextEditingController(text: p['nome']);
    final envCtrl = TextEditingController(text: p['envelope']);
    final telCtrl = TextEditingController(text: p['tel']);
    final emailCtrl = TextEditingController(text: p['email'] ?? '');
    final classeCtrl = TextEditingController(text: p['classe']);
    final aniverCtrl = TextEditingController(text: p['aniver']);
    final cpfCtrl = TextEditingController(text: p['cpf'] ?? '');
    final familiaCtrl = TextEditingController(text: p['familia'] ?? '');
    final parentescoCtrl = TextEditingController(text: p['parentesco'] ?? '');
    final conjugeCtrl = TextEditingController(text: p['conjuge'] ?? '');
    final filhosCtrl = TextEditingController(text: p['filhos'] ?? '');
    final enderecoCtrl = TextEditingController(text: p['endereco'] ?? '');
    final rolCtrl = TextEditingController(text: p['rol'] ?? '');
    final obsCtrl = TextEditingController(text: p['observacoes'] ?? '');
    String tipoVal = p['tipo'] ?? 'Comungante';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    // Cabeçalho da edição
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: Color(0xFF047857), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar Membro & Família',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Atualize os dados eclesiásticos, cadastrais e de parentesco',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Formulário scrollável
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSectionBadge('DADOS GERAIS & CONTATO'),
                          const SizedBox(height: 10),
                          _buildFormField(controller: nomeCtrl, label: 'Nome Completo', icon: Icons.person_rounded),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildFormField(controller: envCtrl, label: 'Envelope nº', icon: Icons.tag_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _buildFormField(controller: rolCtrl, label: 'ROL nº', icon: Icons.book_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: _buildFormField(controller: aniverCtrl, label: 'Aniversário', icon: Icons.cake_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(controller: telCtrl, label: 'Telefone / WhatsApp', icon: Icons.phone_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFormField(controller: cpfCtrl, label: 'CPF', icon: Icons.badge_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(controller: emailCtrl, label: 'E-mail do Membro', icon: Icons.email_rounded),
                          const SizedBox(height: 12),
                          _buildFormField(controller: enderecoCtrl, label: 'Endereço Residencial', icon: Icons.location_on_rounded),

                          const SizedBox(height: 20),
                          _buildSectionBadge('VÍNCULO FAMILIAR & DOMICÍLIO'),
                          const SizedBox(height: 10),
                          _buildFormField(controller: familiaCtrl, label: 'Nome da Família / Núcleo', icon: Icons.roofing_rounded),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(controller: parentescoCtrl, label: 'Grau / Papel no Lar', icon: Icons.people_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFormField(controller: conjugeCtrl, label: 'Nome do Cônjuge', icon: Icons.favorite_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(controller: filhosCtrl, label: 'Filhos / Dependentes', icon: Icons.child_care_rounded),

                          const SizedBox(height: 20),
                          _buildSectionBadge('ECLESIÁSTICO & ESCOLA DOMINICAL'),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: tipoVal,
                            decoration: InputDecoration(
                              labelText: 'Condição do Membro',
                              prefixIcon: const Icon(Icons.church_rounded, size: 20, color: Color(0xFF047857)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Comungante', child: Text('Comungante')),
                              DropdownMenuItem(value: 'Não-Comungante', child: Text('Não-Comungante')),
                              DropdownMenuItem(value: 'Oficial (Diácono)', child: Text('Oficial (Diácono)')),
                              DropdownMenuItem(value: 'Oficial (Presbítero)', child: Text('Oficial (Presbítero)')),
                              DropdownMenuItem(value: 'Comungante (Profª)', child: Text('Comungante (Professora EBD)')),
                              DropdownMenuItem(value: 'Pastor Titular', child: Text('Pastor Titular')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => tipoVal = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(controller: classeCtrl, label: 'Classe da EBD', icon: Icons.menu_book_rounded),
                          const SizedBox(height: 12),
                          _buildFormField(controller: obsCtrl, label: 'Observações Pastorais / Secretaria', icon: Icons.note_alt_rounded, maxLines: 2),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Botões de Ação
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  p['nome'] = nomeCtrl.text.trim();
                                  p['envelope'] = envCtrl.text.trim();
                                  p['tel'] = telCtrl.text.trim();
                                  p['email'] = emailCtrl.text.trim();
                                  p['classe'] = classeCtrl.text.trim();
                                  p['aniver'] = aniverCtrl.text.trim();
                                  p['cpf'] = cpfCtrl.text.trim();
                                  p['familia'] = familiaCtrl.text.trim();
                                  p['parentesco'] = parentescoCtrl.text.trim();
                                  p['conjuge'] = conjugeCtrl.text.trim();
                                  p['filhos'] = filhosCtrl.text.trim();
                                  p['endereco'] = enderecoCtrl.text.trim();
                                  p['rol'] = rolCtrl.text.trim();
                                  p['tipo'] = tipoVal;
                                  p['observacoes'] = obsCtrl.text.trim();
                                });
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dados de "${p['nome']}" atualizados com sucesso!'),
                                    backgroundColor: const Color(0xFF047857),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047857),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 20),
                              label: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
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

  // BOTTOM SHEET DE VISUALIZAÇÃO DETALHADA DO MEMBRO
  Widget _buildViewBottomSheet(Map<String, dynamic> p) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Barra de arrasto
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Header do Membro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFECFDF5),
                  child: Text(
                    p['nome'].toString().substring(0, 1),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nome'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p['tipo'],
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Envelope #${p['envelope']}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF047857)),
                  tooltip: 'Editar Membro',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openEditModal(p);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Informações completas em abas ou blocos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // CARD 1: Registros Eclesiásticos (IPB)
                _buildInfoCard(
                  title: 'REGISTROS ECLESIÁSTICOS (IPB)',
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF047857),
                  children: [
                    _buildInfoRow('Livro do ROL Oficial:', 'ROL nº ${p['rol'] ?? '000'}'),
                    _buildInfoRow('Condição do Membro:', p['tipo']),
                    _buildInfoRow('Modo de Recepção:', p['modoAdmissao'] ?? 'Profissão de Fé e Batismo'),
                    _buildInfoRow('Data de Admissão:', p['admissao'] ?? 'Não informada'),
                    _buildInfoRow('Sociedade Interna:', p['sociedade'] ?? 'Geral'),
                  ],
                ),
                const SizedBox(height: 14),

                // CARD 2: Vínculo Familiar & Núcleo
                _buildInfoCard(
                  title: 'NÚCLEO FAMILIAR',
                  icon: Icons.roofing_rounded,
                  iconColor: const Color(0xFF2563EB),
                  children: [
                    _buildInfoRow('Família Cadastrada:', p['familia'] ?? 'Não associada', isHighlight: true),
                    _buildInfoRow('Papel no Lar:', p['parentesco'] ?? 'Membro'),
                    if ((p['conjuge'] ?? '').toString().isNotEmpty)
                      _buildInfoRow('Cônjuge:', p['conjuge']),
                    if ((p['filhos'] ?? '').toString().isNotEmpty)
                      _buildInfoRow('Filhos / Dependentes:', p['filhos']),
                    _buildInfoRow('Endereço do Lar:', p['endereco'] ?? 'Não informado'),
                  ],
                ),
                const SizedBox(height: 14),

                // CARD 3: Dados Pessoais & Contato
                _buildInfoCard(
                  title: 'DADOS PESSOAIS & CONTATO',
                  icon: Icons.badge_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  children: [
                    _buildInfoRow('CPF:', p['cpf'] ?? 'Não informado'),
                    _buildInfoRow('Aniversário:', '${p['aniver']} (${p['nascimento'] ?? 'Não informado'})'),
                    _buildInfoRow('Telefone / WhatsApp:', p['tel']),
                    _buildInfoRow('E-mail:', p['email'] ?? 'Não informado'),
                    _buildInfoRow('Estado Civil:', p['estadoCivil'] ?? 'Não informado'),
                  ],
                ),
                const SizedBox(height: 14),

                // CARD 4: Educação Bíblica & EBD
                _buildInfoCard(
                  title: 'ESCOLA BÍBLICA DOMINICAL (EBD)',
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFFD97706),
                  children: [
                    _buildInfoRow('Classe Atual:', p['classe']),
                    _buildInfoRow('Observações:', p['observacoes'] ?? 'Nenhuma observação cadastrada.'),
                  ],
                ),
                const SizedBox(height: 18),

                // Ações Rápidas (Impressão de Etiqueta e WhatsApp)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ThermalPrinterService.instance.printMemberQrLabel(
                            memberName: p['nome'],
                            envelopeNumber: p['envelope'],
                            qrData: 'IPB:${p['envelope']}',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Enviando etiqueta de ${p['nome']} para a POS...'),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF047857)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF047857)),
                        label: const Text('Imprimir Etiqueta POS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openEditModal(p);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Editar Cadastro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF047857)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF047857), width: 1.5)),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
                color: isHighlight ? const Color(0xFF047857) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
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
              'Pessoas & Famílias',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF047857)),
            tooltip: 'Cadastrar Pessoa',
            onPressed: () {
              final novaPessoa = {
                'id': _pessoas.length + 1,
                'nome': '',
                'envelope': '${100 + _pessoas.length + 1}',
                'tipo': 'Comungante',
                'tel': '',
                'email': '',
                'classe': 'Jovens (Bereanos)',
                'aniver': '',
                'nascimento': '',
                'cpf': '',
                'estadoCivil': 'Solteiro',
                'familia': '',
                'parentesco': '',
                'conjuge': '',
                'filhos': '',
                'endereco': '',
                'rol': '',
                'admissao': '',
                'modoAdmissao': 'Profissão de Fé',
                'sociedade': '',
                'observacoes': '',
              };
              _openEditModal(novaPessoa);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'pessoas'),
      body: Column(
        children: [
          // Barra de Busca
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, envelope, rol ou família...',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => _searchTerm = val.trim()),
            ),
          ),

          // Pílulas de Filtro Rápido
          Container(
            height: 44,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Comungante'),
                const SizedBox(width: 8),
                _buildFilterChip('Não-Comungante'),
                const SizedBox(width: 8),
                _buildFilterChip('Oficiais'),
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
                  '${_filteredPessoas.length} PESSOAS / FAMÍLIAS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF047857)),
                    SizedBox(width: 4),
                    Text('Toque para visualizar ou editar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                  ],
                ),
              ],
            ),
          ),

          // Lista de Pessoas
          Expanded(
            child: _filteredPessoas.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma pessoa encontrada.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: _filteredPessoas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final p = _filteredPessoas[idx];
                      return _buildPersonCard(p);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
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

  Widget _buildPersonCard(Map<String, dynamic> p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openViewModal(p),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar com inicial
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Center(
                    child: Text(
                      p['nome'].toString().substring(0, 1),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857), fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Dados centrais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nome'],
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p['tipo'],
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p['familia'] ?? 'Família IPB',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📞 ${p['tel']} • 🎂 ${p['aniver']}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Botão de editar e Envelope
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${p['envelope']}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Editar',
                      onPressed: () => _openEditModal(p),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
