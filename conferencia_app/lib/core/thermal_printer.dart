import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
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
    if (address != null && address.isNotEmpty) {
      return ThermalPrinterSelection(
        name: prefs.getString(_nameKey) ?? 'Impressora Bluetooth',
        address: address,
      );
    }
    // Auto-detecta impressora pareada se ainda não configurada
    try {
      final devices = await listPairedDevices();
      if (devices.isNotEmpty) {
        final candidate = devices.firstWhere(
          (d) {
            final n = d.name.toUpperCase();
            return n.contains('POS') ||
                n.contains('PRINTER') ||
                n.contains('58') ||
                n.contains('80') ||
                n.contains('MPT') ||
                n.contains('RPP') ||
                n.contains('BLUETOOTH');
          },
          orElse: () => devices.first,
        );
        await saveSelectedPrinter(candidate);
        return ThermalPrinterSelection(
          name: candidate.name,
          address: candidate.address,
        );
      }
    } catch (_) {}
    return null;
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
        'Nenhuma impressora térmica configurada. Pareie no Bluetooth e selecione nas configurações.',
      );
    }
    await _channel.invokeMethod<bool>('printText', {
      'address': selected.address,
      'text': _normalizeText(text),
      'cutPaper': cutPaper,
    });
  }

  Future<void> printRawBytes(
    List<int> bytes, {
    ThermalPrinterSelection? printer,
    bool cutPaper = false,
  }) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Nenhuma impressora térmica configurada. Pareie no Bluetooth e selecione nas configurações.',
      );
    }
    await _channel.invokeMethod<bool>('printRawBytes', {
      'address': selected.address,
      'bytes': Uint8List.fromList(bytes),
      'cutPaper': cutPaper,
    });
  }

  Future<void> printMemberQrLabel({
    required String memberName,
    required String envelopeNumber,
    required String qrData,
    ThermalPrinterSelection? printer,
  }) async {
    final bytes = <int>[];

    // Reset ESC @
    bytes.addAll([0x1B, 0x40]);
    // Code Page CP850
    bytes.addAll([0x1B, 0x74, 0x02]);
    // Alinhamento Central
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Cabeçalho
    final header = _normalizeText('IGREJA PRESBITERIANA DO BRASIL\nDIACONATO & TESOURARIA\n--------------------------------\n');
    bytes.addAll(latin1.encode(header));

    // Envelope em destaque (Double-height)
    bytes.addAll([0x1B, 0x21, 0x20]);
    bytes.addAll(latin1.encode('ENVELOPE #$envelopeNumber\n'));
    bytes.addAll([0x1B, 0x21, 0x00]); // Normal

    // Nome do Membro
    final nameFormatted = _normalizeText(memberName);
    bytes.addAll(latin1.encode('$nameFormatted\n--------------------------------\n\n'));

    // QR Code universal ESC/POS Raster Bit Image (GS v 0)
    // Funciona em 100% das impressoras térmicas (Epson, POS-58, Goojprt, MPT, etc.)
    final rasterBytes = _buildQrRasterEscPos(qrData, moduleSize: 6);
    bytes.addAll(rasterBytes);

    // Rodapé da etiqueta
    bytes.addAll(latin1.encode('\n\nCole no envelope do dizimo\n\n\n\n'));

    // cutPaper: false para evitar erro em impressoras portáteis sem guilhotina
    await printRawBytes(bytes, printer: printer, cutPaper: false);
  }

  static List<int> _buildQrRasterEscPos(String data, {int moduleSize = 6}) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final modCount = qrImage.moduleCount;

    const quietZone = 2;
    final totalModules = modCount + (quietZone * 2);
    final widthDots = totalModules * moduleSize;
    final heightDots = totalModules * moduleSize;
    final widthBytes = (widthDots + 7) ~/ 8;

    final bytes = <int>[];
    // GS v 0 0 xL xH yL yH
    bytes.addAll([
      0x1D,
      0x76,
      0x30,
      0x00,
      widthBytes & 0xFF,
      (widthBytes >> 8) & 0xFF,
      heightDots & 0xFF,
      (heightDots >> 8) & 0xFF,
    ]);

    for (int y = 0; y < heightDots; y++) {
      final modY = (y ~/ moduleSize) - quietZone;
      for (int byteIdx = 0; byteIdx < widthBytes; byteIdx++) {
        int byteVal = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = (byteIdx * 8) + bit;
          if (x < widthDots) {
            final modX = (x ~/ moduleSize) - quietZone;
            final isDark = modX >= 0 &&
                modX < modCount &&
                modY >= 0 &&
                modY < modCount &&
                qrImage.isDark(modY, modX);
            if (isDark) {
              byteVal |= (1 << (7 - bit));
            }
          }
        }
        bytes.add(byteVal);
      }
    }

    return bytes;
  }

  Future<void> printTest({ThermalPrinterSelection? printer}) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Nenhuma impressora Bluetooth pareada ou selecionada.',
      );
    }
    final now = DateTime.now();
    final bytes = <int>[];
    bytes.addAll([0x1B, 0x40]); // Reset ESC @
    bytes.addAll([0x1B, 0x74, 0x02]); // CP850
    bytes.addAll([0x1B, 0x61, 0x01]); // Centralizado
    bytes.addAll([0x1B, 0x45, 0x01]); // Negrito
    bytes.addAll(latin1.encode('IGREJA PRESBITERIANA DO BRASIL\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('Diaconato & Tesouraria\n'));
    bytes.addAll(latin1.encode('--------------------------------\n'));
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('TESTE DE COMUNICACAO POS\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('--------------------------------\n'));
    bytes.addAll([0x1B, 0x61, 0x00]); // À esquerda
    bytes.addAll(latin1.encode('Impressora: ${_normalizeText(selected.name)}\n'));
    bytes.addAll(latin1.encode('Endereco:   ${selected.address}\n'));
    bytes.addAll(latin1.encode('Data/Hora:  ${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}\n\n'));
    bytes.addAll([0x1B, 0x61, 0x01]); // Centralizado
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('*** BLUETOOTH CONECTADO OK ***\n\n\n\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);

    await printRawBytes(bytes, printer: selected, cutPaper: false);
  }

  Future<void> printEnvelope({
    required String membro,
    required String destinacao,
    required String forma,
    required double valor,
    required String id,
    ThermalPrinterSelection? printer,
  }) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Nenhuma impressora Bluetooth pareada ou selecionada.',
      );
    }
    final now = DateTime.now();
    final dateStr =
        '${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}';

    final bytes = <int>[];
    // Reset ESC @
    bytes.addAll([0x1B, 0x40]);
    // Code Page CP850
    bytes.addAll([0x1B, 0x74, 0x02]);

    // Cabeçalho Centralizado
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold
    bytes.addAll(latin1.encode('IGREJA PRESBITERIANA DO BRASIL\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('Diaconato & Tesouraria\n'));
    bytes.addAll(latin1.encode('================================\n'));
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('COMPROVANTE DE ENTRADA\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('--------------------------------\n'));

    // Dados à esquerda
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(latin1.encode('Data/Hora:  $dateStr\n'));
    bytes.addAll(latin1.encode('Controle:   #$id\n'));
    bytes.addAll(latin1.encode('Destinacao: ${_destinacaoLabel(destinacao)}\n'));
    bytes.addAll(latin1.encode('Forma:      ${_formaLabel(forma)}\n'));
    bytes.addAll(latin1.encode('--------------------------------\n'));
    bytes.addAll(latin1.encode('Membro / Contribuinte:\n'));
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('  ${_normalizeText(membro)}\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('================================\n'));

    // Valor em destaque (Centralizado, Double-Height, Bold)
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x21, 0x20]); // Double-Height
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold
    bytes.addAll(latin1.encode('VALOR: ${_money(valor)}\n'));
    bytes.addAll([0x1B, 0x21, 0x00]); // Normal
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold off
    bytes.addAll(latin1.encode('================================\n\n'));

    // Assinatura e versículo
    bytes.addAll(latin1.encode('________________________________\n'));
    bytes.addAll(latin1.encode('Visto Junta Diaconal / Tesouraria\n\n'));
    bytes.addAll(latin1.encode('"Deus ama ao que da com alegria."\n'));
    bytes.addAll(latin1.encode('(2 Co 9:7)\n\n\n\n'));

    await printRawBytes(bytes, printer: selected, cutPaper: false);
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
    ThermalPrinterSelection? printer,
  }) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Nenhuma impressora Bluetooth pareada ou selecionada.',
      );
    }
    final now = DateTime.now();
    final dateStr =
        '${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}';

    final statusBatimento = diferencaDinheiro.abs() < 0.01
        ? '100% CONCILIADO'
        : (diferencaDinheiro > 0
            ? '+ ${_money(diferencaDinheiro)} (SOBRA SALVA)'
            : '- ${_money(diferencaDinheiro.abs())} (DIFERENCA)');

    final bytes = <int>[];
    // Reset ESC @
    bytes.addAll([0x1B, 0x40]);
    // Code Page CP850
    bytes.addAll([0x1B, 0x74, 0x02]);

    // Cabeçalho Centralizado
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('IGREJA PRESBITERIANA DO BRASIL\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('Junta Diaconal & Tesouraria\n'));
    bytes.addAll(latin1.encode('================================\n'));
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('TERMO DE APURACAO DIACONAL\nDIZIMOS E OFERTAS\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('--------------------------------\n'));

    // Dados à esquerda
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(latin1.encode('Data/Hora: $dateStr\n'));
    bytes.addAll(latin1.encode('Servico:   ${_normalizeText(culto)}\n'));
    bytes.addAll(latin1.encode('--------------------------------\n'));

    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('RESUMO FINANCEIRO\n'));
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll([0x1B, 0x61, 0x00]);

    bytes.addAll(latin1.encode('Especie (Contado):  ${_money(totalFisico)}\n'));
    bytes.addAll(latin1.encode('Envelopes Dinheiro: ${_money(totalEnvelopesDinheiro)}\n'));
    bytes.addAll(latin1.encode('Ofertas Salva:      ${_money(diferencaDinheiro)}\n'));
    bytes.addAll(latin1.encode('PIX / Transf.:      ${_money(totalPix)}\n'));
    bytes.addAll(latin1.encode('Cartoes:            ${_money(totalCartao)}\n'));
    bytes.addAll(latin1.encode('================================\n'));

    // TOTAL GERAL em destaque
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll([0x1B, 0x21, 0x20]);
    bytes.addAll([0x1B, 0x45, 0x01]);
    bytes.addAll(latin1.encode('TOTAL: ${_money(totalGeral)}\n'));
    bytes.addAll([0x1B, 0x21, 0x00]);
    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll(latin1.encode('================================\n'));

    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(latin1.encode('DESTINACOES\n'));
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll(latin1.encode('Dizimos:        ${_money(totDizimo)}\n'));
    bytes.addAll(latin1.encode('Ofertas Gerais: ${_money(totOferta)}\n'));
    if (totMissoes > 0) {
      bytes.addAll(latin1.encode('Missoes:        ${_money(totMissoes)}\n'));
    }
    if (totConstrucao > 0) {
      bytes.addAll(latin1.encode('Construcao:     ${_money(totConstrucao)}\n'));
    }
    bytes.addAll(latin1.encode('--------------------------------\n'));
    bytes.addAll(latin1.encode('Total Envelopes: $totalEnvelopes un\n'));
    bytes.addAll(latin1.encode('Batimento Salva: $statusBatimento\n'));
    bytes.addAll(latin1.encode('--------------------------------\n'));

    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll(latin1.encode('COMISSAO DE CONFERENCIA\n\n'));
    bytes.addAll(latin1.encode('________________________________\n'));
    bytes.addAll(latin1.encode('1o: ${_normalizeText(conferente1)}\n\n'));
    bytes.addAll(latin1.encode('________________________________\n'));
    bytes.addAll(latin1.encode('2o: ${_normalizeText(conferente2)}\n\n'));
    bytes.addAll(latin1.encode('"Deus ama ao que da com alegria."\n'));
    bytes.addAll(latin1.encode('(2 Co 9:7)\n\n\n\n'));

    await printRawBytes(bytes, printer: selected, cutPaper: false);
  }

  static String _destinacaoLabel(String d) {
    switch (d.toLowerCase().trim()) {
      case 'dizimo':
        return 'DIZIMO';
      case 'oferta':
        return 'OFERTA GERAL';
      case 'missoes':
        return 'MISSOES';
      case 'construcao':
        return 'CONSTRUCAO';
      default:
        return _normalizeText(d.toUpperCase());
    }
  }

  static String _formaLabel(String f) {
    switch (f.toLowerCase().trim()) {
      case 'dinheiro':
        return 'DINHEIRO (ESPECIE)';
      case 'pix':
        return 'PIX';
      case 'cartao':
        return 'CARTAO';
      default:
        return _normalizeText(f.toUpperCase());
    }
  }

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

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class ThermalPrinterException implements Exception {
  final String message;
  const ThermalPrinterException(this.message);

  @override
  String toString() => message;
}
