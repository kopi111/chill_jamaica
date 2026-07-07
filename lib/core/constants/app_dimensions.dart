/// Spacing, radius and sizing tokens.
///
/// Using a fixed scale keeps layouts rhythmic and makes responsive tweaks a
/// one-line change instead of a hunt through widgets.
abstract final class AppDimensions {
  const AppDimensions._();

  // Spacing scale (4pt grid).
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // Corner radii.
  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 22;
  static const double radiusPill = 999;

  // Component sizing.
  static const double buttonHeight = 52;
  static const double cartBarHeight = 72;
  static const double productCardMinHeight = 260;
  static const double heroHeight = 200;

  // Responsive breakpoint: tablets show more product columns.
  static const double tabletBreakpoint = 600;

  /// GPS accuracy (metres) above which we warn the customer.
  static const double lowAccuracyThresholdMeters = 20;
}
