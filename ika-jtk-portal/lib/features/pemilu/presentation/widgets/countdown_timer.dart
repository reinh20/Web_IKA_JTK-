import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime? deadline;
  final VoidCallback? onFinished;
  const CountdownTimer({super.key, required this.deadline, this.onFinished});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _finishedCalled = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (widget.deadline == null) {
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }
    final diff = widget.deadline!.difference(DateTime.now());
    if (diff.isNegative) {
      if (mounted && _remaining > Duration.zero) {
        setState(() => _remaining = Duration.zero);
      } else if (mounted && _remaining == Duration.zero) {
        // already zero
      }
      if (!_finishedCalled) {
        _finishedCalled = true;
        widget.onFinished?.call();
      }
    } else {
      if (mounted) {
        setState(() => _remaining = diff);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _pair(days, 'Hari'),
        _pair(hours, 'Jam'),
        _pair(minutes, 'Menit'),
        _pair(seconds, 'Detik'),
      ],
    );
  }

  Widget _pair(int value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
