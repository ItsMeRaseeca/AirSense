import 'package:flutter/material.dart';

/// AirSense premium warm colour palette.
///
///  Bistro     #210100   – primary dark / hero backgrounds
///  Goldfinch  #E6A341   – primary accent, highlights, normal state
///  Butter     #FECE79   – light accent, warm card backgrounds
///  Indian Red #B14A36   – secondary warning
///  Garnet     #8C0902   – danger / POOR status
///  Off-White  #FAF7F2   – main background
class AppColors {
  AppColors._();

  static const Color bistro     = Color(0xFF210100);
  static const Color goldfinch  = Color(0xFFE6A341);
  static const Color butter     = Color(0xFFFECE79);
  static const Color indianRed  = Color(0xFFB14A36);
  static const Color garnet     = Color(0xFF8C0902);

  static const Color background = Color(0xFFFAF7F2);
  static const Color cardWhite  = Color(0xFFFFFFFF);
  static const Color cardWarm   = Color(0xFFFFFDF8);

  static const Color textPrimary   = Color(0xFF210100);
  static const Color textSecondary = Color(0xFF7A5C54);
  static const Color textMuted     = Color(0xFFBBA9A4);

  static const Color divider = Color(0xFFEDE0DA);

  // Semantic helpers
  static const Color normalAccent = goldfinch;
  static const Color poorAccent   = garnet;
  static const Color warnAccent   = indianRed;

  // Status dot colours
  static const Color dotConnected = Color(0xFF4CAF50);
  static const Color dotStale     = Color(0xFFFFA726);
  static const Color dotError     = garnet;
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.goldfinch,
        brightness: Brightness.light,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display', // falls back to system on Android
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.bistro),
        titleTextStyle: TextStyle(
          color: AppColors.bistro,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.bistro,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  // ── Text Styles ──────────────────────────────────────────────────────────────

  static const TextStyle heroTitle = TextStyle(
    color: AppColors.cardWarm,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  static const TextStyle heroStatus = TextStyle(
    color: Colors.white,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle heroValue = TextStyle(
    color: Colors.white,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
    height: 1,
  );

  static const TextStyle heroLabel = TextStyle(
    color: Color(0xFFD4B8B0),
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle cardLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
  );

  static const TextStyle cardValue = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.1,
  );

  static const TextStyle cardUnit = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Decoration helpers ───────────────────────────────────────────────────────

  static BoxDecoration cardDecoration({
    Color? color,
    double radius = 24,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardWhite,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? [cardShadow],
    );
  }

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0A210100),
    blurRadius: 20,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  static BoxDecoration heroCardDecoration({bool poor = false}) {
    return BoxDecoration(
      color: AppColors.cardWarm,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: poor
            ? AppColors.indianRed.withValues(alpha: 0.25)
            : AppColors.goldfinch.withValues(alpha: 0.25),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0E210100),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

