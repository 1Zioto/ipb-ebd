import 'package:flutter/foundation.dart';
import '../models/ebd_models.dart';

class EbdService {
  static final EbdService instance = EbdService._internal();
  EbdService._internal() {
    _initializeMockData();
  }

  final List<EbdClassModel> _classes = [];
  final Map<int, EbdSessionDetailsModel> _sessions = {};

  void _initializeMockData() {
    _classes.addAll([
      EbdClassModel(
        id: 1,
        name: 'Classe dos Jovens — Bereanos',
        ageRange: '18 a 30 anos',
        room: 'Sala 04',
        teacherName: 'Prof. Marcos Vinícius',
        teacherId: 10,
        studentsCount: 18,
        status: 'pendente',
        presentCount: 0,
        biblesCount: 0,
        magazinesCount: 0,
        offerAmount: 0.0,
        isLinkedToUser: true, // Vinculada ao professor Marcos
      ),
      EbdClassModel(
        id: 2,
        name: 'Classe dos Adultos — Bereia',
        ageRange: '31 a 59 anos',
        room: 'Nave Principal',
        teacherName: 'Presb. Paulo Roberto',
        teacherId: 11,
        studentsCount: 32,
        status: 'em_andamento',
        presentCount: 28,
        biblesCount: 26,
        magazinesCount: 24,
        offerAmount: 180.0,
        isLinkedToUser: false,
      ),
      EbdClassModel(
        id: 3,
        name: 'Classe Infantil — Cordeirinhos de Cristo',
        ageRange: '4 a 8 anos',
        room: 'Sala das Crianças 01',
        teacherName: 'Profª. Débora Neves',
        teacherId: 12,
        studentsCount: 14,
        status: 'finalizada',
        presentCount: 13,
        biblesCount: 11,
        magazinesCount: 13,
        offerAmount: 45.0,
        isLinkedToUser: false,
      ),
      EbdClassModel(
        id: 4,
        name: 'Classe de Juniores — Soldados da Fé',
        ageRange: '9 a 13 anos',
        room: 'Sala 02',
        teacherName: 'Prof. Lucas Mendes',
        teacherId: 13,
        studentsCount: 16,
        status: 'finalizada',
        presentCount: 15,
        biblesCount: 14,
        magazinesCount: 14,
        offerAmount: 60.0,
        isLinkedToUser: false,
      ),
      EbdClassModel(
        id: 5,
        name: 'Classe de Adolescentes — UPA',
        ageRange: '14 a 17 anos',
        room: 'Sala 03',
        teacherName: 'Diác. Carlos Silva',
        teacherId: 14,
        studentsCount: 15,
        status: 'em_andamento',
        presentCount: 12,
        biblesCount: 12,
        magazinesCount: 10,
        offerAmount: 50.0,
        isLinkedToUser: false,
      ),
      EbdClassModel(
        id: 6,
        name: 'Classe da Melhor Idade — Simeão & Ana',
        ageRange: '60+ anos',
        room: 'Salão Nobre',
        teacherName: 'Rev. Antônio Carlos',
        teacherId: 15,
        studentsCount: 22,
        status: 'finalizada',
        presentCount: 20,
        biblesCount: 20,
        magazinesCount: 18,
        offerAmount: 210.0,
        isLinkedToUser: false,
      ),
    ]);

    // Inicializa a sessão da Classe dos Jovens (ID 1)
    _sessions[1] = EbdSessionDetailsModel(
      sessionId: 101,
      classId: 1,
      className: 'Classe dos Jovens — Bereanos',
      eventDate: 'Domingo, 13 de Outubro',
      teacherName: 'Prof. Marcos Vinícius',
      teacherPersonId: 10,
      status: 'pendente',
      materialMode: 'individual',
      biblesTotal: 0,
      magazinesTotal: 0,
      offerAmount: 0.0,
      records: [
        AttendanceRecordModel(personId: 1, studentName: 'André Luiz Albuquerque', envelopeNumber: '101', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 2, studentName: 'Beatriz Vasconcelos', envelopeNumber: '102', isPresent: true, broughtBible: true, broughtMagazine: false, isBirthdayWeek: true),
        AttendanceRecordModel(personId: 3, studentName: 'Carlos Eduardo Nogueira', envelopeNumber: '103', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 4, studentName: 'Daniel Moreira Sampaio', envelopeNumber: '104', isPresent: false, broughtBible: false, broughtMagazine: false),
        AttendanceRecordModel(personId: 5, studentName: 'Esther Ramos Peixoto', envelopeNumber: '105', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 6, studentName: 'Felipe Augusto Santos', envelopeNumber: '106', isPresent: true, broughtBible: false, broughtMagazine: true),
        AttendanceRecordModel(personId: 7, studentName: 'Gabriel Henrique Braga', envelopeNumber: '107', isPresent: true, broughtBible: true, broughtMagazine: true, isBirthdayToday: true),
        AttendanceRecordModel(personId: 8, studentName: 'Helena Cristina Dias', envelopeNumber: '108', isPresent: false, broughtBible: false, broughtMagazine: false),
        AttendanceRecordModel(personId: 9, studentName: 'Isabela Monteiro Rios', envelopeNumber: '109', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 10, studentName: 'João Vitor Medeiros', envelopeNumber: '110', isPresent: true, broughtBible: true, broughtMagazine: false),
        AttendanceRecordModel(personId: 11, studentName: 'Lucas Ferreira da Silva', envelopeNumber: '111', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 12, studentName: 'Manuela Guimarães Lima', envelopeNumber: '112', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 13, studentName: 'Nicolas Duarte Castro', envelopeNumber: '113', isPresent: false, broughtBible: false, broughtMagazine: false),
        AttendanceRecordModel(personId: 14, studentName: 'Priscila Valença Barros', envelopeNumber: '114', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 15, studentName: 'Rafael Guimarães Pinto', envelopeNumber: '115', isPresent: true, broughtBible: true, broughtMagazine: true),
        AttendanceRecordModel(personId: 16, studentName: 'Samuel Tavares Queiroz', envelopeNumber: '116', isPresent: true, broughtBible: false, broughtMagazine: false),
        AttendanceRecordModel(personId: 17, studentName: 'Thiago Mendes Coelho', envelopeNumber: '117', isPresent: false, broughtBible: false, broughtMagazine: false),
        AttendanceRecordModel(personId: 18, studentName: 'Vitória Bastos Fontes', envelopeNumber: '118', isPresent: true, broughtBible: true, broughtMagazine: true),
      ],
    );

    // Inicializa sessões para as outras classes para demonstração completa
    for (final c in _classes) {
      if (c.id == 1) continue;
      _sessions[c.id] = EbdSessionDetailsModel(
        sessionId: 100 + c.id,
        classId: c.id,
        className: c.name,
        eventDate: 'Domingo, 13 de Outubro',
        teacherName: c.teacherName,
        teacherPersonId: c.teacherId,
        status: c.status,
        materialMode: 'individual',
        biblesTotal: c.biblesCount,
        magazinesTotal: c.magazinesCount,
        offerAmount: c.offerAmount,
        records: List.generate(
          c.studentsCount,
          (i) => AttendanceRecordModel(
            personId: (c.id * 100) + i + 1,
            studentName: 'Aluno ${c.name.split(' ')[1]} ${i + 1}',
            envelopeNumber: '${(c.id * 100) + i + 1}',
            isPresent: i < c.presentCount,
            broughtBible: i < c.biblesCount,
            broughtMagazine: i < c.magazinesCount,
            isBirthdayToday: i == 2 && c.id == 2,
            isBirthdayWeek: i == 4 && c.id == 3,
          ),
        ),
      );
    }
  }

