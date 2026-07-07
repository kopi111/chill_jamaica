import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../location/presentation/location_provider.dart';
import '../../../location/presentation/location_service.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/delivery_details.dart';
import '../../domain/repositories/order_repository.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_controller.dart';
import 'order_confirmation_screen.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/delivery_method_selector.dart';

/// Cart + checkout: edit lines, pick delivery, enter phone, place the order.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(text: '+1 (876) ');

  DeliveryMethod _method = DeliveryMethod.address;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForResult();
    final List<CartItem> items = ref.watch(cartProvider);
    final AsyncValue<PlacedOrder?> checkout =
        ref.watch(checkoutControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.cartTitle)),
      body: OfflineBanner(
        child: items.isEmpty
            ? EmptyView(
                message: AppStrings.cartEmpty,
                actionLabel: 'Browse Menu',
                onAction: () => context.go(AppRoutes.menu),
              )
            : _CheckoutForm(
                formKey: _formKey,
                items: items,
                method: _method,
                onMethodChanged: (DeliveryMethod m) =>
                    setState(() => _method = m),
                addressController: _addressController,
                phoneController: _phoneController,
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _PlaceOrderBar(
              isSubmitting: checkout.isLoading,
              onPlaceOrder: _submit,
            ),
    );
  }

  /// Navigates to confirmation on success and shows friendly errors otherwise.
  void _listenForResult() {
    ref.listen<AsyncValue<PlacedOrder?>>(checkoutControllerProvider,
        (AsyncValue<PlacedOrder?>? previous, AsyncValue<PlacedOrder?> next) {
      next.whenOrNull(
        data: (PlacedOrder? placed) {
          if (placed == null) return;
          context.pushReplacement(
            AppRoutes.orderConfirmation,
            extra: OrderConfirmationArgs(
              orderId: placed.orderId,
              wasQueuedOffline: placed.outcome == SubmitOutcome.queuedOffline,
              deliveryAddress: _currentDeliveryAddress(),
            ),
          );
        },
        error: (Object error, _) {
          final String message =
              error is Failure ? error.message : AppStrings.genericError;
          context.showSnack(message, isError: true);
        },
      );
    });
  }

  String _currentDeliveryAddress() {
    if (_method == DeliveryMethod.address) return _addressController.text.trim();
    final LocationResult? loc =
        ref.read(locationControllerProvider).valueOrNull;
    return loc?.address ?? loc?.coordinate.toString() ?? 'GPS location';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final DeliveryDetails? delivery = _buildDelivery();
    if (delivery == null) {
      context.showSnack('Set a delivery location first.', isError: true);
      return;
    }

    await ref.read(checkoutControllerProvider.notifier).submit(
          phoneE164: Formatters.toE164Jamaican(_phoneController.text),
          delivery: delivery,
        );
  }

  /// Assembles [DeliveryDetails] from the chosen method, or null if incomplete.
  DeliveryDetails? _buildDelivery() {
    if (_method == DeliveryMethod.address) {
      return DeliveryDetails.typed(_addressController.text.trim());
    }
    final LocationResult? loc =
        ref.read(locationControllerProvider).valueOrNull;
    if (loc == null) return null;
    return DeliveryDetails.gps(
      coordinates: loc.coordinate,
      resolvedAddress: loc.address,
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.formKey,
    required this.items,
    required this.method,
    required this.onMethodChanged,
    required this.addressController,
    required this.phoneController,
  });

  final GlobalKey<FormState> formKey;
  final List<CartItem> items;
  final DeliveryMethod method;
  final ValueChanged<DeliveryMethod> onMethodChanged;
  final TextEditingController addressController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          ...items.map((CartItem item) => _CartLine(item: item)),
          const SizedBox(height: AppDimensions.spaceLg),
          _SectionTitle('Delivery'),
          const SizedBox(height: AppDimensions.spaceSm),
          DeliveryMethodSelector(
            method: method,
            onMethodChanged: onMethodChanged,
            addressController: addressController,
            addressValidator: method == DeliveryMethod.address
                ? Validators.deliveryAddress
                : (_) => null,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _SectionTitle(AppStrings.phoneLabel),
          const SizedBox(height: AppDimensions.spaceSm),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.jamaicanPhone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '+1 (876) 123-4567',
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXxl),
        ],
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CartNotifier cart = ref.read(cartProvider.notifier);
    return CartItemTile(
      item: item,
      onQuantityChanged: (int q) => cart.setQuantity(item.product, q),
      onRemove: () => cart.remove(item.product),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _PlaceOrderBar extends ConsumerWidget {
  const _PlaceOrderBar({required this.isSubmitting, required this.onPlaceOrder});

  final bool isSubmitting;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int subtotal = ref.watch(cartSubtotalProvider);
    return SafeArea(
      minimum: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(AppStrings.total, style: context.textStyles.titleMedium),
              Text(
                Formatters.jmd(subtotal),
                style: context.textStyles.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          AppButton(
            label: AppStrings.placeOrder,
            icon: Icons.local_shipping_outlined,
            isLoading: isSubmitting,
            onPressed: onPlaceOrder,
          ),
        ],
      ),
    );
  }
}
