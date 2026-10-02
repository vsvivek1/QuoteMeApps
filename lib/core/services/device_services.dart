import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'device_services.g.dart';

/// Picks photos through the system photo picker (no broad storage
/// permission) and compresses them to max 1600 px, ~75% JPEG.
class MediaService {
  final _picker = ImagePicker();

  Future<List<String>> pickImages({int limit = 6}) async {
    if (limit <= 0) return const [];
    final files = await _picker.pickMultiImage(limit: limit, maxWidth: 2400, maxHeight: 2400);
    final out = <String>[];
    for (final f in files.take(limit)) {
      out.add(await compress(f.path));
    }
    return out;
  }

  Future<String?> takePhoto() async {
    final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 2400);
    return f == null ? null : compress(f.path);
  }

  Future<String> compress(String path) async {
    if (kIsWeb) return path;
    try {
      final dir = await getTemporaryDirectory();
      final target = p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}.jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        target,
        minWidth: 1600,
        minHeight: 1600,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      return result?.path ?? path;
    } catch (_) {
      return path;
    }
  }
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class LocationService {
  /// Current position with "while in use" permission, or null if denied.
  Future<GeoPoint?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return GeoPoint(pos.latitude, pos.longitude);
  }
}

/// Speech to text for the request text box.
class SpeechService {
  final _stt = SpeechToText();
  bool _ready = false;

  Future<bool> start(String localeId, void Function(String text, bool done) onResult) async {
    _ready = _ready || await _stt.initialize();
    if (!_ready) return false;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(localeId: localeId, partialResults: true, listenMode: ListenMode.dictation),
    );
    return true;
  }

  Future<void> stop() => _stt.stop();
  bool get isListening => _stt.isListening;
}

@Riverpod(keepAlive: true)
MediaService mediaService(Ref ref) => MediaService();

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => LocationService();

@Riverpod(keepAlive: true)
SpeechService speechService(Ref ref) => SpeechService();

bool isLocalFile(String path) => !kIsWeb && !path.startsWith('http') && File(path).existsSync();
