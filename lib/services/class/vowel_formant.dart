class VowelFormant {
  final double f1;
  final double f2;
  final double? f1Min;
  final double? f1Max;
  final double? f2Min;
  final double? f2Max;

  const VowelFormant({
    required this.f1,
    required this.f2,
    this.f1Min,
    this.f1Max,
    this.f2Min,
    this.f2Max,
  });

  bool get hasRange => f1Min != null && f1Max != null && f2Min != null && f2Max != null;

  factory VowelFormant.fromJson(Map<String, dynamic> j) => VowelFormant(
        f1: (j['f1'] as num?)?.toDouble() ?? 0.0,
        f2: (j['f2'] as num?)?.toDouble() ?? 0.0,
        f1Min: (j['f1_min'] as num?)?.toDouble(),
        f1Max: (j['f1_max'] as num?)?.toDouble(),
        f2Min: (j['f2_min'] as num?)?.toDouble(),
        f2Max: (j['f2_max'] as num?)?.toDouble(),
      );
}
