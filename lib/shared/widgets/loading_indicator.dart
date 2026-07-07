import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Centred spinner with an optional caption.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(color: AppColors.primaryGreen),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppDimensions.spaceMd),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton grid shown while products load — feels faster than a spinner.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({this.columns = 2, super.key});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.backgroundCream,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppDimensions.spaceMd,
          mainAxisSpacing: AppDimensions.spaceMd,
          childAspectRatio: 0.72,
        ),
        itemCount: columns * 2,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
    );
  }
}
