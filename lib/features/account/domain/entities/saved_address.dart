import 'package:flutter/material.dart';

/// Which of a customer's two saved addresses this is.
///
/// [wireValue] is the exact Firestore field name — renaming one needs a data
/// migration.
enum AddressLabel {
  home(wireValue: 'homeAddress', label: 'Home', icon: Icons.home_outlined),
  work(wireValue: 'workAddress', label: 'Work', icon: Icons.work_outline);

  const AddressLabel({
    required this.wireValue,
    required this.label,
    required this.icon,
  });

  final String wireValue;
  final String label;
  final IconData icon;
}

/// An address the customer stored on their profile so checkout can reuse it.
@immutable
class SavedAddress {
  const SavedAddress({required this.label, required this.line});

  final AddressLabel label;

  /// The full address as the customer typed it.
  final String line;

  bool get isUsable => line.trim().length >= _minimumUsableLength;

  static const int _minimumUsableLength = 10;

  @override
  bool operator ==(Object other) =>
      other is SavedAddress && other.label == label && other.line == line;

  @override
  int get hashCode => Object.hash(label, line);
}
