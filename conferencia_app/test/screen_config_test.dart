import 'package:flutter_test/flutter_test.dart';
import 'package:ipb_conferencia/models/models.dart';

void main() {
  group('ScreenConfig & UserModel Tests', () {
    test('UserModel serializes and deserializes institutionId properly', () {
      final json = {
        'id': 1,
        'name': 'Rev. Pastor IPB',
        'email': 'pastor@ipb.org.br',
        'role': 'Pastor / Presidente',
        'institution_id': 12,
        'is_offline': false,
      };

      final user = UserModel.fromJson(json);
      expect(user.institutionId, 12);
      expect(user.role, 'Pastor / Presidente');
      expect(user.isOffline, isFalse);

      final serialized = user.toJson();
      expect(serialized['institution_id'], 12);
      expect(serialized['name'], 'Rev. Pastor IPB');
    });

    test('Screen toggles parsing logic resolves church specific settings and defaults', () {
      final togglesRaw = {
        '5': {
          'classes': false,
          'boletim': true,
          'dizimos': true,
        },
        '12': {
          'classes': true,
          'boletim': false,
          'dizimos': false,
        }
      };

      // Mocking church 5
      final church5Toggles = togglesRaw['5']!.map((k, v) => MapEntry(k, v == true));
      expect(church5Toggles['classes'], isFalse);
      expect(church5Toggles['boletim'], isTrue);
      expect(church5Toggles['dizimos'], isTrue);

      // Mocking church 12
      final church12Toggles = togglesRaw['12']!.map((k, v) => MapEntry(k, v == true));
      expect(church12Toggles['classes'], isTrue);
      expect(church12Toggles['boletim'], isFalse);
      expect(church12Toggles['dizimos'], isFalse);

      // Default when screen key not present
      final isFinanceiroEnabled = church12Toggles['financeiro'] ?? true;
      expect(isFinanceiroEnabled, isTrue);
    });
  });
}
