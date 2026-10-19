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
import '../../../account/domain/entities/customer_profile.dart';
import '../../../account/domain/entities/saved_address.dart';
import '../../../account/presentation/providers/account_providers.dart';
import '../../../location/presentation/location_provider.dart';
import '../../../location/presentation/location_service.dart';
import '../../../payment/domain/entities/payment_method.dart';
import '../../../payment/domain/entities/payment_summary.dart';
import '../../../payment/presentation/screens/card_payment_screen.dart';
import '../../../payment/presentation/widgets/payment_method_selector.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/delivery_details.dart';
import '../../domain/repositories/order_repository.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_controller.dart';
import 'order_confirmation_screen.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/delivery_method_selector.dart';

/// Cart + checkout: edit lines, pick delivery, choose how to pay, then either
/// place a cash order or continue to the card payment screen.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DeliveryMethod _deliveryMethod = DeliveryMethod.address;
  PaymentMethod _paymentMethod = PaymentMethod.card;
  bool _hasPrefilledFromProfile = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _showCheckoutErrorsAsSnacks();
    final CustomerProfile? customer =
        ref.watch(signedInCustomerProvider).valueOrNull;
    _prefillOnce(customer);

    final List<CartItem> items = ref.watch(cartProvider);
    final bool isSubmitting = ref.watch(checkoutControllerProvider).isLoading;

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
                customer: customer,
                deliveryMethod: _deliveryMethod,
                onDeliveryMethodChanged: _selectDeliveryMethod,
                paymentMethod: _paymentMethod,
                onPaymentMethodChanged: _selectPaymentMethod,
                addressController: _addressController,
                phoneController: _phoneController,
                onSavedAddressPicked: _useSavedAddress,
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _CheckoutBar(
              isSubmitting: isSubmitting,
              isSignedIn: customer != null,
              paymentMethod: _paymentMethod,
              onCheckout: () => _checkout(customer),
              onSignIn: () => context.push(AppRoutes.signIn),
            ),
    );
  }

  void _selectDeliveryMethod(DeliveryMethod method) =>
      setState(() => _deliveryMethod = method);

  void _selectPaymentMethod(PaymentMethod method) =>
      setState(() => _paymentMethod = method);

  void _useSavedAddress(SavedAddress address) {
    setState(() {
      _deliveryMethod = DeliveryMethod.address;
      _addressController.text = address.line;
    });
  }

  /// Copies the profile's phone and home address into the form the first time
  /// it loads, without stomping on anything the customer has since typed.
  ///
  /// Deferred to after the frame because writing to a controller notifies the
  /// text fields, and they must not be marked dirty mid-build.
  void _prefillOnce(CustomerProfile? customer) {
    if (customer == null || _hasPrefilledFromProfile) return;
    _hasPrefilledFromProfile = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyProfileToForm(customer);
    });
  }

  void _applyProfileToForm(CustomerProfile customer) {
    _phoneController.text = Formatters.prettyPhone(customer.phone);
    final List<SavedAddress> saved = customer.deliverableAddresses;
    if (saved.isNotEmpty && _addressController.text.trim().isEmpty) {
      _addressController.text = saved.first.line;
    }
  }

  Future<void> _checkout(CustomerProfile? customer) async {
    if (customer == null) {
      context.push(AppRoutes.signIn);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final DeliveryDetails? delivery = _buildDelivery();
    if (delivery == null) {
      context.showSnack('Set a delivery location first.', isError: true);
      return;
    }

    if (_paymentMethod.isCard) {
      _goToCardPayment(delivery);
      return;
    }
    await _placeCashOrder(delivery);
  }

  void _goToCardPayment(DeliveryDetails delivery) {
    context.push(
      AppRoutes.cardPayment,
      extra: CardPaymentArgs(
        amountJmd: ref.read(cartSubtotalProvider),
        phoneE164: Formatters.toE164Jamaican(_phoneController.text),
        delivery: delivery,
      ),
    );
  }

  Future<void> _placeCashOrder(DeliveryDetails delivery) async {
    final PlacedOrder? placed =
        await ref.read(checkoutControllerProvider.notifier).submit(
              phoneE164: Formatters.toE164Jamaican(_phoneController.text),
              delivery: delivery,
              payment: const PaymentSummary.cashOnDelivery(),
            );
    if (placed == null || !mounted) return;

    context.pushReplacement(
      AppRoutes.orderConfirmation,
      extra: OrderConfirmationArgs(
        orderId: placed.orderId,
        wasQueuedOffline: placed.outcome == SubmitOutcome.queuedOffline,
        deliveryAddress: delivery.displayAddress,
        payment: const PaymentSummary.cashOnDelivery(),
      ),
    );
  }

  /// Assembles [DeliveryDetails] from the chosen method, or null if incomplete.
  DeliveryDetails? _buildDelivery() {
    if (_deliveryMethod == DeliveryMethod.address) {
      return DeliveryDetails.typed(_addressController.text.trim());
    }
    final LocationResult? location =
        ref.read(locationControllerProvider).valueOrNull;
    if (location == null) return null;
    return DeliveryDetails.gps(
      coordinates: location.coordinate,
      resolvedAddress: location.address,
    );
  }

  void _showCheckoutErrorsAsSnacks() {
    ref.listen<AsyncValue<PlacedOrder?>>(checkoutControllerProvider,
        (AsyncValue<PlacedOrder?>? previous, AsyncValue<PlacedOrder?> next) {
      next.whenOrNull(
        error: (Object error, _) => context.showSnack(
          error is Failure ? error.message : AppStrings.genericError,
          isError: true,
        ),
      );
    });
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.formKey,
    required this.items,
    required this.customer,
    required this.deliveryMethod,
    required this.onDeliveryMethodChanged,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.addressController,
    required this.phoneController,
    required this.onSavedAddressPicked,
  });

  final GlobalKey<FormState> formKey;
  final List<CartItem> items;
  final CustomerProfile? customer;
  final DeliveryMethod deliveryMethod;
  final ValueChanged<DeliveryMethod> onDeliveryMethodChanged;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final ValueChanged<SavedAddress> onSavedAddressPicked;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          ...items.map((CartItem item) => _CartLine(item: item)),
          const SizedBox(height: AppDimensions.spaceLg),
          const _SectionTitle('Delivery'),
          const SizedBox(height: AppDimensions.spaceSm),
          _SavedAddressChips(
            addresses: customer?.deliverableAddresses ?? const <SavedAddress>[],
            onPicked: onSavedAddressPicked,
          ),
          DeliveryMethodSelector(
            method: deliveryMethod,
            onMethodChanged: onDeliveryMethodChanged,
            addressController: addressController,
            addressValidator: deliveryMethod == DeliveryMethod.address
                ? Validators.deliveryAddress
                : (_) => null,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          const _SectionTitle(AppStrings.phoneLabel),
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
          const SizedBox(height: AppDimensions.spaceLg),
          const _SectionTitle(AppStrings.paymentSectionTitle),
          const SizedBox(height: AppDimensions.spaceSm),
          PaymentMethodSelector(
            selected: paymentMethod,
            onSelected: onPaymentMethodChanged,
          ),
          const SizedBox(height: AppDimensions.spaceXxl),
        ],
      ),
    );
  }
}

