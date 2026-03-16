import '../../models/menu_item.dart';
import 'package:flutter/material.dart';

class CategoryNavBar extends StatelessWidget {
  final Function(MenuItem) onItemTap;

  const CategoryNavBar({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final menuItems = MenuItem.getDefaultMenuItems();

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF0F8FF)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All Categories',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isComingSoon
                          ? Colors.grey.shade200
                          : const Color(0xFF35a3d9).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: item.isComingSoon
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  trailing: item.isComingSoon
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF5C6F8A),
                          size: 20,
                        ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    onItemTap(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
