import 'package:flutter/material.dart';
import '../models/inspection_models.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../ui/app_theme.dart';

class ReportsDashboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool embedInShell;

  const ReportsDashboardScreen({
    super.key,
    required this.onBack,
    this.embedInShell = false,
  });

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  List<Report> _reports = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final list = await StorageService.getAllReports();
    if (mounted) {
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    }
  }

  List<Report> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _reports;
    return _reports.where((r) {
      final project = r.bridgeData?.projectName ?? '';
      final chainage = r.bridgeData?.chainages ?? r.location;
      final bridge = r.bridgeData?.bridgeId?.toString() ?? r.title;
      return project.toLowerCase().contains(q) ||
          chainage.toLowerCase().contains(q) ||
          bridge.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteOne(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This will remove the saved inspection report from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteReport(report.id);
      _loadReports();
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all reports?'),
        content: const Text('This will delete all saved inspection reports.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllReports();
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 12),
                Text('Loading reports...', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          )
        : _reports.isEmpty
            ? const AppEmptyState(
                title: 'No reports saved yet',
                message: 'Complete an inspection to generate reports.',
                icon: AppIcons.reports,
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search reports...',
                        prefixIcon: Icon(AppIcons.search, color: AppColors.primary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final report = _filtered[index];
                        final project = report.bridgeData?.projectName ?? '—';
                        final chainage = report.bridgeData?.chainages ?? report.location;
                        final bridge = report.bridgeData?.bridgeId != null
                            ? 'Bridge ${report.bridgeData!.bridgeId}'
                            : report.title;
                        final date = report.timestamp.split('.').first;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      bridge,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                                    ),
                                  ),
                                  const AppStatusBadge(label: 'Completed', tone: AppStatusTone.success),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _meta('Project', project),
                              _meta('Chainage', chainage),
                              _meta('Bridge', bridge),
                              _meta('Inspection Date', date),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => PdfService.generateAndDownloadSingleReport(report),
                                      icon: const Icon(AppIcons.view, size: 16),
                                      label: const Text('VIEW'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => PdfService.generateAndDownloadSingleReport(report),
                                      icon: const Icon(AppIcons.export, size: 16),
                                      label: const Text('EXPORT'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _deleteOne(report),
                                    icon: const Icon(AppIcons.delete, color: AppColors.danger),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  ),
                ],
              );

    if (widget.embedInShell) {
      return Column(
        children: [
          if (_reports.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.danger),
                label: const Text('Clear all', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              ),
            ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Inspection Reports'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
              onPressed: _clearAll,
              tooltip: 'Clear All Reports',
            ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _meta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.label)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink))),
        ],
      ),
    );
  }
}
