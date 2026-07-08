import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Renders a product's picture from either a remote URL or a bundled asset
/// path. When no image is set, it falls back to the Jamaica Chilled brand logo
/// so every product shows real branding instead of an empty placeholder.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageRef,
    this.borderRadius = AppDimensions.radiusSm,
    super.key,
  });

  /// A product's `imagePlaceholder`: an `http(s)` URL, an `assets/…` path, or
  /// empty for the brand-logo fallback.
  final String imageRef;
  final double borderRadius;

  bool get _isRemote => imageRef.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _isRemote
          ? CachedNetworkImage(
              imageUrl: imageRef,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, _) => const _BrandLogo(),
              errorWidget: (_, _, _) => const _BrandLogo(),
            )
          : _LocalImage(
              path: imageRef.startsWith('assets/')
                  ? imageRef
                  : AppAssets.brandLogo,
            ),
    );
  }
}

/// Brand logo shown when a product has no custom image.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) => const _LocalImage(path: AppAssets.brandLogo);
}

/// A bundled image, letter-boxed on a white field so wide logos aren't cropped.
class _LocalImage extends StatelessWidget {
  const _LocalImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimensions.spaceXs),
      child: Image.asset(path, fit: BoxFit.contain),
    );
  }
}
