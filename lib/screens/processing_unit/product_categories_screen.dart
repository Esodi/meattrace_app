import 'package:flutter/material.dart';
import '../../models/product_category.dart';
import '../../services/api_service.dart';
import 'add_product_category_screen.dart';
import '../../widgets/product_category_card.dart';

class ProductCategoriesScreen extends StatefulWidget {
  const ProductCategoriesScreen({Key? key}) : super(key: key);

  @override
  _ProductCategoriesScreenState createState() => _ProductCategoriesScreenState();
}

class _ProductCategoriesScreenState extends State<ProductCategoriesScreen> with SingleTickerProviderStateMixin {
  late Future<List<ProductCategory>> _categories;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _categories = _fetchCategories();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<List<ProductCategory>> _fetchCategories() async {
    return await ApiService().fetchProductCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Product Categories', style: theme.textTheme.titleLarge),
        centerTitle: false,
      ),
      body: FutureBuilder<List<ProductCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories found.'));
          } else {
            final categories = snapshot.data!;
            // start entrance animation
            _animController.forward(from: 0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.hintColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration.collapsed(hintText: 'Search categories...'),
                            onChanged: (v) {
                              // quick local filtering could be added later
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            // navigate to add
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductCategoryScreen()));
                            setState(() {
                              _categories = _fetchCategories();
                            });
                          },
                          icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisExtent: 92,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final animation = CurvedAnimation(
                          parent: _animController,
                          curve: Interval((index / categories.length).clamp(0.0, 1.0), 1.0, curve: Curves.easeOut),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: Offset(0, 0.06), end: Offset.zero).animate(animation),
                            child: ProductCategoryCard(
                              category: category,
                              onTap: () {
                                // placeholder - could open category detail
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${category.name}')));
                              },
                              onEdit: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductCategoryScreen(initialCategory: category)));
                                if (result == true) {
                                  setState(() {
                                    _categories = _fetchCategories();
                                  });
                                }
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete category'),
                                    content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  try {
                                    await ApiService().deleteProductCategory(category.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category deleted')));
                                    setState(() {
                                      _categories = _fetchCategories();
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete category: $e')));
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }
        },
      ),
      // keep FAB for quick create (also accessible from search bar)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductCategoryScreen()));
          setState(() {
            _categories = _fetchCategories();
          });
        },
        label: Text('Add Category'),
        icon: Icon(Icons.add),
      ),
    );
  }
}