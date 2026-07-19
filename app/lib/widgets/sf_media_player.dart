import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../theme/sf_theme.dart';
import 'sf_button.dart';
import 'sf_card.dart';

enum SfMediaKind { video, audio }

typedef SfMediaUrlResolver = Future<String> Function();

SfMediaKind? sfMediaKindForContentType(String contentType) {
  final normalized = contentType.trim().toLowerCase();
  if (normalized.startsWith('video/')) return SfMediaKind.video;
  if (normalized.startsWith('audio/')) return SfMediaKind.audio;
  return null;
}

bool sfContentTypeCanPrint(String contentType) {
  final normalized = contentType.trim().toLowerCase();
  return !normalized.startsWith('video/') &&
      !normalized.startsWith('audio/') &&
      !normalized.startsWith('image/');
}

/// In-app player for the backend's short-lived signed media URLs.
///
/// The iOS audio treatment is Dynamic-Island-inspired UI inside the app. It is
/// intentionally not described as a system Live Activity.
class SfNetworkMediaPlayer extends StatefulWidget {
  const SfNetworkMediaPlayer({
    super.key,
    required this.url,
    required this.title,
    required this.kind,
    this.subtitle,
    this.autoplay = true,
    this.refreshUrl,
  });

  final String url;
  final String title;
  final String? subtitle;
  final SfMediaKind kind;
  final bool autoplay;

  /// Resolves a new short-lived URL after a player or transport failure.
  ///
  /// Signed media URLs are immutable credentials with a TTL. Retrying the
  /// same string after expiry cannot recover, so production callers should
  /// provide a resolver that asks the backend for a new grant.
  final SfMediaUrlResolver? refreshUrl;

  @override
  State<SfNetworkMediaPlayer> createState() => _SfNetworkMediaPlayerState();
}

