import 'dart:async';
import 'package:flutter/material.dart';

class RestTimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback? onComplete;
  final bool autoStart;

  const RestTimerWidget({super.key, required this.durationSeconds, this.onComplete, this.autoStart = true});

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remaining;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    if (widget.autoStart) _start();
  }

  void _start() {
    _timer?.cancel();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          timer.cancel();
          _isRunning = false;
          widget.onComplete?.call();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _skip() {
    _timer?.cancel();
    setState(() { _remaining = 0; _isRunning = false; });
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remaining / widget.durationSeconds);
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rest', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: 80, height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  Text('$minutes:${seconds.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: _isRunning ? _pause : _start,
                ),
                TextButton(onPressed: _skip, child: const Text('Skip')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
