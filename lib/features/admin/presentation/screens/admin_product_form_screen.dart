import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/extensions.dart';
import '../../../menu/domain/entities/product.dart';
import '../providers/admin_product_providers.dart';

/// Create or edit a single product. A null [product] means "create".
class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({required this.product, super.key});

  final Product? product;

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _sizeMl;
  late final TextEditingController _priceJmd;
  late final TextEditingController _imageUrl;
  late bool _isAvailable;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final Product? existing = widget.product;
    _name = TextEditingController(text: existing?.name ?? '');
    _sizeMl = TextEditingController(
      text: existing == null ? '' : existing.sizeMl.toString(),
    );
    _priceJmd = TextEditingController(
      text: existing == null ? '' : existing.priceJmd.toString(),
    );
    _imageUrl = TextEditingController(text: existing?.imagePlaceholder ?? '');
    _isAvailable = existing?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _sizeMl.dispose();
    _priceJmd.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool saving =
        ref.watch(adminProductControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: AbsorbPointer(
        absorbing: saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            children: <Widget>[
              _ImagePreview(controller: _imageUrl),
              const SizedBox(height: AppDimensions.spaceLg),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.productNameLabel,
                ),
                validator: _requireText,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                controller: _sizeMl,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: AppStrings.productSizeLabel,
                ),
                validator: _requirePositiveInt,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                controller: _priceJmd,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: AppStrings.productPriceLabel,
                  prefixText: 'JMD \$ ',
                ),
                validator: _requirePositiveInt,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: AppStrings.productImageUrlLabel,
                  hintText: AppStrings.productImageUrlHint,
                ),
                validator: _validateOptionalUrl,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.productAvailableLabel),
                value: _isAvailable,
                onChanged: (bool value) =>
                    setState(() => _isAvailable = value),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text(AppStrings.saveProduct),
              ),
              if (_isEditing) ...<Widget>[
                const SizedBox(height: AppDimensions.spaceSm),
                TextButton.icon(
                  onPressed: saving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.urgentRed),
                  label: const Text(
                    AppStrings.deleteProduct,
                    style: TextStyle(color: AppColors.urgentRed),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _requireText(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requirePositiveInt(String? value) {
    final int parsed = int.tryParse((value ?? '').trim()) ?? 0;
    return parsed > 0 ? null : 'Enter a number greater than 0';
  }

  String? _validateOptionalUrl(String? value) {
    final String url = (value ?? '').trim();
    if (url.isEmpty) return null;
    final bool looksValid =
        url.startsWith('http://') || url.startsWith('https://');
    return looksValid ? null : 'Must start with http:// or https://';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final Product draft = (widget.product ??
            const Product(
              id: '',
              name: '',
              sizeMl: 0,
              priceJmd: 0,
              imagePlaceholder: '',
              isAvailable: true,
            ))
        .copyWith(
      name: _name.text.trim(),
      sizeMl: int.parse(_sizeMl.text.trim()),
      priceJmd: int.parse(_priceJmd.text.trim()),
      imagePlaceholder: _imageUrl.text.trim(),
      isAvailable: _isAvailable,
    );

    final bool ok =
        await ref.read(adminProductControllerProvider.notifier).save(draft);
    if (!mounted) return;
    if (ok) {
      context.showSnack(AppStrings.productSaved);
      context.pop();
    } else {
      context.showSnack(AppStrings.serverError, isError: true);
    }
  }

  Future<void> _confirmDelete() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text(AppStrings.deleteProduct),
            content: const Text(AppStrings.deleteProductConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.urgentRed,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(AppStrings.deleteProduct),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final bool ok = await ref
        .read(adminProductControllerProvider.notifier)
        .delete(widget.product!.id);
    if (!mounted) return;
    if (ok) {
      context.showSnack(AppStrings.productDeleted);
      context.pop();
    } else {
      context.showSnack(AppStrings.serverError, isError: true);
    }
  }
}

/// Live preview of the entered image URL, so the admin sees the picture before
/// saving. Falls back to the gradient placeholder when empty or broken.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final String url = controller.text.trim();
    final bool hasUrl = url.startsWith('http');
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _PreviewFallback(label: 'Loading…'),
                errorWidget: (_, _, _) =>
                    const _PreviewFallback(label: 'Image not found'),
              )
            : const _PreviewFallback(label: 'No image — paste a URL below'),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.coconutPlaceholder),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('🥥', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(label, style: context.textStyles.bodySmall),
        ],
      ),
    );
  }
}
