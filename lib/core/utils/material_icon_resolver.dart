import 'package:flutter/material.dart';

class MaterialIconResolver {
  const MaterialIconResolver._();

  static final Map<int, IconData> _icons = {
    Icons.card_giftcard.codePoint: Icons.card_giftcard,
    Icons.category.codePoint: Icons.category,
    Icons.category_rounded.codePoint: Icons.category_rounded,
    Icons.directions_car.codePoint: Icons.directions_car,
    Icons.grid_view_rounded.codePoint: Icons.grid_view_rounded,
    Icons.health_and_safety.codePoint: Icons.health_and_safety,
    Icons.more_horiz.codePoint: Icons.more_horiz,
    Icons.movie.codePoint: Icons.movie,
    Icons.payments.codePoint: Icons.payments,
    Icons.receipt_long.codePoint: Icons.receipt_long,
    Icons.redeem.codePoint: Icons.redeem,
    Icons.restaurant.codePoint: Icons.restaurant,
    Icons.savings.codePoint: Icons.savings,
    Icons.school.codePoint: Icons.school,
    Icons.shopping_bag.codePoint: Icons.shopping_bag,
    Icons.trending_up.codePoint: Icons.trending_up,
    Icons.work.codePoint: Icons.work,
  };

  static IconData fromCodePoint(
    int? codePoint, {
    IconData fallback = Icons.category,
  }) {
    if (codePoint == null) {
      return fallback;
    }
    return _icons[codePoint] ?? fallback;
  }
}
