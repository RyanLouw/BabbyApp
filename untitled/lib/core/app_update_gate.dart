import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Checks Google Play for an update at startup and whenever the app resumes.
///
/// An available update uses Play's immediate update flow, so a user cannot keep
/// using an obsolete build. Sideloaded and debug builds remain usable because
/// Google Play cannot report update availability for those installations.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  static const _updates = MethodChannel('com.babbycare.app/play_update');

  bool _checking = false;
  bool _updateRequired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkForUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_checking || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final required =
          await _updates.invokeMethod<bool>('checkAndStartImmediateUpdate') ??
          false;
      if (mounted) setState(() => _updateRequired = required);
    } on PlatformException catch (error) {
      // Play update checks normally fail for local/debug installations. Only
      // block when Play had already confirmed that an update is required.
      if (mounted &&
          (_updateRequired || error.code != 'UPDATE_CHECK_FAILED')) {
        setState(() {
          _updateRequired = true;
          _error = 'Could not open Google Play. Check your connection.';
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_updateRequired)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.system_update, size: 56),
                        const SizedBox(height: 20),
                        Text(
                          'Update required',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error ??
                              'A new version of Babby Care is ready. Update to continue.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _checking ? null : _checkForUpdate,
                          icon: _checking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.open_in_new),
                          label: const Text('Update now'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
