// config/categories.dart
import 'package:flutter/material.dart';

class ProductCategories {
  static const List<String> allCategories = [
    'todos',
    'comida',
    'ropa',
    'artesanias',
    'electronica',
    'hogar',
    'deportes',
    'libros',
    'joyeria',
    'salud',
    'belleza',
    'juguetes',
    'mascotas',
    'otros'
  ];

  static const Map<String, String> categoryIcons = {
    'todos': '',
    'comida': '🍕',
    'ropa': '👕',
    'artesanias': '🎨',
    'electronica': '📱',
    'hogar': '🏠',
    'deportes': '⚽',
    'libros': '📚',
    'joyeria': '💎',
    'salud': '💊',
    'belleza': '💄',
    'juguetes': '🧸',
    'mascotas': '🐕',
    'otros': '📦'
  };

  static const Map<String, Color> categoryColors = {
    'todos': Colors.blue,
    'comida': Colors.orange,
    'ropa': Colors.pink,
    'artesanias': Colors.brown,
    'electronica': Colors.purple,
    'hogar': Colors.green,
    'deportes': Colors.red,
    'libros': Colors.indigo,
    'joyeria': Colors.amber,
    'salud': Colors.teal,
    'belleza': Colors.deepPurple,
    'juguetes': Colors.cyan,
    'mascotas': Colors.lightGreen,
    'otros': Colors.grey,
  };

  static String getIcon(String category) {
    return categoryIcons[category] ?? '📦';
  }

  static Color getColor(String category) {
    return categoryColors[category] ?? Colors.grey;
  }
}