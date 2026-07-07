import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/customer_order.dart';
import '../../domain/entities/delivery_details.dart';
import '../../domain/entities/order_draft.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';

/// Firestore (de)serialization for orders.
///
/// Two directions live here:
/// * [draftToFirestore] — the map written when placing an order.
/// * [fromDoc] — a persisted [CustomerOrder] read back for history.
abstract final class OrderModel {
  const OrderModel._();

  /// Builds the Firestore payload for a new order.
  static Map<String, dynamic> draftToFirestore(OrderDraft draft) {
    final DeliveryDetails d = draft.delivery;
    return <String, dynamic>{
      'customerPhone': draft.customerPhone,
      'deliveryMethod': d.method.wireValue,
      'deliveryAddress': _addressForWire(d),
      'gpsCoordinates': d.coordinates == null
          ? null
          : GeoPoint(d.coordinates!.latitude, d.coordinates!.longitude),
      'items': draft.items.map(_itemToMap).toList(),
      'subtotal': draft.subtotal,
      'deliveryFee': draft.deliveryFee,
      'total': draft.total,
      'status': OrderStatus.newOrder.wireValue,
      'statusHistory': <Map<String, dynamic>>[
        <String, dynamic>{
          'status': OrderStatus.newOrder.wireValue,
          'timestamp': Timestamp.now(),
          'updatedBy': 'customer',
        },
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'adminId': null,
    };
  }

  /// A JSON-safe version of the payload for the offline (Hive) queue.
  ///
  /// Server sentinels/`GeoPoint` can't be stored locally, so coordinates become
  /// plain numbers and timestamps are dropped (re-applied on sync).
  static Map<String, dynamic> draftToQueueJson(OrderDraft draft) {
    final DeliveryDetails d = draft.delivery;
    return <String, dynamic>{
      'customerPhone': draft.customerPhone,
      'deliveryMethod': d.method.wireValue,
      'deliveryAddress': _addressForWire(d),
      'lat': d.coordinates?.latitude,
      'lng': d.coordinates?.longitude,
      'items': draft.items.map(_itemToMap).toList(),
      'subtotal': draft.subtotal,
      'deliveryFee': draft.deliveryFee,
      'total': draft.total,
    };
  }

  /// Rebuilds a Firestore payload from a queued (offline) order json, adding
  /// the server-side fields that were deferred while offline.
  static Map<String, dynamic> queueJsonToFirestore(Map<String, dynamic> json) {
    final double? lat = (json['lat'] as num?)?.toDouble();
    final double? lng = (json['lng'] as num?)?.toDouble();
    return <String, dynamic>{
      'customerPhone': json['customerPhone'],
      'deliveryMethod': json['deliveryMethod'],
      'deliveryAddress': json['deliveryAddress'],
      'gpsCoordinates': (lat != null && lng != null) ? GeoPoint(lat, lng) : null,
      'items': json['items'],
      'subtotal': json['subtotal'],
      'deliveryFee': json['deliveryFee'],
      'total': json['total'],
      'status': OrderStatus.newOrder.wireValue,
      'statusHistory': <Map<String, dynamic>>[
        <String, dynamic>{
          'status': OrderStatus.newOrder.wireValue,
          'timestamp': Timestamp.now(),
          'updatedBy': 'customer',
        },
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'adminId': null,
    };
  }

  static CustomerOrder fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? const <String, dynamic>{};
    return CustomerOrder(
      id: doc.id,
      customerPhone: (data['customerPhone'] as String?) ?? '',
      delivery: _deliveryFromData(data),
      items: _itemsFromData(data['items']),
      subtotal: (data['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromWire(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // --- Helpers ---

  static String? _addressForWire(DeliveryDetails d) =>
      d.method == DeliveryMethod.address ? d.typedAddress : d.resolvedAddress;

  static Map<String, dynamic> _itemToMap(OrderItem i) => <String, dynamic>{
        'productId': i.productId,
        'productName': i.productName,
        'size': i.size,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
      };

  static List<OrderItem> _itemsFromData(Object? raw) {
    if (raw is! List) return const <OrderItem>[];
    return raw.whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> m) {
      return OrderItem(
        productId: (m['productId'] as String?) ?? '',
        productName: (m['productName'] as String?) ?? 'Coconut Water',
        size: (m['size'] as String?) ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (m['unitPrice'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static DeliveryDetails _deliveryFromData(Map<String, dynamic> data) {
    final DeliveryMethod method =
        DeliveryMethod.fromWire(data['deliveryMethod'] as String?);
    final GeoPoint? point = data['gpsCoordinates'] as GeoPoint?;
    if (method == DeliveryMethod.gps && point != null) {
      return DeliveryDetails.gps(
        coordinates:
            GeoCoordinate(latitude: point.latitude, longitude: point.longitude),
        resolvedAddress: data['deliveryAddress'] as String?,
      );
    }
    return DeliveryDetails.typed((data['deliveryAddress'] as String?) ?? '');
  }
}
