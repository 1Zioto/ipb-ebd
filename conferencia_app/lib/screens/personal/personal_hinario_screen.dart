import 'package:flutter/material.dart';

class PersonalHinarioScreen extends StatefulWidget {
  const PersonalHinarioScreen({super.key});

  @override
  State<PersonalHinarioScreen> createState() => _PersonalHinarioScreenState();
}

class _PersonalHinarioScreenState extends State<PersonalHinarioScreen> {
  String _search = '';

  final List<Map<String, dynamic>> _hinos = [
    {
      'numero': 1,
      'titulo': 'Doxologia',
      'letra': 'A Deus, supremo Benfeitor,\nVós, anjos e homens, dai louvor;\nA Deus, o Filho, e a Deus, o Pai,\nA Deus, Espírito, exaltai. Amém.',
    },
    {
      'numero': 15,
      'titulo': 'Segurança e Paz',
      'letra': 'Em nada ponho a minha fé,\nSenão na graça de Jesus;\nNo sacrifício remidor,\nNo sangue do meu Salvador.\n\nA minha fé e o meu amor\nEstão firmados no Senhor,\nEstão firmados no Senhor.',
    },
    {
      'numero': 32,
      'titulo': 'Castelo Forte',
      'letra': 'Castelo forte é nosso Deus,\nEspada e bom escudo;\nCom seu poder nos livrará\nDe todo transe agudo.\nCom fúria e pertinaz,\nPersegue Satanás,\nCom ânimo cruel;\nMuito astuto e mui rebel,\nIgual não há na terra.',
    },
    {
      'numero': 108,
      'titulo': 'Santo, Santo, Santo',
      'letra': 'Santo! Santo! Santo! Deus onipotente!\nCedo de manhã cantaremos teu louvor;\nSanto! Santo! Santo! Justo e compassivo,\nÉs um só Deus, supremo Criador.',
    },
    {
      'numero': 214,
      'titulo': 'Maravilhosa Graça',
      'letra': 'Maravilhosa graça! Maior que o meu pecar,\nComo poder cantá-la? Como hei de começar?\nAlivia a minha mente, dá gozo e paz bendita;\nFoi concedida a mim a graça infinita.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _hinos.where((h) {
      final term = _search.toLowerCase();
      return h['numero'].toString().contains(term) ||
          h['titulo'].toString().toLowerCase().contains(term);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Cântico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquise por número ou título do hino...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhum hino encontrado.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final h = filtered[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${h['numero']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 14),
                            ),
                          ),
                          title: Text(h['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: const Text('Hinário Novo Cântico (HNC)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: SelectableText(
                                h['letra'],
                                style: const TextStyle(fontSize: 14, height: 1.6, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

