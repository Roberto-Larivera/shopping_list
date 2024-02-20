import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'dart:convert';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});
  @override
  State<StatefulWidget> createState() {
    return _GroceryListState();
  }
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'shopping-list-backend-53b85-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items. Please try again later.');
    }

    if (json.decode(response.body) == null) {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    if (listData.isEmpty) {
      return [];
    }

    final List<GroceryItem> loadedItems = [];

    for (var item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
        id: item.key,
        name: item.value['name'],
        quantity: item.value['quantity'],
        category: category,
      ));
    }

    return loadedItems;
  }

  void _addNewItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (ctx) => const NewItem(),
    ));

    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
    _showInfoMessage('Item added!');
  }

  void _removeItem(GroceryItem item) async {
    final url = Uri.https(
        'shopping-list-backend-53b85-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        _groceryItems.remove(item);
      });
      _showInfoMessage('Item removed!');
    } else {
      _showInfoMessage('Failed to remove item!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewItem,
          ),
        ],
      ),
      body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text(
                snapshot.error.toString(),
              ));
            }

            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No items yet!'),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (ctx, index) => Dismissible(
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                key: ValueKey(snapshot.data![index].id),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text('${snapshot.data![index].quantity}'),
                ),
              ),
            );
          }),
    );
  }
}
