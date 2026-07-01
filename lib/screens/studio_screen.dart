import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../moteur/generation_engine.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final _promptController   = TextEditingController();
  final _apiKeyController   = TextEditingController();
  final _imageUrlController = TextEditingController();

  GenerationMode _mode          = GenerationMode.textToVideo;
  String         _selectedRatio = '16:9';
  bool           _isGenerating  = false;
  String         _statusMessage = '';
  String?        _videoUrl;
  String?        _errorMessage;
  bool           _showDirector  = false;
  bool           _showSettings  = false;

  double _fluidity = 50;
  double _gravity  = 50;
  double _pan      = 0;
  double _tilt     = 0;
  double _zoom     = 0;

  final _ratios = ['9:16', '16:9', '1:1', '4:5', '21:9'];

  @override
  void dispose() {
    _promptController.dispose();
    _apiKeyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _generate() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() => _showSettings = true);
      _snack('Entre ta clé API Replicate !');
      return;
    }
    if (_mode == GenerationMode.textToVideo &&
        _promptController.text.trim().isEmpty) {
      _snack('Écris un prompt !');
      return;
    }
    if (_mode == GenerationMode.imageToVideo &&
        _imageUrlController.text.trim().isEmpty) {
      _snack('Colle l\'URL de ton image !');
      return;
    }

    setState(() {
      _isGenerating  = true;
      _statusMessage = 'Connexion...';
      _videoUrl      = null;
      _errorMessage  = null;
    });

    final result = await GenerationEngine.generate(
      GenerationRequest(
        prompt  : _promptController.text,
        ratio   : _selectedRatio,
        director: DirectorSettings(
          fluidity: _fluidity, gravity: _gravity,
          pan: _pan, tilt: _tilt, zoom: _zoom,
        ),
        apiKey  : _apiKeyController.text.trim(),
        mode    : _mode,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null : _imageUrlController.text.trim(),
      ),
      onStatus: (s) => setState(() => _statusMessage = s),
    );

    setState(() {
      _isGenerating = false;
      if (result.status == 'succeeded') {
        _videoUrl      = result.videoUrl;
        _statusMessage = 'Vidéo prête !';
      } else {
        _errorMessage  = result.error;
        _statusMessage = 'Erreur';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        title: Row(children: [
          const Text('VizionAI', style: TextStyle(
              color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x22D4AF37),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('STUDIO', style: TextStyle(
                color: Color(0xFFD4AF37), fontSize: 9,
                letterSpacing: 3, fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
            icon: Icon(_showSettings ? Icons.close : Icons.key,
                color: const Color(0xFF999999)),
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (_showSettings) ...[
            _label('CLÉ API REPLICATE'),
            _field(_apiKeyController, hint: 'r8_xxxxxxxxxxxx', obscure: true),
            const SizedBox(height: 16),
          ],

          _label('MODE DE GÉNÉRATION'),
          Row(children: [
            _modeBtn('✍️  TEXTE → VIDÉO', 'Wan 2.1', GenerationMode.textToVideo),
            const SizedBox(width: 10),
            _modeBtn('🖼️  IMAGE → VIDÉO', 'Wan I2V', GenerationMode.imageToVideo),
          ]),
          const SizedBox(height: 6),
          Text(
            _mode == GenerationMode.textToVideo
                ? '💡 Écris en anglais pour de meilleurs résultats'
                : '💡 Colle un lien direct d\'image (imgbb.com)',
            style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
          ),
          const SizedBox(height: 20),

          if (_mode == GenerationMode.textToVideo) ...[
            _label('PROMPT (EN ANGLAIS)'),
            _field(_promptController,
                hint: 'A smiling doctor in a hospital, cinematic 4K...', lines: 4),
            const SizedBox(height: 20),
          ],

          if (_mode == GenerationMode.imageToVideo) ...[
            _label('URL DE TON IMAGE'),
            _field(_imageUrlController, hint: 'https://i.ibb.co/xxx/photo.jpg'),
            const SizedBox(height: 8),
            const Text(
              '💡 Upload sur imgbb.com → copie le "Direct link"',
              style: TextStyle(color: Color(0xFF555555), fontSize: 10),
            ),
            const SizedBox(height: 12),
            _label('PROMPT (OPTIONNEL)'),
            _field(_promptController,
                hint: 'Smooth cinematic motion...', lines: 2),
            const SizedBox(height: 20),
          ],

          _label('FORMAT'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _ratios.map((r) {
              final sel = r == _selectedRatio;
              return GestureDetector(
                onTap: () => setState(() => _selectedRatio = r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFD4AF37) : const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sel
                        ? const Color(0xFFD4AF37) : const Color(0x20FFFFFF)),
                  ),
                  child: Text(r, style: TextStyle(
                    color: sel ? Colors.black : const Color(0xFF999999),
                    fontWeight: FontWeight.bold, fontSize: 12,
                  )),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => setState(() => _showDirector = !_showDirector),
            child: Row(children: [
              _label('DIRECTOR PANEL'),
              const Spacer(),
              Icon(_showDirector ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF999999)),
            ]),
          ),
          if (_showDirector) ...[
            const SizedBox(height: 8),
            _sliderWidget('Créativité', _fluidity, (v) => setState(() => _fluidity = v),
                sub: 'guide → ${GenerationEngine.mapGuidance(_fluidity).toStringAsFixed(1)}'),
            _sliderWidget('Qualité', _gravity, (v) => setState(() => _gravity = v),
                sub: 'steps → ${GenerationEngine.mapSteps(_gravity)}'),
            _sliderWidget('Pan',  _pan,  (v) => setState(() => _pan  = v), min: -100, max: 100),
            _sliderWidget('Tilt', _tilt, (v) => setState(() => _tilt = v), min: -100, max: 100),
            _sliderWidget('Zoom', _zoom, (v) => setState(() => _zoom = v), min: -100, max: 100),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                disabledBackgroundColor: const Color(0xFF222222),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isGenerating
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Color(0xFFD4AF37))),
                      const SizedBox(width: 12),
                      Text(_statusMessage, style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 12)),
                    ])
                  : Text(
                      _mode == GenerationMode.textToVideo
                          ? 'GÉNÉRER LA VIDÉO' : 'ANIMER L\'IMAGE',
                      style: const TextStyle(color: Colors.black,
                          fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 20),

          if (_videoUrl != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _videoUrl!));
                _snack('Lien copié !');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1F0D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('✅ Vidéo générée !', style: TextStyle(
                      color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_videoUrl!, style: const TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 11,
                      decoration: TextDecoration.underline)),
                  const SizedBox(height: 6),
                  const Text('Appuie pour copier le lien',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
                ]),
              ),
            ),

          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F0D0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Text('❌ $_errorMessage',
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _modeBtn(String label, String sub, GenerationMode mode) {
    final sel = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFD4AF37) : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel
                ? const Color(0xFFD4AF37) : const Color(0x20FFFFFF)),
          ),
          child: Column(children: [
            Text(label, textAlign: TextAlign.center, style: TextStyle(
              color: sel ? Colors.black : const Color(0xFFF2F2F2),
              fontWeight: FontWeight.bold, fontSize: 11,
            )),
            Text(sub, style: TextStyle(
              color: sel ? Colors.black54 : const Color(0xFF555555), fontSize: 9)),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: Color(0xFF999999),
        fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
  );

  Widget _field(TextEditingController c,
      {String hint = '', int lines = 1, bool obscure = false}) =>
      TextField(
        controller: c, maxLines: lines, obscureText: obscure,
        style: const TextStyle(color: Color(0xFFF2F2F2), fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12),
          filled: true, fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x20FFFFFF))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0x20FFFFFF))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        ),
      );

  Widget _sliderWidget(String label, double value, ValueChanged<double> cb,
      {double min = 0, double max = 100, String? sub}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(color: Color(0xFFF2F2F2), fontSize: 12)),
          const Spacer(),
          Text(value.toStringAsFixed(0),
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
          if (sub != null) ...[
            const SizedBox(width: 8),
            Text(sub, style: const TextStyle(color: Color(0xFF555555), fontSize: 10)),
          ],
        ]),
        SliderTheme(
          data: const SliderThemeData(
            activeTrackColor: Color(0xFFD4AF37),
            inactiveTrackColor: Color(0xFF333333),
            thumbColor: Color(0xFFD4AF37),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: cb),
        ),
        const SizedBox(height: 4),
      ]);
}
