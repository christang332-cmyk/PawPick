import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../widgets/paw_widgets.dart';

enum AppNoticeType { success, error, warning, info }

class AppNotice {
  const AppNotice({
    required this.type,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.duration,
  });

  final AppNoticeType type;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration? duration;
}

abstract final class AppNotifier {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final List<AppNotice> _queue = [];
  static OverlayEntry? _entry;
  static AppNotice? _current;
  static Timer? _timer;

  static void success(String title, {
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _enqueue(AppNotice(
        type: AppNoticeType.success,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ));

  static void error(String title, {
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _enqueue(AppNotice(
        type: AppNoticeType.error,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ));

  static void warning(String title, {
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _enqueue(AppNotice(
        type: AppNoticeType.warning,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ));

  static void info(String title, {
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => _enqueue(AppNotice(
        type: AppNoticeType.info,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ));

  static void _enqueue(AppNotice notice) {
    final duplicate = (_current?.title == notice.title &&
            _current?.message == notice.message) ||
        _queue.any((item) =>
            item.title == notice.title && item.message == notice.message);
    if (duplicate) return;
    _queue.add(notice);
    _showNext();
  }

  static void _showNext() {
    if (_current != null || _queue.isEmpty) return;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      Future<void>.delayed(const Duration(milliseconds: 100), _showNext);
      return;
    }
    _current = _queue.removeAt(0);
    _entry = OverlayEntry(builder: (_) => _NoticeCard(notice: _current!));
    overlay.insert(_entry!);
    HapticFeedback.lightImpact();
    _startTimer();
  }

  static void _startTimer() {
    _timer?.cancel();
    final notice = _current;
    if (notice == null) return;
    _timer = Timer(
      notice.duration ??
          Duration(seconds: notice.actionLabel == null ? 4 : 6),
      dismiss,
    );
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    _current = null;
    _showNext();
  }
}

class _NoticeCard extends StatefulWidget {
  const _NoticeCard({required this.notice});

  final AppNotice notice;

  @override
  State<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<_NoticeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _paused = false;

  Color get _accent {
    switch (widget.notice.type) {
      case AppNoticeType.success:
        return AppColors.softGreen;
      case AppNoticeType.error:
        return AppColors.pink;
      case AppNoticeType.warning:
        return AppColors.yellow;
      case AppNoticeType.info:
        return AppColors.sky;
    }
  }

  IconData get _icon {
    switch (widget.notice.type) {
      case AppNoticeType.success:
        return Icons.check_rounded;
      case AppNoticeType.error:
      case AppNoticeType.warning:
        return Icons.priority_high_rounded;
      case AppNoticeType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    final duration = widget.notice.duration ??
        Duration(seconds: widget.notice.actionLabel == null ? 4 : 6);
    _progress = AnimationController(vsync: this, duration: duration)
      ..forward();
    SemanticsService.announce(
      '${widget.notice.title}. ${widget.notice.message ?? ''}',
      TextDirection.ltr,
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _setPaused(bool paused) {
    if (_paused == paused) return;
    setState(() => _paused = paused);
    if (paused) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 120),
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onLongPressStart: (_) => _setPaused(true),
                onLongPressEnd: (_) => _setPaused(false),
                child: Dismissible(
                  key: ValueKey('${widget.notice.title}-${widget.notice.message}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => AppNotifier.dismiss(),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _accent,
                                  foregroundColor: AppColors.ink,
                                  child: Icon(_icon, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Semantics(
                                    liveRegion: true,
                                    label:
                                        '${widget.notice.title}. ${widget.notice.message ?? ''}',
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.notice.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        if (widget.notice.message != null)
                                          Text(
                                            widget.notice.message!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (widget.notice.actionLabel != null)
                                  PawButton(
                                    label: widget.notice.actionLabel!,
                                    variant: PawButtonVariant.text,
                                    expand: false,
                                    height: 44,
                                    onPressed: () {
                                      widget.notice.onAction?.call();
                                      AppNotifier.dismiss();
                                    },
                                  ),
                                PawIconButton(
                                  tooltip: 'Dismiss',
                                  size: 44,
                                  onPressed: AppNotifier.dismiss,
                                  icon: Icons.close_rounded,
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) => Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 1 - _progress.value,
                                child: Container(height: 3, color: _accent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
