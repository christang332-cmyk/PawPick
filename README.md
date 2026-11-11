# PawPick

Pet accessories for little things and big joy.

## Asset rights

The product photos currently bundled under `assets/images/products/` are sourced
from third-party brand listings and are placeholders for development. Replace
them with licensed or owned photography before any public release.

## How to edit products

- Update the catalog only in `lib/data/seed_data.dart`.
- Do not rename image files without updating the matching `images` list in the seed.
- Run `dart run tool/audit.dart` (or `flutter test`) after changing product data or assets.
- If you change any asset or font file, do a full app stop and run `flutter run` again; hot reload does not reload native assets or fonts.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
