sealed class ChatResponse {
  const ChatResponse();
}

class ChatResponseContent extends ChatResponse {
  final String text;
  const ChatResponseContent(this.text);
}

class ChatResponseUsage extends ChatResponse {
  final int inputTokens;
  final int outputTokens;
  const ChatResponseUsage({
    required this.inputTokens,
    required this.outputTokens,
  });
}

class ChatResponseError extends ChatResponse {
  final String code;
  final String message;
  final bool recoverable;
  const ChatResponseError({
    required this.code,
    required this.message,
    this.recoverable = false,
  });
}
