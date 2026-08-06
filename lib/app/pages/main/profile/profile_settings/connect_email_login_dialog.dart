import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/password_textfield.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/validate_password.dart';

class ConnectEmailLoginDialog extends StatefulWidget {
  const ConnectEmailLoginDialog({super.key, required this.email});

  final String email;

  @override
  State<ConnectEmailLoginDialog> createState() =>
      _ConnectEmailLoginDialogState();
}

class _ConnectEmailLoginDialogState extends State<ConnectEmailLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.addEmailSignIn),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.addEmailSignInDescription(widget.email)),
              const SizedBox(height: 20),
              PasswordTextField(
                controller: _passwordController,
                labelText: context.l10n.password,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => validatePassword(context, value),
              ),
              const SizedBox(height: 12),
              PasswordTextField(
                controller: _confirmationController,
                labelText: context.l10n.confirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseEnterYourPassword;
                  }
                  if (value != _passwordController.text) {
                    return context.l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.connect)),
      ],
    );
  }
}
