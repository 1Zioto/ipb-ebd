import 'package:flutter/material.dart';

class PersonalBibliaScreen extends StatefulWidget {
  const PersonalBibliaScreen({super.key});

  @override
  State<PersonalBibliaScreen> createState() => _PersonalBibliaScreenState();
}

class _PersonalBibliaScreenState extends State<PersonalBibliaScreen> {
  String _selectedBook = 'Salmos';
  int _selectedChapter = 23;
  double _fontSize = 16.0;

  final List<String> _books = [
    'Gênesis', 'Êxodo', 'Levítico', 'Números', 'Deuteronômio',
    'Josué', 'Juízes', 'Rute', '1 Samuel', '2 Samuel',
    'Salmos', 'Provérbios', 'Eclesiastes', 'Isaías', 'Jeremias',
    'Mateus', 'Marcos', 'Lucas', 'João', 'Atos',
    'Romanos', '1 Coríntios', '2 Coríntios', 'Gálatas', 'Efésios',
    'Filipenses', 'Colossenses', '1 Tessalonicenses', 'Hebreus', 'Apocalipse',
  ];

  // Texto bíblico demonstrativo de domínio público (João Ferreira de Almeida)
  final Map<String, List<String>> _verses = {
    'Salmos 23': [
      '1. O SENHOR é o meu pastor; nada me faltará.',
      '2. Ele me faz repousar em pastos verdejantes; leva-me para junto das águas de descanso;',
      '3. refrigera a minha alma; guia-me pelas veredas da justiça por amor do seu nome.',
      '4. Ainda que eu ande pelo vale da sombra da morte, não temerei mal nenhum, porque tu estás comigo; o teu bordão e o teu cajado me consolam.',
      '5. Preparas-me uma mesa na presença dos meus adversários, unges a minha cabeça com óleo; o meu cálice transborda.',
      '6. Certamente a bondade e a misericórdia me seguirão todos os dias da minha vida, e habitarei na Casa do SENHOR para todo o sempre.',
    ],
    'Salmos 122': [
      '1. Alegrei-me quando me disseram: Vamos à Casa do SENHOR.',
      '2. Pararam os nossos pés junto às tuas portas, ó Jerusalém!',
      '3. Jerusalém, que estás edificada como uma cidade compacta,',
      '4. para onde sobem as tribos, as tribos do SENHOR, como testemunho a Israel, para renderem graças ao nome do SENHOR.',
    ],
    '1 Coríntios 14': [
      '39. Portanto, meus irmãos, procurai com zelo o dom de profetizar e não proibais o falar em outras línguas.',
      '40. Tudo, porém, seja feito com decência e ordem.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final key = '$_selectedBook $_selectedChapter';
    final currentVerses = _verses[key] ?? [
      '1. No princípio era o Verbo, e o Verbo estava com Deus, e o Verbo era Deus.',
      '2. Ele estava no princípio com Deus.',
      '3. Todas as coisas foram feitas por meio dele, e sem ele nada do que foi feito se fez.',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$_selectedBook $_selectedChapter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: 'Tamanho da fonte',
            onPressed: () {
              setState(() {
                _fontSize = _fontSize == 16.0 ? 19.0 : (_fontSize == 19.0 ? 14.0 : 16.0);
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Selecionar Livro',
            onSelected: (book) {
              setState(() {
                _selectedBook = book;
                _selectedChapter = book == 'Salmos' ? 23 : 1;
              });
            },
            itemBuilder: (ctx) => _books.map((b) => PopupMenuItem(value: b, child: Text(b))).toList(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Almeida Revista e Atualizada (ARA)',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _selectedChapter > 1 ? () => setState(() => _selectedChapter--) : null,
                  ),
                  Text('Cap. $_selectedChapter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _selectedChapter++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...currentVerses.map((v) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                v,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.6,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

