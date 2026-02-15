import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

enum CreationType { petition, poll }

class CreationFloatingActionButton extends StatefulWidget {
  final CreationType type;
  final WidgetBuilder pageBuilder;

  const CreationFloatingActionButton({
    super.key,
    required this.type,
    required this.pageBuilder,
  });

  @override
  State<CreationFloatingActionButton> createState() =>
      _CreationFloatingActionButtonState();
}

class _CreationFloatingActionButtonState
    extends State<CreationFloatingActionButton> {
  bool _loading = true;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    QuotaUpdateNotifier.instance.addListener(_loadStatus);
  }

  @override
  void dispose() {
    QuotaUpdateNotifier.instance.removeListener(_loadStatus);
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await PublishingQuotaService.instance.getDailyStatus();
      if (!mounted) return;
      setState(() {
        _canCreate = widget.type == CreationType.petition
            ? status.canCreatePetition
            : status.canCreatePoll;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handlePressed() async {
    if (!_canCreate) {
      showErrorSnackBar(context.l10n.dailyCreateLimitReached);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: widget.pageBuilder),
    );
    if (mounted) _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _loading ? null : _handlePressed,
      backgroundColor: _canCreate ? null : Colors.grey,
      child: _loading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.add),
    );
  }
}
