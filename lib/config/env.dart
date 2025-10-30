import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get openAiKey =>
      (dotenv.env['OPENAI_API_KEY'] ?? const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '')).trim();
}


