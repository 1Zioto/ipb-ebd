import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class PersonalDispositivosScreen extends StatefulWidget {
  const PersonalDispositivosScreen({super.key});

  @override
  State<PersonalDispositivosScreen> createState() => _PersonalDispositivosScreenState();
}

class _PersonalDispositivosScreenState extends State<PersonalDispositivosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    final list = await ApiService.instance.getDevices();
    if (!mounted) return;
    setState(() {
      _devices = list;
      _loading = false;
    });
  }

  Future<void> _revokeDevice(int deviceId, String deviceName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar Sessão?'),
        content: Text('Deseja desconectar o dispositivo "$deviceName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.instance.revokeDevice(deviceId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão encerrada com sucesso.')),
      );
      _loadDevices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao encerrar sessão.')),
      );
    }
  }

  Future<void> _revokeOthers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar Outros Aparelhos?'),
        content: const Text('Todas as outras sessões ativas serão invalidadas imediatamente no servidor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desconectar Outros'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.instance.revokeOtherDevices();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas as outras sessões foram revogadas.')),
      );
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Dispositivos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: Color(0xFF047857), size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Segurança da Conta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF065F46),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Monitore onde sua conta está conectada e revogue acessos remotos a qualquer momento.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sessões Ativas (${_devices.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (_devices.length > 1)
                        TextButton.icon(
                          onPressed: _revokeOthers,
                          icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFDC2626)),
                          label: const Text('Desconectar outros', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_devices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text('Nenhum dispositivo registrado.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._devices.map((device) {
                      final isCurrent = device['is_current'] == true;
                      final devName = device['device_name']?.toString() ?? 'Dispositivo';
                      final platform = device['platform']?.toString().toLowerCase() ?? 'android';
                      final ip = device['ip_address']?.toString() ?? '127.0.0.1';

                      IconData devIcon = Icons.smartphone_rounded;
                      if (platform == 'web') devIcon = Icons.language_rounded;
                      if (platform == 'desktop') devIcon = Icons.computer_rounded;
                      if (platform == 'ios') devIcon = Icons.phone_iphone_rounded;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isCurrent ? const Color(0xFF10B981) : Colors.transparent,
                            width: isCurrent ? 1.5 : 0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isCurrent ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            foregroundColor: isCurrent ? const Color(0xFF047857) : const Color(0xFF64748B),
                            child: Icon(devIcon),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  devName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Este aparelho',
                                    style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Plataforma: ${platform.toUpperCase()} • IP: $ip', style: const TextStyle(fontSize: 11)),
                              if (device['last_active_at'] != null)
                                Text('Último acesso: ${device['last_active_at']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: isCurrent
                              ? null
                              : IconButton(
                                  tooltip: 'Revogar sessão',
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                                  onPressed: () => _revokeDevice(device['id'] as int, devName),
                                ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

