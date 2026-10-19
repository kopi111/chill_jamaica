/// Named route paths, kept in one place so navigation calls stay typo-proof.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String menu = '/';
  static const String cart = '/cart';
  static const String cardPayment = '/checkout/payment';
  static const String orderConfirmation = '/order-confirmation';
  static const String myOrders = '/my-orders';

  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminProductForm = '/admin/products/form';
}
