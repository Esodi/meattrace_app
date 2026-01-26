import 'package:flutter/material.dart';
import '../../models/product_category.dart';
import '../../services/api_service.dart';

class AddProductCategoryScreen extends StatefulWidget {
  final ProductCategory? initialCategory;

  const AddProductCategoryScreen({super.key, this.initialCategory});

  @override
  _AddProductCategoryScreenState createState() =>
      _AddProductCategoryScreenState();
}

class _AddProductCategoryScreenState extends State<AddProductCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';

  bool get isEditing => widget.initialCategory != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product Category' : 'Add Product Category',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Category Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _saveCategory();
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Save Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCategory() async {
    if (isEditing) {
      final updated = ProductCategory(
        id: widget.initialCategory!.id,
        name: _name,
        description: _description,
      );
      try {
        await ApiService().updateProductCategory(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category updated successfully!')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update category: $e')),
        );
      }
    } else {
      final newCategory = ProductCategory(
        name: _name,
        description: _description,
      );

      try {
        await ApiService().addProductCategory(newCategory);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Category added successfully!')));
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add category: $e')));
      }
    }
  }
}
