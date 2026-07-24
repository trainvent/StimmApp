import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;

  const VerificationCodeInput({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromMainController);
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() => _onDigitChanged(i));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromMainController);
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncFromMainController() {
    if (_isSyncing) return;
    _isSyncing = true;

    String text = widget.controller.text;
    if (text.length > 6) text = text.substring(0, 6);

    for (int i = 0; i < 6; i++) {
      if (i < text.length) {
        if (_controllers[i].text != text[i]) {
          _controllers[i].text = text[i];
        }
      } else {
        if (_controllers[i].text.isNotEmpty) {
          _controllers[i].clear();
        }
      }
    }
    _isSyncing = false;
  }

  void _onDigitChanged(int index) {
    if (_isSyncing) return;

    String value = _controllers[index].text;

    // Handle paste or multi-character input
    if (value.length > 1) {
      _isSyncing = true;
      // It's a paste!
      String newCode = value;

      // If the user pasted something longer than 6 chars, truncate it
      if (newCode.length > 6) {
        newCode = newCode.substring(0, 6);
      }

      // Update the main controller with the pasted code
      widget.controller.text = newCode;

      // Manually sync back to boxes since we are in _isSyncing block
      for (int i = 0; i < 6; i++) {
        if (i < newCode.length) {
          if (_controllers[i].text != newCode[i]) {
            _controllers[i].text = newCode[i];
          }
        } else {
          _controllers[i].clear();
        }
      }

      _isSyncing = false;

      // Move focus to the end of the new input
      int nextIndex = newCode.length;
      if (nextIndex < 6) {
        FocusScope.of(context).requestFocus(_focusNodes[nextIndex]);
      } else {
        FocusScope.of(context).unfocus();
        widget.onCompleted?.call(newCode);
      }
      return;
    }

    // Normal single digit entry
    String newCode = '';
    for (var c in _controllers) {
      newCode += c.text;
    }

    if (widget.controller.text != newCode) {
      _isSyncing = true;
      widget.controller.text = newCode;
      _isSyncing = false;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
        widget.onCompleted?.call(newCode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Row(
          children: [
            SizedBox(
              width: 45,
              height: 55,
              child: TextField(
                // Only assign the key to the first TextField so the finder can locate it
                key: index == 0 ? widget.key : null,
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                // Allow more than 1 char temporarily to capture paste events
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isEmpty && index > 0) {
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                  }
                },
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            if (index < 5) const SizedBox(width: 8),
          ],
        );
      }),
    );
  }
}
