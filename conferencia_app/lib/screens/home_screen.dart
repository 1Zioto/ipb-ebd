import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/thermal_printer.dart';
import '../models/models.dart';
import '../widgets/app_drawer.dart';
import 'configuracoes_impressora_screen.dart';
import 'envelopes_tab.dart';
import 'etiquetas_membros_screen.dart';
import 'fechamento_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  final ColetaModel? coleta;
  const HomeScreen({super.key, this.initialTab = 0, this.coleta});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<EnvelopeEntry> _entries = [];
  List<MemberModel> _members = [];
  final Map<double, int> _cashCounts = {};

  late ColetaModel? _currentColeta;

  @override
  void initState() {
    super.initState();
    _currentColeta = widget.coleta;
    _currentTab = widget.initialTab;
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
    await ThermalPrinterService.instance.selectedPrinter();
  }

  Future<void> _loadSavedState() async {
    // Se recebemos uma conferência online, buscar os lançamentos do servidor
    if (_currentColeta != null && !ApiService.instance.isOffline) {
      try {
        final details = await ApiService.instance.getConferenciaDetails(_currentColeta!.id);
        if (details['entries'] != null && details['entries'] is List<EnvelopeEntry>) {
          setState(() {
            _entries = details['entries'] as List<EnvelopeEntry>;
            if (details['coleta'] != null) {
              _currentColeta = details['coleta'] as ColetaModel;
            }
          });
          return;
        }
      } catch (_) {}
    }

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

  void _handleAddEntry(EnvelopeEntry entry) async {
    if (_currentColeta != null && !ApiService.instance.isOffline) {
      try {
        final saved = await ApiService.instance.addEnvelopeLancamento(
          _currentColeta!.id,
          personId: entry.personId,
          amount: entry.valor,
          forma: entry.forma,
          envelopeNumber: entry.envelopeNumber,
          membro: entry.membro,
          destinacao: entry.destinacao,
        );
        setState(() {
          _entries.insert(0, saved);
        });
        _saveState();
        return;
      } catch (e) {
        if (e is DuplicateEntryException) {
          // Confirmar duplicação
          if (mounted) {
            final force = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Envelope Já Lançado'),
                content: Text('Este envelope já foi lançado nesta conferência. Deseja adicionar mesmo assim?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Lançar Mesmo Assim'),
                  ),
                ],
              ),
            );
            if (force == true) {
              final forcedEntry = await ApiService.instance.addEnvelopeLancamento(
                _currentColeta!.id,
                personId: entry.personId,
                amount: entry.valor,
                forma: entry.forma,
                envelopeNumber: entry.envelopeNumber,
                membro: entry.membro,
                destinacao: entry.destinacao,
                force: true,
              );
              setState(() {
                _entries.insert(0, forcedEntry);
              });
              _saveState();
              return;
            }
          }
          return;
        }
      }
    }

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
            onPressed: () async {
              Navigator.of(ctx).pop();
              final intId = int.tryParse(id);
              if (_currentColeta != null && intId != null && !ApiService.instance.isOffline) {
                try {
                  await ApiService.instance.deleteEnvelopeLancamento(_currentColeta!.id, intId);
                } catch (_) {}
              }
              setState(() {
                _entries.removeWhere((e) => e.id == id);
              });
              _saveState();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entrada removida.')),
                );
              }
            },
            child: const Text('Remover'),
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



  double get totalGeral => _entries.fold(0.0, (sum, e) => sum + e.valor);

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
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset(
                'assets/images/ipb-logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857), size: 24),
              ),
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
          // Apenas o botão de QR Codes conforme solicitado
          IconButton(
            tooltip: 'Etiquetas & QR Codes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EtiquetasMembrosScreen(members: _members),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_2, color: Color(0xFF047857), size: 26),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'conferencia'),
      body: Column(
        children: [
          // HUD Totalizador no topo
          if (_currentTab != 2)
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
                      const SizedBox(width: 8),
                      _buildMiniPill(
                        userName.split(' ').first,
                        'Responsável',
                        color: const Color(0xFF047857),
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
                FechamentoTab(
                  entries: _entries,
                  cashCounts: const {},
                  onResetSession: _handleResetSession,
                  coleta: _currentColeta,
                  onColetaUpdated: (updated) {
                    setState(() => _currentColeta = updated);
                  },
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
