import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

/// Small, readability-focused extensions used across the UI.

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);

  /// True on tablet-width layouts, where grids show more columns.
  bool get isTablet => screenSize.width >= AppDimensions.tabletBreakpoint;

  /// Shows a themed snackbar with friendly copy.
  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? colors.error : null,
        ),
      );
  }
}

extension IterableSumX<E> on Iterable<E> {
  /// Sums a numeric projection of each element — clearer than a manual fold.
  int sumBy(int Function(E element) selector) =>
      fold(0, (int running, E element) => running + selector(element));

  double sumByDouble(double Function(E element) selector) =>
      fold(0, (double running, E element) => running + selector(element));
}
