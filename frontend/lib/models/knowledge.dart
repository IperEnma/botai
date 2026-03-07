class KnowledgeChunk {
  final String? id;
  final String tenantId;
  final String topic;
  final String content;
  final String? keywords;
  final bool active;
  final DateTime? createdAt;

  KnowledgeChunk({
    this.id,
    required this.tenantId,
    required this.topic,
    required this.content,
    this.keywords,
    this.active = true,
    this.createdAt,
  });

  factory KnowledgeChunk.fromJson(Map<String, dynamic> json) {
    return KnowledgeChunk(
      id: json['id']?.toString(),
      tenantId: json['tenantId'] as String,
      topic: json['topic'] as String,
      content: json['content'] as String,
      keywords: json['keywords'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'topic': topic,
      'content': content,
      'keywords': keywords,
      'active': active,
    };
  }

  KnowledgeChunk copyWith({
    String? id,
    String? tenantId,
    String? topic,
    String? content,
    String? keywords,
    bool? active,
    DateTime? createdAt,
  }) {
    return KnowledgeChunk(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      keywords: keywords ?? this.keywords,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
