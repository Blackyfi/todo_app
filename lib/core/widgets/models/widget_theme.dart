import 'package:flutter/material.dart' as mat;

/// Widget theme configuration for customized appearance
class WidgetTheme {
  final String name;
  final WidgetColorScheme colorScheme;
  final WidgetTextStyle textStyle;
  final double cornerRadius;
  final bool showShadow;

  const WidgetTheme({
    required this.name,
    required this.colorScheme,
    this.textStyle = WidgetTextStyle.normal,
    this.cornerRadius = 16.0,
    this.showShadow = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'colorScheme': colorScheme.index,
      'textStyle': textStyle.index,
      'cornerRadius': cornerRadius,
      'showShadow': showShadow ? 1 : 0,
    };
  }

  factory WidgetTheme.fromMap(Map<String, dynamic> map) {
    return WidgetTheme(
      name: map['name'] ?? 'Default',
      colorScheme: WidgetColorScheme.values[map['colorScheme'] ?? 0],
      textStyle: WidgetTextStyle.values[map['textStyle'] ?? 0],
      cornerRadius: map['cornerRadius'] ?? 16.0,
      showShadow: map['showShadow'] == 1,
    );
  }

  WidgetTheme copyWith({
    String? name,
    WidgetColorScheme? colorScheme,
    WidgetTextStyle? textStyle,
    double? cornerRadius,
    bool? showShadow,
  }) {
    return WidgetTheme(
      name: name ?? this.name,
      colorScheme: colorScheme ?? this.colorScheme,
      textStyle: textStyle ?? this.textStyle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showShadow: showShadow ?? this.showShadow,
    );
  }

  /// Default light theme
  static const WidgetTheme light = WidgetTheme(
    name: 'Light',
    colorScheme: WidgetColorScheme.light,
  );

  /// Default dark theme
  static const WidgetTheme dark = WidgetTheme(
    name: 'Dark',
    colorScheme: WidgetColorScheme.dark,
  );

  /// Material You themed
  static const WidgetTheme materialYou = WidgetTheme(
    name: 'Material You',
    colorScheme: WidgetColorScheme.materialYou,
    cornerRadius: 24.0,
  );

  /// Minimal theme
  static const WidgetTheme minimal = WidgetTheme(
    name: 'Minimal',
    colorScheme: WidgetColorScheme.minimal,
    textStyle: WidgetTextStyle.small,
    cornerRadius: 8.0,
    showShadow: false,
  );
}

enum WidgetColorScheme {
  light,
  dark,
  materialYou,
  minimal,
  ocean,
  sunset,
  forest,
  custom,
}

extension WidgetColorSchemeExtension on WidgetColorScheme {
  String get label {
    switch (this) {
      case WidgetColorScheme.light:
        return 'Light';
      case WidgetColorScheme.dark:
        return 'Dark';
      case WidgetColorScheme.materialYou:
        return 'Material You';
      case WidgetColorScheme.minimal:
        return 'Minimal';
      case WidgetColorScheme.ocean:
        return 'Ocean Blue';
      case WidgetColorScheme.sunset:
        return 'Sunset Orange';
      case WidgetColorScheme.forest:
        return 'Forest Green';
      case WidgetColorScheme.custom:
        return 'Custom';
    }
  }

  /// Background color for the widget
  mat.Color get backgroundColor {
    switch (this) {
      case WidgetColorScheme.light:
        return const mat.Color(0xFFFFFFFF);
      case WidgetColorScheme.dark:
        return const mat.Color(0xFF1E1E1E);
      case WidgetColorScheme.materialYou:
        return const mat.Color(0xFFF5F5F5);
      case WidgetColorScheme.minimal:
        return const mat.Color(0xFFFAFAFA);
      case WidgetColorScheme.ocean:
        return const mat.Color(0xFF1565C0);
      case WidgetColorScheme.sunset:
        return const mat.Color(0xFFE65100);
      case WidgetColorScheme.forest:
        return const mat.Color(0xFF2E7D32);
      case WidgetColorScheme.custom:
        return const mat.Color(0xFFFFFFFF);
    }
  }

  /// Text color for the widget
  mat.Color get textColor {
    switch (this) {
      case WidgetColorScheme.light:
      case WidgetColorScheme.minimal:
      case WidgetColorScheme.materialYou:
        return const mat.Color(0xFF000000);
      case WidgetColorScheme.dark:
      case WidgetColorScheme.ocean:
      case WidgetColorScheme.sunset:
      case WidgetColorScheme.forest:
        return const mat.Color(0xFFFFFFFF);
      case WidgetColorScheme.custom:
        return const mat.Color(0xFF000000);
    }
  }

  /// Secondary text color (for descriptions, dates, etc.)
  mat.Color get secondaryTextColor {
    return textColor.withAlpha(179); // 70% opacity
  }
}

enum WidgetTextStyle {
  small,
  normal,
  large,
  extraLarge,
}

extension WidgetTextStyleExtension on WidgetTextStyle {
  String get label {
    switch (this) {
      case WidgetTextStyle.small:
        return 'Small';
      case WidgetTextStyle.normal:
        return 'Normal';
      case WidgetTextStyle.large:
        return 'Large';
      case WidgetTextStyle.extraLarge:
        return 'Extra Large';
    }
  }

  /// Title font size
  double get titleFontSize {
    switch (this) {
      case WidgetTextStyle.small:
        return 12.0;
      case WidgetTextStyle.normal:
        return 14.0;
      case WidgetTextStyle.large:
        return 16.0;
      case WidgetTextStyle.extraLarge:
        return 18.0;
    }
  }

  /// Body font size
  double get bodyFontSize {
    switch (this) {
      case WidgetTextStyle.small:
        return 10.0;
      case WidgetTextStyle.normal:
        return 12.0;
      case WidgetTextStyle.large:
        return 14.0;
      case WidgetTextStyle.extraLarge:
        return 16.0;
    }
  }
}
