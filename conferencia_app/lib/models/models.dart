double asDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? defaultValue;
  }
  return defaultValue;
}

int asInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    return int.tryParse(trimmed) ??
        (double.tryParse(trimmed)?.toInt() ?? defaultValue);
  }
  return defaultValue;
}

class UserModel {
  final int? id;
  final String name;
  final String? email;
  final String role;
  final int? institutionId;
  final bool isOffline;

  const UserModel({
    this.id,
    required this.name,
    this.email,
    this.role = 'Membro / Oficial',
    this.institutionId,
    this.isOffline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Usuário IPB',
      email: json['email']?.toString(),
      role:
          json['role']?.toString() ??
          json['roles']?.toString() ??
          'Oficial / Membro',
      institutionId: json['institution_id'] is int
          ? json['institution_id']
          : int.tryParse(json['institution_id']?.toString() ?? ''),
      isOffline: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'institution_id': institutionId,
    'is_offline': isOffline,
  };
}

class MemberModel {
  final int id;
  final String fullName;
  final String? envelopeNumber;

  const MemberModel({
    required this.id,
    required this.fullName,
    this.envelopeNumber,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      envelopeNumber: json['envelope_number']?.toString(),
    );
  }

  String get label => envelopeNumber != null && envelopeNumber!.isNotEmpty
      ? '$fullName (#$envelopeNumber)'
      : fullName;

  String get qrCodePayload =>
      envelopeNumber != null && envelopeNumber!.isNotEmpty
      ? 'IPB:$envelopeNumber'
      : 'IPB:ID$id';
}

class ColetaModel {
  final int id;
  final String code;
  final String date;
  final String serviceMeeting;
  final String? description;
  final String status;
  final String? creatorName;
  final String? closerName;
  final String? openedAt;
  final String? closedAt;
  final int entryCount;
  final double totalAmount;
  final double totalDizimos;
  final double ofertaDinheiro;
  final double ofertaPix;
  final double ofertaTransferencia;
  final double totalOfertas;
  final double totalGeral;
  final String? notes;

  const ColetaModel({
    required this.id,
    required this.code,
    required this.date,
    required this.serviceMeeting,
    this.description,
    required this.status,
    this.creatorName,
    this.closerName,
    this.openedAt,
    this.closedAt,
    required this.entryCount,
    required this.totalAmount,
    required this.totalDizimos,
    required this.ofertaDinheiro,
    required this.ofertaPix,
    required this.ofertaTransferencia,
    required this.totalOfertas,
    required this.totalGeral,
    this.notes,
  });

  bool get isAberta {
    final s = status.toLowerCase().trim();
    return s == 'aberta' ||
        s.contains('reaberta') ||
        s.contains('andamento') ||
        s.contains('conferência') ||
        s.contains('conferencia');
  }

