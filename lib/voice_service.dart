import 'package:speech_to_text/speech_to_text.dart';
import 'dart:developer' as dev;

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  // Inicializa o serviço de voz
  Future<bool> initVoice() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) => dev.log('Status de Voz: $status'),
        onError: (error) => dev.log('Erro de Voz: $error'),
      );
      return _isAvailable;
    } catch (e) {
      dev.log('Erro ao inicializar voz: $e');
      return false;
    }
  }

  // Começa a ouvir
  void startListening(Function(String) onResult) {
    if (_isAvailable) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'pt_BR', // Força o português brasileiro
      );
    }
  }

  // Para de ouvir
  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}