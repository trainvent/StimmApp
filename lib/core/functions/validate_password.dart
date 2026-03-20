import 'package:flutter/material.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/generated/l10n.dart';

String? validatePassword(BuildContext context, String? value) {
  if (value == null || value.isEmpty) {
    return context.l10n.enterSomething;
  }

  final List<String> errors = [];

  if (value.length < 8) {
    errors.add(S.of(context).passwordMustBeAtLeast8CharactersLong);
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    errors.add(S.of(context).passwordValidation('uppercase'));
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    errors.add(S.of(context).passwordValidation('lowercase'));
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    errors.add(S.of(context).passwordValidation('number'));
  }
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    errors.add(S.of(context).passwordValidation('special'));
  }

  if (errors.isEmpty) {
    Navigator.of(context).maybePop;
    return null;
  }

  return errors.join('\n');
}
