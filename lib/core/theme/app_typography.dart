import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text scale. Headings use Outfit, body copy uses Inter.
class AppTypography {
  static TextStyle display(Color c) => GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: c);
  static TextStyle h1(Color c) => GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: c);
  static TextStyle h2(Color c) => GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: c);
  static TextStyle h3(Color c) => GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: c);
  static TextStyle bodyLarge(Color c) => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: c);
  static TextStyle body(Color c) => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: c);
  static TextStyle caption(Color c) => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: c);
  static TextStyle label(Color c) => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: c);
}
