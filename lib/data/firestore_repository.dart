import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../domain/models/order.dart';

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    int pawPoints = 0,
  }) {
    return _firestore.collection('users').doc(uid).set(
      {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'pawPoints': pawPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> ensureGoogleProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final reference = _firestore.collection('users').doc(uid);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      await saveProfile(
        uid: uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        pawPoints: 0,
      );
    } else {
      await reference.set(
        {
          'name': name,
          'email': email,
          'photoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> saveOrder(String uid, Order order) {
    return _firestore.collection('users').doc(uid).collection('orders').doc(order.number).set({
    'userId': uid,
    'number': order.number,
      'subtotalMinor': order.subtotalMinor,
      'shippingMinor': order.shippingMinor,
      'totalMinor': order.totalMinor,
      'paymentMethod': order.paymentMethod,
      'status': order.status.name,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'address': {
        'fullName': order.address.fullName,
        'phone': order.address.phone,
        'line': order.address.line,
        'city': order.address.city,
        'postalCode': order.address.postalCode,
      },
      'items': order.items
          .map(
            (item) => {
              'productId': item.productId,
              'name': item.name,
              'image': item.image,
              'unitPriceMinor': item.unitPriceMinor,
              'quantity': item.quantity,
              'variantId': item.variantId,
              'styleId': item.styleId,
              'color': item.color,
              'size': item.size,
            },
          )
          .toList(),
    });
  }
}

final firestoreRepository = FirestoreRepository();
