import '../../../../core/errors/failures.dart';
import '../entities/order_draft.dart';
import '../repositories/order_repository.dart';

/// Places an order after guarding against an empty cart.
class PlaceOrder {
  const PlaceOrder(this._repository);

  final OrderRepository _repository;

  Future<PlacedOrder> call(OrderDraft draft) {
    if (draft.isEmpty) {
      throw const ServerFailure('Yuh cart empty — add someting first.');
    }
    return _repository.placeOrder(draft);
  }
}
