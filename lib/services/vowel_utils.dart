import 'dart:typed_data';
import 'package:flutter/material.dart';

// Maps vowelId (1–18 from DB) to Flask index (0–17) and asset filename.
int vowelIdToIndex(int vowelId) => vowelId - 1;

String vowelIndexToAssetName(int index) {
  if (index < 9) return '0${index + 1}';
  return 's${index - 8}';
}
