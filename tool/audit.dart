import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pawpick/data/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every product has at least one valid image asset', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assetPaths = <String>{...manifest.listAssets()};

    for (final product in products) {
      expect(product.images, isNotEmpty,
          reason: 'Product ${product.id} has no image list.');
      for (final imagePath in product.images) {
        expect(
          assetPaths.contains(imagePath),
          isTrue,
          reason: 'Missing asset for ${product.id}: $imagePath',
        );
      }
    }
  });

  test('money formatting is centralized and uses the bundled peso glyph', () async {
    final libRoot = Directory('lib');
    final files = await libRoot
        .list(recursive: true, followLinks: false)
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .cast<File>()
        .toList();

    for (final file in files) {
      final relativePath = file.path.replaceAll('\\', '/');
      if (relativePath.endsWith('/core/utils/money.dart') ||
          relativePath.endsWith('/app/config.dart')) {
        continue;
      }

      final text = await file.readAsString();
      final hasMoneyFormatting = text.contains('NumberFormat.currency') ||
          text.contains('toStringAsFixed(2)') ||
          text.contains('₱') ||
          text.contains('\\u20B1');

      expect(
        hasMoneyFormatting,
        isFalse,
        reason: 'Move money formatting out of $relativePath and keep it in the money utility.',
      );
    }
  });
}
