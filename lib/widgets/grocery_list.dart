import 'package:flutter/material.dart';
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
  final List<GroceryItem> _groceryItems = [];
  void _addNewItem() async {
    final result =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (ctx) => const NewItem(),
    ));

    if (result == null) {
      return;
    }

    setState(() {
      _groceryItems.add(result);
    });
  }

  void _removeItem(GroceryItem item) {
    setState(() {
      _groceryItems.remove(item);
    });
  }


  @override
  Widget build(BuildContext context) {

    Widget content = const Center(
      child: Text('No items yet!'),
    );
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed:(direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text('${_groceryItems[index].quantity}'),
          ),
        ),
      );
    }

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
      body: content,
    );
  }
}
