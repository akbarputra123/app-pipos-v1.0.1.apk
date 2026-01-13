import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// =======================================================
/// GLOBAL SHIMMER WIDGET
/// - DARK / LIGHT MODE AWARE
/// - REUSABLE
/// - AMAN UNTUK LIST / CARD / GRID
/// =======================================================

class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor.withOpacity(0.4),
      child: child,
    );
  }
}

/// =======================================================
/// SHIMMER LIST (DEFAULT CARD LIST)
/// =======================================================
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double height;
  final EdgeInsets margin;
  final BorderRadius borderRadius;

  const ShimmerList({
    super.key,
    this.itemCount = 6,
    this.height = 100,
    this.margin = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShimmer(
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: margin,
          height: height,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}

/// =======================================================
/// SHIMMER CARD (SINGLE)
/// =======================================================
class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
