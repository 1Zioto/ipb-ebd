import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThermalPrinterDevice {
  final String name;
  final String address;

  const ThermalPrinterDevice({
    required this.name,
    required this.address,
  });

  factory ThermalPrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return ThermalPrinterDevice(
      name: map['name']?.toString() ?? 'Dispositivo Bluetooth',
      address: map['address']?.toString() ?? '',
    );
  }

  String get label => '$name\n$address';
}

class ThermalPrinterSelection {
  final String name;
  final String address;

  const ThermalPrinterSelection({
    required this.name,
    required this.address,
  });

  bool get isValid => address.trim().isNotEmpty;
}

class ThermalPrinterService {
  ThermalPrinterService._();

  static final instance = ThermalPrinterService._();

  static const _channel =
      MethodChannel('br.org.ipb.conferencia/thermal_printer');
  static const _nameKey = 'thermal_printer_name';
  static const _addressKey = 'thermal_printer_address';
  static const _autoPrintEnvelopeKey = 'thermal_auto_print_envelope';
  static const _autoPrintFechamentoKey = 'thermal_auto_print_fechamento';

  Future<List<ThermalPrinterDevice>> listPairedDevices() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listPairedDevices');
    return (raw ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(ThermalPrinterDevice.fromMap)
        .where((device) => device.address.trim().isNotEmpty)
        .toList();
  }

