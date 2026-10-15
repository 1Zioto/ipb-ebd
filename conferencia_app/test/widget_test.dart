import 'package:flutter_test/flutter_test.dart';
import 'package:ipb_conferencia/models/models.dart';

void main() {
  test('offline queue serializes an immutable, idempotent batch payload', () {
    const item = OfflineColetaQueueItem(
      operationId: 'b5a59d4a-7626-4c90-9d40-2bb8af2df153',
      deviceId: 'd4a99d55-d77f-4d62-875c-02b86a3bd558',
      capturedAt: '2026-10-15T13:30:00.000Z',
      coleta: {'date': '2026-10-15', 'service_meeting': 'Culto Noturno'},
      entries: [
        EnvelopeEntry(
          id: 'local-1',
          personId: 42,
          membro: 'Membro IPB',
          envelopeNumber: '42',
          valor: 100,
          destinacao: 'dizimo',
          forma: 'cartao',
          timestamp: '2026-10-15T13:30:00.000Z',
        ),
      ],
      status: 'pending_upload',
    );

    final payload = item.toServerPayload();
    expect(payload['client_operation_id'], item.operationId);
    expect(payload['device_id'], item.deviceId);
    expect((payload['entries'] as List).single['payment_method'], 'outros');
    expect(item.awaitsUpload, isTrue);
    expect(item.isResolved, isFalse);
  });
}
