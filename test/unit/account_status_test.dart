import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/data/supabase/mappers.dart';

void main() {
  test('profile status and suspension date map from profiles row', () {
    final p = mapProfile({
      'id': 'u1',
      'name': 'A',
      'roles': ['buyer'],
      'status': 'suspended',
      'suspended_until': '2026-10-09T00:00:00Z',
    });
    expect(p.accountStatus, 'suspended');
    expect(p.isBlocked, isTrue);
    expect(p.suspendedUntil, isNotNull);
    expect(mapProfile({'id': 'u2'}).isBlocked, isFalse);
  });
}
