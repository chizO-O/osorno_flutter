import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum _SearchFilter { product, skinType, ingredient }

/// Client-side text match over the latest posts loaded from Firestore.
/// The controller/focus node live for the lifetime of this tab so switching
/// filters never clears the query or dismisses the user from the search flow.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _posts = FirestoreService.instance.postsStream();
  final _controller = TextEditingController();
  final _searchFocus = FocusNode();
  _SearchFilter _filter = _SearchFilter.product;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _has(String s, String q) => s.toLowerCase().contains(q);

  bool _matches(Post post) {
    if (_query.isEmpty) return false;
    final q = _query.toLowerCase();
    switch (_filter) {
      case _SearchFilter.product:
        return post.tags.any((t) => _has(t, q)) ||
            post.routine.any((r) => _has(r.product, q)) ||
            _has(post.title, q);
      case _SearchFilter.ingredient:
        return post.tags.any((t) => _has(t, q)) || _has(post.body, q);
      case _SearchFilter.skinType:
        return _has(post.authorSkinType, q);
    }
  }

  void _setFilter(_SearchFilter value) {
    if (_filter == value) return;
    setState(() => _filter = value);
    // Keep the current text and return focus to the field after the chip tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  String _label(_SearchFilter filter) => switch (filter) {
        _SearchFilter.product => 'Product',
        _SearchFilter.skinType => 'Skin type',
        _SearchFilter.ingredient => 'Ingredient',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              key: const ValueKey('persistent-search-field'),
              focusNode: _searchFocus,
              controller: _controller,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                hintText: 'Search products, ingredients, skin type',
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                          _searchFocus.requestFocus();
                        },
                        icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                for (final f in _SearchFilter.values) ...[
                  if (f != _SearchFilter.product) const SizedBox(width: 8),
                  _SmoothFilterChip(
                    label: _label(f),
                    selected: _filter == f,
                    onTap: () => _setFilter(f),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _posts,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_query.isEmpty) {
                  return const Center(
                    child: Text('Type to search posts',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }

                final results = snapshot.data!.where(_matches).toList();
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 190),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: results.isEmpty
                      ? Center(
                          key: ValueKey('empty-${_filter.name}'),
                          child: const Text('No matches found',
                              style: TextStyle(color: AppColors.muted)),
                        )
                      : ListView.builder(
                          key: ValueKey('results-${_filter.name}'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: results.length,
                          itemBuilder: (_, i) => PostCard(post: results[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SmoothFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenLight : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.greenDark : AppColors.ink,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
