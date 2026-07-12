import 'package:frontend/services/practice_api.dart';

String buildPronunciationSuggestion({
  required VowelFormant? ref,
  required double userF1,
  required double userF2,
  required bool isEnglish,
}) {
  if (ref == null || (userF1 == 0 && userF2 == 0)) return '';

  final List<String> partsEn = [];
  final List<String> partsTh = [];

  if (ref.hasRange) {
   
    if (userF1 < ref.f1Min!) {
      partsEn.add('closing your mouth slightly');
      partsTh.add('อ้าปากลดลงอีกนิดนะ');
    } else if (userF1 > ref.f1Max!) {
      partsEn.add('opening your mouth wider');
      partsTh.add('อ้าปากให้กว้างขึ้นอีกนิดนะ ');
    }

    if (userF2 > ref.f2Max!) {
      partsEn.add('moving your tongue slightly back');
      partsTh.add('ขยับลิ้นถอยไปด้านหลังอีกนิดนะ');
    } else if (userF2 < ref.f2Min!) {
      partsEn.add('moving your tongue slightly forward');
      partsTh.add('ขยับลิ้นมาด้านหน้าอีกนิดนะ');
    }
  } else {
    final f1Diff = userF1 - ref.f1;
    final f2Diff = userF2 - ref.f2;
    const f1Threshold = 200.0;
    const f2Threshold = 200.0;

    if (f1Diff > f1Threshold) {
      partsEn.add('closing your mouth slightly');
      partsTh.add('หุบปากลงอีกนิดนะ');
    } else if (f1Diff < -f1Threshold) {
      partsEn.add('opening your mouth wider ');
      partsTh.add('อ้าปากให้กว้างขึ้นอีกนิดนะ ');
    }

    if (f2Diff > f2Threshold) {
      partsEn.add('moving your tongue slightly back ');
      partsTh.add('ขยับลิ้นถอยไปด้านหลังอีกนิดนะ ');
    } else if (f2Diff < -f2Threshold) {
      partsEn.add('moving your tongue slightly forward ');
      partsTh.add('ขยับลิ้นมาด้านหน้าอีกนิดนะ ');
    }
  }

  if (partsEn.isEmpty) return '';
  return isEnglish
      ? 'Try ${partsEn.join(', ')}.'
      : 'ลอง${partsTh.join(' ')}';
}
