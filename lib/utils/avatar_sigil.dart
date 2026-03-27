/// Soul-mapping: deterministic Unicode sigil selection for avatar placeholders.
///
/// Each Latin letter maps to a curated pool of Unicode characters drawn from
/// 8 scripts grouped into 3 aesthetic categories:
///
///   Category 1 — Occult & Geometric:
///     Bamum (U+A6A0–)     West African syllabary
///     Vai   (U+A500–)     West African syllabary
///     Cypriot Syllabary (U+10800–)
///
///   Category 2 — Spiky & Aggressive:
///     Imperial Aramaic (U+10840–)   Semitic abjad
///     Phoenician       (U+10900–)   Semitic abjad
///     Gothic           (U+10330–)   Germanic alphabet
///
///   Category 3 — Void & Ethereal:
///     Linear B   (U+10000–)   Mycenaean Greek syllabary
///     Glagolitic (U+2C00–)    Old Church Slavonic alphabet
///
/// All codepoints are verified against the Unicode character database.
/// Each pool entry is included ONLY when that script has an attested,
/// phonetically correct correspondence for the given Latin key.
/// Sequential-offset guessing is never used; scripts with no true
/// correspondent for a given letter are omitted from that letter's pool.
///
/// Pool selection: first character of the name (uppercased) picks the pool.
/// Index selection: stable FNV-1a 32-bit hash of the FULL name picks the glyph.
/// Same name → same sigil, always.

// ignore_for_file: constant_identifier_names

