import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../domain/entities/product.dart';
import '../providers/menu_providers.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/product_card.dart';

/// Home screen: hero banner + product grid + sticky cart bar.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Product>> products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appNameEmoji),
        actions: <Widget>[
          CartBadgeIcon(onTap: () => context.push(AppRoutes.cart)),
          IconButton(
            tooltip: AppStrings.myOrdersTitle,
            onPressed: () => context.push(AppRoutes.myOrders),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: AppStrings.myProfile,
            onPressed: () => context.push(AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: OfflineBanner(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(productsProvider),
          child: products.when(
            loading: () => const _MenuScaffoldBody(child: ProductGridSkeleton()),
            error: (Object error, _) => _MenuScaffoldBody(
              child: ErrorView(
                message: AppStrings.menuLoadError,
                onRetry: () => ref.invalidate(productsProvider),
              ),
            ),
            data: (List<Product> items) => items.isEmpty
                ? const _MenuScaffoldBody(
                    child: EmptyView(
                      message: AppStrings.menuEmpty,
                      emoji: '🌴',
                    ),
                  )
                : _ProductGrid(products: items),
          ),
        ),
      ),
      bottomNavigationBar: CartSummaryBar(
        onViewCart: () => context.push(AppRoutes.cart),
      ),
    );
  }
}

/// Keeps error/empty/loading states scrollable so pull-to-refresh still works.
class _MenuScaffoldBody extends StatelessWidget {
  const _MenuScaffoldBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final int columns = context.isTablet ? 4 : 2;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _HeroBanner()),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppDimensions.spaceMd,
              mainAxisSpacing: AppDimensions.spaceMd,
              childAspectRatio: 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) =>
                  ProductCard(product: products[index]),
              childCount: products.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppDimensions.cartBarHeight),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.heroHeight,
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMd,
        AppDimensions.spaceMd,
        AppDimensions.spaceMd,
        0,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.tropicalGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const Text('🥥🌴🇯🇲', style: TextStyle(fontSize: 30)),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            AppStrings.tagline,
            style: context.textStyles.headlineSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
