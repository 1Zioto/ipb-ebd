class UserModel {
  final int? id;
  final String name;
  final String? email;
  final String role;
  final bool isOffline;

  const UserModel({
    this.id,
    required this.name,
    this.email,
    this.role = 'Membro / Oficial',
    this.isOffline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Usuário IPB',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? json['roles']?.toString() ?? 'Oficial / Membro',
      isOffline: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      envelopeNumber: json['envelope_number']?.toString(),
    );
  }

  String get label => envelopeNumber != null && envelopeNumber!.isNotEmpty
      ? '$fullName (#$envelopeNumber)'
      : fullName;
}

class EnvelopeEntry {
  final String id;
  final int? personId;
  final String membro;
  final double valor;
  final String destinacao; // 'dizimo' | 'oferta' | 'missoes' | 'construcao'
  final String forma;      // 'dinheiro' | 'pix' | 'cartao'
  final String timestamp;

  const EnvelopeEntry({
    required this.id,
    this.personId,
    required this.membro,
    required this.valor,
    required this.destinacao,
    required this.forma,
    required this.timestamp,
  });

  factory EnvelopeEntry.fromJson(Map<String, dynamic> json) {
    return EnvelopeEntry(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      personId: json['person_id'] is int ? json['person_id'] : int.tryParse(json['person_id']?.toString() ?? ''),
      membro: json['membro']?.toString() ?? 'Oferta',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      destinacao: json['destinacao']?.toString() ?? 'dizimo',
      forma: json['forma']?.toString() ?? 'dinheiro',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'person_id': personId,
        'membro': membro,
        'valor': valor,
        'destinacao': destinacao,
        'forma': forma,
        'timestamp': timestamp,
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
