import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/prefs_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/customer_order.dart';
import '../providers/order_providers.dart';
import '../widgets/order_card.dart';

/// "My Orders": looks up orders by the customer's (cached) phone number.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? phone = ref.watch(customerPhoneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myOrdersTitle)),
      body: phone == null
          ? _PhoneLookupForm(
              onSubmit: (String e164) =>
                  ref.read(customerPhoneProvider.notifier).save(e164),
            )
          : _OrdersList(phone: phone),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CustomerOrder>> orders =
        ref.watch(ordersByPhoneProvider(phone));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ordersByPhoneProvider(phone)),
      child: orders.when(
        loading: () => const LoadingIndicator(),
        error: (Object error, _) => ErrorView(
          message: AppStrings.serverError,
          onRetry: () => ref.invalidate(ordersByPhoneProvider(phone)),
        ),
        data: (List<CustomerOrder> list) {
          if (list.isEmpty) {
            return ListView(
              children: <Widget>[
                const SizedBox(height: 120),
                EmptyView(
                  message: AppStrings.ordersEmpty,
                  actionLabel: 'Use a different number',
                  onAction: () =>
                      ref.read(customerPhoneProvider.notifier).clear(),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            itemCount: list.length,
            itemBuilder: (BuildContext context, int index) =>
                OrderCard(order: list[index]),
          );
        },
      ),
    );
  }
}

class _PhoneLookupForm extends StatefulWidget {
  const _PhoneLookupForm({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_PhoneLookupForm> createState() => _PhoneLookupFormState();
}

class _PhoneLookupFormState extends State<_PhoneLookupForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller =
      TextEditingController(text: '+1 (876) ');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(Formatters.toE164Jamaican(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('🥥', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              AppStrings.lookupPhonePrompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              validator: Validators.jamaicanPhone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
                labelText: AppStrings.phoneLabel,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('See My Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