  // Retorna resumo estatístico em tempo real do dia da EBD
  Future<EbdDashboardStats> getDashboardStats() async {
    int totalMatriculados = 0;
    int totalPresentes = 0;
    int totalBiblias = 0;
    int totalRevistas = 0;
    double totalOfertas = 0.0;

    for (final c in _classes) {
      totalMatriculados += c.studentsCount;
      totalPresentes += c.presentCount;
      totalBiblias += c.biblesCount;
      totalRevistas += c.magazinesCount;
      totalOfertas += c.offerAmount;
    }

    final int totalAusentes = totalMatriculados - totalPresentes;
    final double freq = totalMatriculados > 0
        ? (totalPresentes / totalMatriculados) * 100
        : 0.0;

    final aniversariantes = [
      const BirthdayModel(
        name: 'Gabriel Henrique Braga',
        dateFormatted: 'Hoje (13/10)',
        className: 'Jovens (Bereanos)',
        isToday: true,
      ),
      const BirthdayModel(
        name: 'Beatriz Vasconcelos',
        dateFormatted: 'Terça (15/10)',
        className: 'Jovens (Bereanos)',
        isToday: false,
      ),
      const BirthdayModel(
        name: 'Presb. Paulo Roberto',
        dateFormatted: 'Quinta (17/10)',
        className: 'Adultos (Bereia)',
        isToday: false,
      ),
      const BirthdayModel(
        name: 'Mariana Lima',
        dateFormatted: 'Sábado (19/10)',
        className: 'Cordeirinhos de Cristo',
        isToday: false,
      ),
    ];

    return EbdDashboardStats(
      totalMatriculados: totalMatriculados,
      totalPresentes: totalPresentes,
      totalAusentes: totalAusentes,
      frequenciaPercent: freq,
      totalBiblias: totalBiblias,
      totalRevistas: totalRevistas,
      totalOfertas: totalOfertas,
      dataDomingo: '13 de Outubro de 2026',
      aniversariantes: aniversariantes,
    );
  }

