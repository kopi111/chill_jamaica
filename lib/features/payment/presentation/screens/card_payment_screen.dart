import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../account/domain/entities/customer_profile.dart';
import '../../../account/presentation/providers/account_providers.dart';
import '../../../order/domain/entities/delivery_details.dart';
import '../../../order/domain/repositories/order_repository.dart';
import '../../../order/presentation/providers/checkout_controller.dart';
import '../../../order/presentation/screens/order_confirmation_screen.dart';
import '../../domain/entities/card_details.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_summary.dart';
import '../card_field_validators.dart';
import '../providers/payment_providers.dart';
import '../widgets/card_input_formatters.dart';

/// What the cart hands to the payment screen so it can finish the order.
@immutable
class CardPaymentArgs {
  const CardPaymentArgs({
    required this.amountJmd,
    required this.phoneE164,
    required this.delivery,
  });

  final int amountJmd;
  final String phoneE164;
  final DeliveryDetails delivery;
}

/// Takes the card payment, then places the order once the money clears.
///
/// The card never leaves this screen: it goes straight to the gateway, and only
/// the brand, last four digits and the gateway's reference reach Firestore.
class CardPaymentScreen extends ConsumerStatefulWidget {
  const CardPaymentScreen({required this.args, super.key});

  final CardPaymentArgs args;

  @override
  ConsumerState<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends ConsumerState<CardPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _holderName = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  final TextEditingController _securityCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _number.addListener(_refreshBrandHint);
  }

  @override
  void dispose() {
    _number.removeListener(_refreshBrandHint);
    _number.dispose();
    _holderName.dispose();
    _expiry.dispose();
    _securityCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _showPaymentErrorsAsSnacks();
    final bool isBusy = ref.watch(cardPaymentControllerProvider).isLoading ||
        ref.watch(checkoutControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.payByCard)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: <Widget>[
              _AmountHeader(amountJmd: widget.args.amountJmd),
              const SizedBox(height: AppDimensions.spaceLg),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                inputFormatters: const <TextInputFormatter>[
                  CardNumberFormatter(),
                ],
                validator: CardFieldValidators.number,
                decoration: InputDecoration(
                  labelText: AppStrings.cardNumberLabel,
                  hintText: '4242 4242 4242 4242',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixText: _brandLabel(),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                controller: _holderName,
                textCapitalization: TextCapitalization.characters,
                validator: CardFieldValidators.holderName,
                decoration: const InputDecoration(
                  labelText: AppStrings.cardHolderLabel,
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _expiry,
                      keyboardType: TextInputType.number,
                      inputFormatters: const <TextInputFormatter>[
                        ExpiryDateFormatter(),
                      ],
                      validator: CardFieldValidators.expiry,
                      decoration: const InputDecoration(
                        labelText: AppStrings.cardExpiryLabel,
                        hintText: 'MM/YY',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMd),
                  Expanded(
                    child: TextFormField(
                      controller: _securityCode,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (String? value) =>
                          CardFieldValidators.securityCode(
                        value,
                        cardNumber: _number.text,
                      ),
                      decoration: const InputDecoration(
                        labelText: AppStrings.cardCvvLabel,
                        hintText: '123',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              _SecurityNote(gatewayName: ref.watch(paymentGatewayProvider).displayName),
              const SizedBox(height: AppDimensions.spaceXl),
              AppButton(
                label: '${AppStrings.payNow} ${Formatters.jmd(widget.args.amountJmd)}',
                icon: Icons.lock_outline,
                isLoading: isBusy,
                onPressed: _payAndPlaceOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshBrandHint() => setState(() {});

  String? _brandLabel() {
    final String digits = _number.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return CardDetails(
      number: digits,
      holderName: '',
      expiryMonth: 1,
      expiryYear: 2000,
      securityCode: '',
    ).brand.label;
  }

  Future<void> _payAndPlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final PaymentSummary? payment = await ref
        .read(cardPaymentControllerProvider.notifier)
        .pay(request: _buildRequest(), card: _buildCard());
    if (payment == null || !mounted) return;

    final PlacedOrder? placed =
        await ref.read(checkoutControllerProvider.notifier).submit(
              phoneE164: widget.args.phoneE164,
              delivery: widget.args.delivery,
              payment: payment,
            );
    if (placed == null || !mounted) return;

    context.pushReplacement(
      AppRoutes.orderConfirmation,
      extra: OrderConfirmationArgs(
        orderId: placed.orderId,
        wasQueuedOffline: placed.outcome == SubmitOutcome.queuedOffline,
        deliveryAddress: widget.args.delivery.displayAddress,
        payment: payment,
      ),
    );
  }

  PaymentRequest _buildRequest() {
    final CustomerProfile? customer =
        ref.read(signedInCustomerProvider).valueOrNull;
    return PaymentRequest(
      amountJmd: widget.args.amountJmd,
      reference: _newReference(),
      customerName: customer?.fullName ?? 'Guest',
      customerEmail: customer?.email ?? '',
      customerPhone: widget.args.phoneE164,
    );
  }

  CardDetails _buildCard() {
    final ExpiryDate expiry = ExpiryDate.parse(_expiry.text)!;
    return CardDetails(
      number: _number.text,
      holderName: _holderName.text.trim(),
      expiryMonth: expiry.month,
      expiryYear: expiry.year,
      securityCode: _securityCode.text.trim(),
    );
  }

  /// Merchant-side reference the gateway echoes back for reconciliation.
  String _newReference() =>
      'CJ${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  void _showPaymentErrorsAsSnacks() {
    ref.listen<AsyncValue<PaymentSummary?>>(cardPaymentControllerProvider,
        (AsyncValue<PaymentSummary?>? previous,
            AsyncValue<PaymentSummary?> next) {
      next.whenOrNull(
        error: (Object error, _) => context.showSnack(
          error is Failure ? error.message : AppStrings.genericError,
          isError: true,
        ),
      );
    });
  }
}

class _AmountHeader extends StatelessWidget {
  const _AmountHeader({required this.amountJmd});

  final int amountJmd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        gradient: AppColors.tropicalGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: <Widget>[
          Text(
            AppStrings.amountDue,
            style: context.textStyles.bodyMedium
                ?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            Formatters.jmd(amountJmd),
            style: context.textStyles.headlineMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({required this.gatewayName});

  final String gatewayName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.shield_outlined,
            size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: Text(
            '${AppStrings.cardSecurityNote} Processed by $gatewayName.',
            style: context.textStyles.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
