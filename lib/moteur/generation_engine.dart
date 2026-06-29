import 'dart:convert';
import 'package:http/http.dart' as http;

enum GenerationMode { textToVideo, imageToVideo }

class DirectorSettings {
  final double fluidity;
  final double gravity;
  final double pan;
  final double tilt;
  final double zoom;

  const DirectorSettings({
    this.fluidity = 50,
    this.gravity  = 50,
    this.pan      = 0,
    this.tilt     = 0,
    this.zoom     = 0,
  });
}

class GenerationRequest {
  final String           prompt;
  final String           ratio;
  final DirectorSettings director;
  final String           apiKey;
  final GenerationMode   mode;
  final String?          imageUrl;

  const GenerationRequest({
    required this.prompt,
    required this.ratio,
    required this.director,
    required this.apiKey,
    this.mode     = GenerationMode.textToVideo,
    this.imageUrl,
  });
}

class GenerationResult {
  final String  status;
  final String? videoUrl;
  final String? error;

  const GenerationResult({
    required this.status,
    this.videoUrl,
    this.error,
  });
}

class GenerationEngine {

  static const String _baseUrl = 'https://api.replicate.com/v1';

  // ── MAPPERS ────────────────────────────────────────────────────

  // fluidity (0-100) → guide_scale (1.0 – 10.0)
  static double mapGuidance(double fluidity) =>
      1.0 + (fluidity / 100.0) * 9.0;

  // gravity (0-100) → steps (20 – 50)
  static int mapSteps(double gravity) =>
      (20 + (gravity / 100.0) * 30).round();

  static int mapMotionBucket(double fluidity) =>
      (fluidity * 2.55).round().clamp(1, 255);

  static double mapCondAug(double gravity) =>
      (gravity / 100.0).clamp(0.0, 1.0);

  // ── INPUTS ─────────────────────────────────────────────────────

  static Map<String, dynamic> _buildTextInput(GenerationRequest req) => {
    'prompt'      : req.prompt.trim(),
    'guide_scale' : mapGuidance(req.director.fluidity),
    'steps'       : mapSteps(req.director.gravity),
    'num_frames'  : 81,
  };

  static Map<String, dynamic> _buildImageInput(GenerationRequest req) => {
    'image'       : req.imageUrl!.trim(),
    'prompt'      : req.prompt.trim().isEmpty
        ? 'cinematic video, smooth motion'
        : req.prompt.trim(),
    'guide_scale' : mapGuidance(req.director.fluidity),
    'steps'       : mapSteps(req.director.gravity),
  };

  // ── GENERATE ───────────────────────────────────────────────────

  static Future<GenerationResult> generate(
    GenerationRequest request, {
    Function(String)? onStatus,
  }) async {
    final isImage = request.mode == GenerationMode.imageToVideo;

    final endpoint = isImage
        ? '$_baseUrl/models/wavespeedai/wan-2.1-i2v-480p/predictions'
        : '$_baseUrl/models/wavespeedai/wan-2.1-t2v-480p/predictions';

    final input = isImage
        ? _buildImageInput(request)
        : _buildTextInput(request);

    onStatus?.call(isImage
        ? 'Animation de l\'image...'
        : 'Connexion à Wan 2.1...');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Token ${request.apiKey}',
          'Content-Type' : 'application/json',
        },
        body: jsonEncode({'input': input}),
      );

      if (response.statusCode != 201) {
        final body = jsonDecode(response.body);
        return GenerationResult(
          status: 'failed',
          error : body['detail']?.toString() ??
                  'Erreur API ${response.statusCode}',
        );
      }

      final id = jsonDecode(response.body)['id'] as String;
      return _poll(id, request.apiKey, onStatus: onStatus);

    } catch (e) {
      return GenerationResult(
        status: 'failed',
        error : 'Erreur réseau: $e',
      );
    }
  }

  // ── POLLING ────────────────────────────────────────────────────

  static Future<GenerationResult> _poll(
    String id,
    String apiKey, {
    Function(String)? onStatus,
  }) async {
    for (int i = 0; i < 120; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final res = await http.get(
          Uri.parse('$_baseUrl/predictions/$id'),
          headers: {'Authorization': 'Token $apiKey'},
        );
        if (res.statusCode != 200) continue;

        final data   = jsonDecode(res.body);
        final status = data['status'] as String;

        if (status == 'starting')   onStatus?.call('Démarrage...');
        if (status == 'processing') onStatus?.call('Génération... (1-3 min)');

        if (status == 'succeeded') {
          final out = data['output'];
          final url = out is List ? out.first as String : out as String?;
          return GenerationResult(status: 'succeeded', videoUrl: url);
        }
        if (status == 'failed' || status == 'canceled') {
          return GenerationResult(
            status: status,
            error : data['error']?.toString() ?? 'Échec',
          );
        }
      } catch (_) { continue; }
    }
    return const GenerationResult(
      status: 'failed',
      error : 'Délai dépassé. Réessaie.',
    );
  }
}