/// One-tap buttons for the addresses already on the customer's profile.
class _SavedAddressChips extends StatelessWidget {
  const _SavedAddressChips({required this.addresses, required this.onPicked});

  final List<SavedAddress> addresses;
  final ValueChanged<SavedAddress> onPicked;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Wrap(
        spacing: AppDimensions.spaceSm,
        children: addresses
            .map(
              (SavedAddress address) => ActionChip(
                avatar: Icon(address.label.icon, size: 18),
                label: Text(address.label.label),
                onPressed: () => onPicked(address),
              ),
            )
            .toList(),
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

class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({
    required this.isSubmitting,
    required this.isSignedIn,
    required this.paymentMethod,
    required this.onCheckout,
    required this.onSignIn,
  });

  final bool isSubmitting;
  final bool isSignedIn;
  final PaymentMethod paymentMethod;
  final VoidCallback onCheckout;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int subtotal = ref.watch(cartSubtotalProvider);
    return SafeArea(
      minimum: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isSignedIn) ...<Widget>[
            const _SignInPrompt(),
            const SizedBox(height: AppDimensions.spaceSm),
          ],
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
            label: _buttonLabel,
            icon: _buttonIcon,
            isLoading: isSubmitting,
            onPressed: isSignedIn ? onCheckout : onSignIn,
          ),
        ],
      ),
    );
  }

  String get _buttonLabel {
    if (!isSignedIn) return AppStrings.signInToCheckout;
    return paymentMethod.isCard
        ? AppStrings.continueToPayment
        : AppStrings.placeOrder;
  }

  IconData get _buttonIcon {
    if (!isSignedIn) return Icons.login;
    return paymentMethod.isCard
        ? Icons.credit_card
        : Icons.local_shipping_outlined;
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, color: AppColors.secondaryGold),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              AppStrings.signInToCheckoutBody,
              style: context.textStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
