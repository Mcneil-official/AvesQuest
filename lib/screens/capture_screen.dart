import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/pending_queue_item.dart';
import '../providers/identification_provider.dart';
import '../providers/pending_queue_provider.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/offline_banner.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  XFile? _pickedFile;
  bool _isSaving = false;

  Future<void> _pickFromSource(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (!mounted) return;
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  Future<void> _confirm() async {
    final file = _pickedFile;
    if (file == null) return;

    setState(() => _isSaving = true);
    final queueProvider = context.read<PendingQueueProvider>();
    final identProvider = context.read<IdentificationProvider>();

    try {
      final permanentPath = await PhotoService.savePhotoToAppDir(file.path);
      final savedItem = await queueProvider.addToQueue(PendingQueueItem(
        photoPath: permanentPath,
        queuedAt: DateTime.now(),
      ));

      final bird = await identProvider.processQueueItem(savedItem);

      if (!mounted) return;

      if (bird != null) {
        Navigator.of(context).pop(bird.id);
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(identProvider.lastResult?.startsWith('error:') == true
              ? identProvider.lastResult!.replaceFirst('error: ', '')
              : 'Could not identify bird — check Journal tab')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: Text(
          'Capture',
          style: AppTypography.titleMd(color: AppColors.onPrimary),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _pickedFile == null ? _buildSourcePicker() : _buildPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePicker() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'How do you want to capture?',
              style: AppTypography.headlineLgMobile(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Snap a photo or pick one from your gallery',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _pickFromSource(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take a Photo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(double.infinity, 60),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _pickFromSource(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Upload from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 60),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.file(
                  File(_pickedFile!.path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _pickedFile = null),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _confirm,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Use This Photo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}