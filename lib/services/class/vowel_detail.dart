class VowelDetail {
  final int id;
  final String symbol;
  final String vowelType;
  final String? unicodePhonetic;
  final String? descriptionEn;
  final String? descriptionTh;
  final String? lipsEn;
  final String? lipsTh;
  final String? tongueEn;
  final String? tongueTh;
  final String? tongueLevelEn;
  final String? tongueLevelTh;
  final String? linkVideo;

  const VowelDetail({
    required this.id,
    required this.symbol,
    required this.vowelType,
    this.unicodePhonetic,
    this.descriptionEn,
    this.descriptionTh,
    this.lipsEn,
    this.lipsTh,
    this.tongueEn,
    this.tongueTh,
    this.tongueLevelEn,
    this.tongueLevelTh,
    this.linkVideo,
  });

  factory VowelDetail.fromJson(Map<String, dynamic> j) => VowelDetail(
        id: j['id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        unicodePhonetic: j['unicode_phonetic'] as String?,
        descriptionEn: j['description_en'] as String?,
        descriptionTh: j['description_th'] as String?,
        lipsEn: j['lips_en'] as String?,
        lipsTh: j['lips_th'] as String?,
        tongueEn: j['tongue_en'] as String?,
        tongueTh: j['tongue_th'] as String?,
        tongueLevelEn: j['tongue_level_en'] as String?,
        tongueLevelTh: j['tongue_level_th'] as String?,
        linkVideo: j['link_video'] as String?,
      );
}
