import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'people_provider.dart';
import 'sortie_provider.dart';
import 'stock_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<StockProvider, PeopleProvider, SortieProvider>(
      builder: (context, stock, people, sorties, child) {
        // Calculate Top Guide
        String topGuideName = "N/A";
        int topScore = -9999;
        final guides = people.people.where((p) => p.role == 'guide');
        if (guides.isNotEmpty) {
          for (var g in guides) {
            if (g.score > topScore) {
              topScore = g.score;
              topGuideName = g.name;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryCard(
                  context,
                  'Active Sorties',
                  sorties.activeSorties.length.toString(),
                  Icons.directions_walk,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  context,
                  'Total Products',
                  stock.products.length.toString(),
                  Icons.inventory,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  context,
                  'Top Guide',
                  '$topGuideName ($topScore pts)',
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