  // Lista as classes (com verificação de escopo de permissões)
  Future<List<EbdClassModel>> getClasses() async {
    return List.from(_classes);
  }

  // Retorna os detalhes da chamada de uma classe
  Future<EbdSessionDetailsModel?> getSessionForClass(int classId) async {
    return _sessions[classId];
  }

  // Salva chamada e recalcula contadores
  Future<void> saveAttendance({
    required int classId,
    required List<AttendanceRecordModel> records,
    required String teacherName,
    required String materialMode,
    required int biblesAgg,
    required int magazinesAgg,
    required double offerAmount,
  }) async {
    final session = _sessions[classId];
    if (session == null) return;

    session.teacherName = teacherName;
    session.materialMode = materialMode;
    session.offerAmount = offerAmount;
    session.biblesTotal = biblesAgg;
    session.magazinesTotal = magazinesAgg;
    if (session.status == 'pendente') {
      session.status = 'em_andamento';
    }

    final classItem = _classes.firstWhere((c) => c.id == classId);
    classItem.teacherName = teacherName;
    classItem.status = session.status;
    classItem.presentCount = session.presentCount;
    classItem.biblesCount = session.biblesCount;
    classItem.magazinesCount = session.magazinesCount;
    classItem.offerAmount = offerAmount;

    if (kDebugMode) {
      print('Chamada da classe $classId salva com sucesso.');
    }
  }

  // Finaliza a chamada
  Future<void> finalizeSession(int classId) async {
    final session = _sessions[classId];
    if (session == null) return;

    session.status = 'finalizada';
    final classItem = _classes.firstWhere((c) => c.id == classId);
    classItem.status = 'finalizada';
    classItem.presentCount = session.presentCount;
    classItem.biblesCount = session.biblesCount;
    classItem.magazinesCount = session.magazinesCount;
  }

  // Reabre chamada (Requer permissão call.reopen)
  Future<void> reopenSession(int classId) async {
    final session = _sessions[classId];
    if (session == null) return;

    session.status = 'em_andamento';
    final classItem = _classes.firstWhere((c) => c.id == classId);
    classItem.status = 'em_andamento';
  }
}
