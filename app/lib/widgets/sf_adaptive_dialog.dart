import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';

Future<bool> showSfConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? cancelLabel,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final resolvedCancel = cancelLabel ?? _defaultLabel(context, cancel: true);
  final resolvedConfirm = confirmLabel ?? _defaultLabel(context, cancel: false);
  final platform = Theme.of(context).platform;
  final apple =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  if (apple) {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(resolvedCancel),
              ),
              CupertinoDialogAction(
                isDefaultAction: !destructive,
                isDestructiveAction: destructive,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(resolvedConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  final c = SfTheme.colorsOf(context);
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            destructive ? Icons.delete_outline_rounded : Icons.check_rounded,
            color: destructive ? c.danger : c.primary,
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(resolvedCancel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: c.danger)
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(resolvedConfirm),
            ),
          ],
        ),
      ) ??
      false;
}

Future<T?> showSfActionSheet<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<SfSheetAction<T>> actions,
  String? cancelLabel,
}) {
  final resolvedCancel = cancelLabel ?? _defaultLabel(context, cancel: true);
  final platform = Theme.of(context).platform;
  final apple =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  if (apple) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(title),
        message: message == null ? null : Text(message),
        actions: [
          for (final action in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: action.destructive,
              onPressed: () => Navigator.of(sheetContext).pop(action.value),
              child: Text(action.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(resolvedCancel),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: SfType.ui(size: 18, weight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 5),
              Text(
                message,
                style: SfType.ui(color: SfTheme.colorsOf(context).muted),
              ),
            ],
            const SizedBox(height: 10),
            for (final action in actions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: action.icon == null ? null : Icon(action.icon),
                title: Text(action.label),
                textColor: action.destructive
                    ? SfTheme.colorsOf(context).danger
                    : null,
                iconColor: action.destructive
                    ? SfTheme.colorsOf(context).danger
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(action.value),
              ),
          ],
        ),
      ),
    ),
  );
}

String _defaultLabel(BuildContext context, {required bool cancel}) =>
    switch (Localizations.localeOf(context).languageCode) {
      'ru' => cancel ? 'Отмена' : 'Подтвердить',
      'en' => cancel ? 'Cancel' : 'Confirm',
      _ => cancel ? 'Bekor qilish' : 'Tasdiqlash',
    };

class SfSheetAction<T> {
  const SfSheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool destructive;
}
