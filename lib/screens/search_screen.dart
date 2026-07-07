import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';
import 'spending_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Spending> _allSpendings = [];
  List<Spending> _filteredSpendings = [];
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService().getSpendings();
    setState(() {
      _allSpendings = data;
      _filteredSpendings = _allSpendings.where((s) {
        final query = _searchController.text.toLowerCase();
        return s.title.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query);
      }).toList();
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSpendings = _allSpendings.where((s) {
        return s.title.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _hasChanged),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search title or category...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withAlpha(150),
            ),
          ),
          style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
        ),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSpendings.isEmpty
          ? const Center(child: Text('No results found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredSpendings.length,
              itemBuilder: (context, index) {
                final s = _filteredSpendings[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(
                        _getCategoryIcon(s.category),
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${s.category} • ${DateFormat('MMM dd, yyyy').format(s.date)}',
                    ),
                    trailing: Text(
                      '₹${s.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SpendingDetailScreen(spending: s),
                        ),
                      );
                      if (result == true) {
                        _hasChanged = true;
                        _loadData();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.medical_services;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.receipt;
    }
  }
}
