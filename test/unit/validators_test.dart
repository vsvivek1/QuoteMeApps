import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/utils/validators.dart';

void main() {
  test('GSTIN checksum', () {
    final first14 = '27AAPFU0939F1Z';
    final valid = '$first14${Validators.gstinCheckChar(first14)}';
    expect(Validators.gstin(valid), isTrue);
    expect(Validators.gstin(valid.toLowerCase()), isTrue);
    final wrong = '$first14${valid.endsWith('A') ? 'B' : 'A'}';
    expect(Validators.gstin(wrong), isFalse);
    expect(Validators.gstin('27AAPFU0939F1'), isFalse);
    expect(Validators.gstin('99AAPFU0939F1ZV'), isFalse);
  });

  test('known real-format GSTIN passes', () {
    // Widely published sample GSTINs with valid check digits.
    expect(Validators.gstin('27AAPFU0939F1ZV'), isTrue);
    expect(Validators.gstin('29AAGCB7383J1Z4'), isTrue);
  });

  test('Udyam', () {
    expect(Validators.udyam('UDYAM-KA-01-0001234'), isTrue);
    expect(Validators.udyam('UDYAM-KA-1-0001234'), isFalse);
  });

  test('EIN', () {
    expect(Validators.ein('12-3456789'), isTrue);
    expect(Validators.ein('123456789'), isTrue);
    expect(Validators.ein('07-3456789'), isFalse);
    expect(Validators.ein('12-345678'), isFalse);
  });

  test('postal codes', () {
    expect(Validators.indiaPin('560034'), isTrue);
    expect(Validators.indiaPin('060034'), isFalse);
    expect(Validators.usZip('75201'), isTrue);
    expect(Validators.usZip('75201-1234'), isTrue);
    expect(Validators.usZip('7520'), isFalse);
  });

  test('phones', () {
    expect(Validators.indiaMobile('98765 43210'), isTrue);
    expect(Validators.indiaMobile('5876543210'), isFalse);
    expect(Validators.usPhone('(212) 555-0123'), isTrue);
    expect(Validators.usPhone('1125550123'), isFalse);
    expect(Validators.usPhone('212555012'), isFalse);
  });

  test('contact info detector', () {
    expect(ContactInfoDetector.containsContactInfo('call me on 98765 43210'), isTrue);
    expect(ContactInfoDetector.containsContactInfo('mail a@b.com'), isTrue);
    expect(ContactInfoDetector.containsContactInfo('price is 25000 for 2 units'), isFalse);
  });
}
