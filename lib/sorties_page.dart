import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'models.dart';
import 'people_provider.dart';
import 'pdf_generator.dart';
import 'sortie_provider.dart';
import 'stock_provider.dart';

class SortiesPage extends StatefulWidget {
  const SortiesPage({super.key});

  @override
  State<SortiesPage> createState() => _SortiesPageState();
}

class _SortiesPageState extends State<SortiesPage> {
  DateTime _selectedDate = DateTime.now();

  void _showMonthYearPicker(BuildContext context) {
    final yearController = TextEditingController(
      text: _selectedDate.year.toString(),
    );
    int selectedMonth = _selectedDate.month;
    const frenchMonths = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sélectionner un mois'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: 'Année'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(frenchMonths[index]),
                      );
                    }),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedMonth = newValue;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                final year = int.tryParse(yearController.text);
                if (year != null) {
                  this.setState(() {
                    _selectedDate = DateTime(year, selectedMonth);
                  });
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    const frenchMonths = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return frenchMonths[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Sorties (${_getMonthName(_selectedDate.month)} ${_selectedDate.year})',
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Sélectionner un Mois',
              onPressed: () => _showMonthYearPicker(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Actives'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SortieList(status: 'active', selectedDate: _selectedDate),
            _SortieList(status: 'completed', selectedDate: _selectedDate),
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
  final DateTime selectedDate;
  const _SortieList({required this.status, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Consumer<SortieProvider>(
      builder: (context, provider, child) {
        final allSorties = status == 'active'
            ? provider.activeSorties
            : provider.historySorties;

        // Filter by selected month and year based on departure date
        final list = allSorties.where((s) {
          return s.departureDate.year == selectedDate.year &&
              s.departureDate.month == selectedDate.month;
        }).toList();

        if (list.isEmpty) {
          final statusFrench = status == 'active' ? 'actives' : 'terminées';
          return Center(
            child: Text('Aucune sortie $statusFrench pour ce mois.'),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final sortie = list[index];
            final bool hasMissing =
                status == 'completed' && sortie.hasMissingItems;

            return Card(
              margin: const EdgeInsets.all(8.0),
              color: hasMissing ? Colors.red.withOpacity(0.1) : null,
              child: ListTile(
                title: Text('Sortie ${sortie.displayId}'),
                subtitle: Text(
                  'Départ: ${sortie.departureDate.day}/${sortie.departureDate.month}/${sortie.departureDate.year}\nArticles: ${sortie.items.length}',
                ),
                trailing: hasMissing
                    ? const Icon(Icons.warning, color: Colors.red)
                    : const Icon(Icons.arrow_forward_ios),
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
  DateTime? _departureDate;
  DateTime? _returnDate;

  // Product Selection State
  String _selectedCategory = 'equipment';

  // Helper for date picking
  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isDeparture ? _departureDate : _returnDate) ??
          _departureDate ??
          DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

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

    // --- LOGIC FOR SEARCHABLE DROPDOWNS ---
    Person? findPersonById(List<Person> people, String? id) {
      if (id == null) return null;
      try {
        return people.firstWhere((p) => p.id == id);
      } catch (e) {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Sortie')),
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
                    DropdownSearch<Person>(
                      selectedItem: findPersonById(
                        allPeople,
                        _selectedResponsible,
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            labelText: "Rechercher une personne",
                          ),
                        ),
                        itemBuilder: (context, person, isSelected) => ListTile(
                          title: Text(person.name),
                          subtitle: Text(person.role),
                        ),
                      ),
                      items: allPeople,
                      itemAsString: (Person p) => p.name,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Responsable (Requis)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      onChanged: (Person? person) {
                        setState(() => _selectedResponsible = person?.id);
                      },
                      validator: (p) =>
                          p == null ? 'Responsable est requis' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownSearch<Person>(
                            selectedItem: findPersonById(
                              guides,
                              _selectedGuide,
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  labelText: "Rechercher un guide",
                                ),
                              ),
                            ),
                            items: guides,
                            itemAsString: (Person p) => p.name,
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Guide",
                                  ),
                                ),
                            onChanged: (Person? person) {
                              setState(() => _selectedGuide = person?.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownSearch<Person>(
                            selectedItem: findPersonById(
                              cuisiniers,
                              _selectedCuisinier,
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  labelText: "Rechercher un cuisinier",
                                ),
                              ),
                            ),
                            items: cuisiniers,
                            itemAsString: (Person p) => p.name,
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Cuisinier",
                                  ),
                                ),
                            onChanged: (Person? person) {
                              setState(() => _selectedCuisinier = person?.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Dates Selection
          ExpansionTile(
            title: const Text('Dates'),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de Départ',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _departureDate == null
                                ? 'Select Date'
                                : '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de Retour',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _returnDate == null
                                ? 'Select Date'
                                : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
                          ),
                        ),
                      ),
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
                  'Produits :',
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
            child: Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                final availableProducts = stockProvider.products
                    .where((p) => p.type == _selectedCategory)
                    .toList();

                return ListView.builder(
                  itemCount: availableProducts.length,
                  itemBuilder: (context, index) {
                    final product = availableProducts[index];
                    SortieItem? cartItem;
                    try {
                      cartItem = _cart.firstWhere(
                        (item) => item.productId == product.id,
                      );
                    } catch (e) {
                      cartItem = null;
                    }
                    final isAdded = cartItem != null;

                    final displayedStock = isAdded
                        ? product.currentQuantity - cartItem.quantityTaken
                        : product.currentQuantity;

                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        'En Stock: $displayedStock / ${product.initialQuantity}',
                      ),
                      trailing: isAdded
                          ? TextButton.icon(
                              icon: const Icon(Icons.edit),
                              label: Text(
                                'Pris : ${cartItem.quantityTaken}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => _showQuantityDialog(
                                context,
                                product,
                                cartItem: cartItem,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.green,
                              ),
                              tooltip: 'Ajouter au panier',
                              onPressed: () =>
                                  _showQuantityDialog(context, product),
                            ),
                    );
                  },
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
                Text('Articles à prendre : ${_cart.length}'),
                ElevatedButton(
                  onPressed:
                      _selectedResponsible == null ||
                          _cart.isEmpty ||
                          _departureDate == null ||
                          _returnDate == null
                      ? null
                      : _createSortie,
                  child: const Text('CONFIRMER LA SORTIE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(
    BuildContext context,
    Product product, {
    SortieItem? cartItem,
  }) {
    final isEditing = cartItem != null;
    final controller = TextEditingController(
      text: isEditing ? cartItem.quantityTaken.toString() : '1',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEditing ? 'Modifier ${product.name}' : 'Ajouter ${product.name}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantité'),
          autofocus: true,
        ),
        actions: [
          if (isEditing)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _cart.removeWhere((item) => item.productId == product.id);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Retirer'),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;

              if (qty < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La quantité ne peut pas être négative.'),
                  ),
                );
                return;
              }
              if (qty > product.currentQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pas assez en stock. Seulement ${product.currentQuantity} disponible(s).',
                    ),
                  ),
                );
                return;
              }

              setState(() {
                if (isEditing) {
                  if (qty > 0) {
                    cartItem.quantityTaken = qty;
                  } else {
                    _cart.removeWhere((item) => item.productId == product.id);
                  }
                } else {
                  if (qty > 0) {
                    _cart.add(
                      SortieItem(productId: product.id, quantityTaken: qty),
                    );
                  }
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  void _createSortie() {
    if (_selectedResponsible == null ||
        _departureDate == null ||
        _returnDate == null)
      return;
    Provider.of<SortieProvider>(context, listen: false).createSortie(
      guideId: _selectedGuide ?? '',
      cuisinierId: _selectedCuisinier,
      responsibleId: _selectedResponsible!,
      items: _cart,
      departureDate: _departureDate!,
      returnDate: _returnDate!,
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
  String _selectedCategory = 'Tous';

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
    final peopleProvider = Provider.of<PeopleProvider>(context, listen: false);
    final isReadOnly = widget.sortie.status == 'completed';

    String getPersonName(String? id) {
      if (id == null || id.isEmpty) return 'N/A';
      try {
        return peopleProvider.people.firstWhere((p) => p.id == id).name;
      } catch (e) {
        return 'Unknown Person';
      }
    }

    String formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails : Sortie ${widget.sortie.displayId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Générer le PDF',
            onPressed: () {
              generateSortiePdf(
                widget.sortie,
                stockProvider.products,
                peopleProvider.people,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Résumé de la Sortie'),
            initiallyExpanded: true,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Status'),
                subtitle: Text(widget.sortie.status.toUpperCase()),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Responsible'),
                subtitle: Text(getPersonName(widget.sortie.responsibleId)),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Guide'),
                subtitle: Text(getPersonName(widget.sortie.guideId)),
              ),
              ListTile(
                leading: const Icon(Icons.soup_kitchen),
                title: const Text('Cuisinier'),
                subtitle: Text(getPersonName(widget.sortie.cuisinierId)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Date de Création'),
                subtitle: Text(formatDate(widget.sortie.creationDate)),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: const Text('Date de Départ'),
                subtitle: Text(formatDate(widget.sortie.departureDate)),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Date de Retour'),
                subtitle: Text(formatDate(widget.sortie.returnDate)),
              ),
              if (widget.sortie.completionDate != null)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Date de Réalisation'),
                  subtitle: Text(formatDate(widget.sortie.completionDate!)),
                ),
            ],
          ),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails des Articles',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: ['Tous', 'Équipement', 'Secs', 'Frais']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategory = v!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.where((item) {
                if (_selectedCategory == 'Tous') return true;
                try {
                  final product = stockProvider.products.firstWhere(
                    (p) => p.id == item.productId,
                  );
                  return product.type.toLowerCase() ==
                      _getCategoryValue(_selectedCategory).toLowerCase();
                } catch (e) {
                  return false;
                }
              }).length,
              itemBuilder: (context, index) {
                final filteredItems = _items.where((item) {
                  if (_selectedCategory == 'Tous') return true;
                  try {
                    final product = stockProvider.products.firstWhere(
                      (p) => p.id == item.productId,
                    );
                    return product.type.toLowerCase() ==
                        _getCategoryValue(_selectedCategory).toLowerCase();
                  } catch (e) {
                    return false;
                  }
                }).toList();

                final item = filteredItems[index];
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
                            Text('Pris : ${item.quantityTaken}'),
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
                            'Manquant : $missing',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isReadOnly) ...[
                            CheckboxListTile(
                              title: const Text(
                                'Excusé ? (Événement incontrôlable)',
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
                              '(Excusé)',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                        const SizedBox(height: 8),
                        if (!isReadOnly)
                          TextFormField(
                            initialValue: item.note,
                            decoration: const InputDecoration(
                              labelText: 'Note (Optionnel)',
                              icon: Icon(Icons.note),
                            ),
                            onChanged: (val) => item.note = val,
                          )
                        else if (item.note != null && item.note!.isNotEmpty)
                          Text('Note : ${item.note}'),
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
                    'CLÔTURER LA SORTIE (RETOUR)',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryValue(String category) {
    switch (category) {
      case 'Équipement':
        return 'equipment';
      case 'Secs':
        return 'secs';
      case 'Frais':
        return 'frais';
      default:
        return 'all';
    }
  }
}
