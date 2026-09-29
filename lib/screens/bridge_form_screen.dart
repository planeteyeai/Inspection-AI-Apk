import 'dart:collection';

import 'package:flutter/material.dart';
import '../models/bridge_record.dart';
import '../models/inspection_models.dart';
import '../models/span_arrangement_record.dart';
import '../services/database_service.dart';
import '../ui/app_theme.dart';

/// Temporary TDD/reference master list.
/// No safe unified structural-element master table was found in database_Bms
/// (see implementation notes: structural_form is form typology;
/// non_structural_elements is inspection-scoped; component tables are separate).
const List<String> kTddStructuralElements = [
  'Span',
  'Expansion Joint',
  'Bearing per Pier',
  'Bearing per Abutment',
  'Pedestrals',
  'Abutment',
  'Pier',
  'Pier Cap',
  'Abutmement Foundation',
  'Pier foundation',
  'Approach Slab',
];

class BridgeFormScreen extends StatefulWidget {
  final Function(BridgeFormData) onProceed;

  const BridgeFormScreen({super.key, required this.onProceed});

  @override
  State<BridgeFormScreen> createState() => _BridgeFormScreenState();
}

class _BridgeFormScreenState extends State<BridgeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _elementDescriptionControllers = {};

  final LinkedHashSet<String> _selectedElementNames = LinkedHashSet<String>();
  String? _elementsError;

  List<ProjectRecord> _projects = [];
  List<StructureTypeRecord> _structureTypes = [];
  List<String> _chainages = [];
  List<BridgeRecord> _bridges = [];
  List<SpanArrangementRecord> _spans = [];
  List<String> _superstructureOptions = [];

  ProjectRecord? _selectedProject;
  StructureTypeRecord? _selectedStructureType;
  String? _selectedChainage;
  BridgeRecord? _selectedBridge;
  SpanArrangementRecord? _selectedSpan;
  String? _selectedSuperstructure;
  SuperstructureBridgeInfo? _superstructureBridgeInfo;

  bool _loadingProjects = true;
  bool _loadingStructureTypes = false;
  bool _loadingChainages = false;
  bool _loadingBridges = false;
  bool _loadingSpans = false;
  bool _loadingSuperstructure = false;
  String? _locationError;
  String? _spanError;
  String? _superstructureError;

  // Chainage search controller (search state is managed in _ChainagePickerSheet)
  final TextEditingController _chainageSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadSuperstructureOptions();
  }

  @override
  void dispose() {
    for (final controller in _elementDescriptionControllers.values) {
      controller.dispose();
    }
    _chainageSearchController.dispose();
    super.dispose();
  }

  TextEditingController _descriptionControllerFor(String elementName) {
    return _elementDescriptionControllers.putIfAbsent(
      elementName,
      () => TextEditingController(),
    );
  }

  void _toggleStructuralElement(String elementName) {
    setState(() {
      _elementsError = null;
      if (_selectedElementNames.contains(elementName)) {
        _selectedElementNames.remove(elementName);
      } else {
        _selectedElementNames.add(elementName);
        _descriptionControllerFor(elementName);
      }
    });
  }

  List<ElementFormData> _buildSelectedElements() {
    return _selectedElementNames.map((name) {
      return ElementFormData(
        elementName: name,
        description: _elementDescriptionControllers[name]?.text.trim() ?? '',
      );
    }).toList();
  }

  void _clearBridgeDependentState() {
    _selectedBridge = null;
    _bridges = [];
    _clearSpanSuperstructureState();
  }

  void _clearChainageAndBelowState() {
    _selectedChainage = null;
    _chainages = [];
    _chainageSearchController.clear();
    _clearBridgeDependentState();
  }

  void _clearStructureTypeAndBelowState() {
    _selectedStructureType = null;
    _structureTypes = [];
    _clearChainageAndBelowState();
  }

  void _clearSpanSuperstructureState() {
    _spans = [];
    _selectedSpan = null;
    _superstructureBridgeInfo = null;
    _selectedSuperstructure = null;
    _spanError = null;
    _superstructureError = null;
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loadingProjects = true;
      _locationError = null;
    });
    try {
      final projects = await DatabaseService.getProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _loadingProjects = false;
        if (projects.isEmpty) {
          _locationError = 'No projects found in the database.';
        }
      });
    } on AuthConnectionException {
      if (!mounted) return;
      setState(() {
        _loadingProjects = false;
        _locationError = 'Unable to load projects. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProjects = false;
        _locationError = 'Unable to load projects. Please try again.';
      });
    }
  }

  Future<void> _loadStructureTypes(String projectName) async {
    setState(() {
      _loadingStructureTypes = true;
      _locationError = null;
    });
    try {
      final types = await DatabaseService.getStructureTypesForProject(
        projectName,
      );
      if (!mounted) return;
      setState(() {
        _structureTypes = types;
        _loadingStructureTypes = false;
        if (types.isEmpty) {
          _locationError = 'No structure types available for this project.';
        }
      });
    } on AuthConnectionException {
      if (!mounted) return;
      setState(() {
        _loadingStructureTypes = false;
        _locationError = 'Unable to load structure types. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingStructureTypes = false;
        _locationError = 'Unable to load structure types. Please try again.';
      });
    }
  }

  Future<void> _loadSuperstructureOptions() async {
    setState(() {
      _loadingSuperstructure = true;
      _superstructureError = null;
    });
    try {
      final options = await DatabaseService.getSuperstructureTypeOptions();
      if (!mounted) return;
      setState(() {
        _superstructureOptions = options;
        _loadingSuperstructure = false;
        if (options.isEmpty) {
          _superstructureError =
              'No superstructure type options found in the database.';
        }
      });
    } on AuthConnectionException {
      if (!mounted) return;
      setState(() {
        _loadingSuperstructure = false;
        _superstructureError =
            'Unable to load superstructure options. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSuperstructure = false;
        _superstructureError =
            'Unable to load superstructure options. Please try again.';
      });
    }
  }

  Future<void> _onProjectChanged(ProjectRecord? project) async {
    setState(() {
      _selectedProject = project;
      _locationError = null;
      _clearStructureTypeAndBelowState();
    });

    if (project == null || project.databaseName.isEmpty) return;

    await _loadStructureTypes(project.databaseName);
  }

  Future<void> _onStructureTypeChanged(
    StructureTypeRecord? structureType,
  ) async {
    setState(() {
      _selectedStructureType = structureType;
      _locationError = null;
      _clearChainageAndBelowState();
    });

    if (_selectedProject == null || structureType == null) return;

    setState(() => _loadingChainages = true);
    try {
      final chainages =
          await DatabaseService.getChainagesForProjectAndStructureType(
            _selectedProject!.databaseName,
            structureType.code,
          );
      if (!mounted) return;
      setState(() {
        _chainages = chainages;
        _loadingChainages = false;
        if (chainages.isEmpty) {
          _locationError =
              'No chainages found for this project and structure type.';
        }
      });
    } on AuthConnectionException {
      if (!mounted) return;
      setState(() {
        _loadingChainages = false;
        _locationError = 'Unable to load chainages. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingChainages = false;
        _locationError = 'Unable to load chainages. Please try again.';
      });
    }
  }

  Future<void> _onChainageChanged(String? chainage) async {
    setState(() {
      _selectedChainage = chainage;
      _locationError = null;
      _clearBridgeDependentState();
    });

    if (_selectedProject == null ||
        _selectedStructureType == null ||
        chainage == null ||
        chainage.isEmpty)
      return;

    setState(() => _loadingBridges = true);
    try {
      final bridges =
          await DatabaseService.getBridgesForProjectStructureTypeAndChainage(
            _selectedProject!.databaseName,
            _selectedStructureType!.code,
            chainage,
          );
      if (!mounted) return;

      BridgeRecord? autoSelected;
      if (bridges.length == 1) {
        autoSelected = bridges.first;
      }

      setState(() {
        _bridges = bridges;
        _loadingBridges = false;
        if (bridges.isEmpty) {
          _locationError =
              'No bridge records found for this project, structure type and chainage.';
          _selectedBridge = null;
        } else {
          _selectedBridge = autoSelected;
        }
      });

      if (autoSelected != null) {
        await _loadBridgeDependentData(autoSelected.bridgeId);
      }
    } on AuthConnectionException {
      if (!mounted) return;
      setState(() {
        _loadingBridges = false;
        _locationError = 'Unable to load bridge records. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingBridges = false;
        _locationError = 'Unable to load bridge records. Please try again.';
      });
    }
  }

  Future<void> _onBridgeChanged(BridgeRecord? bridge) async {
    setState(() {
      _selectedBridge = bridge;
      _locationError = null;
      _clearSpanSuperstructureState();
    });
    if (bridge != null) {
      await _loadBridgeDependentData(bridge.bridgeId);
    }
  }

  Future<void> _loadBridgeDependentData(int bridgeId) async {
    setState(() {
      _loadingSpans = true;
      _spanError = null;
      _superstructureError = null;
    });

    List<SpanArrangementRecord> spans = [];
    SuperstructureBridgeInfo? info;
    String? spanErr;
    String? superErr;

    try {
      spans = await DatabaseService.getSpanArrangementsForBridge(bridgeId);
    } on AuthConnectionException {
      spanErr = 'Unable to load span data. Please try again.';
    } catch (_) {
      spanErr = 'Unable to load span data. Please try again.';
    }

    try {
      info = await DatabaseService.getSuperstructureBridgeInfo(bridgeId);
    } on AuthConnectionException {
      superErr =
          'Unable to load bridge superstructure flags. Please try again.';
    } catch (_) {
      superErr =
          'Unable to load bridge superstructure flags. Please try again.';
    }

    if (!mounted) return;

    SpanArrangementRecord? selectedSpan;
    String? selectedSuperstructure = _selectedSuperstructure;

    if (spans.isEmpty) {
      selectedSpan = null;
    } else if (spans.length == 1) {
      selectedSpan = spans.first;
      selectedSuperstructure = _resolveSuperstructureForSpan(
        selectedSpan,
        selectedSuperstructure,
      );
    }

    setState(() {
      _spans = spans;
      _selectedSpan = selectedSpan;
      _superstructureBridgeInfo = info;
      _selectedSuperstructure = selectedSuperstructure;
      _loadingSpans = false;
      _spanError =
          spanErr ??
          (spans.isEmpty
              ? 'No span arrangement records found for this bridge.'
              : null);
      if (superErr != null) {
        _superstructureError = superErr;
      }
    });
  }

  String? _resolveSuperstructureForSpan(
    SpanArrangementRecord span,
    String? current,
  ) {
    final suggested = span.suggestedSuperstructureLabel;
    if (suggested == null) return current;

    // Prefer an exact master option match when available.
    final exact = _superstructureOptions.where((o) => o == suggested).toList();
    if (exact.isNotEmpty) return exact.first;

    final containsType = (span.spanType ?? '').trim();
    if (containsType.isNotEmpty) {
      final partial = _superstructureOptions
          .where((o) => o.toLowerCase().contains(containsType.toLowerCase()))
          .toList();
      if (partial.isNotEmpty) return partial.first;
    }

    // Span-derived label is still usable via _effectiveSuperstructureOptions.
    return suggested;
  }

  void _onSpanChanged(SpanArrangementRecord? span) {
    setState(() {
      _selectedSpan = span;
      _spanError = null;
      if (span != null) {
        _selectedSuperstructure = _resolveSuperstructureForSpan(
          span,
          _selectedSuperstructure,
        );
      }
    });
  }

  void _handleSubmit() {
    if (_selectedProject == null || _selectedProject!.databaseName.isEmpty) {
      setState(() => _locationError = 'Please select a project.');
      return;
    }
    if (_selectedStructureType == null) {
      setState(() => _locationError = 'Please select a structure type.');
      return;
    }
    if (_selectedChainage == null || _selectedChainage!.isEmpty) {
      setState(() => _locationError = 'Please select a chainage.');
      return;
    }
    if (_selectedBridge == null) {
      setState(
        () => _locationError = _bridges.length > 1
            ? 'Please select the correct bridge record.'
            : 'Please wait for bridge selection to complete.',
      );
      return;
    }
    if (_selectedSpan == null) {
      setState(
        () => _spanError = _spans.isEmpty
            ? 'No span arrangement records found for this bridge.'
            : 'Please select a span.',
      );
      return;
    }
    if (_selectedSuperstructure == null ||
        _selectedSuperstructure!.trim().isEmpty) {
      setState(
        () => _superstructureError = 'Please select Type of Superstructure.',
      );
      return;
    }
    if (_selectedElementNames.isEmpty) {
      setState(
        () => _elementsError = 'Please select at least one structural element.',
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final bridge = _selectedBridge!;
      final span = _selectedSpan!;
      final data = BridgeFormData(
        projectName: _selectedProject!.databaseName,
        chainages: _selectedChainage!,
        bridgeId: bridge.bridgeId,
        bridgeNo: bridge.bridgeNo,
        bridgeSide: bridge.bridgeSide,
        bridgeType: bridge.typeOfBridge,
        totalNoOfSpan: _spans.isNotEmpty ? _spans.length : bridge.totalNoOfSpan,
        spId: span.spId,
        spanMaterial: span.spanMaterial,
        spanType: span.spanType,
        spanLength: span.spanLength,
        span: span.label,
        typeOfSuperstructure: _selectedSuperstructure!,
        rcPscMembers: _superstructureBridgeInfo
            ?.reinforcedConcreteAndPrestressedConcreteMembers,
        steelMembers: _superstructureBridgeInfo?.checkSteelMembers,
        elements: _buildSelectedElements(),
      );
      widget.onProceed(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridgeSelected = _selectedBridge != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionCard(
              title: 'BRIDGE INFORMATION',
              subtitle: 'Project, chainage, bridge, and span',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('PROJECT', required: true),
                  if (_loadingProjects)
                    _loadingIndicator()
                  else
                    _buildDropdown<ProjectRecord>(
                      value: _selectedProject,
                      hint: 'Select Project',
                      items: _projects,
                      itemLabel: (p) => p.displayName,
                      onChanged: _onProjectChanged,
                    ),
                  const SizedBox(height: 16),

                  _buildLabel('STRUCTURE TYPE', required: true),
                  if (_loadingStructureTypes)
                    _loadingIndicator()
                  else
                    _buildDropdown<StructureTypeRecord>(
                      value: _selectedStructureType,
                      hint: _selectedProject == null
                          ? 'Select a project first'
                          : _structureTypes.isEmpty
                          ? 'No structure types available'
                          : 'Select Structure Type',
                      items: _structureTypes,
                      itemLabel: (t) => t.name,
                      enabled:
                          _selectedProject != null &&
                          !_loadingStructureTypes &&
                          _structureTypes.isNotEmpty,
                      onChanged: _selectedProject == null
                          ? null
                          : _onStructureTypeChanged,
                    ),
                  if (_selectedProject != null &&
                      !_loadingStructureTypes &&
                      _structureTypes.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No structure types available for this project.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  _buildLabel('CHAINAGE', required: true),
                  if (_loadingChainages)
                    _loadingIndicator()
                  else
                    _buildChainageSelector(),
                  if (_selectedStructureType != null &&
                      !_loadingChainages &&
                      _chainages.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No chainages available for this structure type.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (_loadingBridges)
                    _loadingIndicator()
                  else if (_bridges.length > 1) ...[
                    _buildLabel('BRIDGE', required: true),
                    _buildDropdown<BridgeRecord>(
                      value: _selectedBridge,
                      hint: 'Select Bridge',
                      items: _bridges,
                      itemLabel: (b) => b.displayLabel,
                      onChanged: _onBridgeChanged,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedBridge != null) ...[
                    _buildBridgeSummary(_selectedBridge!),
                    const SizedBox(height: 16),
                  ],

                  if (_locationError != null) ...[
                    Text(
                      _locationError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  _buildLabel('SPAN', required: true),
                  if (!bridgeSelected)
                    _buildDropdown<String>(
                      value: null,
                      hint: 'Select a bridge first',
                      items: const [],
                      itemLabel: (s) => s,
                      enabled: false,
                      onChanged: null,
                    )
                  else if (_loadingSpans)
                    _loadingIndicator()
                  else if (_spans.isEmpty)
                    Text(
                      _spanError ??
                          'No span arrangement records found for this bridge.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    )
                  else ...[
                    _buildDropdown<SpanArrangementRecord>(
                      value: _selectedSpan,
                      hint: 'Select Span',
                      items: _spans,
                      itemLabel: (s) => s.label,
                      onChanged: _onSpanChanged,
                    ),
                    if (_selectedSpan != null) ...[
                      const SizedBox(height: 10),
                      _buildSpanDetails(_selectedSpan!),
                    ],
                  ],
                  if (_spanError != null && _spans.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _spanError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  const SizedBox(height: 8),
                  const Text(
                    'SUPERSTRUCTURE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLabel('TYPE OF SUPERSTRUCTURE', required: true),
                  if (_loadingSuperstructure && _superstructureOptions.isEmpty)
                    _loadingIndicator()
                  else
                    _buildDropdown<String>(
                      value:
                          _selectedSuperstructure != null &&
                              _effectiveSuperstructureOptions.contains(
                                _selectedSuperstructure,
                              )
                          ? _selectedSuperstructure
                          : null,
                      hint: bridgeSelected
                          ? 'Select Type of Superstructure'
                          : 'Select a bridge first',
                      items: _effectiveSuperstructureOptions,
                      itemLabel: (s) => s,
                      enabled:
                          bridgeSelected &&
                          _effectiveSuperstructureOptions.isNotEmpty,
                      onChanged: bridgeSelected
                          ? (val) => setState(() {
                              _selectedSuperstructure = val;
                              _superstructureError = null;
                            })
                          : null,
                    ),
                  if (_superstructureBridgeInfo != null) ...[
                    const SizedBox(height: 10),
                    _buildSuperstructureBridgeInfo(_superstructureBridgeInfo!),
                  ],
                  if (_superstructureError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _superstructureError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            AppSectionCard(
              title: 'STRUCTURAL ELEMENTS',
              subtitle: 'Select elements and add descriptions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kTddStructuralElements.map((name) {
                      final selected = _selectedElementNames.contains(name);
                      return FilterChip(
                        label: Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.ink,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) => _toggleStructuralElement(name),
                        selectedColor: AppColors.lightCyan,
                        checkmarkColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedElementNames.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'SELECTED ELEMENTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedElementNames.map((name) {
                        return InputChip(
                          label: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          onDeleted: () => _toggleStructuralElement(name),
                          deleteIconColor: AppColors.muted,
                          backgroundColor: AppColors.lightCyan,
                          side: const BorderSide(color: AppColors.primary),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ..._selectedElementNames.map((name) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  AppIcons.checkFilled,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionControllerFor(name),
                              maxLines: 3,
                              minLines: 2,
                              decoration: _inputDecoration(
                                hint: 'Description for $name',
                              ),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      'No structural elements selected yet.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (_elementsError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _elementsError!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppGradientButton(
              onPressed: _handleSubmit,
              icon: AppIcons.next,
              label: 'Next  →',
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _effectiveSuperstructureOptions {
    final options = List<String>.from(_superstructureOptions);
    final suggested = _selectedSpan?.suggestedSuperstructureLabel;
    if (suggested != null &&
        suggested.isNotEmpty &&
        !options.contains(suggested)) {
      options.add(suggested);
    }
    return options;
  }

  Widget _loadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Chainage selector with live search in a bottom sheet.
  Widget _buildChainageSelector() {
    final enabled =
        _selectedStructureType != null &&
        !_loadingChainages &&
        _chainages.isNotEmpty;
    final hint = _selectedProject == null
        ? 'Select a project first'
        : _selectedStructureType == null
        ? 'Select a structure type first'
        : _chainages.isEmpty
        ? 'No chainages available'
        : 'Select Chainage';

    return GestureDetector(
      onTap: enabled
          ? () async {
              // Reset search query each time dialog opens
              _chainageSearchController.clear();
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) {
                  return _ChainagePickerSheet(
                    chainages: _chainages,
                    selectedChainage: _selectedChainage,
                    searchController: _chainageSearchController,
                  );
                },
              );
              if (result != null) {
                await _onChainageChanged(result);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedChainage ?? hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _selectedChainage != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _selectedChainage != null
                      ? Colors.black87
                      : Colors.grey.shade500,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildSpanDetails(SpanArrangementRecord span) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPAN DETAILS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _summaryLine('Span', span.shortLabel),
          _summaryLine('sp_id', '${span.spId}'),
          _summaryLine(
            'Type',
            (span.spanType ?? '').isEmpty ? 'N/A' : span.spanType!,
          ),
          _summaryLine(
            'Material',
            (span.spanMaterial ?? '').isEmpty ? 'N/A' : span.spanMaterial!,
          ),
          _summaryLine(
            'Length',
            (span.spanLength ?? '').isEmpty ? 'N/A' : span.spanLength!,
          ),
        ],
      ),
    );
  }

  Widget _buildSuperstructureBridgeInfo(SuperstructureBridgeInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BRIDGE SUPERSTRUCTURE FLAGS (DB)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.teal.shade800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _summaryLine(
            'RC/PSC',
            info.reinforcedConcreteAndPrestressedConcreteMembers ?? 'N/A',
          ),
          _summaryLine('Steel', info.checkSteelMembers ?? 'N/A'),
          _summaryLine('Status', info.status ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildBridgeSummary(BridgeRecord bridge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BRIDGE INFORMATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _summaryLine(
            'Bridge No',
            (bridge.bridgeNo ?? '').isEmpty ? 'N/A' : bridge.bridgeNo!,
          ),
          _summaryLine(
            'Type',
            (bridge.typeOfBridge ?? '').isEmpty ? 'N/A' : bridge.typeOfBridge!,
          ),
          _summaryLine(
            'Side',
            (bridge.bridgeSide ?? '').isEmpty ? 'N/A' : bridge.bridgeSide!,
          ),
          _summaryLine(
            'Spans',
            _spans.isNotEmpty
                ? '${_spans.length}'
                : (bridge.totalNoOfSpan?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    T? effectiveValue;
    if (value != null && items.contains(value)) {
      effectiveValue = value;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: effectiveValue,
          isExpanded: true,
          hint: Text(
            hint,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade700,
              letterSpacing: 0.8,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

/// Bottom sheet widget for chainage selection with live search.
class _ChainagePickerSheet extends StatefulWidget {
  final List<String> chainages;
  final String? selectedChainage;
  final TextEditingController searchController;

  const _ChainagePickerSheet({
    required this.chainages,
    required this.selectedChainage,
    required this.searchController,
  });

  @override
  State<_ChainagePickerSheet> createState() => _ChainagePickerSheetState();
}

class _ChainagePickerSheetState extends State<_ChainagePickerSheet> {
  late List<String> _filtered;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = widget.chainages;
    widget.searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearch);
    super.dispose();
  }

  void _onSearch() {
    final q = widget.searchController.text.trim().toLowerCase();
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? widget.chainages
          : widget.chainages.where((c) => c.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'SELECT CHAINAGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.chainages.length} available',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: widget.searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search chainage...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              widget.searchController.clear();
                            },
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Results
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No matching chainage found.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final chainage = _filtered[index];
                          final isSelected =
                              chainage == widget.selectedChainage;
                          return ListTile(
                            title: Text(
                              chainage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 18,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(chainage),
                          );
                        },
                      ),
              ),
              SizedBox(height: bottomPadding + 8),
            ],
          ),
        );
      },
    );
  }
}
