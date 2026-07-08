/// Named route paths, kept in one place so navigation calls stay typo-proof.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String menu = '/';
  static const String cart = '/cart';
  static const String orderConfirmation = '/order-confirmation';
  static const String myOrders = '/my-orders';

  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminProductForm = '/admin/products/form';
}