  Future<ThermalPrinterSelection?> selectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_addressKey)?.trim();
    if (address == null || address.isEmpty) return null;
    return ThermalPrinterSelection(
      name: prefs.getString(_nameKey) ?? 'Impressora Bluetooth',
      address: address,
    );
  }

  Future<void> saveSelectedPrinter(ThermalPrinterDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, device.name);
    await prefs.setString(_addressKey, device.address);
  }

  Future<void> clearSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_addressKey);
  }

  Future<bool> autoPrintEnvelopeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPrintEnvelopeKey) ?? false;
  }

  Future<void> saveAutoPrintEnvelopeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPrintEnvelopeKey, enabled);
  }

  Future<bool> autoPrintFechamentoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPrintFechamentoKey) ?? true;
  }

  Future<void> saveAutoPrintFechamentoEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPrintFechamentoKey, enabled);
  }

  Future<void> printText(
    String text, {
    ThermalPrinterSelection? printer,
    bool cutPaper = false,
  }) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Selecione a impressora termica nas configuracoes.',
      );
    }
    await _channel.invokeMethod<bool>('printText', {
      'address': selected.address,
      'text': _normalizeText(text),
      'cutPaper': cutPaper,
    });
  }

  Future<void> printTest() async {
    final selected = await selectedPrinter();
    final now = DateTime.now();
    await printText(
      [
        _receiptStart,
        _center('IGREJA PRESBITERIANA', width: 32),
        _center('DO BRASIL', width: 32),
        _receiptEnd,
        '-' * 32,
        _center('TESTE DE IMPRESSORA POS', width: 32),
        '',
        'Impressora: ${selected?.name ?? '-'}',
        'Data: ${_two(now.day)}/${_two(now.month)}/${now.year}',
        'Hora: ${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}',
        '',
        _center('COMUNICACAO BLUETOOTH OK', width: 32),
        _center('DIACONATO & TESOURARIA', width: 32),
        '-' * 32,
        '',
      ].join('\n'),
    );
  }

  Future<void> printEnvelope({
    required String membro,
    required String destinacao,
    required String forma,
    required double valor,
    required String id,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}';

    final lines = <String>[
      _receiptStart,
      _center('IGREJA PRESBITERIANA', width: 32),
      _center('DO BRASIL', width: 32),
      _receiptEnd,
      _center('Diaconato & Tesouraria', width: 32),
      '=' * 32,
      _center('COMPROVANTE DE ENTRADA', width: 32),
      '-' * 32,
      'Data: $dateStr',
      'Reg. ID: #$id',
      'Destinacao: ${destinacao.toUpperCase()}',
      'Forma: ${forma.toUpperCase()}',
      '-' * 32,
      'Membro / Dizimista:',
      '  $membro',
      '=' * 32,
      _receiptStart,
      _center('VALOR: ${_money(valor)}', width: 32),
      _receiptEnd,
      '=' * 32,
      '',
      _center('___________________________', width: 32),
      _center('Visto Junta Diaconal / Tesouraria', width: 32),
      '',
      _center('Deus ama ao que da com alegria.', width: 32),
      _center('(2 Co 9:7)', width: 32),
      '',
    ];

    await printText(lines.join('\n'));
  }

  Future<void> printFechamento({
    required double totalFisico,
    required double totalEnvelopesDinheiro,
    required double diferencaDinheiro,
    required double totalPix,
    required double totalCartao,
    required double totalGeral,
    required int totalEnvelopes,
    required double totDizimo,
    required double totOferta,
    required double totMissoes,
    required double totConstrucao,
    required String conferente1,
    required String conferente2,
    required String culto,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}';

    final statusBatimento = diferencaDinheiro.abs() < 0.01
        ? '100% CONCILIADO'
        : (diferencaDinheiro > 0
            ? '+ ${_money(diferencaDinheiro)} (SOBRA SALVA)'
            : '- ${_money(diferencaDinheiro.abs())} (DIFERENCA)');

    final lines = <String>[
      _receiptStart,
      _center('IGREJA PRESBITERIANA', width: 32),
      _center('DO BRASIL', width: 32),
      _receiptEnd,
      _center('Junta Diaconal & Tesouraria', width: 32),
      '=' * 32,
      _center('TERMO DE APURACAO DIACONAL', width: 32),
      _center('DIZIMOS E OFERTAS', width: 32),
      '-' * 32,
      'Data/Hora: $dateStr',
      'Servico: $culto',
      '-' * 32,
      _center('RESUMO FINANCEIRO', width: 32),
      'Especie (Contado): ${_money(totalFisico)}',
      'Envelopes Dinheiro: ${_money(totalEnvelopesDinheiro)}',
      'Ofertas Salva: ${_money(diferencaDinheiro)}',
      'PIX / Transf.: ${_money(totalPix)}',
      'Cartoes: ${_money(totalCartao)}',
      '=' * 32,
      _receiptStart,
      'TOTAL GERAL: ${_money(totalGeral)}',
      _receiptEnd,
      '=' * 32,
      _center('DESTINACOES', width: 32),
      'Dizimos: ${_money(totDizimo)}',
      'Ofertas Gerais: ${_money(totOferta)}',
      if (totMissoes > 0) 'Missoes: ${_money(totMissoes)}',
      if (totConstrucao > 0) 'Construcao: ${_money(totConstrucao)}',
      '-' * 32,
      'Total de Envelopes: $totalEnvelopes un',
      'Batimento Salva: $statusBatimento',
      '-' * 32,
      _center('COMISSAO DE CONFERENCIA', width: 32),
      '',
      _center('___________________________', width: 32),
      _center('1o: $conferente1', width: 32),
      '',
      _center('___________________________', width: 32),
      _center('2o: $conferente2', width: 32),
      '',
      _center('Deus ama ao que da com alegria.', width: 32),
      _center('(2 Co 9:7)', width: 32),
      '',
    ];

    await printText(lines.join('\n'));
  }

  static const _receiptStart = '\x1BE\x01\x1B!\x18';
  static const _receiptEnd = '\x1B!\x00\x1BE\x00';

  static String _normalizeText(String text) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
      'Á': 'A',
      'À': 'A',
      'Ã': 'A',
      'Â': 'A',
      'Ä': 'A',
      'É': 'E',
      'Ê': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ú': 'U',
      'Ç': 'C',
    };
    var out = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    replacements.forEach((from, to) => out = out.replaceAll(from, to));
    return out;
  }

  static String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _center(String value, {required int width}) {
    if (value.length >= width) return value;
    final left = ((width - value.length) / 2).floor();
    return '${' ' * left}$value';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class ThermalPrinterException implements Exception {
  final String message;
  const ThermalPrinterException(this.message);

  @override
  String toString() => message;
}
