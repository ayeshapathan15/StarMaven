import 'voice_command_processor.dart';

class DemoVoiceProcessor {
  static Future<VoiceCommandResult> processCommand(String command) async {
    return await VoiceCommandProcessor.processCommand(command);
  }
}