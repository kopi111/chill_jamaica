import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/extensions.dart';
import '../../../location/presentation/location_provider.dart';
import '../../../location/presentation/location_service.dart';
import '../../domain/entities/delivery_details.dart';

/// Lets the customer choose between typing an address and using GPS, and
/// renders the matching input. Reports the chosen [DeliveryDetails] upward.
class DeliveryMethodSelector extends ConsumerWidget {
  const DeliveryMethodSelector({
    required this.method,
    required this.onMethodChanged,
    required this.addressController,
    required this.addressValidator,
    super.key,
  });

  final DeliveryMethod method;
  final ValueChanged<DeliveryMethod> onMethodChanged;
  final TextEditingController addressController;
  final FormFieldValidator<String> addressValidator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedButton<DeliveryMethod>(
          segments: const <ButtonSegment<DeliveryMethod>>[
            ButtonSegment<DeliveryMethod>(
              value: DeliveryMethod.address,
              icon: Icon(Icons.edit_location_alt_outlined),
              label: Text(AppStrings.typeMyAddress),
            ),
            ButtonSegment<DeliveryMethod>(
              value: DeliveryMethod.gps,
              icon: Icon(Icons.my_location_rounded),
              label: Text(AppStrings.useMyGpsLocation),
            ),
          ],
          selected: <DeliveryMethod>{method},
          onSelectionChanged: (Set<DeliveryMethod> s) => onMethodChanged(s.first),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        if (method == DeliveryMethod.address)
          TextFormField(
            controller: addressController,
            validator: addressValidator,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: AppStrings.addressLabel,
              hintText: AppStrings.addressHint,
              prefixIcon: Icon(Icons.home_outlined),
            ),
          )
        else
          const _GpsPanel(),
      ],
    );
  }
}

class _GpsPanel extends ConsumerWidget {
  const _GpsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LocationResult?> location =
        ref.watch(locationControllerProvider);

    return location.when(
      loading: () => const _GpsCard(
        icon: Icons.gps_fixed,
        child: Row(
          children: <Widget>[
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppDimensions.spaceSm),
            Text(AppStrings.acquiringLocation),
          ],
        ),
      ),
      error: (Object error, _) => _GpsError(error: error),
      data: (LocationResult? result) =>
          result == null ? const _GpsPrompt() : _GpsAcquired(result: result),
    );
  }
}

class _GpsPrompt extends ConsumerWidget {
  const _GpsPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GpsCard(
      icon: Icons.my_location_rounded,
      child: Row(
        children: <Widget>[
          const Expanded(child: Text('Wi can find yuh automatically.')),
          FilledButton.icon(
            onPressed: () =>
                ref.read(locationControllerProvider.notifier).acquire(),
            icon: const Icon(Icons.location_searching_rounded, size: 18),
            label: const Text('Locate Me'),
          ),
        ],
      ),
    );
  }
}

class _GpsAcquired extends StatelessWidget {
  const _GpsAcquired({required this.result});

  final LocationResult result;

  @override
  Widget build(BuildContext context) {
    final bool lowAccuracy =
        !result.isAccurateWithin(AppDimensions.lowAccuracyThresholdMeters);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _GpsCard(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.primaryGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                result.address ?? result.coordinate.toString(),
                style: context.textStyles.bodyLarge,
              ),
              Text(
                'Accuracy: ±${result.accuracyMeters.toStringAsFixed(0)}m',
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        ),
        if (lowAccuracy)
          const Padding(
            padding: EdgeInsets.only(top: AppDimensions.spaceSm),
            child: Text(
              AppStrings.lowAccuracyWarning,
              style: TextStyle(color: AppColors.statusProcessing),
            ),
          ),
      ],
    );
  }
}

class _GpsError extends ConsumerWidget {
  const _GpsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool permanentlyDenied =
        error is LocationFailure && (error as LocationFailure).isPermanentlyDenied;
    final String message =
        error is Failure ? (error as Failure).message : AppStrings.locationDenied;
    return _GpsCard(
      icon: Icons.location_off_rounded,
      iconColor: AppColors.urgentRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            children: <Widget>[
              if (permanentlyDenied)
                OutlinedButton(
                  onPressed: () =>
                      ref.read(locationServiceProvider).openSettings(),
                  child: const Text('Open Settings'),
                )
              else
                OutlinedButton(
                  onPressed: () =>
                      ref.read(locationControllerProvider.notifier).acquire(),
                  child: const Text('Try Again'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  const _GpsCard({
    required this.icon,
    required this.child,
    this.iconColor = AppColors.primaryGreen,
  });

  final IconData icon;
  final Widget child;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: iconColor),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(child: child),
        ],
      ),
    );
  }
}
