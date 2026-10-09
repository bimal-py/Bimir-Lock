/// Constants for asset paths. Reference these instead of hardcoding strings
/// at call sites so renames stay mechanical.
class AssetRoutes {
  static const String imagePath = 'assets/images';
  static const String logoPath = '$imagePath/logos';

  // images/logos
  static const String appLogo = '$logoPath/app_logo.png';
  static const String appLogoSmall = '$logoPath/app_logo_small.png';

  // images (defaults / empty states)
  static const String defaultAvatar = '$imagePath/default_avatar.png';
  static const String defaultImage = '$imagePath/default_image.png';
  static const String noDataFound = '$imagePath/nodatafound.svg';
}
