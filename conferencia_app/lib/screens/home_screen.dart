import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';
import 'cedulas_tab.dart';
import 'configuracoes_impressora_screen.dart';
import 'envelopes_tab.dart';
import 'fechamento_tab.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<EnvelopeEntry> _entries = [];
  List<MemberModel> _members = [];
  final Map<double, int> _cashCounts = {};

  String? _printerAddress;

  @override
  void initState() {
    super.initState();
    _initCashCounts();
    _loadSavedState();
    _loadMembers();
    _checkPrinterStatus();
  }

  void _initCashCounts() {
    for (final d in denominationsList) {
      _cashCounts[d.value] = 0;
    }
  }

  Future<void> _checkPrinterStatus() async {
    final selected = await ThermalPrinterService.instance.selectedPrinter();
    if (!mounted) return;
    setState(() => _printerAddress = selected?.address);
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesRaw = prefs.getString('ipb_conferencia_entries');
    if (entriesRaw != null) {
      try {
        final List list = jsonDecode(entriesRaw);
        setState(() {
          _entries = list.map((e) => EnvelopeEntry.fromJson(e)).toList();
        });
      } catch (_) {}
    }

    final cashRaw = prefs.getString('ipb_conferencia_cash');
    if (cashRaw != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(cashRaw);
        setState(() {
          map.forEach((k, v) {
            final val = double.tryParse(k);
            if (val != null && v is int) {
              _cashCounts[val] = v;
            }
          });
        });
      } catch (_) {}
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ipb_conferencia_entries',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );

    final cashMap = <String, int>{};
    _cashCounts.forEach((k, v) => cashMap[k.toString()] = v);
    await prefs.setString('ipb_conferencia_cash', jsonEncode(cashMap));
  }

  Future<void> _loadMembers() async {
    final members = await ApiService.instance.getMembers();
    if (!mounted) return;
    setState(() => _members = members);
  }

  void _handleAddEntry(EnvelopeEntry entry) {
    setState(() {
      _entries.insert(0, entry);
    });
    _saveState();
  }

  void _handleRemoveEntry(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover entrada?'),
        content: const Text('Deseja realmente remover este envelope da conferência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _entries.removeWhere((e) => e.id == id);
              });
              _saveState();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entrada removida.')),
              );
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _handleUpdateCashCount(double val, int qty) {
    setState(() {
      _cashCounts[val] = qty;
    });
    _saveState();
  }

  void _handleResetCash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zerar contagem?'),
        content: const Text('Deseja zerar a contagem de todas as cédulas e moedas físicas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _cashCounts.forEach((k, _) => _cashCounts[k] = 0);
              });
              _saveState();
            },
            child: const Text('Zerar'),
          ),
        ],
      ),
    );
  }

  void _handleResetSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar nova sessão?'),
        content: const Text('Todos os lançamentos e contagens serão limpos para uma nova conferência.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _entries.clear();
                _cashCounts.forEach((k, _) => _cashCounts[k] = 0);
              });
              _saveState();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nova sessão iniciada.')),
              );
            },
            child: const Text('Iniciar Nova'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do sistema?'),
        content: const Text('Os lançamentos salvos nesta sessão permanecerão guardados no aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ApiService.instance.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  double get totalFisico {
    double t = 0.0;
    _cashCounts.forEach((val, qty) => t += val * qty);
    return t;
  }

  double get totalEnvelopesDinheiro {
    return _entries
        .where((e) => e.forma == 'dinheiro')
        .fold(0.0, (sum, e) => sum + e.valor);
  }

  double get totalPix {
    return _entries
        .where((e) => e.forma == 'pix')
        .fold(0.0, (sum, e) => sum + e.valor);
  }

  double get totalCartao {
    return _entries
        .where((e) => e.forma == 'cartao')
        .fold(0.0, (sum, e) => sum + e.valor);
  }

  double get totalGeral => totalFisico + totalPix + totalCartao;
  double get diferencaDinheiro => totalFisico - totalEnvelopesDinheiro;

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final userName = user?.name ?? 'Oficial IPB';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/images/ipb-logo.png',
              width: 30,
              height: 30,
              errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IPB • Conferência',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botão Rápido Impressora POS
          IconButton(
            tooltip: 'Configurar Impressora POS',
            onPressed: () {
              setState(() => _currentTab = 3);
            },
            icon: Stack(
              children: [
                const Icon(Icons.print_outlined, color: Color(0xFF047857)),
                if (_printerAddress != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
          ),
        ],
      ),
      body: Column(
        children: [
          // HUD Totalizador no topo
          if (_currentTab != 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL APURADO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'R\$ ${totalGeral.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildMiniPill('${_entries.length}', 'Envelopes'),
                      const SizedBox(width: 6),
                      _buildMiniPill(
                        diferencaDinheiro.abs() < 0.01 ? '100% OK' : (diferencaDinheiro > 0 ? '+R\$ ${diferencaDinheiro.toInt()}' : 'Dif'),
                        'Batimento',
                        color: diferencaDinheiro.abs() < 0.01 ? const Color(0xFF047857) : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                EnvelopesTab(
                  entries: _entries,
                  members: _members,
                  onAddEntry: _handleAddEntry,
                  onRemoveEntry: _handleRemoveEntry,
                ),
                CedulasTab(
                  cashCounts: _cashCounts,
                  onUpdateCount: _handleUpdateCashCount,
                  onReset: _handleResetCash,
                ),
                FechamentoTab(
                  entries: _entries,
                  cashCounts: _cashCounts,
                  onResetSession: _handleResetSession,
                ),
                const ConfiguracoesImpressoraScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) {
          setState(() => _currentTab = idx);
          _checkPrinterStatus();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail, color: Color(0xFF047857)),
            label: 'Envelopes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate, color: Color(0xFF047857)),
            label: 'Cédulas',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified, color: Color(0xFF047857)),
            label: 'Fechamento',
          ),
          NavigationDestination(
            icon: Icon(Icons.print_outlined),
            selectedIcon: Icon(Icons.print, color: Color(0xFF047857)),
            label: 'Impressora',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String value, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color ?? const Color(0xFF0F172A)),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
