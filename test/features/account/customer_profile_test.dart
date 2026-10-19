import 'package:chill_jamaica/features/account/domain/entities/customer_profile.dart';
import 'package:chill_jamaica/features/account/domain/entities/saved_address.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerProfile _profile({
  String fullName = 'Lex Robinson',
  String? homeAddress,
  String? workAddress,
  String? photoUrl,
}) =>
    CustomerProfile(
      uid: 'uid-1',
      fullName: fullName,
      email: 'lex@example.com',
      phone: '+18761234567',
      photoUrl: photoUrl,
      homeAddress: homeAddress,
      workAddress: workAddress,
    );

void main() {
  group('saved addresses', () {
    test('lists only the addresses detailed enough to deliver to', () {
      final CustomerProfile profile = _profile(
        homeAddress: '12 Hope Road, Kingston 6, St. Andrew',
        workAddress: 'work',
      );

      final List<SavedAddress> addresses = profile.deliverableAddresses;
      expect(addresses, hasLength(1));
      expect(addresses.single.label, AddressLabel.home);
    });

    test('is empty when neither address is set', () {
      expect(_profile().deliverableAddresses, isEmpty);
    });

    test('keeps home before work', () {
      final CustomerProfile profile = _profile(
        homeAddress: '12 Hope Road, Kingston 6, St. Andrew',
        workAddress: '5 Trafalgar Road, Kingston 10, St. Andrew',
      );

      expect(
        profile.deliverableAddresses.map((SavedAddress a) => a.label),
        <AddressLabel>[AddressLabel.home, AddressLabel.work],
      );
    });
  });

  group('display helpers', () {
    test('builds initials from the first and last name', () {
      expect(_profile().initials, 'LR');
      expect(_profile(fullName: 'Lex Anthony Robinson').initials, 'LR');
    });

    test('falls back gracefully on a one-word or empty name', () {
      expect(_profile(fullName: 'Lex').initials, 'L');
      expect(_profile(fullName: '   ').initials, '🥥');
    });

    test('greets by first name', () {
      expect(_profile().firstName, 'Lex');
      expect(_profile(fullName: '  ').firstName, 'friend');
    });

    test('knows whether a photo has been uploaded', () {
      expect(_profile().hasPhoto, isFalse);
      expect(_profile(photoUrl: '').hasPhoto, isFalse);
      expect(_profile(photoUrl: 'https://example.com/p.jpg').hasPhoto, isTrue);
    });
  });

  group('copyWith', () {
    test('changes only what it is given', () {
      final CustomerProfile edited = _profile(homeAddress: 'old address here')
          .copyWith(fullName: 'Lex A. Robinson');

      expect(edited.fullName, 'Lex A. Robinson');
      expect(edited.homeAddress, 'old address here');
      expect(edited.email, 'lex@example.com');
      expect(edited.uid, 'uid-1');
    });
  });
}
