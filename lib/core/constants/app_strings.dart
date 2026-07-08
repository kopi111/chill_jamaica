/// User-facing copy for Chill Jamaica.
///
/// Keeping strings in one place makes the Jamaican-patois voice consistent and
/// leaves room for localisation later. Patois flavour is intentional but stays
/// readable and professional.
abstract final class AppStrings {
  const AppStrings._();

  static const String appName = 'Jamaica Chilled';
  static const String appNameEmoji = 'Jamaica Chilled 🥥';
  static const String tagline = 'Fresh Coconut Water, Straight To Yuh Door';

  // --- Menu ---
  static const String addToCart = 'Add to Cart';
  static const String viewCart = 'View Cart';
  static const String menuEmpty = 'No coconut water right now — soon come!';
  static const String menuLoadError = 'Couldn\'t load di menu. Pull to try again.';
  static const String pullToRefresh = 'Pull to refresh';

  // --- Cart / checkout ---
  static const String cartTitle = 'Yuh Cart';
  static const String cartEmpty = 'Yuh cart empty — go grab some coconut water!';
  static const String subtotal = 'Subtotal';
  static const String deliveryFee = 'Delivery';
  static const String total = 'Total';
  static const String typeMyAddress = 'Type My Address';
  static const String useMyGpsLocation = 'Use My GPS Location';
  static const String placeOrder = 'Place Order';
  static const String removeItem = 'Remove item';
  static const String removeItemConfirm = 'Take dis one out di cart?';
  static const String phoneLabel = 'Phone Number';
  static const String addressLabel = 'Delivery Address';
  static const String addressHint = 'House #, street, town, parish';
  static const String acquiringLocation = 'Finding yuh location…';
  static const String lowAccuracyWarning =
      'Location accuracy is low — di driver might need a call. Add a note if yuh can.';

  // --- Order confirmation ---
  static const String orderPlaced = 'Order Placed!';
  static const String freshnessComing = 'Wi bringing di freshness to yuh! 🇯🇲🥥';
  static const String estimatedDelivery = 'Estimated delivery: 30–45 mins';
  static const String trackMyOrder = 'Track My Order';
  static const String backToHome = 'Back to Home';
  static const String shareOrder = 'Share Order';

  // --- My orders ---
  static const String myOrdersTitle = 'My Orders';
  static const String ordersEmpty = 'Yuh neva order nuttin yet!';
  static const String lookupPhonePrompt = 'Enter yuh phone number to see yuh orders';

  // --- Admin ---
  static const String adminAppName = 'Jamaica Chilled — Admin';
  static const String adminLogin = 'Admin Login';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String rememberMe = 'Remember me';
  static const String forgotPassword = 'Forgot password?';
  static const String signIn = 'Sign In';
  static const String logout = 'Log Out';
  static const String logoutConfirm = 'Log out of di admin console?';
  static const String dashboardTitle = 'Orders';
  static const String markDelivered = 'Mark Delivered';
  static const String callCustomer = 'Call Customer';
  static const String exportTodaysOrders = 'Export Today\'s Orders';
  static const String newOrderNotification = 'New Coconut Water Order! 🥥';

  // --- Admin: product catalogue ---
  static const String manageProducts = 'Products';
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit Product';
  static const String deleteProduct = 'Delete Product';
  static const String deleteProductConfirm =
      'Remove dis product from di menu? Dis can\'t be undone.';
  static const String productSaved = 'Product saved!';
  static const String productDeleted = 'Product removed.';
  static const String noProductsYet = 'No products yet — add di first one!';
  static const String productNameLabel = 'Product Name';
  static const String productSizeLabel = 'Size (ml)';
  static const String productPriceLabel = 'Price (JMD)';
  static const String productImageUrlLabel = 'Image URL (optional)';
  static const String productImageUrlHint = 'https://…/coconut.jpg';
  static const String productAvailableLabel = 'Available to order';
  static const String saveProduct = 'Save Product';

  // --- Patois flavour ---
  static const String allGood = 'Everyting criss!';
  static const String takeCare = 'Walk good!';
  static const String thankYou = 'Bless up!';
  static const String comingSoon = 'Soon come!';
  static const String feelingGood = 'Irie!';

  // --- Errors (friendly) ---
  static const String offlineBanner = 'Yuh offline — wi saved it, will send when di signal come back.';
  static const String networkError = 'Network a act up. Check yuh connection an\' try again.';
  static const String serverError = 'Someting went wrong pon our side. Try again shortly.';
  static const String locationDenied = 'Location off. Turn it on or type yuh address instead.';
  static const String locationDeniedForever =
      'Location blocked in settings. Open settings to allow it, or type yuh address.';
  static const String genericError = 'Someting nuh right. Try again.';
}
