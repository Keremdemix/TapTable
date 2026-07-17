import 'dart:ui';

import 'package:flutter/material.dart';

Color safeColorFromHex(String? hexString, Color fallbackColor) {
  if (hexString == null || hexString.isEmpty) {
    return fallbackColor;
  }

  try {
    String cleanHex = hexString.replaceAll('#', '').trim();

    // Eğer sadece 6 haneliyse (örn: FF5733), opacity (opaklık) için başına 'FF' ekliyoruz
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }

    // Karakter uzunluğu 8 değilse veya geçersiz karakter varsa hata fırlatır
    if (cleanHex.length != 8) {
      return fallbackColor;
    }

    return Color(int.parse(cleanHex, radix: 16));
  } catch (e) {
    // DB'den beklenmedik hatalı bir format gelirse uygulama çökmez, yedek rengi gösterir
    debugPrint("Renk dönüştürme hatası ($hexString): $e");
    return fallbackColor;
  }
}
