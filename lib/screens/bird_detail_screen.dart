import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as share;

import '../data/rarity_table.dart';
import '../models/bird.dart';
import '../providers/bird_provider.dart';
import '../repositories/bird_repository.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/game_background.dart';
import '../widgets/oriented_image.dart';
import '../widgets/rarity_badge.dart';

({Color border, Color glow, double width}) _rarityBorder(Rarity rarity) {
  return switch (rarity) {
    Rarity.common => (
      border: AppColors.outlineVariant,
      glow: Colors.transparent,
      width: 1.0,
    ),
    Rarity.uncommon => (
      border: AppColors.primaryContainer.withValues(alpha: 0.6),
      glow: AppColors.primaryContainer.withValues(alpha: 0.15),
      width: 1.5,
    ),
    Rarity.rare => (
      border: AppColors.rarityRare.withValues(alpha: 0.6),
      glow: AppColors.rarityRare.withValues(alpha: 0.2),
      width: 1.5,
    ),
    Rarity.legendary => (
      border: AppColors.rarityLegendary,
      glow: AppColors.rarityLegendary.withValues(alpha: 0.3),
      width: 2.0,
    ),
  };
}

class BirdDetailScreen extends StatefulWidget {
  const BirdDetailScreen({
    super.key,
    required this.bird,
    this.cardIndex = 0,
    this.totalCount = 0,
  });

  final Bird bird;
  final int cardIndex;
  final int totalCount;

  @override
  State<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends State<BirdDetailScreen> {
  late Bird _bird;
  bool _isReidentifying = false;

  @override
  void initState() {
    super.initState();
    _bird = widget.bird;
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this bird?'),
        content: const Text(
          'This will permanently remove it from your collection, including the photo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<BirdProvider>().deleteBird(_bird.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _reidentify() async {
    setState(() => _isReidentifying = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final aiService = AiService(
        proxyUrl: const String.fromEnvironment(
          'BIRDDEX_PROXY_URL',
          defaultValue: 'https://birddex-proxy.birddex.workers.dev',
        ),
      );

      final result = await aiService.identifyPhoto(_bird.photoPath);

      if (!mounted) return;

      if (result.errorMessage != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
        setState(() => _isReidentifying = false);
        return;
      }

      if (result.isNotABird) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No bird detected in this photo')),
        );
        setState(() => _isReidentifying = false);
        return;
      }

      if (result.isUnclear) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Unclear photo — try a different image')),
        );
        setState(() => _isReidentifying = false);
        return;
      }

      final speciesName = result.commonName ?? 'Unknown Bird';
      final scientificName = result.scientificName ?? '';
      final rarity = RarityTable.rarityFor(
        scientificName.isNotEmpty ? scientificName : null,
        speciesName.isNotEmpty ? speciesName : null,
      );

      final updatedBird = _bird.copyWith(
        name: speciesName,
        species: scientificName,
        rarity: rarity,
        habitat: result.habitat ?? _bird.habitat,
        diet: result.diet ?? _bird.diet,
        funFacts: result.funFacts.isNotEmpty ? result.funFacts : _bird.funFacts,
        confidence: result.confidence,
      );

      await BirdRepository().updateBird(updatedBird);
      if (mounted) context.read<BirdProvider>().loadBirds();

      if (!mounted) return;

      setState(() {
        _bird = updatedBird;
        _isReidentifying = false;
      });

