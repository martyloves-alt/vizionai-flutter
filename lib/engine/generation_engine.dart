import 'dart:convert';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════
// MODÈLES DE DONNÉES
// ═══════════════════════════════════════════

class DirectorSettings {
  final double pan;
  final double tilt;
  final double zoom;
  final double fluidity;
  final double gravity;

  const DirectorSettings({
    this.pan = 0,
    this.tilt = 0,
    this.zoom = 0,
    this.fluidity = 50,
    this.gravity = 50,
  });
}

class GenerationRequest {
  final String prompt;
  final String ratio;
  final DirectorSettings director;
  final String apiKey;

  const GenerationRequest({
    required this.prompt,
    required this.ratio,
    required this.director,
    required this.apiKey,
  });
}

class GenerationResult {
  final String status;
  final String? videoUrl;
  final String? error;

  const GenerationResult({
    required this.status,
    this.videoUrl,
    this.error,
  });
}

// ═══════════════════════════════════════════
// MOTEUR DÉTERMINISTE
// ═══════════════════════════════════════════

class GenerationEngine {

  static const String _modelVersion =
      '1e205ea73084bd17a0a3b43396e49ba0d6bc2e754e9283b2df49fad2dcf95755';

  static const String _baseUrl = 'https://api.replicate.com/v1';

  // --- PARAMETER MAPPER ---
  // fluidity (0-100) → motion_bucket_id (1-255)
  static int mapMotionBucket(double fluidity) {
    return (fluidity * 2.55).round().clamp(1, 255);
  }

  // gravity (0-100) → cond_aug (0.0-1.0)
  static double mapCondAug(double gravity) {
    return (gravity / 100.0).clamp(0.0, 1.0);
  }

  // ratio → dimensions
  static Map<String, int> mapDimensions(String ratio) {
    switch (ratio) {
      case '16:9': return {'width': 1024, 'height': 576};
      case '9:16': return {'width': 576,  'height': 1024};
      case '1:1':  return {'width': 768,  'height': 768};
      case '4:5':  return {'width': 768,  'height': 960};
      case '21:9': return {'width': 1024, 'height': 440};
      default:     return {'width': 1024, 'height': 576};
    }
  }

  // --- REQUEST BUILDER ---
  static Map<String, dynamic> buildInput(GenerationRequest req) {
    final dims = mapDimensions(req.ratio);
    return {
      'prompt': req.prompt.trim(),
      'width': dims['width'],
      'height': dims['height'],
      'motion_bucket_id': mapMotionBucket(req.director.fluidity),
      'cond_aug': mapCondAug(req.director.gravity),
      'fps_id': 6,
      'num_frames': 14,
    };
  }

  // --- GENERATE ---
  static Future<GenerationResult> generate(
    GenerationRequest request, {
    Function(String)? onStatus,
  }) async {
    try {
      onStatus?.call('Envoi de la requête...');

      final response = await http.post(
        Uri.parse('$_baseUrl/predictions'),
        headers: {
          'Authorization': 'Token ${request.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': _modelVersion,
          'input': buildInput(request),
        }),
      );

      if (response.statusCode != 201) {
        return GenerationResult(
          status: 'failed',
          error: 'Erreur API ${response.statusCode}',
        );
      }

      final id = jsonDecode(response.body)['id'] as String;
      return _poll(id, request.apiKey, onStatus: onStatus);
    } catch (e) {
      return GenerationResult(status: 'failed', error: 'Erreur réseau: $e');
    }
  }

  static Future<GenerationResult> _poll(
    String id,
    String apiKey, {
    Function(String)? onStatus,
  }) async {
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 5));

      final res = await http.get(
        Uri.parse('$_baseUrl/predictions/$id'),
        headers: {'Authorization': 'Token $apiKey'},
      );

      if (res.statusCode != 200) continue;

      final data = jsonDecode(res.body);
      final status = data['status'] as String;

      if (status == 'starting')    onStatus?.call('Démarrage...');
      if (status == 'processing')  onStatus?.call('Génération en cours...');

      if (status == 'succeeded') {
        final out = data['output'];
        final url = out is List ? out.first as String : out as String?;
        return GenerationResult(status: 'succeeded', videoUrl: url);
      }
      if (status == 'failed' || status == 'canceled') {
        return GenerationResult(status: status, error: data['error']);
      }
    }
    return const GenerationResult(status: 'failed', error: 'Délai dépassé');
  }
}