class _SfNetworkMediaPlayerState extends State<SfNetworkMediaPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  AudioPlayer? _audioPlayer;
  StreamSubscription<PlayerException>? _audioErrorSubscription;
  Object? _error;
  bool _initializing = true;
  late String _activeUrl;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeUrl = widget.url;
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant SfNetworkMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.kind != widget.kind) {
      _activeUrl = widget.url;
      unawaited(_initialize());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_controller?.pause());
      unawaited(_audioPlayer?.pause());
    }
  }

  Future<void> _initialize({bool refreshSignedUrl = false}) async {
    final generation = ++_generation;
    final previous = _controller;
    final previousAudio = _audioPlayer;
    final previousAudioErrors = _audioErrorSubscription;
    _controller = null;
    _audioPlayer = null;
    _audioErrorSubscription = null;
    if (mounted) {
      setState(() {
        _error = null;
        _initializing = true;
      });
    }
    await previousAudioErrors?.cancel();
    await previous?.dispose();
    await previousAudio?.dispose();

    if (refreshSignedUrl && widget.refreshUrl != null) {
      try {
        final refreshed = await widget.refreshUrl!();
        if (!mounted || generation != _generation) return;
        _activeUrl = refreshed;
      } catch (error) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _error = error;
          _initializing = false;
        });
        return;
      }
    }

    final currentUrl = _activeUrl;
    final uri = Uri.tryParse(currentUrl);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = const FormatException('The server returned an invalid URL.');
          _initializing = false;
        });
      }
      return;
    }

    if (widget.kind == SfMediaKind.audio) {
      final player = AudioPlayer();
      _audioPlayer = player;
      _audioErrorSubscription = player.errorStream.listen((error) {
        if (!mounted || _audioPlayer != player) return;
        setState(() {
          _error = error;
          _initializing = false;
        });
      });
      try {
        await player.setUrl(currentUrl);
        if (widget.autoplay) unawaited(player.play());
        if (!mounted || generation != _generation || _audioPlayer != player) {
          await player.dispose();
          return;
        }
        setState(() => _initializing = false);
      } catch (error) {
        if (!mounted || generation != _generation || _audioPlayer != player) {
          return;
        }
        setState(() {
          _error = error;
          _initializing = false;
        });
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (widget.autoplay) await controller.play();
      if (!mounted || generation != _generation || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() => _initializing = false);
    } catch (error) {
      if (!mounted || generation != _generation || _controller != controller) {
        return;
      }
      setState(() {
        _error = error;
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_audioErrorSubscription?.cancel());
    unawaited(_controller?.dispose());
    unawaited(_audioPlayer?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initializing && _error == null && widget.kind == SfMediaKind.audio) {
      final player = _audioPlayer;
      if (player != null) {
        return _AudioPlayerBody(
          player: player,
          title: widget.title,
          subtitle: widget.subtitle,
        );
      }
    }
    final controller = _controller;
    if (_initializing) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || controller == null) {
      return _MediaError(onRetry: _retryWithFreshUrl);
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.hasError) {
          return _MediaError(onRetry: _retryWithFreshUrl);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VideoStage(controller: controller, value: value),
            const SizedBox(height: 14),
            _PlaybackControls(
              controller: controller,
              value: value,
              title: widget.title,
            ),
          ],
        );
      },
    );
  }

  Future<void> _retryWithFreshUrl() => _initialize(refreshSignedUrl: true);
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({required this.controller, required this.value});

  final VideoPlayerController controller;
  final VideoPlayerValue value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final aspect = value.aspectRatio.isFinite && value.aspectRatio > 0
        ? value.aspectRatio.clamp(0.58, 2.4).toDouble()
        : 16 / 9;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => value.isPlaying
                      ? unawaited(controller.pause())
                      : unawaited(controller.play()),
                  child: AnimatedOpacity(
                    duration: SfMotion.resolve(context, SfMotion.quick),
                    opacity: value.isPlaying ? 0 : 1,
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: c.ink.withValues(alpha: 0.76),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: c.bg,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (value.isBuffering)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioPlayerBody extends StatelessWidget {
  const _AudioPlayerBody({
    required this.player,
    required this.title,
    required this.subtitle,
  });

  final AudioPlayer player;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlayerState>(
    stream: player.playerStateStream,
    initialData: player.playerState,
    builder: (context, stateSnapshot) {
      final state = stateSnapshot.data ?? player.playerState;
      return StreamBuilder<Duration?>(
        stream: player.durationStream,
        initialData: player.duration,
        builder: (context, durationSnapshot) => StreamBuilder<Duration>(
          stream: player.positionStream,
          initialData: player.position,
          builder: (context, positionSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final position = positionSnapshot.data ?? Duration.zero;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _AudioStage(
                      title: title,
                      subtitle: subtitle,
                      playing: state.playing,
                    ),
                    if (state.processingState == ProcessingState.loading ||
                        state.processingState == ProcessingState.buffering)
                      const CircularProgressIndicator(),
                  ],
                ),
                const SizedBox(height: 14),
                _AudioPlaybackControls(
                  player: player,
                  state: state,
                  position: position,
                  duration: duration,
                  title: title,
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _AudioStage extends StatelessWidget {
  const _AudioStage({
    required this.title,
    required this.subtitle,
    required this.playing,
  });

  final String title;
  final String? subtitle;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final platform = Theme.of(context).platform;
    final apple = platform == TargetPlatform.iOS;
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primarySoft, c.accentSoft, c.surface2],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.border),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            bottom: -44,
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 180,
              color: c.primary.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (apple)
                  AnimatedContainer(
                    key: const Key('ios-in-app-now-playing'),
                    duration: SfMotion.resolve(context, SfMotion.standard),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090909),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: playing ? 20 : 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          playing
                              ? Icons.graphic_eq_rounded
                              : Icons.pause_rounded,
                          size: 16,
                          color: c.accent,
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'NOW PLAYING · IN APP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(Icons.headphones_rounded, size: 46, color: c.primary),
                const SizedBox(height: 20),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: SfType.ui(
                    size: 17,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 11.5, color: c.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.controller,
    required this.value,
    required this.title,
  });

  final VideoPlayerController controller;
  final VideoPlayerValue value;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final duration = value.duration;
    final position = value.position > duration ? duration : value.position;
    final durationMs = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final positionMs = position.inMilliseconds
        .clamp(0, durationMs.round())
        .toDouble();
    return SfSurfaceCard(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '$title playback position',
            value: '${_time(position)} of ${_time(duration)}',
            child: Slider(
              key: const Key('media-position-slider'),
              value: positionMs,
              max: durationMs,
              onChanged: (milliseconds) => unawaited(
                controller.seekTo(Duration(milliseconds: milliseconds.round())),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  _time(position),
                  style: SfType.mono(size: 10, color: c.muted),
                ),
                const Spacer(),
                Text(
                  _time(duration),
                  style: SfType.mono(size: 10, color: c.muted),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Back 10 seconds',
                onPressed: () => unawaited(
                  controller.seekTo(position - const Duration(seconds: 10)),
                ),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('media-play-pause'),
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () => value.isPlaying
                    ? unawaited(controller.pause())
                    : unawaited(controller.play()),
                child: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 27,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Forward 10 seconds',
                onPressed: () => unawaited(
                  controller.seekTo(position + const Duration(seconds: 10)),
                ),
                icon: const Icon(Icons.forward_10_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioPlaybackControls extends StatelessWidget {
  const _AudioPlaybackControls({
    required this.player,
    required this.state,
    required this.position,
    required this.duration,
    required this.title,
  });

  final AudioPlayer player;
  final PlayerState state;
  final Duration position;
  final Duration duration;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final safePosition = _clampDuration(position, Duration.zero, duration);
    final durationMs = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final positionMs = safePosition.inMilliseconds
        .clamp(0, durationMs.round())
        .toDouble();
    final completed = state.processingState == ProcessingState.completed;
    return SfSurfaceCard(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '$title playback position',
            value: '${_time(safePosition)} of ${_time(duration)}',
            child: Slider(
              key: const Key('media-position-slider'),
              value: positionMs,
              max: durationMs,
              onChanged: (milliseconds) => unawaited(
                player.seek(Duration(milliseconds: milliseconds.round())),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  _time(safePosition),
                  style: SfType.mono(size: 10, color: c.muted),
                ),
                const Spacer(),
                Text(
                  _time(duration),
                  style: SfType.mono(size: 10, color: c.muted),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Back 10 seconds',
                onPressed: () => unawaited(
                  player.seek(
                    _clampDuration(
                      safePosition - const Duration(seconds: 10),
                      Duration.zero,
                      duration,
                    ),
                  ),
                ),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('media-play-pause'),
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  if (state.playing) {
                    await player.pause();
                    return;
                  }
                  if (completed) await player.seek(Duration.zero);
                  unawaited(player.play());
                },
                child: Icon(
                  state.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 27,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Forward 10 seconds',
                onPressed: () => unawaited(
                  player.seek(
                    _clampDuration(
                      safePosition + const Duration(seconds: 10),
                      Duration.zero,
                      duration,
                    ),
                  ),
                ),
                icon: const Icon(Icons.forward_10_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 250,
    child: Center(
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_disabled_rounded,
              size: 36,
              color: SfTheme.colorsOf(context).danger,
            ),
            const SizedBox(height: 10),
            Text(
              'This media could not be played.',
              textAlign: TextAlign.center,
              style: SfType.ui(size: 14, weight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'The temporary link may have expired. Request a fresh link and try again.',
              textAlign: TextAlign.center,
              style: SfType.ui(
                size: 11.5,
                color: SfTheme.colorsOf(context).muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SfButton(
              key: const Key('media-retry-fresh-url'),
              kind: SfButtonKind.soft,
              leading: Icons.refresh_rounded,
              label: 'Retry player',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    ),
  );
}

String _time(Duration value) {
  final safe = value.isNegative ? Duration.zero : value;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

Duration _clampDuration(Duration value, Duration minimum, Duration maximum) {
  if (value < minimum) return minimum;
  if (maximum > Duration.zero && value > maximum) return maximum;
  return value;
}
