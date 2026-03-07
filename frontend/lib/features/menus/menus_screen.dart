import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/menu.dart';
import '../../providers/auth_provider.dart';

class MenusScreen extends ConsumerStatefulWidget {
  final String botId;
  final String? tenantId;
  final bool embedded;

  const MenusScreen({super.key, required this.botId, this.tenantId, this.embedded = false});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  List<Menu> _menus = [];
  String? _selectedMenuId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.tenantId != null && widget.tenantId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenus());
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(MenusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tenantId != null && widget.tenantId != oldWidget.tenantId) {
      _loadMenus();
    }
  }

  Future<void> _loadMenus() async {
    final tenantId = widget.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getMenus(tenantId);
      if (mounted) {
        setState(() {
          _menus = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _saveMenu(Menu menu, {bool isNew = false}) async {
    final tenantId = widget.tenantId ?? menu.tenantId;
    if (tenantId.isEmpty) return;
    final menuWithTenant = menu.copyWith(tenantId: tenantId);
    try {
      final api = ref.read(apiServiceProvider);
      if (isNew || menu.id == null || menu.id!.isEmpty) {
        final saved = await api.createMenu(menuWithTenant);
        if (mounted) setState(() => _menus = [..._menus, saved]);
      } else {
        final saved = await api.updateMenu(menuWithTenant);
        if (mounted) {
          setState(() {
            final i = _menus.indexWhere((m) => m.id == saved.id);
            if (i >= 0) _menus = [..._menus]..[i] = saved;
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menú guardado'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error al cargar menús: $_error', style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadMenus, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (widget.tenantId == null || widget.tenantId!.isEmpty) {
      return const Center(child: Text('Selecciona un bot para gestionar sus menús'));
    }

    final Menu? selectedMenu = _selectedMenuId != null
        ? _menus.cast<Menu?>().firstWhere(
            (m) => m?.id == _selectedMenuId,
            orElse: () => null,
          )
        : null;

    final content = Row(
        children: [
          SizedBox(
            width: 300,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Menús',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showMenuDialog(),
                          tooltip: 'Nuevo menú',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _menus.length,
                      itemBuilder: (context, index) {
                        final menu = _menus[index];
                        final isSelected = menu.id == _selectedMenuId;
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: isSelected ? AppTheme.primaryColor : Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            menu.menuKey,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${menu.options.length} opciones',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
                          onTap: () => setState(() => _selectedMenuId = menu.id),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showMenuDialog(menu: menu);
                              } else if (value == 'delete') {
                                _confirmDelete(menu);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedMenu != null
                ? _MenuEditor(
                    menu: selectedMenu,
                    allMenus: _menus,
                    onSave: (updatedMenu) => _saveMenu(updatedMenu),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Selecciona un menú para editarlo',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Menús'),
        actions: [
          TextButton.icon(
            onPressed: _showTriggersDialog,
            icon: const Icon(Icons.bolt),
            label: const Text('Triggers'),
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Menú'),
      ),
    );
  }

  void _showMenuDialog({Menu? menu}) {
    showDialog(
      context: context,
      builder: (context) => _CreateMenuDialog(
        existingMenu: menu,
        onSave: (newMenu) {
          final isNew = menu == null;
          _saveMenu(
            newMenu.copyWith(tenantId: widget.tenantId ?? newMenu.tenantId),
            isNew: isNew,
          );
        },
      ),
    );
  }

  void _showTriggersDialog() {
    if (_menus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea al menos un menú antes de configurar triggers')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _TriggersDialog(menus: _menus),
    );
  }

  void _confirmDelete(Menu menu) {
    final tenantId = widget.tenantId;
    if (tenantId == null || tenantId.isEmpty || menu.id == null || menu.id!.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar menú'),
        content: Text('¿Seguro que quieres eliminar "${menu.menuKey}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(apiServiceProvider).deleteMenu(tenantId, menu.id!);
                if (mounted) {
                  setState(() {
                    _menus.removeWhere((m) => m.id == menu.id);
                    if (_selectedMenuId == menu.id) _selectedMenuId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menú eliminado')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _MenuEditor extends StatefulWidget {
  final Menu menu;
  final List<Menu> allMenus;
  final ValueChanged<Menu> onSave;

  const _MenuEditor({
    required this.menu,
    required this.allMenus,
    required this.onSave,
  });

  @override
  State<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<_MenuEditor> {
  late TextEditingController _textController;
  late List<MenuOption> _options;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.menu.text);
    _options = List.from(widget.menu.options);
  }

  @override
  void didUpdateWidget(_MenuEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menu.id != widget.menu.id) {
      _textController.text = widget.menu.text;
      _options = List.from(widget.menu.options);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menú: ${widget.menu.menuKey}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_options.length} opciones',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Texto del menú',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'El mensaje que verá el usuario...',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Opciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _options.removeAt(oldIndex);
                _options.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final option = _options[index];
              return Card(
                key: ValueKey(option.optionKey + index.toString()),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      option.optionKey,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  title: Text(option.label),
                  subtitle: Text(
                    '→ ${option.targetMenuKey}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editOption(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _options.removeAt(index)),
                      ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _textController.text = widget.menu.text;
                    setState(() => _options = List.from(widget.menu.options));
                  },
                  child: const Text('Descartar cambios'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _PreviewCard(
            text: _textController.text,
            options: _options,
          ),
        ],
      ),
    );
  }

  void _addOption() {
    _showOptionDialog();
  }

  void _editOption(int index) {
    _showOptionDialog(existingOption: _options[index], index: index);
  }

  void _showOptionDialog({MenuOption? existingOption, int? index}) {
    final keyController = TextEditingController(text: existingOption?.optionKey ?? '');
    final labelController = TextEditingController(text: existingOption?.label ?? '');
    String targetMenu = existingOption?.targetMenuKey ?? widget.allMenus.first.menuKey;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingOption != null ? 'Editar Opción' : 'Nueva Opción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Tecla (1, 2, 0, etc.)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Etiqueta',
                hintText: 'Ej: 📅 Ver horarios',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: targetMenu,
              decoration: const InputDecoration(labelText: 'Menú destino'),
              items: widget.allMenus.map((m) {
                return DropdownMenuItem(value: m.menuKey, child: Text(m.menuKey));
              }).toList(),
              onChanged: (v) => targetMenu = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final option = MenuOption(
                optionKey: keyController.text,
                targetMenuKey: targetMenu,
                label: labelController.text,
                sortOrder: index ?? _options.length,
              );
              setState(() {
                if (index != null) {
                  _options[index] = option;
                } else {
                  _options.add(option);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final updatedMenu = widget.menu.copyWith(
      text: _textController.text,
      options: _options,
    );
    widget.onSave(updatedMenu);
  }
}

class _PreviewCard extends StatelessWidget {
  final String text;
  final List<MenuOption> options;

  const _PreviewCard({required this.text, required this.options});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFDCF8C6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Vista previa (WhatsApp)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text),
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...options.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${o.optionKey}. ${o.label}'),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateMenuDialog extends StatefulWidget {
  final Menu? existingMenu;
  final ValueChanged<Menu> onSave;

  const _CreateMenuDialog({this.existingMenu, required this.onSave});

  @override
  State<_CreateMenuDialog> createState() => _CreateMenuDialogState();
}

class _CreateMenuDialogState extends State<_CreateMenuDialog> {
  late TextEditingController _keyController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.existingMenu?.menuKey ?? '');
    _textController = TextEditingController(text: widget.existingMenu?.text ?? '');
  }

  @override
  void dispose() {
    _keyController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingMenu != null ? 'Editar Menú' : 'Nuevo Menú'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: 'Clave del menú',
              hintText: 'Ej: main, servicios, contacto',
            ),
            enabled: widget.existingMenu == null,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Texto del menú',
              hintText: 'El mensaje que verá el usuario...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final menu = Menu(
              id: widget.existingMenu?.id,
              tenantId: widget.existingMenu?.tenantId ?? 'default',
              menuKey: _keyController.text,
              text: _textController.text,
              options: widget.existingMenu?.options ?? [],
            );
            widget.onSave(menu);
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _TriggersDialog extends StatefulWidget {
  final List<Menu> menus;

  const _TriggersDialog({required this.menus});

  @override
  State<_TriggersDialog> createState() => _TriggersDialogState();
}

class _TriggersDialogState extends State<_TriggersDialog> {
  final List<MenuTrigger> _triggers = [
    MenuTrigger(id: '1', tenantId: 'default', triggerWord: 'hola', menuKey: 'main'),
    MenuTrigger(id: '2', tenantId: 'default', triggerWord: 'menu', menuKey: 'main'),
    MenuTrigger(id: '3', tenantId: 'default', triggerWord: 'inicio', menuKey: 'main'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Triggers de Menú'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Palabras que activan menús automáticamente',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...List.generate(_triggers.length, (index) {
              final trigger = _triggers[index];
              return ListTile(
                leading: const Icon(Icons.bolt, color: Colors.orange),
                title: Text('"${trigger.triggerWord}"'),
                subtitle: Text('→ ${trigger.menuKey}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => setState(() => _triggers.removeAt(index)),
                ),
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: AppTheme.primaryColor),
              title: const Text('Agregar trigger'),
              onTap: _addTrigger,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Triggers guardados')),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _addTrigger() {
    final wordController = TextEditingController();
    String selectedMenu = widget.menus.first.menuKey;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Trigger'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordController,
              decoration: const InputDecoration(
                labelText: 'Palabra',
                hintText: 'Ej: hola, ayuda, info',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMenu,
              decoration: const InputDecoration(labelText: 'Menú a activar'),
              items: widget.menus.map((m) {
                return DropdownMenuItem(value: m.menuKey, child: Text(m.menuKey));
              }).toList(),
              onChanged: (v) => selectedMenu = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _triggers.add(MenuTrigger(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  tenantId: 'default',
                  triggerWord: wordController.text,
                  menuKey: selectedMenu,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
