import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inspection_models.dart';
import '../ui/app_theme.dart';

const List<Map<String, String>> kDetectionOptions = [
  {'label': 'All Distress', 'value': 'all'},
  {'label': 'Crack', 'value': 'crack'},
  {'label': 'Wide Crack', 'value': 'wide_crack'},
  {'label': 'Hollow Section', 'value': 'hollow_section'},
  {'label': 'Honeycombing', 'value': 'honeycombing'},
  {'label': 'Spalling', 'value': 'spalling'},
  {'label': 'Scaling', 'value': 'scaling'},
  {'label': 'Steel Corrosion', 'value': 'steel_corrosion'},
  {'label': 'Steel Exposed', 'value': 'exposed_steel'},
  {'label': 'Efflorescence', 'value': 'efflorescence'},
  {'label': 'Pedestal Damage', 'value': 'pedestal_damage'},
  {'label': 'Vegetation Growth', 'value': 'vegetation_growth'},
];

class ImageSourceScreen extends StatefulWidget {
  final BridgeFormData? bridgeData;
  final Function(Uint8List imageBytes, String detectionTarget) onImageSelected;
  final VoidCallback onBack;

  const ImageSourceScreen({
    super.key,
    this.bridgeData,
    required this.onImageSelected,
    required this.onBack,
  });

  @override
  State<ImageSourceScreen> createState() => _ImageSourceScreenState();
}

class _ImageSourceScreenState extends State<ImageSourceScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedDetectionTarget = 'all';
  Uint8List? _previewBytes;
  bool _analyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _previewBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to select image. Please try again.')),
        );
      }
    }
  }

  Future<void> _analyze() async {
    final bytes = _previewBytes;
    if (bytes == null || _analyzing) return;
    setState(() => _analyzing = true);
    widget.onImageSelected(bytes, _selectedDetectionTarget);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.bridgeData != null)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: AppColors.softBlue,
              child: Row(
                children: [
                  const Icon(AppIcons.place, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if (widget.bridgeData!.projectName.isNotEmpty) widget.bridgeData!.projectName,
                        widget.bridgeData!.chainages,
                        if (widget.bridgeData!.bridgeId != null) 'ID ${widget.bridgeData!.bridgeId}',
                        widget.bridgeData!.span,
                      ].where((s) => s.trim().isNotEmpty).join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.bridgeData != null) const SizedBox(height: 14),

          AppSectionCard(
            title: 'IMAGE CAPTURE',
            subtitle: 'Preview the image, then analyze with AI',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _previewBytes == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.image, size: 40, color: AppColors.muted),
                              SizedBox(height: 8),
                              Text('Image preview', style: AppTextStyles.muted),
                            ],
                          ),
                        )
                      : Image.memory(_previewBytes!, fit: BoxFit.contain, width: double.infinity),
                ),
                const SizedBox(height: 16),
                const Text('DETECTION TARGET', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDetectionTarget,
                  items: kDetectionOptions.map((opt) {
                    return DropdownMenuItem(
                      value: opt['value'],
                      child: Text(opt['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDetectionTarget = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _sourceButton(
                        icon: AppIcons.camera,
                        title: 'CAPTURE IMAGE',
                        subtitle: 'Use camera',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sourceButton(
                        icon: AppIcons.gallery,
                        title: 'SELECT FROM GALLERY',
                        subtitle: 'Choose photo',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppGradientButton(
                  label: 'Analyze with AI  →',
                  icon: AppIcons.aiAnalysis,
                  loading: _analyzing,
                  onPressed: _previewBytes == null || _analyzing ? null : _analyze,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(AppIcons.back, size: 16),
                    label: const Text('Back to inspection details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
