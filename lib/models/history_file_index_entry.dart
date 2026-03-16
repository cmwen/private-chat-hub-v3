class HistoryFileIndexEntry {
  final String conversationId;
  final String filePath;
  final int lastModifiedMs;
  final int fileSize;
  final DateTime indexedAt;

  const HistoryFileIndexEntry({
    required this.conversationId,
    required this.filePath,
    required this.lastModifiedMs,
    required this.fileSize,
    required this.indexedAt,
  });

  factory HistoryFileIndexEntry.fromJson(Map<String, dynamic> json) {
    return HistoryFileIndexEntry(
      conversationId: json['conversationId'] as String,
      filePath: json['filePath'] as String,
      lastModifiedMs: (json['lastModifiedMs'] as num).toInt(),
      fileSize: (json['fileSize'] as num).toInt(),
      indexedAt: DateTime.parse(json['indexedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'filePath': filePath,
        'lastModifiedMs': lastModifiedMs,
        'fileSize': fileSize,
        'indexedAt': indexedAt.toIso8601String(),
      };
}
