class Menu {
  final String? id;
  final String tenantId;
  final String menuKey;
  final String text;
  final bool active;
  final List<MenuOption> options;

  Menu({
    this.id,
    required this.tenantId,
    required this.menuKey,
    required this.text,
    this.active = true,
    this.options = const [],
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id']?.toString(),
      tenantId: json['tenantId'] as String,
      menuKey: json['menuKey'] as String,
      text: json['text'] as String,
      active: json['active'] as bool? ?? true,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => MenuOption.fromJson(o))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'menuKey': menuKey,
      'text': text,
      'active': active,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  Menu copyWith({
    String? id,
    String? tenantId,
    String? menuKey,
    String? text,
    bool? active,
    List<MenuOption>? options,
  }) {
    return Menu(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      menuKey: menuKey ?? this.menuKey,
      text: text ?? this.text,
      active: active ?? this.active,
      options: options ?? this.options,
    );
  }
}

class MenuOption {
  final String? id;
  final String optionKey;
  final String targetMenuKey;
  final String label;
  final int sortOrder;

  MenuOption({
    this.id,
    required this.optionKey,
    required this.targetMenuKey,
    required this.label,
    this.sortOrder = 0,
  });

  factory MenuOption.fromJson(Map<String, dynamic> json) {
    return MenuOption(
      id: json['id']?.toString(),
      optionKey: json['optionKey'] as String,
      targetMenuKey: json['targetMenuKey'] as String,
      label: json['label'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'optionKey': optionKey,
      'targetMenuKey': targetMenuKey,
      'label': label,
      'sortOrder': sortOrder,
    };
  }
}

class MenuTrigger {
  final String? id;
  final String tenantId;
  final String triggerWord;
  final String menuKey;

  MenuTrigger({
    this.id,
    required this.tenantId,
    required this.triggerWord,
    required this.menuKey,
  });

  factory MenuTrigger.fromJson(Map<String, dynamic> json) {
    return MenuTrigger(
      id: json['id']?.toString(),
      tenantId: json['tenantId'] as String,
      triggerWord: json['triggerWord'] as String,
      menuKey: json['menuKey'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'triggerWord': triggerWord,
      'menuKey': menuKey,
    };
  }
}
