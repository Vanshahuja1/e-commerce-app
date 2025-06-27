import 'package:flutter/material.dart';
import '../../utils/app_routes.dart'; // Adjust the path as needed

class CategorySection extends StatelessWidget {
  const CategorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Fruits', 'icon': Icons.apple, 'color': Colors.red.shade400},
      {'name': 'Vegetables', 'icon': Icons.eco, 'color': Colors.green.shade400},
      {'name': 'Dairy', 'icon': Icons.local_drink, 'color': Colors.blue.shade400},
      {'name': 'Grains & Cereals', 'icon': Icons.grain, 'color': Colors.amber.shade400},
      {'name': 'Pulses & Legumes', 'icon': Icons.circle, 'color': Colors.brown.shade400},
      {'name': 'Spices & Herbs', 'icon': Icons.local_florist, 'color': Colors.green.shade600},
      {'name': 'Cooking Oils', 'icon': Icons.opacity, 'color': Colors.yellow.shade600},
      {'name': 'Beverages', 'icon': Icons.local_cafe, 'color': Colors.orange.shade400},
      {'name': 'Snacks & Processed', 'icon': Icons.cookie, 'color': Colors.purple.shade400},
      {'name': 'Condiments & Sauces', 'icon': Icons.restaurant, 'color': Colors.red.shade600},
      {'name': 'Seafood & Meat', 'icon': Icons.set_meal, 'color': Colors.pink.shade400},
      {'name': 'Bakery', 'icon': Icons.cake, 'color': Colors.orange.shade400},
      {'name': 'Frozen Foods', 'icon': Icons.ac_unit, 'color': Colors.cyan.shade400},
      {'name': 'Household Items', 'icon': Icons.home, 'color': Colors.grey.shade600},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 4),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  width: 85,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.search,
                        arguments: {'category': category['name']},
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: (category['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: (category['color'] as Color).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            size: 30,
                            color: category['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Container(
                            width: 80,
                            child: Text(
                              category['name'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}