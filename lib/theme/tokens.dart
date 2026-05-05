import 'package:flutter/material.dart';

class FlipoutColors {
  const FlipoutColors._();

  static const bg = Color(0xfff8fafc);
  static const surface1 = Color(0xffffffff);
  static const surface2 = Color(0xfff1f5f9);
  static const surface3 = Color(0xffe2e8f0);
  static const border = Color(0xffe2e8f0);
  static const borderStrong = Color(0xffcbd5e1);

  static const accent = Color(0xff0d9488);
  static const accentHover = Color(0xff0f766e);
  static const accentSoft = Color(0xffccfbf1);
  static const accentTint = Color(0xfff0fdfa);
  static const accentInk = Color(0xff134e4a);

  static const winner = Color(0xffb45309);
  static const winnerSoft = Color(0xfffef3c7);
  static const winnerInk = Color(0xff78350f);

  static const squeeze = Color(0xff7c3aed);
  static const squeezeSoft = Color(0xffede9fe);
  static const squeezeInk = Color(0xff4c1d95);

  static const text = Color(0xff0f172a);
  static const textMuted = Color(0xff475569);
  static const textDim = Color(0xff94a3b8);

  static const cardBg = Color(0xffffffff);
  static const cardBorder = Color(0xffe2e8f0);
  static const cardBackA = Color(0xff0d9488);
  static const cardBackB = Color(0xff14b8a6);

  static const suitRed = Color(0xffdc2626);
  static const suitBlack = Color(0xff0f172a);
  static const suitBlue = Color(0xff2563eb);
  static const suitGreen = Color(0xff16a34a);
}

class FlipoutRadius {
  const FlipoutRadius._();

  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const pill = 999.0;
}

class FlipoutSpace {
  const FlipoutSpace._();

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s7 = 32.0;
}

class FlipoutType {
  const FlipoutType._();

  static const xs = 11.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const x2l = 28.0;

  static const body = FontWeight.w500;
  static const bold = FontWeight.w700;
  static const cta = FontWeight.w900;
}

class FlipoutShadows {
  const FlipoutShadows._();

  static const shadow1 = [
    BoxShadow(color: Color(0x0f0f172a), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const shadow2 = [
    BoxShadow(color: Color(0x1a0f172a), offset: Offset(0, 12), blurRadius: 32),
  ];
}
