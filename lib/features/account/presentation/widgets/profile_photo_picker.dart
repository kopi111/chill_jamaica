import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/profile_photo.dart';

/// Circular avatar that lets the customer pick a photo from camera or gallery.
///
/// Shows, in order of preference: the freshly picked [pendingPhoto], the
/// already-uploaded [existingPhotoUrl], then [initials].
class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    required this.initials,
    required this.onPhotoPicked,
    this.pendingPhoto,
    this.existingPhotoUrl,
    this.diameter = 112,
    super.key,
  });

  final String initials;
  final ValueChanged<ProfilePhoto> onPhotoPicked;
  final ProfilePhoto? pendingPhoto;
  final String? existingPhotoUrl;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: () => _pickPhoto(context),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _Avatar(
                initials: initials,
                pendingPhoto: pendingPhoto,
                existingPhotoUrl: existingPhotoUrl,
              ),
              const Align(
                alignment: Alignment.bottomRight,
                child: _CameraBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final ImageSource? source = await _askForSource(context);
    if (source == null) return;

    final XFile? file = await ImagePicker().pickImage(
      source: source,
      maxWidth: _maxPhotoWidth,
      imageQuality: _photoQuality,
    );
    if (file == null) return;

    onPhotoPicked(
      ProfilePhoto(bytes: await file.readAsBytes(), fileName: file.name),
    );
  }

  Future<ImageSource?> _askForSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Downscaled on-device so uploads stay small on Jamaican mobile data.
  static const double _maxPhotoWidth = 800;
  static const int _photoQuality = 85;
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.pendingPhoto,
    required this.existingPhotoUrl,
  });

  final String initials;
  final ProfilePhoto? pendingPhoto;
  final String? existingPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.tropicalGradient,
        border: Border.all(color: AppColors.white, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: _photo() ?? _initialsLabel(context),
    );
  }

  Widget? _photo() {
    final ProfilePhoto? pending = pendingPhoto;
    if (pending != null) {
      return Image.memory(pending.bytes, fit: BoxFit.cover);
    }
    final String url = existingPhotoUrl ?? '';
    if (url.isEmpty) return null;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  Widget _initialsLabel(BuildContext context) => Center(
        child: Text(
          initials,
          style: context.textStyles.headlineMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceXs),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondaryGold,
      ),
      child: const Icon(
        Icons.photo_camera,
        size: 18,
        color: AppColors.white,
      ),
    );
  }
}
