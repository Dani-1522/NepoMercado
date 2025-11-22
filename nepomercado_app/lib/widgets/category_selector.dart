
import 'package:flutter/material.dart';
import '../config/categories.dart';

class CategorySelector extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final bool scrollable;

  const CategorySelector({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.scrollable = true,
  }) : super(key: key);

  @override
  _CategorySelectorState createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  @override
  Widget build(BuildContext context) {
    final categories = ProductCategories.allCategories;

    Widget selector = ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryChip(category);
      },
    );

    if (!widget.scrollable) {
      selector = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map(_buildCategoryChip).toList(),
      );
    }

    return Container(
      height: widget.scrollable ? 60 : null,
      child: selector,
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = widget.selectedCategory == category;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ProductCategories.getIcon(category)),
            const SizedBox(width: 6),
            Text(
              _getCategoryDisplayName(category),
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            widget.onCategoryChanged(category);
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: ProductCategories.getColor(category),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    final names = {
      'todos': 'Todos',
      'comida': 'Comida',
      'ropa': 'Ropa',
      'artesanias': 'Artesanías',
      'electronica': 'Electrónica',
      'hogar': 'Hogar',
      'deportes': 'Deportes',
      'libros': 'Libros',
      'joyeria': 'Joyería',
      'salud': 'Salud',
      'belleza': 'Belleza',
      'juguetes': 'Juguetes',
      'mascotas': 'Mascotas',
      'otros': 'Otros',
    };
    return names[category] ?? category;
  }
}