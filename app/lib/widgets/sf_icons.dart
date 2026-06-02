import 'package:flutter/material.dart';

/// Semantic icon set for the StarForge teacher app. We use Material's
/// line/outlined icons as Flutter primitives — the StarForge identity is
/// carried by [SfStar], not the iconography.
///
/// Names mirror the JSX `Icons` map for 1:1 porting.
class SfIcons {
  // Navigation / tab bar
  static const home = Icons.cottage_outlined;
  static const cal = Icons.calendar_today_outlined;
  static const cohort = Icons.groups_outlined;
  static const book = Icons.menu_book_outlined;
  static const chat = Icons.chat_bubble_outline;
  static const bell = Icons.notifications_none_outlined;
  static const user = Icons.person_outline;

  // Actions
  static const check = Icons.check;
  static const x = Icons.close;
  static const clock = Icons.access_time_rounded;
  static const search = Icons.search;
  static const plus = Icons.add;
  static const arrowR = Icons.arrow_forward;
  static const arrowL = Icons.arrow_back;
  static const chevR = Icons.chevron_right;
  static const chevD = Icons.expand_more;
  static const more = Icons.more_horiz;
  static const filter = Icons.tune_outlined;

  // Pin / edit / star (AI uses SfStar in code, not this)
  static const pin = Icons.push_pin_outlined;
  static const edit = Icons.edit_outlined;

  // File types
  static const attach = Icons.attach_file_outlined;
  static const send = Icons.send_outlined;
  static const doc = Icons.description_outlined;
  static const pdf = Icons.picture_as_pdf_outlined;
  static const video = Icons.play_circle_outline;
  static const folder = Icons.folder_outlined;
  static const upload = Icons.upload_outlined;
  static const printer = Icons.print_outlined;
  static const download = Icons.download_outlined;

  // Misc
  static const trend = Icons.trending_up;
  static const globe = Icons.language;
  static const settings = Icons.settings_outlined;
  static const logout = Icons.logout;
  static const brand = Icons.local_offer_outlined; // tag
  static const shield = Icons.shield_outlined;
  static const flag = Icons.flag_outlined;
  static const ai = Icons.auto_awesome_outlined;
}

/// Thin Icon wrapper that defaults to the inherited text color so icons
/// inherit "currentColor" semantics like the CSS originals.
class SfIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const SfIcon(this.icon, {super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color;
    return Icon(icon, size: size, color: c);
  }
}
