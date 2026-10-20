import 'package:flutter/material.dart';

/// Immutable colors resolved from this widget tree, never a global selection.
@immutable
class ChoreiaPalette extends ThemeExtension<ChoreiaPalette> {
  const ChoreiaPalette({required this.stage,required this.raisedSurface,required this.heading,required this.ink,required this.rose,required this.roseBright,required this.roseDeep,required this.amber,required this.amberDeep,required this.glowWarm,required this.outline,required this.focusRing,required this.error,required this.errorContainer,required this.onErrorContainer,required this.disabledSurface,required this.disabledForeground,required this.pillFill,required this.textAlphaFloor,required this.glowRoseAlpha,required this.glowWarmAlpha,required this.panelTintAlpha,required this.panelWhiteAlpha,required this.shadowAlpha,required this.pillFillAlpha});
  final Color stage;
  final Color raisedSurface;
  final Color heading;
  final Color ink;
  final Color rose;
  final Color roseBright;
  final Color roseDeep;
  final Color amber;
  final Color amberDeep;
  final Color glowWarm;
  final Color outline;
  final Color focusRing;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color disabledSurface;
  final Color disabledForeground;
  final Color pillFill;
  final double textAlphaFloor;
  final double glowRoseAlpha;
  final double glowWarmAlpha;
  final double panelTintAlpha;
  final double panelWhiteAlpha;
  final double shadowAlpha;
  final double pillFillAlpha;
  static const dark = ChoreiaPalette(
    stage: Color(0xFF0A0508),
    raisedSurface: Color(0xFF2A1220),
    heading: Color(0xFFFBF2F5),
    ink: Color(0xFFF6EEF1),
    rose: Color(0xFFF0A6BD),
    roseBright: Color(0xFFF6B9CB),
    roseDeep: Color(0xFFE8A2B6),
    amber: Color(0xFFECC49B),
    amberDeep: Color(0xFFE6C49A),
    glowWarm: Color(0xFFFFBA8A),
    outline: Color(0xFFA18B96),
    focusRing: Color(0xFFF6B9CB),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    disabledSurface: Color(0xFF32272E),
    disabledForeground: Color(0xFFB7A7B0),
    pillFill: Color(0xFF000000),
    textAlphaFloor: 0.55,
    glowRoseAlpha: 0.08,
    glowWarmAlpha: 0.08,
    panelTintAlpha: 0.06,
    panelWhiteAlpha: 0.02,
    shadowAlpha: 0.4,
    pillFillAlpha: 0.25,
  );
  static const light = ChoreiaPalette(
    stage: Color(0xFFFFF8FA),
    raisedSurface: Color(0xFFF2E4EB),
    heading: Color(0xFF22151D),
    ink: Color(0xFF30212A),
    rose: Color(0xFF8E3757),
    roseBright: Color(0xFF8B3154),
    roseDeep: Color(0xFF893752),
    amber: Color(0xFF775028),
    amberDeep: Color(0xFF73502D),
    glowWarm: Color(0xFF775028),
    outline: Color(0xFF85717C),
    focusRing: Color(0xFF6F2D4A),
    error: Color(0xFFAA2832),
    errorContainer: Color(0xFFFFE4E4),
    onErrorContainer: Color(0xFF610C17),
    disabledSurface: Color(0xFFEFE5EA),
    disabledForeground: Color(0xFF786B74),
    pillFill: Color(0xFFFFFFFF),
    textAlphaFloor: 0.72,
    glowRoseAlpha: 0.07,
    glowWarmAlpha: 0.05,
    panelTintAlpha: 0.045,
    panelWhiteAlpha: 0.02,
    shadowAlpha: 0.08,
    pillFillAlpha: 0.55,
  );
  static ChoreiaPalette of(BuildContext context) => Theme.of(context).extension<ChoreiaPalette>() ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);
  Color get bright => heading;
  Color get oxblood => raisedSurface;
  static const onVideoCaption = Color(0xFFFBF2F5);
  Color text(double opacity) => ink.withValues(alpha: opacity.clamp(textAlphaFloor, 1.0).toDouble());
  Color hairline(double opacity) => ink.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble());
  @override
  ChoreiaPalette copyWith({Color? stage,Color? raisedSurface,Color? heading,Color? ink,Color? rose,Color? roseBright,Color? roseDeep,Color? amber,Color? amberDeep,Color? glowWarm,Color? outline,Color? focusRing,Color? error,Color? errorContainer,Color? onErrorContainer,Color? disabledSurface,Color? disabledForeground,Color? pillFill,double? textAlphaFloor,double? glowRoseAlpha,double? glowWarmAlpha,double? panelTintAlpha,double? panelWhiteAlpha,double? shadowAlpha,double? pillFillAlpha}) => ChoreiaPalette(stage: stage ?? this.stage,raisedSurface: raisedSurface ?? this.raisedSurface,heading: heading ?? this.heading,ink: ink ?? this.ink,rose: rose ?? this.rose,roseBright: roseBright ?? this.roseBright,roseDeep: roseDeep ?? this.roseDeep,amber: amber ?? this.amber,amberDeep: amberDeep ?? this.amberDeep,glowWarm: glowWarm ?? this.glowWarm,outline: outline ?? this.outline,focusRing: focusRing ?? this.focusRing,error: error ?? this.error,errorContainer: errorContainer ?? this.errorContainer,onErrorContainer: onErrorContainer ?? this.onErrorContainer,disabledSurface: disabledSurface ?? this.disabledSurface,disabledForeground: disabledForeground ?? this.disabledForeground,pillFill: pillFill ?? this.pillFill,textAlphaFloor: textAlphaFloor ?? this.textAlphaFloor,glowRoseAlpha: glowRoseAlpha ?? this.glowRoseAlpha,glowWarmAlpha: glowWarmAlpha ?? this.glowWarmAlpha,panelTintAlpha: panelTintAlpha ?? this.panelTintAlpha,panelWhiteAlpha: panelWhiteAlpha ?? this.panelWhiteAlpha,shadowAlpha: shadowAlpha ?? this.shadowAlpha,pillFillAlpha: pillFillAlpha ?? this.pillFillAlpha);
  @override
  ChoreiaPalette lerp(covariant ChoreiaPalette? other, double t) { if (other == null) return this; return ChoreiaPalette(stage: Color.lerp(stage, other.stage, t)!,raisedSurface: Color.lerp(raisedSurface, other.raisedSurface, t)!,heading: Color.lerp(heading, other.heading, t)!,ink: Color.lerp(ink, other.ink, t)!,rose: Color.lerp(rose, other.rose, t)!,roseBright: Color.lerp(roseBright, other.roseBright, t)!,roseDeep: Color.lerp(roseDeep, other.roseDeep, t)!,amber: Color.lerp(amber, other.amber, t)!,amberDeep: Color.lerp(amberDeep, other.amberDeep, t)!,glowWarm: Color.lerp(glowWarm, other.glowWarm, t)!,outline: Color.lerp(outline, other.outline, t)!,focusRing: Color.lerp(focusRing, other.focusRing, t)!,error: Color.lerp(error, other.error, t)!,errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,disabledSurface: Color.lerp(disabledSurface, other.disabledSurface, t)!,disabledForeground: Color.lerp(disabledForeground, other.disabledForeground, t)!,pillFill: Color.lerp(pillFill, other.pillFill, t)!,textAlphaFloor: textAlphaFloor + (other.textAlphaFloor - textAlphaFloor) * t,glowRoseAlpha: glowRoseAlpha + (other.glowRoseAlpha - glowRoseAlpha) * t,glowWarmAlpha: glowWarmAlpha + (other.glowWarmAlpha - glowWarmAlpha) * t,panelTintAlpha: panelTintAlpha + (other.panelTintAlpha - panelTintAlpha) * t,panelWhiteAlpha: panelWhiteAlpha + (other.panelWhiteAlpha - panelWhiteAlpha) * t,shadowAlpha: shadowAlpha + (other.shadowAlpha - shadowAlpha) * t,pillFillAlpha: pillFillAlpha + (other.pillFillAlpha - pillFillAlpha) * t); }
}
