import 'package:flutter/material.dart';
import '../../models/filter_options.dart';

class FilterModal extends StatefulWidget {
  final FilterState currentFilter;
  final Function(FilterState) onFilterChanged;

  const FilterModal({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late FilterState _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
  }

  void _applyFilters() {
    widget.onFilterChanged(_tempFilter);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _tempFilter = const FilterState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Slightly higher
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Type Section
                  _buildFilterSection(
                    '🔀 Post Type',
                    'Choose what kind of posts to see',
                    Column(
                      children: PostType.values.map((type) => 
                        _buildRadioTile(
                          type.displayName,
                          _tempFilter.postType == type,
                          () => setState(() => _tempFilter = _tempFilter.copyWith(postType: type)),
                        ),
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category Section
                  _buildFilterSection(
                    '🧭 Category',
                    'Filter by content mood or theme',
                    Column(
                      children: CategoryFilter.values.map((category) => 
                        _buildRadioTile(
                          category.displayName,
                          _tempFilter.category == category,
                          () => setState(() => _tempFilter = _tempFilter.copyWith(category: category)),
                        ),
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sort By Section
                  _buildFilterSection(
                    '🔄 Sort By',
                    'Choose how posts are ordered',
                    Column(
                      children: SortOption.values.map((sort) => 
                        _buildRadioTile(
                          sort.displayName,
                          _tempFilter.sortBy == sort,
                          () => setState(() => _tempFilter = _tempFilter.copyWith(sortBy: sort)),
                        ),
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // My Posts Toggle
                  _buildFilterSection(
                    '🙋 My Posts',
                    'Show only your own posts',
                    _buildSwitchTile(
                      'Show My Posts Only',
                      _tempFilter.showMyPostsOnly,
                      (value) => setState(() => _tempFilter = _tempFilter.copyWith(showMyPostsOnly: value)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildRadioTile(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF333333),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFDC2626) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF666666),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFCCCCCC),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFDC2626),
            activeTrackColor: const Color(0xFFDC2626).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF666666),
            inactiveTrackColor: const Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}
