import '../../../../core/utils/formatters.dart';
import '../entities/customer_order.dart';
import '../repositories/order_repository.dart';

/// Fetches a customer's order history, normalising the phone number first.
class GetOrdersByPhone {
  const GetOrdersByPhone(this._repository);

  final OrderRepository _repository;

  Future<List<CustomerOrder>> call(String rawPhone) =>
      _repository.getOrdersByPhone(Formatters.toE164Jamaican(rawPhone));
}