  factory ColetaModel.fromJson(Map<String, dynamic> json) {
    final rawId = asInt(json['id']);
    final totalDiz = asDouble(
      json['total_dizimos'],
      asDouble(json['total_amount']),
    );
    final ofDin = asDouble(json['oferta_dinheiro']);
    final ofPix = asDouble(json['oferta_pix']);
    final ofTransf = asDouble(json['oferta_transferencia']);
    final totOf = asDouble(json['total_ofertas'], ofDin + ofPix + ofTransf);
    final totGeral = asDouble(json['total_geral'], totalDiz + totOf);

    return ColetaModel(
      id: rawId,
      code:
          json['code']?.toString() ??
          'CONF-${rawId.toString().padLeft(6, '0')}',
      date: json['date']?.toString().split('T')[0] ?? '',
      serviceMeeting: json['service_meeting']?.toString() ?? 'Culto de Domingo',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'Aberta',
      creatorName: json['creator'] is Map
          ? json['creator']['name']?.toString()
          : json['creator_name']?.toString(),
      closerName: json['closer'] is Map
          ? json['closer']['name']?.toString()
          : json['closer_name']?.toString(),
      openedAt: json['opened_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      entryCount: asInt(json['entry_count']),
      totalAmount: asDouble(json['total_amount'], totGeral),
      totalDizimos: totalDiz,
      ofertaDinheiro: ofDin,
      ofertaPix: ofPix,
      ofertaTransferencia: ofTransf,
      totalOfertas: totOf,
      totalGeral: totGeral,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'date': date,
    'service_meeting': serviceMeeting,
    'description': description,
    'status': status,
    'creator_name': creatorName,
    'closer_name': closerName,
    'opened_at': openedAt,
    'closed_at': closedAt,
    'entry_count': entryCount,
    'total_amount': totalAmount,
    'total_dizimos': totalDizimos,
    'oferta_dinheiro': ofertaDinheiro,
    'oferta_pix': ofertaPix,
    'oferta_transferencia': ofertaTransferencia,
    'total_ofertas': totalOfertas,
    'total_geral': totalGeral,
    'notes': notes,
  };
}

class EnvelopeEntry {
  final String id;
  final int? personId;
  final String membro;
  final String? envelopeNumber;
  final double valor;
  final String destinacao; // 'dizimo' | 'oferta' | 'missoes' | 'construcao'
  final String forma; // 'dinheiro' | 'pix' | 'transferencia' | 'cartao'
  final String timestamp;

  const EnvelopeEntry({
    required this.id,
    this.personId,
    required this.membro,
    this.envelopeNumber,
    required this.valor,
    required this.destinacao,
    required this.forma,
    required this.timestamp,
  });

  factory EnvelopeEntry.fromJson(Map<String, dynamic> json) {
    return EnvelopeEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      personId: json['person_id'] != null ? asInt(json['person_id']) : null,
      membro:
          json['membro']?.toString() ??
          json['contribuinte']?.toString() ??
          json['person']?['full_name']?.toString() ??
          json['contribuinte_nome']?.toString() ??
          'Oferta',
      envelopeNumber:
          json['envelope_number']?.toString() ??
          json['envelope']?.toString() ??
          json['person']?['envelope_number']?.toString(),
      valor: asDouble(json['valor'], asDouble(json['amount'])),
      destinacao:
          json['destinacao']?.toString() ??
          json['contribution_type']?.toString() ??
          'dizimo',
      forma:
          json['forma']?.toString() ??
          json['payment_method']?.toString() ??
          'dinheiro',
      timestamp:
          json['timestamp']?.toString() ??
          json['hora']?.toString() ??
          json['created_at']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'person_id': personId,
    'membro': membro,
    'envelope_number': envelopeNumber,
    'valor': valor,
    'destinacao': destinacao,
    'forma': forma,
    'timestamp': timestamp,
  };
}

/// A local, append-only representation of a conference recorded without a
/// connection. Its payload is never edited after creation; only its delivery
/// and review state may change.
class OfflineColetaQueueItem {
  final String operationId;
  final String deviceId;
  final String capturedAt;
  final Map<String, dynamic> coleta;
  final List<EnvelopeEntry> entries;
  final String status;
  final int? serverId;
  final String? reviewNotes;
  final int attempts;

  const OfflineColetaQueueItem({
    required this.operationId,
    required this.deviceId,
    required this.capturedAt,
    required this.coleta,
    required this.entries,
    required this.status,
    this.serverId,
    this.reviewNotes,
    this.attempts = 0,
  });

  bool get awaitsUpload => status == 'pending_upload';
  bool get awaitsReview => status == 'pending_review';
  bool get isResolved => status == 'approved' || status == 'rejected';

  factory OfflineColetaQueueItem.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] is List
        ? json['entries'] as List
        : const [];
    return OfflineColetaQueueItem(
      operationId: json['operation_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      capturedAt: json['captured_at']?.toString() ?? '',
      coleta: Map<String, dynamic>.from(json['coleta'] as Map? ?? const {}),
      entries: rawEntries
          .whereType<Map>()
          .map(
            (entry) => EnvelopeEntry.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(),
      status: json['status']?.toString() ?? 'pending_upload',
      serverId: json['server_id'] == null ? null : asInt(json['server_id']),
      reviewNotes: json['review_notes']?.toString(),
      attempts: asInt(json['attempts']),
    );
  }

  OfflineColetaQueueItem copyWith({
    String? status,
    int? serverId,
    String? reviewNotes,
    int? attempts,
  }) => OfflineColetaQueueItem(
    operationId: operationId,
    deviceId: deviceId,
    capturedAt: capturedAt,
    coleta: coleta,
    entries: entries,
    status: status ?? this.status,
    serverId: serverId ?? this.serverId,
    reviewNotes: reviewNotes ?? this.reviewNotes,
    attempts: attempts ?? this.attempts,
  );

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'device_id': deviceId,
    'captured_at': capturedAt,
    'coleta': coleta,
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'status': status,
    'server_id': serverId,
    'review_notes': reviewNotes,
    'attempts': attempts,
  };

  Map<String, dynamic> toServerPayload() => {
    'client_operation_id': operationId,
    'device_id': deviceId,
    'captured_at': capturedAt,
    'coleta': coleta,
    'entries': entries
        .map(
          (entry) => {
            'person_id': entry.personId,
            'amount': entry.valor,
            'contribution_type': entry.destinacao.isEmpty
                ? 'dizimo'
                : entry.destinacao,
            'payment_method': entry.forma == 'cartao' ? 'outros' : entry.forma,
            'envelope_number': entry.envelopeNumber,
            'contribuinte_nome': entry.membro,
            'is_unidentified': entry.personId == null,
          },
        )
        .toList(),
  };
}

class DenominationItem {
  final double value;
  final String label;
  final bool isCedula;

  const DenominationItem({
    required this.value,
    required this.label,
    required this.isCedula,
  });
}

const denominationsList = [
  DenominationItem(value: 200, label: 'R\$ 200', isCedula: true),
  DenominationItem(value: 100, label: 'R\$ 100', isCedula: true),
  DenominationItem(value: 50, label: 'R\$ 50', isCedula: true),
  DenominationItem(value: 20, label: 'R\$ 20', isCedula: true),
  DenominationItem(value: 10, label: 'R\$ 10', isCedula: true),
  DenominationItem(value: 5, label: 'R\$ 5', isCedula: true),
  DenominationItem(value: 2, label: 'R\$ 2', isCedula: true),
  DenominationItem(value: 1, label: 'R\$ 1', isCedula: false),
  DenominationItem(value: 0.50, label: '50¢', isCedula: false),
  DenominationItem(value: 0.25, label: '25¢', isCedula: false),
  DenominationItem(value: 0.10, label: '10¢', isCedula: false),
  DenominationItem(value: 0.05, label: '5¢', isCedula: false),
];
