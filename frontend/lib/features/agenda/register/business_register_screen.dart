import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import 'business_registration_model.dart';
import 'konecta_tokens.dart';
import 'register_success_screen.dart';
import 'steps/step_category.dart';
import 'steps/step_department.dart';
import 'steps/step_description.dart';
import 'steps/step_locality.dart';
import 'steps/step_name.dart';
import 'widgets/agenda_showcase_panel.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/top_bar.dart';

const _kDraftKey = 'agenda_business_reg_draft';
const _kTotalSteps = 5;

class BusinessRegisterScreen extends ConsumerStatefulWidget {
  const BusinessRegisterScreen({super.key});

  @override
  ConsumerState<BusinessRegisterScreen> createState() =>
      _BusinessRegisterScreenState();
}

class _BusinessRegisterScreenState
    extends ConsumerState<BusinessRegisterScreen> {
  final _reg = BusinessRegistration();
  int _step = 0;
  bool _loading = false;
  String? _error;
  bool _showValidationError = false;
  late final ValueNotifier<bool> _canContinueNotifier;

  bool get _canContinue {
    switch (_step) {
      case 0:
        return (_reg.name?.trim().length ?? 0) >= 2;
      case 1:
        return _reg.department != null;
      case 2:
        return _reg.locality?.trim().isNotEmpty == true;
      default:
        return true;
    }
  }

  // Steps 0, 1, 2 are required (no skip)
  bool get _isRequired => _step < 3;

  @override
  void initState() {
    super.initState();
    _canContinueNotifier = ValueNotifier<bool>(_canContinue);
    _loadDraft();
  }

  @override
  void dispose() {
    _canContinueNotifier.dispose();
    super.dispose();
  }

  // ── Draft ────────────────────────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDraftKey);
    if (raw == null || !mounted) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final hasData = map['name'] != null ||
          map['department'] != null ||
          map['locality'] != null;
      if (!hasData) return;

      _showDraftSheet(map);
    } catch (_) {
      // Malformed draft — ignore
    }
  }

  void _showDraftSheet(Map<String, dynamic> map) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: KTokens.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: KTokens.border,
                      borderRadius:
                          BorderRadius.circular(KTokens.rPill),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tenés un registro a medias',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Podés continuar desde donde dejaste o empezar de cero.',
                  style: KTokens.tHint,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _clearDraft();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: KTokens.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(KTokens.rMd),
                          ),
                          foregroundColor: KTokens.inkMuted,
                        ),
                        child: Text('Empezar de nuevo',
                            style: KTokens.tCta
                                .copyWith(color: KTokens.inkMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _restoreFromMap(map);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KTokens.ink,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(KTokens.rMd),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Continuar',
                            style: KTokens.tCta
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  void _restoreFromMap(Map<String, dynamic> map) {
    setState(() {
      _reg.name = map['name'] as String?;
      _reg.department = map['department'] as String?;
      _reg.locality = map['locality'] as String?;
      _reg.streetAddress = map['streetAddress'] as String?;
      _reg.description = map['description'] as String?;
      if (_reg.locality?.isNotEmpty == true) {
        _step = 2;
      } else if (_reg.department != null) {
        _step = 1;
      }
    });
    _canContinueNotifier.value = _canContinue;
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftKey, jsonEncode(_reg.toJson()));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _back() {
    if (_step > 0) {
      setState(() {
        _step--;
        _showValidationError = false;
      });
      _canContinueNotifier.value = _canContinue;
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/agenda');
      }
    }
  }

  void _skip() {
    if (_step < _kTotalSteps - 1) {
      setState(() {
        _step++;
        _showValidationError = false;
      });
      _canContinueNotifier.value = _canContinue;
      HapticFeedback.lightImpact();
      _saveDraft();
    }
  }

  void _tryNext() {
    if (!_canContinue) {
      setState(() => _showValidationError = true);
      return;
    }
    if (_step < _kTotalSteps - 1) {
      setState(() {
        _step++;
        _showValidationError = false;
      });
      _canContinueNotifier.value = _canContinue;
      HapticFeedback.lightImpact();
      _saveDraft();
    } else {
      _submit();
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userState = await ref.read(agendaUserProvider.future);
      final tenantId = userState.tenantId;
      if (tenantId == null) {
        setState(() => _error = 'No encontramos tu cuenta');
        return;
      }

      final api = ref.read(agendaApiServiceProvider);

      final tags = <String>[
        if (_reg.department != null) _reg.department!,
        if (_reg.locality?.isNotEmpty == true) _reg.locality!,
        ..._reg.categories.map((c) => c.nombre),
      ];

      final locationParts = [
        if (_reg.department != null) _reg.department!,
        if (_reg.locality?.isNotEmpty == true) _reg.locality!,
        if (_reg.streetAddress?.isNotEmpty == true) _reg.streetAddress!,
      ].where((s) => s.isNotEmpty).join(', ');

      final parts = <String>[
        if (_reg.description?.isNotEmpty == true) _reg.description!,
        if (locationParts.isNotEmpty) '📍 $locationParts',
      ];
      final descripcion = parts.join('\n');

      final business = await api.createBusiness(
        tenantId: tenantId,
        nombre: _reg.name!.trim(),
        descripcion: descripcion.isEmpty ? null : descripcion,
        searchTags: tags,
      );

      if (_reg.categories.isNotEmpty) {
        await api.associateCategories(
          tenantId: tenantId,
          businessId: business.id,
          categoryIds: _reg.categories.map((c) => c.id).toList(),
        );
      }

      await _clearDraft();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegisterSuccessScreen(tenantId: tenantId),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return StepName(
          key: const ValueKey(0),
          value: _reg.name ?? '',
          onChanged: (v) {
            _reg.name = v;
            _canContinueNotifier.value = v.trim().length >= 2;
          },
          onSubmitted: _tryNext,
          showError: _showValidationError && _step == 0,
        );
      case 1:
        return StepDepartment(
          key: const ValueKey(1),
          value: _reg.department,
          onChanged: (v) {
            _reg.department = v;
            _canContinueNotifier.value = v != null;
          },
          onSubmitted: _tryNext,
          showError: _showValidationError && _step == 1,
          summaryName: _reg.name,
        );
      case 2:
        return StepLocality(
          key: const ValueKey(2),
          department: _reg.department,
          value: _reg.locality ?? '',
          onChanged: (v) {
            _reg.locality = v;
            _canContinueNotifier.value = v.trim().isNotEmpty;
          },
          streetAddress: _reg.streetAddress ?? '',
          onStreetChanged: (v) => _reg.streetAddress = v,
          onSubmitted: _tryNext,
          showError: _showValidationError && _step == 2,
          summaryName: _reg.name,
          summaryDepartment: _reg.department,
        );
      case 3:
        return StepCategory(
          key: const ValueKey(3),
          value: _reg.categories,
          onChanged: (v) => setState(() => _reg.categories = v),
          summaryName: _reg.name,
          summaryDepartment: _reg.department,
          summaryLocality: _reg.locality,
        );
      case 4:
        return StepDescription(
          key: const ValueKey(4),
          value: _reg.description ?? '',
          onChanged: (v) => _reg.description = v,
          summaryName: _reg.name,
          summaryDepartment: _reg.department,
          summaryLocality: _reg.locality,
          summaryCategory: _reg.categories.isEmpty
              ? null
              : _reg.categories.map((c) => c.nombre).join(', '),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: KTokens.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(KTokens.rSm),
          border:
              Border.all(color: KTokens.errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: KTokens.errorColor, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: KTokens.tError)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        // Mobile-only bottom bar (desktop builds its own inside ConstrainedBox)
        final mobileBottomBar = ValueListenableBuilder<bool>(
          valueListenable: _canContinueNotifier,
          builder: (_, canCont, __) => BottomBar(
            onSkip: _isRequired ? null : _skip,
            onNext: _tryNext,
            canContinue: canCont,
            isLast: _step == _kTotalSteps - 1,
          ),
        );

        final stepBody = SafeArea(
          bottom: false,
          child: Column(
            children: [
              TopBar(
                step: _step,
                total: _kTotalSteps,
                onBack: _back,
                showBrand: isDesktop,
              ),
              if (_error != null) _buildErrorBanner(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: _buildCurrentStep(),
                      ),
              ),
            ],
          ),
        );

        if (isDesktop) {
          final desktopStep = _loading
              ? const Center(child: CircularProgressIndicator())
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _buildCurrentStep(),
                );

          return Scaffold(
            backgroundColor: KTokens.bg,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Full-width top bar: progress bar sits above the
                  //    showcase card thanks to Spacer pushing it right.
                  TopBar(
                    step: _step,
                    total: _kTotalSteps,
                    onBack: _back,
                    showBrand: true,
                  ),
                  if (_error != null) _buildErrorBanner(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Left: form, right-aligned in 576px ──────────
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 576),
                              child: Column(
                                children: [
                                  Expanded(child: desktopStep),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _canContinueNotifier,
                                    builder: (_, canCont, __) => BottomBar(
                                      onSkip: _isRequired ? null : _skip,
                                      onNext: _tryNext,
                                      canContinue: canCont,
                                      isLast: _step == _kTotalSteps - 1,
                                    ),
                                  ),
                                  const SizedBox(height: 56),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // ── Right: showcase card ─────────────────────────
                        const Expanded(child: AgendaShowcasePanel()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: KTokens.bg,
          body: stepBody,
          bottomNavigationBar: mobileBottomBar,
        );
      },
    );
  }
}
