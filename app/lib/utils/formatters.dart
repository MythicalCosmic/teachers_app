/// Small, allocation-conscious formatters for the Uzbek-first mobile client.
///
/// Keeping these here avoids pulling a heavyweight date/number formatter into
/// every scrolling list. A future localization package can replace this file
/// without changing the domain layer.
abstract final class SfFormatters {
  static const _monthsUz = <String>[
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  static const _weekdaysUz = <String>[
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
  ];

  static String compactDateUz(DateTime value) {
    final local = value.toLocal();
    return '${local.day} ${_monthsUz[local.month - 1]}';
  }

  static String fullDateUz(DateTime value) {
    final local = value.toLocal();
    return '${_weekdaysUz[local.weekday - 1]} · '
        '${local.day} ${_monthsUz[local.month - 1]}';
  }

  static String time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String moneyUzs(num value) {
    final raw = value.round().abs().toString();
    final grouped = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      if (index > 0 && (raw.length - index) % 3 == 0) grouped.write(' ');
      grouped.write(raw[index]);
    }
    return '${value.isNegative ? '−' : ''}$grouped so‘m';
  }

  static String relativeUz(DateTime value, {DateTime? now}) {
    final delta = (now ?? DateTime.now()).difference(value.toLocal());
    if (delta.isNegative) {
      final future = -delta;
      if (future.inMinutes < 60) {
        return '${future.inMinutes.clamp(1, 59)} daqiqadan keyin';
      }
      if (future.inHours < 24) return '${future.inHours} soatdan keyin';
      return '${future.inDays} kundan keyin';
    }
    if (delta.inMinutes < 1) return 'hozir';
    if (delta.inMinutes < 60) return '${delta.inMinutes} daqiqa oldin';
    if (delta.inHours < 24) return '${delta.inHours} soat oldin';
    if (delta.inDays < 7) return '${delta.inDays} kun oldin';
    return compactDateUz(value);
  }
}
