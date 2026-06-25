class VowelFormant {
  final double f1;
  final double f2;

  const VowelFormant({required this.f1, required this.f2});

  factory VowelFormant.fromJson(Map<String, dynamic> j) => VowelFormant(
        f1: (j['f1'] as num).toDouble(),
        f2: (j['f2'] as num).toDouble(),
      );
}
