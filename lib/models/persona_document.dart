class PersonaDocument {
  final String name;
  final String? defaultModel;
  final String? defaultSystemPrompt;
  final String filePath;

  const PersonaDocument({
    required this.name,
    this.defaultModel,
    this.defaultSystemPrompt,
    required this.filePath,
  });
}