/// Pool map: Latin uppercase letter → list of verified Unicode scalar values.
///
/// Script order within each pool (where present):
///   Gothic · Phoenician · Imperial Aramaic · Glagolitic ·
///   Linear B · Cypriot · Vai · Bamum
const Map<String, List<int>> _sigilPools = {
  // A — Gothic AHSA · Phoenician ALF · Imp-Aramaic ALEPH ·
  //     Glagolitic AZU · Linear-B A · Cypriot A · Vai A · Bamum A
  'A': [0x10330, 0x10900, 0x10840, 0x2C00, 0x10000, 0x10800, 0xA549, 0xA6A0],

  // B — Gothic BAIRKAN · Phoenician BET · Imp-Aramaic BETH ·
  //     Glagolitic BUKY · Vai BA
  //     (Linear-B/Cypriot have no BA syllable; Bamum has no B letter)
  'B': [0x10331, 0x10901, 0x10841, 0x2C01, 0xA552],

  // C — Glagolitic TSI (≈TS/C) · Glagolitic CHRIVI (≈CH) ·
  //     Vai CEE · Vai CA
  //     (Gothic/Phoenician/Aramaic/LinearB/Cypriot/Bamum have no C letter)
  'C': [0x2C1C, 0x2C1D, 0xA51A, 0xA566],

  // D — Gothic DAGS · Phoenician DELT · Imp-Aramaic DALETH ·
  //     Glagolitic DOBRO · Linear-B DA · Vai DA
  //     (Cypriot merged /d/ into T syllables; Bamum has no D letter)
  'D': [0x10333, 0x10903, 0x10843, 0x2C04, 0x10005, 0xA560],

  // E — Gothic AIHVUS · Phoenician HE (Greek ε source) ·
  //     Imp-Aramaic HE · Glagolitic YESTU · Linear-B E ·
  //     Cypriot E · Vai E · Bamum EE (≈E)
  'E': [0x10334, 0x10904, 0x10844, 0x2C05, 0x10001, 0x10801, 0xA5E1, 0xA6A4],

  // F — Gothic FAIHU · Glagolitic FRITU · Vai FA
  //     (Phoenician/Aramaic/LinearB/Cypriot/Bamum have no F letter)
  'F': [0x10346, 0x2C17, 0xA558],

  // G — Gothic GIBA · Phoenician GAML · Imp-Aramaic GIMEL ·
  //     Glagolitic GLAGOLI · Vai GA
  //     (Linear-B/Cypriot merged /g/ into K; Bamum has no G letter)
  'G': [0x10332, 0x10902, 0x10842, 0x2C03, 0xA56D],

  // H — Gothic HAGL · Phoenician HET · Imp-Aramaic HETH ·
  //     Glagolitic HERU · Vai HA
  //     (Linear-B/Cypriot had no /h/ phoneme; Bamum has no H letter)
  'H': [0x10337, 0x10907, 0x10847, 0x2C18, 0xA54C],

  // I — Gothic EIS · Phoenician YOD (Greek ι source) ·
  //     Imp-Aramaic YODH · Glagolitic I ·
  //     Linear-B I · Cypriot I · Vai I · Bamum I
  'I': [0x10339, 0x10909, 0x10849, 0x2C0B, 0x10002, 0x10802, 0xA524, 0xA6A9],

  // J — Gothic IUJA (palatal /j/) · Glagolitic DJERVI (≈DJ/soft-J) ·
  //     Linear-B JA · Cypriot JA · Vai JA
  //     (Phoenician/Aramaic YOD = I/Y rather than J; Bamum has no J)
  'J': [0x10336, 0x2C0C, 0x1000A, 0x10805, 0xA567],

  // K — Gothic KUSMA · Phoenician KAF · Imp-Aramaic KAPH ·
  //     Glagolitic KAKO · Linear-B KA · Cypriot KA · Vai KA · Bamum KA
  'K': [0x1033A, 0x1090A, 0x1084A, 0x2C0D, 0x1000F, 0x1080A, 0xA56A, 0xA6A1],

  // L — Gothic LAGUS · Phoenician LAMD · Imp-Aramaic LAMEDH ·
  //     Glagolitic LJUDIJE · Cypriot LA · Vai LA · Bamum LA
  //     (Linear-B merged /l/ into R syllables — no distinct LA sign)
  'L': [0x1033B, 0x1090B, 0x1084B, 0x2C0E, 0x1080F, 0xA55E, 0xA6AA],

  // M — Gothic MANNA · Phoenician MEM · Imp-Aramaic MEM ·
  //     Glagolitic MYSLITE · Linear-B MA · Cypriot MA · Vai MA · Bamum M
  'M': [0x1033C, 0x1090C, 0x1084C, 0x2C0F, 0x10014, 0x10814, 0xA56E, 0xA6B3],

  // N — Gothic NAUTHS · Phoenician NUN · Imp-Aramaic NUN ·
  //     Glagolitic NASHI · Linear-B NA · Cypriot NA · Vai NA · Bamum NU
  'N': [0x1033D, 0x1090D, 0x1084D, 0x2C10, 0x10019, 0x10819, 0xA56F, 0xA6BD],

  // O — Gothic OTHAL · Phoenician AIN (Greek ο source) ·
  //     Imp-Aramaic AYIN (same Greek ο source) · Glagolitic ONU ·
  //     Linear-B O · Cypriot O · Vai O · Bamum O
  'O': [0x10349, 0x1090F, 0x1084F, 0x2C11, 0x10003, 0x10803, 0xA5BA, 0xA6A7],

  // P — Gothic PAIRTHRA · Phoenician PE · Imp-Aramaic PE ·
  //     Glagolitic POKOJI · Linear-B PA · Cypriot PA · Vai PA · Bamum PA
  'P': [0x10340, 0x10910, 0x10850, 0x2C12, 0x1001E, 0x1081E, 0xA550, 0xA6AB],

  // Q — Gothic QAIRTHRA · Phoenician QOF · Imp-Aramaic QOPH ·
  //     Linear-B QA
  //     (Glagolitic/Cypriot/Vai/Bamum have no Q letter)
  'Q': [0x10335, 0x10912, 0x10852, 0x10023],

  // R — Gothic RAIDA · Phoenician ROSH · Imp-Aramaic RESH ·
  //     Glagolitic RITSI · Linear-B RA · Cypriot RA · Vai RA · Bamum REE
  'R': [0x10342, 0x10913, 0x10853, 0x2C13, 0x10028, 0x10823, 0xA55F, 0xA6A5],

  // S — Gothic SAUIL · Phoenician SEMK · Imp-Aramaic SAMEKH ·
  //     Glagolitic SLOVO · Linear-B SA · Cypriot SA · Vai SA · Bamum SI
  'S': [0x10343, 0x1090E, 0x1084E, 0x2C14, 0x1002D, 0x10828, 0xA562, 0xA6B7],

  // T — Gothic TEIWS · Phoenician TAU · Imp-Aramaic TAW ·
  //     Glagolitic TVRIDO · Linear-B TA · Cypriot TA · Vai TA · Bamum TAE
  'T': [0x10344, 0x10915, 0x10855, 0x2C15, 0x10032, 0x1082D, 0xA55A, 0xA6A6],

  // U — Gothic URUS · Glagolitic UKU · Linear-B U · Cypriot U ·
  //     Vai U · Bamum U
  //     (Phoenician/Aramaic WAU = W, not U; no Gothic/Phoenician U vowel)
  'U': [0x1033F, 0x2C16, 0x10004, 0x10804, 0xA595, 0xA6A2],

  // V — Glagolitic VEDE · Phoenician WAU (≈V/W) ·
  //     Imp-Aramaic WAW (≈V/W) · Vai VA
  //     (Gothic has no V; LinearB/Cypriot use W; Bamum has no V)
  'V': [0x2C02, 0x10905, 0x10845, 0xA559],

  // W — Gothic WINJA · Phoenician WAU · Imp-Aramaic WAW ·
  //     Linear-B WA · Cypriot WA · Vai WA
  //     (Glagolitic has no W phoneme; Bamum has no W)
  'W': [0x10345, 0x10905, 0x10845, 0x10037, 0x10832, 0xA54E],

  // X — Cypriot XA (dedicated X sign) · Gothic IGGWS (≈Χ/chi) ·
  //     Gothic HWAIR (≈HW/labiovelar) · Glagolitic SHA (≈SH/X fricative)
  //     (Phoenician/Aramaic/LinearB/Vai/Bamum have no X letter)
  'X': [0x10837, 0x10347, 0x10348, 0x2C1E],

  // Y — Gothic IUJA (palatal /j/ = Y in many languages) ·
  //     Phoenician YOD (Greek υ source) · Imp-Aramaic YODH ·
  //     Glagolitic IZHITSA (= Greek Υ) · Vai YA · Bamum YOQ
  'Y': [0x10336, 0x10909, 0x10849, 0x2C2B, 0xA569, 0xA6BF],

  // Z — Phoenician ZAI · Imp-Aramaic ZAYIN ·
  //     Glagolitic ZEMLJA · Linear-B ZA · Cypriot ZA · Vai ZA
  //     (Gothic has no Z letter; Bamum has no Z)
  'Z': [0x10906, 0x10846, 0x2C08, 0x1003C, 0x1083C, 0xA564],

  // Fallback for names starting with non-Latin characters or '@'
  // One representative from each of the 8 scripts (all vowel A/index 0)
  '@': [0x10330, 0x10900, 0x10840, 0x2C00, 0x10000, 0x10800, 0xA549, 0xA6A0],
};

/// Stable FNV-1a 32-bit hash — same algorithm as [string_color.dart].
/// No randomness, no runtime seed. Identical input → identical output.
int _fnv1a(String s) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    hash ^= s.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Returns a deterministic Unicode sigil [String] for [name].
///
/// • The first character of [name] (uppercased) selects the script pool (A–Z,
///   falling back to '@' for non-Latin initials).
/// • The full [name] string is FNV-1a hashed to pick one glyph from that pool.
/// • Same name → same sigil, always. Two users with the same initial but
///   different full names will typically receive different glyphs.
/// • Handles supplementary-plane codepoints (> U+FFFF) correctly via
///   [String.fromCharCodes].
String avatarSigil(String? name) {
  if (name == null || name.isEmpty) {
    return String.fromCharCodes([0x2C00]); // Ⰰ — Glagolitic AZU
  }

  final key = name.substring(0, 1).toUpperCase();
  final pool = _sigilPools[key] ?? _sigilPools['@']!;
  final index = _fnv1a(name).abs() % pool.length;
  return String.fromCharCodes([pool[index]]);
}
