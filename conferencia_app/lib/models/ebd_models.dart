class EbdClassModel {
  final int id;
  final String name;
  final String? ageRange;
  final String? room;
  String teacherName;
  final int? teacherId;
  final int studentsCount;
  String status; // 'pendente' | 'em_andamento' | 'finalizada'
  int presentCount;
  int biblesCount;
  int magazinesCount;
  double offerAmount;
  final bool isLinkedToUser;

  EbdClassModel({
    required this.id,
    required this.name,
    this.ageRange,
    this.room,
    required this.teacherName,
    this.teacherId,
    required this.studentsCount,
    this.status = 'pendente',
    this.presentCount = 0,
    this.biblesCount = 0,
    this.magazinesCount = 0,
    this.offerAmount = 0.0,
    this.isLinkedToUser = false,
  });

  bool get isFinalized => status == 'finalizada';
  bool get isInProgress => status == 'em_andamento';
  bool get isPending => status == 'pendente';

  double get attendancePercentage =>
      studentsCount > 0 ? (presentCount / studentsCount) * 100 : 0.0;

  factory EbdClassModel.fromJson(Map<String, dynamic> json) {
    return EbdClassModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Classe EBD',
      ageRange: json['age_range']?.toString(),
      room: json['room']?.toString(),
      teacherName: json['teacher_name']?.toString() ?? 'Professor Escalado',
      teacherId: json['teacher_id'] is int ? json['teacher_id'] : int.tryParse(json['teacher_id']?.toString() ?? ''),
      studentsCount: json['students_count'] is int ? json['students_count'] : 0,
      status: json['status']?.toString() ?? 'pendente',
      presentCount: json['present_count'] is int ? json['present_count'] : 0,
      biblesCount: json['bibles_count'] is int ? json['bibles_count'] : 0,
      magazinesCount: json['magazines_count'] is int ? json['magazines_count'] : 0,
      offerAmount: (json['offer_amount'] as num?)?.toDouble() ?? 0.0,
      isLinkedToUser: json['is_linked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age_range': ageRange,
        'room': room,
        'teacher_name': teacherName,
        'teacher_id': teacherId,
        'students_count': studentsCount,
        'status': status,
        'present_count': presentCount,
        'bibles_count': biblesCount,
        'magazines_count': magazinesCount,
        'offer_amount': offerAmount,
        'is_linked': isLinkedToUser,
      };
}

class AttendanceRecordModel {
  final int personId;
  final String studentName;
  final String? envelopeNumber;
  bool isPresent;
  bool broughtBible;
  bool broughtMagazine;
  final bool isBirthdayToday;
  final bool isBirthdayWeek;

  AttendanceRecordModel({
    required this.personId,
    required this.studentName,
    this.envelopeNumber,
    this.isPresent = false,
    this.broughtBible = false,
    this.broughtMagazine = false,
    this.isBirthdayToday = false,
    this.isBirthdayWeek = false,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      personId: json['person_id'] is int ? json['person_id'] : int.tryParse(json['person_id']?.toString() ?? '0') ?? 0,
      studentName: json['student_name']?.toString() ?? 'Aluno',
      envelopeNumber: json['envelope_number']?.toString(),
      isPresent: json['present'] == true,
      broughtBible: json['brought_bible'] == true,
      broughtMagazine: json['brought_magazine'] == true,
      isBirthdayToday: json['is_birthday_today'] == true,
      isBirthdayWeek: json['is_birthday_week'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'student_name': studentName,
        'envelope_number': envelopeNumber,
        'present': isPresent,
        'brought_bible': broughtBible,
        'brought_magazine': broughtMagazine,
        'is_birthday_today': isBirthdayToday,
        'is_birthday_week': isBirthdayWeek,
      };
}

class EbdSessionDetailsModel {
  final int sessionId;
  final int classId;
  final String className;
  final String eventDate;
  String teacherName;
  int? teacherPersonId;
  String status; // 'pendente' | 'em_andamento' | 'finalizada'
  String materialMode; // 'individual' | 'agregado'
  int biblesTotal;
  int magazinesTotal;
  double offerAmount;
  final List<AttendanceRecordModel> records;

  EbdSessionDetailsModel({
    required this.sessionId,
    required this.classId,
    required this.className,
    required this.eventDate,
    required this.teacherName,
    this.teacherPersonId,
    this.status = 'pendente',
    this.materialMode = 'individual',
    this.biblesTotal = 0,
    this.magazinesTotal = 0,
    this.offerAmount = 0.0,
    required this.records,
  });

  int get presentCount => records.where((r) => r.isPresent).length;
  int get biblesCount => materialMode == 'agregado'
      ? biblesTotal
      : records.where((r) => r.broughtBible).length;
  int get magazinesCount => materialMode == 'agregado'
      ? magazinesTotal
      : records.where((r) => r.broughtMagazine).length;
  int get totalStudents => records.length;
}

class BirthdayModel {
  final String name;
  final String dateFormatted;
  final String className;
  final bool isToday;

  const BirthdayModel({
    required this.name,
    required this.dateFormatted,
    required this.className,
    this.isToday = false,
  });
}

class EbdDashboardStats {
  final int totalMatriculados;
  final int totalPresentes;
  final int totalAusentes;
  final double frequenciaPercent;
  final int totalBiblias;
  final int totalRevistas;
  final double totalOfertas;
  final String dataDomingo;
  final List<BirthdayModel> aniversariantes;

  const EbdDashboardStats({
    required this.totalMatriculados,
    required this.totalPresentes,
    required this.totalAusentes,
    required this.frequenciaPercent,
    required this.totalBiblias,
    required this.totalRevistas,
    required this.totalOfertas,
    required this.dataDomingo,
    required this.aniversariantes,
  });
}