      messenger.showSnackBar(
        SnackBar(content: Text('Re-identified as $speciesName')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isReidentifying = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Re-identification failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GameBackground(
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailTopBar(
              bird: _bird,
              cardIndex: widget.cardIndex,
              totalCount: widget.totalCount,
              onShare: () => _share(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _DetailPhotoCard(bird: _bird),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.marginMobile),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailIdentity(bird: _bird),
                          const SizedBox(height: AppSpacing.md),
                          _DetailStats(bird: _bird),
                          if (_bird.species.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _SpeciesInfoCard(bird: _bird),
                          ],
                          if (_bird.funFacts.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _FunFactsSection(bird: _bird),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _ReidentifyButton(
                            isReidentifying: _isReidentifying,
                            onTap: _reidentify,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DeleteButton(onTap: _delete),
                          const SizedBox(height: AppSpacing.md),
                          _CaughtDate(date: _bird.caughtAt),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _share(BuildContext context) {
    final text =
        'I found a ${_bird.rarity.label} — ${_bird.name} (${_bird.species}) in my AvesQuest!';
    final file = _bird.photoPath.isNotEmpty ? share.XFile(_bird.photoPath) : null;
    if (file != null) {
      share.SharePlus.instance
          .share(share.ShareParams(files: [file], text: text));
    } else {
      share.SharePlus.instance.share(share.ShareParams(text: text));
    }
  }
}

// ── Re-identify button ──────────────────────────────────────────

class _ReidentifyButton extends StatelessWidget {
  const _ReidentifyButton({
    required this.isReidentifying,
    required this.onTap,
  });

  final bool isReidentifying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: isReidentifying ? null : onTap,
        icon: isReidentifying
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
        label: Text(isReidentifying ? 'Re-identifying…' : 'Re-identify with AI'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

// ── Delete button ────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Delete this bird'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

// ── Custom top bar ───────────────────────────────────────────────

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.bird,
    required this.cardIndex,
    required this.totalCount,
    required this.onShare,
  });

  final Bird bird;
  final int cardIndex;
  final int totalCount;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.onSurface,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceContainerLow.withValues(alpha: 0.0),
                  AppColors.surfaceContainerLow,
                  AppColors.surfaceContainerLow.withValues(alpha: 0.0),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: RarityBadge(rarity: bird.rarity, style: RarityBadgeStyle.pill),
          ),
          const Spacer(),
          if (cardIndex > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                '#${cardIndex.toString().padLeft(2, '0')} / $totalCount',
                style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant)
                    .copyWith(fontSize: 11),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            color: AppColors.onSurfaceVariant,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}

// ── Photo card with spiral binding ───────────────────────────────

class _DetailPhotoCard extends StatelessWidget {
  const _DetailPhotoCard({required this.bird});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final file = File(bird.photoPath);
    final hasPhoto = bird.photoPath.isNotEmpty && file.existsSync();
    final style = _rarityBorder(bird.rarity);

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile, AppSpacing.sm, AppSpacing.marginMobile, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: style.border, width: style.width),
        boxShadow: [
          BoxShadow(
            color: style.glow,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: CustomPaint(
              painter: const _DetailSpiralPainter(),
            ),
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: hasPhoto
                  ? OrientedImage(
                      file: file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: AppColors.outline),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceContainerHigh,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            size: 48, color: AppColors.outline),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSpiralPainter extends CustomPainter {
  const _DetailSpiralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 24.0;
    const startY = 30.0;
    const ringWidth = 12.0;
    const ringHeight = 7.0;

    final cx = size.width / 2;

    for (double y = startY; y < size.height - 20; y += spacing) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, y),
          width: ringWidth,
          height: ringHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Identity block ───────────────────────────────────────────────

class _DetailIdentity extends StatelessWidget {
  const _DetailIdentity({required this.bird});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bird.name.isEmpty ? 'Unidentified' : bird.name,
          style: AppTypography.headlineLgMobile().copyWith(
            fontSize: 28,
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (bird.species.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            bird.species,
            style: AppTypography.bodyLg(color: AppColors.onSurfaceVariant)
                .copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}

// ── Stats section ────────────────────────────────────────────────

class _DetailStats extends StatelessWidget {
  const _DetailStats({required this.bird});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatItem>[];

    if (bird.habitat.isNotEmpty) {
      stats.add(_StatItem(
        icon: Icons.location_on_outlined,
        label: 'Habitat',
        value: bird.habitat,
      ));
    }
    if (bird.diet.isNotEmpty) {
      stats.add(_StatItem(
        icon: Icons.restaurant_outlined,
        label: 'Diet',
        value: bird.diet,
      ));
    }
    if (bird.length != null) {
      stats.add(_StatItem(
        icon: Icons.straighten,
        label: 'Length',
        value: '${bird.length!.toStringAsFixed(1)} cm',
      ));
    }
    if (bird.weight != null) {
      stats.add(_StatItem(
        icon: Icons.monitor_weight_outlined,
        label: 'Weight',
        value: '${bird.weight!.toStringAsFixed(1)} g',
      ));
    }
    if (bird.country.isNotEmpty) {
      stats.add(_StatItem(
        icon: Icons.public,
        label: 'Range',
        value: bird.country,
      ));
    }
    if (bird.confidence != null) {
      final score = (bird.confidence! * 100).round();
      final label = bird.isLowConfidence
          ? 'Best guess ($score%)'
          : '$score% confident';
      stats.add(_StatItem(
        icon: Icons.psychology_outlined,
        label: 'Confidence',
        value: label,
        valueColor: bird.isLowConfidence ? AppColors.rarityRare : null,
      ));
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(stats.length, (i) {
          final stat = stats[i];
          final isLast = i == stats.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.sm + 4,
              bottom: isLast ? AppSpacing.sm + 4 : 0,
            ),
            child: _StatRow(stat: stat, showDivider: !isLast),
          );
        }),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, required this.showDivider});
  final _StatItem stat;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(stat.icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.label,
                      style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    stat.value,
                    style: AppTypography.bodyMd(
                            color: stat.valueColor ?? AppColors.onSurface)
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Divider(
                height: 1,
                color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          ),
      ],
    );
  }
}

// ── Species info card ────────────────────────────────────────────

class _SpeciesInfoCard extends StatelessWidget {
  const _SpeciesInfoCard({required this.bird});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final parts = bird.species.split(' ');
    final hasGenus = parts.length >= 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.biotech_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scientific Name',
                    style: AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant)
                        .copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  bird.species,
                  style: AppTypography.bodyMd(color: AppColors.onSurface)
                      .copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (hasGenus) ...[
                  const SizedBox(height: 4),
                  Text('Genus: ${parts[0]}',
                      style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fun Facts section ────────────────────────────────────────────

class _FunFactsSection extends StatelessWidget {
  const _FunFactsSection({required this.bird});
  final Bird bird;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text('Fun Facts',
                style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant)
                    .copyWith(fontSize: 11)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...bird.funFacts.map((fact) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(fact,
                        style: AppTypography.bodyMd().copyWith(fontSize: 14)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Caught date ──────────────────────────────────────────────────

class _CaughtDate extends StatelessWidget {
  const _CaughtDate({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_offer_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'CAUGHT',
                style: AppTypography.labelSm(color: AppColors.primary)
                    .copyWith(fontSize: 9, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          DateFormat('MMMM d, yyyy').format(date),
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}