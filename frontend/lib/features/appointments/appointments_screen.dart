import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  final String botId;
  final String tenantId;
  final bool embedded;

  const AppointmentsScreen({
    super.key,
    required this.botId,
    required this.tenantId,
    this.embedded = false,
  });

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  List<Service> _services = [];
  bool _loading = true;
  String? _error;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 30));
  /// Si es false, el backend no devuelve citas canceladas (desde el chat se marcan `cancelled`).
  bool _includeCancelled = false;

  static String _dateToStr(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final fromStr = _dateToStr(_from);
      final toStr = _dateToStr(_to);
      final list = await api.getAppointments(
        widget.tenantId,
        from: fromStr,
        to: toStr,
        includeCancelled: _includeCancelled,
      );
      List<Service> svc = [];
      try {
        svc = await api.getServices(widget.tenantId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _appointments = list;
          _services = svc;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _addAppointment() async {
    final nameController = TextEditingController();
    final docController = TextEditingController();
    final timeController = TextEditingController(text: '09:00');
    final serviceNameController = TextEditingController();
    String? selectedService = _services.isNotEmpty ? _services.first.name : null;
    DateTime date = DateTime.now();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva cita'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del cliente',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: docController,
                    decoration: const InputDecoration(
                      labelText: 'Documento (cédula / DNI)',
                      hintText: 'Obligatorio para expediente del usuario',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_services.isEmpty)
                    TextField(
                      controller: serviceNameController,
                      decoration: const InputDecoration(
                        labelText: 'Servicio',
                        hintText: 'Nombre del servicio',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedService,
                      decoration: const InputDecoration(labelText: 'Servicio'),
                      items: _services
                          .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedService = v),
                    ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Fecha'),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      hintText: '09:00',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre requerido')),
                  );
                  return;
                }
                if (docController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documento es obligatorio para el expediente del usuario')),
                  );
                  return;
                }
                final serviceName = _services.isEmpty
                    ? serviceNameController.text.trim()
                    : (selectedService ?? '');
                if (serviceName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Indica el servicio')),
                  );
                  return;
                }
                final time = timeController.text.trim().isEmpty ? '09:00' : timeController.text.trim();
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.createAppointment(widget.tenantId, {
                    'customerName': nameController.text.trim(),
                    'customerDocument': docController.text.trim(),
                    'serviceName': serviceName,
                    'appointmentDate': _dateToStr(date),
                    'appointmentTime': time,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cita creada'), backgroundColor: AppTheme.successColor),
                    );
                    _load();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
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
            Text('Error: $_error', style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agenda de citas',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Ver citas por rango de fechas y agregar citas manualmente',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final from = await showDatePicker(
                                context: context,
                                initialDate: _from,
                                firstDate: DateTime(2020),
                                lastDate: _to,
                              );
                              if (from != null) setState(() => _from = from);
                              if (mounted) _load();
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text('${_from.day}/${_from.month}/${_from.year}'),
                          ),
                          const Text(' – '),
                          TextButton.icon(
                            onPressed: () async {
                              final to = await showDatePicker(
                                context: context,
                                initialDate: _to,
                                firstDate: _from,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (to != null) setState(() => _to = to);
                              if (mounted) _load();
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text('${_to.day}/${_to.month}/${_to.year}'),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addAppointment,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar cita'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: const Text('Ver canceladas'),
                      selected: _includeCancelled,
                      onSelected: (v) {
                        setState(() => _includeCancelled = v);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _appointments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = _appointments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: Colors.indigo),
                        ),
                        title: Text(a.customerName),
                        subtitle: Text(
                          '${a.serviceName} · ${a.appointmentDate} ${a.appointmentTime}',
                        ),
                        trailing: Chip(
                          label: Text(a.status),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: a.status.toLowerCase() == 'cancelled'
                              ? Colors.grey.shade300
                              : Colors.green.shade100,
                        ),
                      );
                    },
                  ),
                  if (_appointments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No hay citas en el rango seleccionado.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Citas')),
      body: content,
    );
  }
}
