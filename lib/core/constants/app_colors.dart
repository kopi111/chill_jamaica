import 'package:flutter/material.dart';

/// Central palette for the Chill Jamaica brand.
///
/// Tropical, coconut-and-reggae inspired. Every colour used in the app should
/// come from here so the theme stays consistent and easy to re-skin.
abstract final class AppColors {
  const AppColors._();

  /// Coconut palm green — primary brand colour.
  static const Color primaryGreen = Color(0xFF2D8A4E);

  /// Ripe coconut gold — secondary / call-to-action accent.
  static const Color secondaryGold = Color(0xFFF5A623);

  /// Coconut shell brown — supporting accent.
  static const Color accentBrown = Color(0xFF8B5E3C);

  /// Warm cream — default screen background.
  static const Color backgroundCream = Color(0xFFFFF8EC);

  static const Color white = Color(0xFFFFFFFF);

  /// Near-black used for primary text and dark surfaces.
  static const Color dark = Color(0xFF1A1A2E);

  /// Urgent red — reserved for the admin app (new-order emphasis, destructive).
  static const Color urgentRed = Color(0xFFE74C3C);

  // --- Order status colours (shared by customer + admin) ---
  static const Color statusNew = Color(0xFF2F80ED);
  static const Color statusProcessing = Color(0xFFF2994A);
  static const Color statusOutForDelivery = Color(0xFF9B51E0);
  static const Color statusDelivered = Color(0xFF27AE60);

  // --- Neutrals ---
  static const Color textPrimary = dark;
  static const Color textSecondary = Color(0xFF6B6B7B);
  static const Color divider = Color(0xFFE8E1D4);
  static const Color surface = white;

  /// Gold → green sweep used on hero banners and primary buttons.
  static const LinearGradient tropicalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryGreen, Color(0xFF3FB56A)],
  );

  /// Reggae stripe accent (gold → green → gold) for thin divider lines.
  static const LinearGradient reggaeStripe = LinearGradient(
    colors: <Color>[secondaryGold, primaryGreen, secondaryGold],
  );

  /// Placeholder gradient for product art until real assets are dropped in.
  static const LinearGradient coconutPlaceholder = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFEFE6D0), Color(0xFFDCCBA6)],
  );
}
