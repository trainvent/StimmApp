import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/creation_floating_action_button.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

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
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      onPressed: _handlePressed,
      icon: Icon(widget.icon),
      color: _canCreate ? null : Colors.grey,
      tooltip: _canCreate ? null : context.l10n.dailyCreateLimitReached,
    );
  }
}
