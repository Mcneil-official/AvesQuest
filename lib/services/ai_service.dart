import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

import '../models/identification_result.dart';

class AiService {
  AiService({required this.proxyUrl});

  final String proxyUrl;

  static const _timeout = Duration(seconds: 60);

  Future<IdentificationResult> identifyPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) {
        return IdentificationResult.error('Photo file not found');
      }

      final bytes = await file.readAsBytes();
      final compressed = await _compressImage(bytes);
      final base64Image = base64Encode(Uint8List.fromList(compressed));

      final response = await http
          .post(
            Uri.parse(proxyUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Image}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        final body = _tryDecode(response.body);
        final msg = body?['error'] as String? ?? 'Proxy returned status ${response.statusCode}';
        return IdentificationResult.error(msg);
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return IdentificationResult.fromJson(body);
    } on SocketException {
      return IdentificationResult.error('Network error — check your connection');
    } on http.ClientException {
      return IdentificationResult.error('Network error — check your connection');
    } catch (e) {
      return IdentificationResult.error('Identification failed: $e');
    }
  }

  Future<List<int>> _compressImage(List<int> bytes) async {
    final image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) return bytes;

    const maxDim = 1024;
    const quality = 75;

    int width = image.width;
    int height = image.height;

    if (width > maxDim || height > maxDim) {
      if (width > height) {
        height = (height * maxDim / width).round();
        width = maxDim;
      } else {
        width = (width * maxDim / height).round();
        height = maxDim;
      }
    }

    final resized = img.copyResize(image, width: width, height: height);
    return img.encodeJpg(resized, quality: quality);
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
