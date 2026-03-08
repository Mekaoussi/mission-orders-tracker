import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'people_provider.dart';
import 'sortie_provider.dart';
import 'stock_provider.dart';

class SortiesPage extends StatelessWidget {
  const SortiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sorties Manager'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SortieList(status: 'active'),
            _SortieList(status: 'completed'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateSortiePage()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _SortieList extends StatelessWidget {
  final String status;
  const _SortieList({required this.status});

  @override
  Widget build(BuildContext context) {
    return Consumer<SortieProvider>(
      builder: (context, provider, child) {
        final list = status == 'active'
            ? provider.activeSorties
            : provider.historySorties;

        if (list.isEmpty) {
          return Center(child: Text('No $status sorties.'));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final sortie = list[index];
            // Helper to get names would be nice, but we'll just show IDs or simple info for now
            // In a real app, you'd look up the Person object by ID to show the name.
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  'Sortie #${sortie.id.substring(sortie.id.length - 4)}',
                ),
                subtitle: Text(
                  'Date: ${sortie.date.toString().split('.')[0]}\nItems: ${sortie.items.length}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SortieDetailPage(sortie: sortie),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// CREATE SORTIE PAGE
// ---------------------------------------------------------------------------

class CreateSortiePage extends StatefulWidget {
  const CreateSortiePage({super.key});

  @override
  State<CreateSortiePage> createState() => _CreateSortiePageState();
}

class _CreateSortiePageState extends State<CreateSortiePage> {
  String? _selectedResponsible;
  String? _selectedGuide;
  String? _selectedCuisinier;
  final List<SortieItem> _cart = [];

  // Product Selection State
  String _selectedCategory = 'equipment';

  @override
  Widget build(BuildContext context) {
    final peopleProvider = Provider.of<PeopleProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);

    final guides = peopleProvider.people
        .where((p) => p.role == 'guide')
        .toList();
    final cuisiniers = peopleProvider.people
        .where((p) => p.role == 'cuisinier')
        .toList();
    final allPeople = peopleProvider.people;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sortie')),
      body: Column(
        children: [
          // 1. People Selection
          ExpansionTile(
            title: const Text('Personnel'),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Responsible (Required)',
                        border: OutlineInputBorder(),
                      ),
                      items: allPeople
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (${p.role})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedResponsible = v),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Guide',
                            ),
                            items: guides
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGuide = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Cuisinier',
                            ),
                            items: cuisiniers
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCuisinier = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Product Selection
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Products:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: ['equipment', 'secs', 'frais']
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: stockProvider.products.length,
              itemBuilder: (context, index) {
                final product = stockProvider.products[index];
                // Filter by category
                if (product.type != _selectedCategory) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('In Stock: ${product.currentQuantity}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      _showQuantityDialog(context, product);
                    },
                  ),
                );
              },
            ),
          ),

          // 3. Cart Summary
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Items to take: ${_cart.length}'),
                ElevatedButton(
                  onPressed: _selectedResponsible == null || _cart.isEmpty
                      ? null
                      : _createSortie,
                  child: const Text('CONFIRM SORTIE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Product product) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              if (qty > 0 && qty <= product.currentQuantity) {
                setState(() {
                  _cart.add(
                    SortieItem(productId: product.id, quantityTaken: qty),
                  );
                });
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid quantity')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _createSortie() {
    if (_selectedResponsible == null) return;
    Provider.of<SortieProvider>(context, listen: false).createSortie(
      guideId: _selectedGuide ?? '',
      cuisinierId: _selectedCuisinier,
      responsibleId: _selectedResponsible!,
      items: _cart,
    );
    Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// SORTIE DETAIL / RETURN PAGE
// ---------------------------------------------------------------------------

class SortieDetailPage extends StatefulWidget {
  final Sortie sortie;
  const SortieDetailPage({super.key, required this.sortie});

  @override
  State<SortieDetailPage> createState() => _SortieDetailPageState();
}

class _SortieDetailPageState extends State<SortieDetailPage> {
  // We keep a local copy of items to edit before saving
  late List<SortieItem> _items;

  @override
  void initState() {
    super.initState();
    // Deep copy logic or just reference?
    // Since we want to edit "returned" values, we can just use the existing objects
    // but we need to be careful not to save until confirmed.
    // For simplicity, we will modify the objects directly but only call 'completeSortie' on save.
    _items = widget.sortie.items;

    // Initialize returned quantity to taken quantity if it's 0 (for easier UI)
    for (var item in _items) {
      if (item.quantityReturned == 0 && widget.sortie.status == 'active') {
        item.quantityReturned = item.quantityTaken;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final isReadOnly = widget.sortie.status == 'completed';

    return Scaffold(
      appBar: AppBar(title: const Text('Sortie Details')),
      body: Column(
        children: [
          // Header Info
          ListTile(
            title: Text('Status: ${widget.sortie.status.toUpperCase()}'),
            subtitle: Text('Date: ${widget.sortie.date}'),
            tileColor: isReadOnly ? Colors.grey[200] : Colors.blue[50],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                // Find product name
                final product = stockProvider.products.firstWhere(
                  (p) => p.id == item.productId,
                  orElse: () => Product(
                    id: '',
                    name: 'Unknown',
                    type: '',
                    initialQuantity: 0,
                    currentQuantity: 0,
                  ),
                );

                final missing = item.quantityTaken - item.quantityReturned;
                final hasDeficit = missing > 0;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Taken: ${item.quantityTaken}'),
                            const SizedBox(width: 20),
                            if (!isReadOnly)
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.quantityReturned
                                      .toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Returned',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      item.quantityReturned =
                                          int.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              )
                            else
                              Text('Returned: ${item.quantityReturned}'),
                          ],
                        ),
                        if (hasDeficit) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Missing: $missing',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isReadOnly) ...[
                            CheckboxListTile(
                              title: const Text(
                                'Excused? (Uncontrollable event)',
                              ),
                              value: item.isExcused,
                              onChanged: (val) {
                                setState(() {
                                  item.isExcused = val ?? false;
                                });
                              },
                            ),
                          ] else if (item.isExcused)
                            const Text(
                              '(Excused)',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                        const SizedBox(height: 8),
                        if (!isReadOnly)
                          TextFormField(
                            initialValue: item.note,
                            decoration: const InputDecoration(
                              labelText: 'Note (Optional)',
                              icon: Icon(Icons.note),
                            ),
                            onChanged: (val) => item.note = val,
                          )
                        else if (item.note != null && item.note!.isNotEmpty)
                          Text('Note: ${item.note}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!isReadOnly)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    // Confirm Return
                    Provider.of<SortieProvider>(
                      context,
                      listen: false,
                    ).completeSortie(widget.sortie, _items);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'CLOSE SORTIE (RETURN)',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
