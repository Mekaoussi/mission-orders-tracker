import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'constants.dart';
import 'models.dart';
import 'people_provider.dart';
import 'pdf_generator.dart';
import 'sortie_provider.dart';
import 'stock_provider.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Panneau d'Administration"),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Réinitialiser la base de données',
              onPressed: () => _showResetDatabaseDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Produits'),
              Tab(text: 'Guides'),
              Tab(text: 'Cuisiniers'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductsTab(),
            _PeopleTab(role: 'guide'),
            _PeopleTab(role: 'cuisinier'),
          ],
        ),
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser toute la base de données ?'),
        content: const Text(
          "Ceci supprimera TOUTES les données (produits, personnel, sorties) et ne peut être annulé. L'application devra être redémarrée après cette action.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              // Close all boxes to release file locks before deleting
              await Hive.close();

              for (final boxName in hiveBoxNames) {
                await Hive.deleteBoxFromDisk(boxName);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Base de données supprimée. Veuillez REDÉMARRER l'application maintenant.",
                  ),
                  duration: Duration(seconds: 6),
                ),
              );
            },
            child: const Text('TOUT SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filtrer par Catégorie',
                border: OutlineInputBorder(),
              ),
              items: ['All', 'equipment', 'secs', 'frais']
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(_translateCategory(category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, provider, child) {
                final filteredProducts = _selectedCategory == 'All'
                    ? provider.products
                    : provider.products
                          .where((p) => p.type == _selectedCategory)
                          .toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Aucun produit dans cette catégorie.'),
                  );
                }
                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${_translateCategory(product.type)} | Init: ${product.initialQuantity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditProductDialog(context, product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer le Produit'),
                                  content: Text('Supprimer ${product.name} ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        provider.deleteProduct(product);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'equipment':
        return 'Équipement';
      case 'secs':
        return 'Secs';
      case 'frais':
        return 'Frais';
      default:
        return 'Tous';
    }
  }

  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String? selectedType;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter un Nouveau Produit'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        hint: const Text('Type'),
                        items: ['equipment', 'secs', 'frais']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(_translateCategory(t)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedType = v),
                        validator: (v) => v == null ? 'Requis' : null,
                      ),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Qté Initiale',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (int.tryParse(v) == null) return 'Nombre invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newProduct = Product(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        type: selectedType!,
                        initialQuantity: int.parse(quantityController.text),
                        currentQuantity: int.parse(quantityController.text),
                      );
                      Provider.of<StockProvider>(
                        context,
                        listen: false,
                      ).addProduct(newProduct);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final quantityController = TextEditingController(
      text: product.initialQuantity.toString(),
    );
    String? selectedType = product.type;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier ${product.name}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: ['equipment', 'secs', 'frais']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(_translateCategory(t)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedType = v),
                      ),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Qté Initiale',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (int.tryParse(v) == null) return 'Nombre invalide';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      product.name = nameController.text;
                      product.type = selectedType!;
                      product.initialQuantity = int.parse(
                        quantityController.text,
                      );
                      Provider.of<StockProvider>(
                        context,
                        listen: false,
                      ).updateProduct(product);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PeopleTab extends StatelessWidget {
  final String role;
  const _PeopleTab({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PeopleProvider>(
        builder: (context, provider, child) {
          final people = provider.people.where((p) => p.role == role).toList();

          if (people.isEmpty) {
            return Center(child: Text('Aucun $role trouvé.'));
          }

          return ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              return ListTile(
                title: Text(person.name),
                subtitle: Text('Score : ${person.score} | ${person.phone}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditPersonDialog(context, person),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.purple,
                      ),
                      onPressed: () => _showReportDialog(context, person, role),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Supprimer $role'),
                            content: Text('Supprimer ${person.name} ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deletePerson(person);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPersonDialog(context, role),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context, String role) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add New $role'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newPerson = Person(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    phone: phoneController.text,
                    role: role,
                  );
                  Provider.of<PeopleProvider>(
                    context,
                    listen: false,
                  ).addPerson(newPerson);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: person.name);
    final phoneController = TextEditingController(text: person.phone);
    final scoreController = TextEditingController(
      text: person.score.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier ${person.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: scoreController,
                decoration: const InputDecoration(labelText: 'Score'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (int.tryParse(v) == null) return 'Nombre invalide';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                person.name = nameController.text;
                person.phone = phoneController.text;
                person.score = int.parse(scoreController.text);
                Provider.of<PeopleProvider>(
                  context,
                  listen: false,
                ).updatePerson(person);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, Person person, String role) {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Sélectionner la période'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Date de début'),
                    subtitle: Text(
                      startDate == null
                          ? 'jj/mm/aaaa'
                          : DateFormat('dd/MM/yyyy').format(startDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => startDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Date de fin'),
                    subtitle: Text(
                      endDate == null
                          ? 'jj/mm/aaaa'
                          : DateFormat('dd/MM/yyyy').format(endDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: (startDate != null && endDate != null)
                      ? () {
                          if (startDate!.isAfter(endDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La date de début doit être avant la date de fin.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(dialogContext);
                          _generateReport(
                            context,
                            person,
                            startDate!,
                            endDate!,
                          );
                        }
                      : null,
                  child: const Text('Générer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateReport(
    BuildContext context,
    Person person,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Use context to get providers
    final sortieProvider = Provider.of<SortieProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final peopleProvider = Provider.of<PeopleProvider>(context, listen: false);

    final personSorties = sortieProvider.sorties.where((sortie) {
      final isResponsible = sortie.responsibleId == person.id;
      final isInDateRange =
          !sortie.departureDate.isBefore(startDate) &&
          !sortie.departureDate.isAfter(endDate);
      return isResponsible && isInDateRange;
    }).toList();

    if (personSorties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucune sortie trouvée pour ${person.name} dans cette période.',
          ),
        ),
      );
      return;
    }

    // Call the new PDF generation function
    try {
      await generateMultiSortieReportPdf(
        person: person,
        sorties: personSorties,
        startDate: startDate,
        endDate: endDate,
        allProducts: stockProvider.products,
        allPeople: peopleProvider.people,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde du PDF: ${e.toString()}'),
        ),
      );
    }
  }
}
