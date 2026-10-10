import 'package:flutter/material.dart';
import '../core/thermal_printer.dart';

class ConfiguracoesImpressoraScreen extends StatefulWidget {
  const ConfiguracoesImpressoraScreen({super.key});

  @override
  State<ConfiguracoesImpressoraScreen> createState() =>
      _ConfiguracoesImpressoraScreenState();
}

class _ConfiguracoesImpressoraScreenState
    extends State<ConfiguracoesImpressoraScreen> {
  bool _loading = true;
  bool _loadingPrinters = false;
  bool _printingTest = false;

  String? _printerAddress;
  String? _printerName;
  bool _autoPrintEnvelope = false;
  bool _autoPrintFechamento = true;

  List<ThermalPrinterDevice> _printers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final selected = await ThermalPrinterService.instance.selectedPrinter();
    final autoEnvelope =
        await ThermalPrinterService.instance.autoPrintEnvelopeEnabled();
    final autoFechamento =
        await ThermalPrinterService.instance.autoPrintFechamentoEnabled();

    if (!mounted) return;
    setState(() {
      _printerAddress = selected?.address;
      _printerName = selected?.name;
      _autoPrintEnvelope = autoEnvelope;
      _autoPrintFechamento = autoFechamento;
      _loading = false;
    });

    // Se já tiver impressora salva, lista para popular o dropdown
    if (_printerAddress != null) {
      _loadPrinters(showFeedback: false);
    }
  }

  Future<void> _loadPrinters({bool showFeedback = true}) async {
    setState(() => _loadingPrinters = true);
    try {
      final devices = await ThermalPrinterService.instance.listPairedDevices();
      if (!mounted) return;
      setState(() => _printers = devices);
      if (showFeedback) {
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Nenhuma impressora Bluetooth pareada encontrada no Android.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${devices.length} dispositivo(s) pareado(s) encontrado(s).'),
              backgroundColor: const Color(0xFF047857),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao listar Bluetooth: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPrinters = false);
    }
  }

  Future<void> _savePrinter(String? address) async {
    if (address == null || address.isEmpty) return;
    final device = _printers.firstWhere(
      (printer) => printer.address == address,
      orElse: () => ThermalPrinterDevice(
        name: _printerName ?? 'Impressora Bluetooth',
        address: address,
      ),
    );
    await ThermalPrinterService.instance.saveSelectedPrinter(device);
    if (!mounted) return;
    setState(() {
      _printerAddress = device.address;
      _printerName = device.name;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impressora salva: ${device.name}'),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }

  Future<void> _clearPrinter() async {
    await ThermalPrinterService.instance.clearSelectedPrinter();
    await ThermalPrinterService.instance.saveAutoPrintEnvelopeEnabled(false);
    if (!mounted) return;
    setState(() {
      _printerAddress = null;
      _printerName = null;
      _autoPrintEnvelope = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impressora removida das configurações.'),
        backgroundColor: Color(0xFF047857),
      ),
    );
  }

  Future<void> _setAutoPrintEnvelope(bool value) async {
    if (value && (_printerAddress == null || _printerAddress!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma impressora antes de ativar a impressão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await ThermalPrinterService.instance.saveAutoPrintEnvelopeEnabled(value);
    if (!mounted) return;
    setState(() => _autoPrintEnvelope = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Impressão automática de envelopes ativada neste aparelho.'
            : 'Impressão automática de envelopes desativada.'),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }

  Future<void> _setAutoPrintFechamento(bool value) async {
    await ThermalPrinterService.instance.saveAutoPrintFechamentoEnabled(value);
    if (!mounted) return;
    setState(() => _autoPrintFechamento = value);
  }

  Future<void> _printTest() async {
    setState(() => _printingTest = true);
    try {
      await ThermalPrinterService.instance.printTest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teste enviado para a impressora com sucesso!'),
          backgroundColor: Color(0xFF047857),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao imprimir teste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _printingTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'IMPRESSORA TÉRMICA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _printerAddress != null
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _printerAddress != null
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Icon(
                        Icons.print_outlined,
                        color: _printerAddress != null
                            ? const Color(0xFF047857)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bluetooth direta (POS 58mm / 80mm)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _printerAddress == null
                                ? 'Pareie a POS 5808L no Android e selecione aqui para imprimir sem abrir seletor.'
                                : 'Selecionada: ${_printerName ?? 'Impressora Bluetooth'} ($_printerAddress)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _loadingPrinters ? null : () => _loadPrinters(showFeedback: true),
                  icon: _loadingPrinters
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching_outlined),
                  label: Text(
                    _loadingPrinters ? 'Buscando...' : 'Buscar pareadas',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_printers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _printers.any((p) => p.address == _printerAddress)
                            ? _printerAddress
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Impressora',
                      prefixIcon: const Icon(Icons.print_outlined, color: Color(0xFF047857)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: _printers
                        .map(
                          (printer) => DropdownMenuItem(
                            value: printer.address,
                            child: Text(
                              '${printer.name} (${printer.address})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _savePrinter,
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _printerAddress == null || _printingTest
                      ? null
                      : _printTest,
                  icon: _printingTest
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    _printingTest ? 'Imprimindo...' : 'Imprimir teste de conexão',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoPrintEnvelope,
                  onChanged: _setAutoPrintEnvelope,
                  activeColor: const Color(0xFF047857),
                  title: const Text(
                    'Imprimir ao registrar envelope / oferta',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Configuração local deste aparelho. Usa a impressora selecionada acima.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  secondary: const Icon(Icons.local_printshop_outlined),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoPrintFechamento,
                  onChanged: _setAutoPrintFechamento,
                  activeColor: const Color(0xFF047857),
                  title: const Text(
                    'Imprimir termo no fechamento da apuração',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Emite o termo canônico de conferência com espaço para assinaturas da comissão.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  secondary: const Icon(Icons.receipt_long_outlined),
                ),
                if (_printerAddress != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _clearPrinter,
                    icon: const Icon(Icons.link_off_outlined),
                    label: const Text('Remover impressora'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
