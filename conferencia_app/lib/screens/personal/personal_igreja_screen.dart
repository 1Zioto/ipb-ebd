import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class PersonalIgrejaScreen extends StatelessWidget {
  const PersonalIgrejaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    
    
    final churchName = user?.churchName ?? 'Igreja Presbiteriana de Campo Verde';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Igreja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CABEÇALHO INSTITUCIONAL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    'assets/images/ipb-logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857), size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  churchName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jurisdição: Presbitério de Campo Verde (PCVE) • Sínodo Mato Grosso',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // HORÁRIOS DE CULTO
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: Color(0xFF047857)),
                      SizedBox(width: 8),
                      Text('Horários de Culto & EBD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildScheduleItem('Domingo 09:00', 'Escola Bíblica Dominical (Todas as classes)'),
                  _buildScheduleItem('Domingo 19:00', 'Culto Solene Vespertino de Adoração'),
                  _buildScheduleItem('Quarta 19:30', 'Reunião de Oração e Estudo Bíblico Doutrinário'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // LIDERANÇA PASTORAL E CONSELHO
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.groups_rounded, color: Color(0xFF047857)),
                      SizedBox(width: 8),
                      Text('Liderança & Oficiais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildLeaderItem('Rev. João Batista da Silva', 'Pastor Titular e Presidente do Conselho'),
                  _buildLeaderItem('Presb. Marcos Aurélio de Souza', 'Vice-Presidente do Conselho'),
                  _buildLeaderItem('Presb. Roberto Mendonça Lima', 'Secretário do Conselho'),
                  _buildLeaderItem('Diác. André Luiz Ramos', 'Presidente da Junta Diaconal & Superintendente EBD'),
                  _buildLeaderItem('Diác. Marcelo Costa Pinto', 'Tesoureiro da Igreja'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // LOCALIZAÇÃO E CONTATOS
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Color(0xFF047857)),
                      SizedBox(width: 8),
                      Text('Endereço & Contatos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text('Rua Maceió, 120 - Centro, Campo Verde - MT', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('Telefone / WhatsApp: (66) 3419-0000', style: TextStyle(fontSize: 12)),
                  const Text('E-mail oficial: secretaria@ipbcampoverde.org.br', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildScheduleItem(String time, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857), fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  static Widget _buildLeaderItem(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFF1F5F9),
            foregroundColor: Color(0xFF047857),
            child: Icon(Icons.person, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(role, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

