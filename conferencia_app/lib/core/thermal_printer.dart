import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

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
        'Nenhuma impressora configurada. Abra o menu, vá em "Configurações da Impressora" e selecione sua POS-58.',
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
        'Nenhuma impressora configurada. Abra o menu, vá em "Configurações da Impressora" e selecione sua POS-58.',
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
    final rasterBytes = _buildQrRasterEscPos(qrData, moduleSize: 6);
    bytes.addAll(rasterBytes);

    // Rodapé da etiqueta
    bytes.addAll(latin1.encode('\n\nCole no envelope do dizimo\n\n\n\n'));

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
        'Nenhuma impressora Bluetooth configurada. Selecione em Configurações > Impressora.',
      );
    }
    final now = DateTime.now();
    final lines = <String>[
      _receiptStart,
      _center('IGREJA PRESBITERIANA', width: 32),
      _center('DO BRASIL', width: 32),
      _receiptEnd,
      _center('Diaconato & Tesouraria', width: 32),
      '=' * 32,
      _receiptStart,
      _center('TESTE DE COMUNICACAO', width: 32),
      _receiptEnd,
      '-' * 32,
      'Impressora: ${_normalizeText(selected.name)}',
      'Endereco:   ${selected.address}',
      'Data/Hora:  ${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}',
      '-' * 32,
      _receiptStart,
      _center('BLUETOOTH CONECTADO OK', width: 32),
      _receiptEnd,
      '=' * 32,
      '',
    ];

    await printText(lines.join('\n'), printer: selected, cutPaper: false);
  }

  Future<void> printEnvelope({
    required String membro,
    required String destinacao,
    required String forma,
    required double valor,
    required String id,
    String? responsavel,
    ThermalPrinterSelection? printer,
  }) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Nenhuma impressora Bluetooth configurada. Selecione em Configurações > Impressora.',
      );
    }
    final now = DateTime.now();
    final dateStr =
        '${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}';

    final resp = responsavel ?? ApiService.instance.currentUser?.name ?? 'Diácono Responsável';

    final lines = <String>[
      _receiptStart,
      _center('IPB • ENTRADA', width: 32),
      _receiptEnd,
      '-' * 32,
      'Data: $dateStr  Ctrl: #$id',
      'Membro: ${_normalizeText(membro)}',
      'Dest: ${_destinacaoLabel(destinacao)} | ${_formaLabel(forma)}',
      'Resp: ${_normalizeText(resp)}',
      '=' * 32,
      _receiptStart,
      _center('VALOR: ${_money(valor)}', width: 32),
      _receiptEnd,
      '=' * 32,
      '',
    ];

    await printText(lines.join('\n'), printer: selected, cutPaper: false);
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
        'Nenhuma impressora Bluetooth configurada. Selecione em Configurações > Impressora.',
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

    final lines = <String>[
      _receiptStart,
      _center('IGREJA PRESBITERIANA', width: 32),
      _center('DO BRASIL', width: 32),
      _receiptEnd,
      _center('Junta Diaconal & Tesouraria', width: 32),
      '=' * 32,
      _receiptStart,
      _center('TERMO DE APURACAO', width: 32),
      _receiptEnd,
      '-' * 32,
      'Data/Hora:  $dateStr',
      'Culto:      ${_normalizeText(culto)}',
      '-' * 32,
      _center('RESUMO FINANCEIRO', width: 32),
      'Especie (Contado):  ${_money(totalFisico)}',
      'Envelopes Dinheiro: ${_money(totalEnvelopesDinheiro)}',
      'Ofertas Salva:      ${_money(diferencaDinheiro)}',
      'PIX / Transf.:      ${_money(totalPix)}',
      'Cartoes:            ${_money(totalCartao)}',
      '=' * 32,
      _receiptStart,
      _center('TOTAL: ${_money(totalGeral)}', width: 32),
      _receiptEnd,
      '=' * 32,
      _center('DESTINACOES', width: 32),
      'Dizimos:        ${_money(totDizimo)}',
      'Ofertas Gerais: ${_money(totOferta)}',
      if (totMissoes > 0) 'Missoes:        ${_money(totMissoes)}',
      if (totConstrucao > 0) 'Construcao:     ${_money(totConstrucao)}',
      '-' * 32,
      'Total Envelopes: $totalEnvelopes un',
      'Batimento Salva: $statusBatimento',
      '-' * 32,
      _center('COMISSAO DE CONFERENCIA', width: 32),
      '',
      _center('________________________________', width: 32),
      _center('1o: ${_normalizeText(conferente1)}', width: 32),
      '',
      _center('________________________________', width: 32),
      _center('2o: ${_normalizeText(conferente2)}', width: 32),
      '',
      _center('"Deus ama ao que da com alegria."', width: 32),
      _center('(2 Co 9:7)', width: 32),
      '',
    ];

    await printText(lines.join('\n'), printer: selected, cutPaper: false);
  }

  Future<void> printDuasViasConferencia(
    Map<String, dynamic> comprovante, {
    ThermalPrinterSelection? printer,
  }) async {
    final selected = printer ?? await selectedPrinter();
    if (selected == null || !selected.isValid) {
      throw const ThermalPrinterException(
        'Nenhuma impressora Bluetooth configurada. Selecione em Configurações > Impressora.',
      );
    }

    final conf = comprovante['conferencia'] is Map ? comprovante['conferencia'] as Map<String, dynamic> : <String, dynamic>{};
    final List items = (comprovante['dizimos'] is Map && (comprovante['dizimos']['itens'] is List))
        ? (comprovante['dizimos']['itens'] as List)
        : (comprovante['lancamentos'] is List ? (comprovante['lancamentos'] as List) : []);

    final ofertas = comprovante['ofertas_avulsas'] is Map ? comprovante['ofertas_avulsas'] as Map<String, dynamic> : <String, dynamic>{};
    final resumo = comprovante['resumo_geral'] is Map ? comprovante['resumo_geral'] as Map<String, dynamic> : <String, dynamic>{};
    final dizimosMap = comprovante['dizimos'] is Map ? comprovante['dizimos'] as Map<String, dynamic> : <String, dynamic>{};
    final totais = comprovante['totais'] is Map ? comprovante['totais'] as Map<String, dynamic> : <String, dynamic>{};
    final porRecebimento = comprovante['por_recebimento'] is Map
        ? comprovante['por_recebimento'] as Map<String, dynamic>
        : (comprovante['consolidado_recebimento'] is Map ? comprovante['consolidado_recebimento'] as Map<String, dynamic> : <String, dynamic>{});

    final inst = comprovante['instituicao'] is Map ? comprovante['instituicao'] as Map<String, dynamic> : <String, dynamic>{};
    final churchName = inst['nome']?.toString() ?? comprovante['church_name']?.toString() ?? 'IGREJA PRESBITERIANA DO BRASIL';
    final isReimpresao = comprovante['is_reimpressao'] == true || (comprovante['meta'] is Map && comprovante['meta']['is_reimpressao'] == true);

    String buildViaText(String viaLabel) {
      final lines = <String>[];
      lines.add('=' * 32);
      lines.add(_center(_normalizeText(churchName.toUpperCase()), width: 32));
      lines.add(_center('CONFERENCIA DE ARRECADACAO', width: 32));
      lines.add('=' * 32);
      lines.add('Conferencia: ${conf['code'] ?? 'CONF-${conf['id']}'}');
      lines.add('Data:        ${conf['date'] ?? conf['data'] ?? ''}');
      final cultoStr = conf['culto'] ?? conf['service_meeting'];
      if (cultoStr != null && cultoStr.toString().isNotEmpty) {
        lines.add('Culto:       ${_normalizeText(cultoStr.toString())}');
      }
      lines.add('Abertura:    ${conf['opened_at'] ?? conf['aberto_em'] ?? ''}');
      lines.add('Fechamento:  ${conf['closed_at'] ?? conf['fechado_em'] ?? ''}');
      lines.add('Resp.:       ${_normalizeText(conf['responsavel_encerramento'] ?? conf['closer_name'] ?? conf['responsavel_abertura'] ?? conf['creator_name'] ?? ApiService.instance.currentUser?.name ?? 'Diacono Resp.')}');
      lines.add('');
      lines.add('--------- DIZIMOS --------------');

      final ofDin = asDouble(ofertas['dinheiro'] ?? conf['oferta_dinheiro']);
      final ofPix = asDouble(ofertas['pix'] ?? conf['oferta_pix']);
      final ofTransf = asDouble(ofertas['transferencia'] ?? conf['oferta_transferencia']);
      final ofTot = asDouble(resumo['total_ofertas'] ?? ofertas['total'] ?? totais['ofertas'] ?? conf['total_ofertas'], ofDin + ofPix + ofTransf);

      double calcTotDiz = 0.0;
      double calcDin = ofDin;
      double calcPix = ofPix;
      double calcTransf = ofTransf;

      if (items.isEmpty) {
        lines.add('Nenhum dizimo lancado.');
      } else {
        for (final item in items) {
          final m = item is Map ? item : {};
          var nome = _normalizeText(m['contribuinte']?.toString() ?? m['membro']?.toString() ?? 'Avulso');
          if (nome.length > 15) nome = nome.substring(0, 15);
          final formaStr = m['forma']?.toString() ?? m['payment_method']?.toString() ?? 'Dinheiro';
          final forma = _formaLabel(formaStr).padRight(5);
          final formaShort = forma.length > 5 ? forma.substring(0, 5) : forma;
          final itemValor = asDouble(m['valor'] ?? m['amount']);
          calcTotDiz += itemValor;

          final fLower = formaStr.toLowerCase();
          if (fLower.contains('pix')) {
            calcPix += itemValor;
          } else if (fLower.contains('transf') || fLower.contains('cart')) {
            calcTransf += itemValor;
          } else {
            calcDin += itemValor;
          }

          final val = itemValor.toStringAsFixed(2).replaceAll('.', ',');
          final left = nome.padRight(16);
          final mid = formaShort.padRight(6);
          final right = val.padLeft(10);
          lines.add('$left$mid$right'.padRight(32).substring(0, 32));
        }
      }

      lines.add('-' * 32);
      final qtdEnvelopes = asInt(dizimosMap['quantidade_envelopes'] ?? conf['entry_count'], items.length);
      final totDiz = asDouble(resumo['total_dizimos'] ?? dizimosMap['total'] ?? totais['dizimos'] ?? conf['total_dizimos'], calcTotDiz);
      lines.add('Envelopes:   ${qtdEnvelopes.toString().padLeft(19)}');
      lines.add('TOTAL DIZIMOS: ${_money(totDiz).padLeft(17)}');
      lines.add('');

      lines.add('------ OFERTAS AVULSAS ---------');
      lines.add('Dinheiro:      ${_money(ofDin).padLeft(17)}');
      lines.add('Pix:           ${_money(ofPix).padLeft(17)}');
      lines.add('Transferencia: ${_money(ofTransf).padLeft(17)}');
      lines.add('-' * 32);
      lines.add('TOTAL OFERTAS: ${_money(ofTot).padLeft(17)}');
      lines.add('');

      lines.add('-------- RESUMO GERAL ----------');
      final totGeral = asDouble(resumo['total_geral'] ?? porRecebimento['geral'] ?? porRecebimento['total_geral'] ?? totais['geral'] ?? conf['total_geral'] ?? conf['total_amount'], totDiz + ofTot);
      lines.add('Dizimos:       ${_money(totDiz).padLeft(17)}');
      lines.add('Ofertas:       ${_money(ofTot).padLeft(17)}');
      lines.add('-' * 32);
      lines.add('TOTAL GERAL:   ${_money(totGeral).padLeft(17)}');
      lines.add('-' * 32);
      lines.add('');

      lines.add('TOTAL POR RECEBIMENTO:');
      final recDin = asDouble(porRecebimento['dinheiro'] ?? dizimosMap['total_dinheiro'], calcDin);
      final recPix = asDouble(porRecebimento['pix'] ?? dizimosMap['total_pix'], calcPix);
      final recTransf = asDouble(porRecebimento['transferencia'] ?? dizimosMap['total_transferencia'], calcTransf);
      lines.add('Dinheiro:      ${_money(recDin).padLeft(17)}');
      lines.add('Pix:           ${_money(recPix).padLeft(17)}');
      lines.add('Transferencia: ${_money(recTransf).padLeft(17)}');
      lines.add('');

      lines.add('Responsavel:');
      lines.add(_normalizeText(conf['responsavel_encerramento'] ?? conf['closer_name'] ?? conf['responsavel_abertura'] ?? conf['creator_name'] ?? ApiService.instance.currentUser?.name ?? 'Diacono Resp.'));
      lines.add('');
      lines.add('Assinatura:');
      lines.add('________________________________');
      lines.add('');
      lines.add(_center(viaLabel, width: 32));
      if (isReimpresao) {
        lines.add(_center('*** REIMPRESSAO ***', width: 32));
      }
      lines.add('=' * 32);
      lines.add('\n\n');
      return lines.join('\n');
    }

    // 1ª VIA — TESOURARIA
    final via1 = buildViaText('1a VIA - TESOURARIA');
    // 2ª VIA — ARQUIVO DA IGREJA
    final via2 = buildViaText('2a VIA - ARQUIVO DA IGREJA');

    final fullTicket = '$via1\n\n- - - - - - - - - - - - - - - - \n    ✂ CORTE AQUI\n- - - - - - - - - - - - - - - - \n\n$via2\n\n\n\n';
    await printText(fullTicket, printer: selected, cutPaper: true);
  }

  static const _receiptStart = '\x1BE\x01\x1B!\x18';
  static const _receiptEnd = '\x1B!\x00\x1BE\x00';

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
      'ü': 'u',
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
      'Ü': 'U',
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
