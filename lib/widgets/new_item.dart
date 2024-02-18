// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});
  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();

  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.other]!;
  bool _isSending = false;

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      try {
        final url = Uri.https(
            'shopping-list-backend-53b85-default-rtdb.firebaseio.com',
            'shopping-list.json');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(
            {
              'name': _enteredName,
              'quantity': _enteredQuantity,
              'category': _selectedCategory.title,
            },
          ),
        );

        final Map<String, dynamic> listData = json.decode(response.body);

        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop(
          GroceryItem(
            id: listData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory,
          ),
        );
      } catch (error) {
        _showInfoMessage('Failed to add item. Please try again later.');
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a new item'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.text,
                  maxLength: 50,
                  decoration: const InputDecoration(
                      // labelText: 'Name',
                      label: Text('Name')),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    } else if (value.trim().length <= 2) {
                      return 'Name must be at least 2 characters long';
                    } else if (value.trim().length > 50) {
                      return 'Name must be less than 50 characters long';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredName = value!;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(label: Text('Quantity')),
                        initialValue: '1',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a quantity';
                          } else if (int.tryParse(value) == null) {
                            return 'Quantity must be a number';
                          } else if (int.tryParse(value)! <= 0) {
                            return 'Quantity must be greater than 0';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredQuantity = int.parse(value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField(
                          value: _selectedCategory,
                          items: [
                            for (final category in categories.entries)
                              DropdownMenuItem(
                                value: category.value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: category.value.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(category.value.title),
                                  ],
                                ),
                              )
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSending
                          ? null
                          : () {
                              _formKey.currentState!.reset();
                            },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                        onPressed: _isSending ? null : _submitForm,
                        child: _isSending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(),
                              )
                            : const Text('Add Item'))
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
