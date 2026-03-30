import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/password_textfield.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _statusMessage = context.l10n.deleteAccountUserNotFound;
        });
        return;
      }

      // 1. Re-authenticate to ensure fresh credentials (required for deletion)
      AuthCredential credential = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Delete the user
      await user.delete();

      setState(() {
        _statusMessage = context.l10n.deleteAccountSuccess;
        _emailController.clear();
        _passwordController.clear();
      });

      if (mounted) {
        // Pop all routes until the first one (which should be the AuthLayout/WelcomePage)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _statusMessage = context.l10n.deleteAccountUserNotFound;
        } else if (e.code == 'wrong-password') {
          _statusMessage = context.l10n.deleteAccountWrongPassword;
        } else {
          _statusMessage = '${context.l10n.error}${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = context.l10n.deleteAccountUnexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deleteAccountTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.deleteAccountTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.deleteAccountDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('deleteAccountEmailField'),
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: context.l10n.email,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || value.isEmpty)
                        ? context.l10n.enterYourEmail
                        : null,
                  ),
                  const SizedBox(height: 16),
                  PasswordTextField(
                    key: const Key('deleteAccountPasswordField'),
                    controller: _passwordController,
                    labelText: context.l10n.password,
                    prefixIcon: const Icon(Icons.lock),
                    validator: (value) => (value == null || value.isEmpty)
                        ? context.l10n.enterSomething
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (_statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusMessage!.contains("success")
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    key: const Key('deleteAccountButton'),
                    onPressed: _isLoading ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const TriangleLoadingIndicator(
                            size: 20,
                            showFill: false,
                            strokeColor: Colors.white,
                          )
                        : Text(context.l10n.deleteAccountButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
