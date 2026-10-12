import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/buttons/creation_floating_action_button.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

class CreationIconButton extends StatefulWidget {
  final CreationType type;
  final WidgetBuilder pageBuilder;
  final IconData icon;

  const CreationIconButton({
    super.key,
    required this.type,
    required this.pageBuilder,
    this.icon = Icons.assignment_add,
  });

  @override
  State<CreationIconButton> createState() => _CreationIconButtonState();
}

class _CreationIconButtonState extends State<CreationIconButton> {
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

  @override
  void didUpdateWidget(covariant CreationIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final status = await PublishingQuotaService.instance.getDailyStatus();
      if (!mounted) return;
      setState(() {
        _canCreate = widget.type == CreationType.petition
            ? status.canCreatePetition
            : status.canCreateQuestionnaire;
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
      showUserMistakeSnackBar(context.l10n.dailyCreateLimitReached);
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
    return IconButton(
      onPressed: _loading ? null : _handlePressed,
      icon: Icon(widget.icon),
      color: _loading || _canCreate ? null : Colors.grey,
      tooltip: _loading || _canCreate
          ? null
          : context.l10n.dailyCreateLimitReached,
    );
  }
}
