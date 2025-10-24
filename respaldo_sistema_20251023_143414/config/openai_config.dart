class OpenAIConfig {
  // API key de OpenAI - configurar en variables de entorno
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String model = 'gpt-3.5-turbo';
  static const int maxTokens = 300; // Aumentado para respuestas más detalladas
  static const double temperature = 0.1; // Reducido para respuestas más consistentes
}