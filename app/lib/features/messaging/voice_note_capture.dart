import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_lame/flutter_lame.dart';
import 'package:record/record.dart';

/// A microphone recording that is ready for the messaging attachment API.
final class CapturedVoiceNote {
  const CapturedVoiceNote({
    required this.bytes,
    required this.duration,
    required this.filename,
  });

  final Uint8List bytes;
  final Duration duration;
  final String filename;

  String get contentType => 'audio/mpeg';
}

enum VoiceCaptureFailure { permissionDenied, unsupported, captureFailed }

final class VoiceCaptureException implements Exception {
  const VoiceCaptureException(this.failure, this.message);

  final VoiceCaptureFailure failure;
  final String message;

  @override
  String toString() => message;
}

/// Small seam that keeps microphone access replaceable in widget tests.
abstract interface class VoiceNoteCapture {
  bool get isRecording;

  Future<void> start();

  Future<CapturedVoiceNote> stop(Duration duration);

  Future<void> cancel();

  Future<void> dispose();
}

/// Captures mono PCM and encodes it to MP3 while recording.
///
/// The production messaging API validates filename and MIME type and allows MP3
/// by default. Encoding the actual PCM stream avoids relabelling an AAC/M4A file
/// as MP3 and keeps a one-minute voice note comfortably small in memory.
final class Mp3VoiceNoteCapture implements VoiceNoteCapture {
  Mp3VoiceNoteCapture({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const _sampleRate = 44100;

  final AudioRecorder _recorder;
  final BytesBuilder _output = BytesBuilder(copy: false);

  StreamSubscription<Uint8List>? _subscription;
  LameMp3Encoder? _encoder;
  Completer<void>? _streamDone;
  Future<void> _encoding = Future<void>.value();
  Object? _streamError;
  int? _trailingByte;
  bool _recording = false;
  bool _disposed = false;

  @override
  bool get isRecording => _recording;

  @override
  Future<void> start() async {
    if (_disposed) {
      throw const VoiceCaptureException(
        VoiceCaptureFailure.captureFailed,
        'Ovoz yozuvchisi yopilgan. Sahifani qayta ochib ko\u2018ring.',
      );
    }
    if (_recording) return;
    if (!await _recorder.hasPermission()) {
      throw const VoiceCaptureException(
        VoiceCaptureFailure.permissionDenied,
        'Mikrofonga ruxsat berilmadi. Telefon sozlamalaridan ruxsatni yoqing.',
      );
    }
    if (!await _recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
      throw const VoiceCaptureException(
        VoiceCaptureFailure.unsupported,
        'Bu qurilma xavfsiz ovoz yozish formatini qo\u2018llamaydi.',
      );
    }

    _output.clear();
    _streamError = null;
    _trailingByte = null;
    _encoding = Future<void>.value();
    _streamDone = Completer<void>();
    _encoder = LameMp3Encoder(
      sampleRate: _sampleRate,
      numChannels: 1,
      bitRate: 64,
    );

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _recording = true;
      _subscription = stream.listen(
        _queueChunk,
        onError: (Object error, StackTrace stackTrace) {
          _streamError ??= error;
          _completeStream();
        },
        onDone: _completeStream,
        cancelOnError: false,
      );
    } on Object catch (error) {
      await _closeEncoder();
      throw VoiceCaptureException(
        VoiceCaptureFailure.captureFailed,
        'Ovoz yozishni boshlab bo\u2018lmadi: $error',
      );
    }
  }

  void _queueChunk(Uint8List chunk) {
    if (chunk.isEmpty) return;
    _encoding = _encoding
        .then((_) async {
          final encoder = _encoder;
          if (encoder == null) return;
          final samples = _pcmSamples(chunk);
          if (samples.isEmpty) return;
          _output.add(await encoder.encode(leftChannel: samples));
        })
        .catchError((Object error, StackTrace stackTrace) {
          _streamError ??= error;
        });
  }

  Int16List _pcmSamples(Uint8List chunk) {
    final prefix = _trailingByte;
    final bytes = prefix == null
        ? chunk
        : (Uint8List(chunk.length + 1)
            ..[0] = prefix
            ..setRange(1, chunk.length + 1, chunk));
    final evenLength = bytes.length - (bytes.length % 2);
    _trailingByte = evenLength == bytes.length ? null : bytes.last;
    if (evenLength == 0) return Int16List(0);
    final data = ByteData.sublistView(bytes, 0, evenLength);
    return Int16List.fromList(<int>[
      for (var offset = 0; offset < evenLength; offset += 2)
        data.getInt16(offset, Endian.little),
    ]);
  }

  void _completeStream() {
    final done = _streamDone;
    if (done != null && !done.isCompleted) done.complete();
  }

  @override
  Future<CapturedVoiceNote> stop(Duration duration) async {
    if (!_recording) {
      throw const VoiceCaptureException(
        VoiceCaptureFailure.captureFailed,
        'Faol ovoz yozuvi topilmadi.',
      );
    }
    _recording = false;
    try {
      await _recorder.stop();
      final done = _streamDone;
      if (done != null && !done.isCompleted) {
        await done.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () async {
            await _subscription?.cancel();
          },
        );
      }
      await _encoding;
      final error = _streamError;
      if (error != null) throw error;
      final encoder = _encoder;
      if (encoder == null) throw StateError('MP3 encoder is not ready.');
      _output.add(await encoder.flush());
      final bytes = _output.takeBytes();
      if (bytes.isEmpty) throw StateError('The captured audio is empty.');
      final milliseconds = duration.inMilliseconds.clamp(1, 60000);
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      return CapturedVoiceNote(
        bytes: bytes,
        duration: Duration(milliseconds: milliseconds),
        filename: 'voice_${stamp}_${milliseconds}ms.mp3',
      );
    } on VoiceCaptureException {
      rethrow;
    } on Object catch (error) {
      throw VoiceCaptureException(
        VoiceCaptureFailure.captureFailed,
        'Ovozli xabar tayyorlanmadi: $error',
      );
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      _streamDone = null;
      _trailingByte = null;
      await _closeEncoder();
    }
  }

  @override
  Future<void> cancel() async {
    if (_recording) {
      _recording = false;
      await _recorder.cancel();
    }
    await _subscription?.cancel();
    _subscription = null;
    _streamDone = null;
    _trailingByte = null;
    await _encoding;
    await _closeEncoder();
    _output.clear();
  }

  Future<void> _closeEncoder() async {
    final encoder = _encoder;
    _encoder = null;
    if (encoder != null) await encoder.close();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await cancel();
    await _recorder.dispose();
    _disposed = true;
  }
}
