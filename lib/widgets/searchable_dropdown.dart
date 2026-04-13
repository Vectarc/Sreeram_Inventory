import 'package:flutter/material.dart';
import '../app_colors.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemAsString;
  final ValueChanged<T?> onChanged;
  final bool isDark;
  final IconData? prefixIcon;
  final bool allowCustom;
  final String? searchHintText;
  final Future<bool> Function(T)? onDeleteItem;
  final bool enabled;
  final bool forceSearch;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    required this.isDark,
    this.prefixIcon,
    this.allowCustom = false,
    this.searchHintText,
    this.onDeleteItem,
    this.enabled = true,
    this.forceSearch = true,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.itemAsString(widget.value as T) : '',
    );
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value != null
          ? widget.itemAsString(widget.value as T)
          : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _dd(bool isDark, String label, IconData? icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: widget.enabled
              ? AppColors.textSecondary(isDark)
              : AppColors.textMuted(isDark),
        ),
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: 18,
                color: widget.enabled
                    ? AppColors.textSecondary(isDark)
                    : AppColors.textMuted(isDark),
              )
            : null,
        filled: true,
        fillColor: widget.enabled
            ? AppColors.card(isDark)
            : AppColors.card(isDark).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: widget.enabled
                ? AppColors.border(isDark)
                : AppColors.border(isDark).withOpacity(0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      );

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _SearchDialog<T>(
        items: widget.items,
        itemAsString: widget.itemAsString,
        isDark: widget.isDark,
        label: widget.label,
        allowCustom: widget.allowCustom,
        searchHintText: widget.searchHintText,
        onDeleteItem: widget.onDeleteItem,
      ),
    ).then((selected) {
      if (selected != null) {
        widget.onChanged(selected as T);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.length <= 10 &&
        !widget.allowCustom &&
        !widget.forceSearch) {
      return DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: widget.value,
        dropdownColor: AppColors.cardElevated(widget.isDark),
        style: TextStyle(
          color: widget.enabled
              ? AppColors.textPrimary(widget.isDark)
              : AppColors.textMuted(widget.isDark),
          fontSize: 14,
        ),
        decoration: _dd(widget.isDark, widget.label, widget.prefixIcon),
        hint: Text(
          'Select ${widget.label}',
          style: TextStyle(
            color: AppColors.textSecondary(widget.isDark),
            fontSize: 13,
          ),
        ),
        items: widget.items
            .map(
              (u) => DropdownMenuItem<T>(
                value: u,
                child: Text(
                  widget.itemAsString(u),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: widget.enabled ? widget.onChanged : null,
      );
    }

    return GestureDetector(
      onTap: widget.enabled ? _showSearchDialog : null,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          style: TextStyle(
            color: widget.enabled
                ? AppColors.textPrimary(widget.isDark)
                : AppColors.textMuted(widget.isDark),
            fontSize: 14,
          ),
          decoration: _dd(widget.isDark, widget.label, widget.prefixIcon)
              .copyWith(
                hintText: 'Select ${widget.label}',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary(widget.isDark),
                  fontSize: 13,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: widget.enabled
                      ? AppColors.textSecondary(widget.isDark)
                      : AppColors.textMuted(widget.isDark),
                ),
              ),
        ),
      ),
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemAsString;
  final bool isDark;
  final String label;
  final bool allowCustom;
  final String? searchHintText;
  final Future<bool> Function(T)? onDeleteItem;

  const _SearchDialog({
    required this.items,
    required this.itemAsString,
    required this.isDark,
    required this.label,
    required this.allowCustom,
    this.searchHintText,
    this.onDeleteItem,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  late List<T> _filteredMap;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMap = widget.items;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filteredMap = widget.items
            .where((i) => widget.itemAsString(i).toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardElevated(widget.isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
              decoration: InputDecoration(
                hintText: widget.searchHintText ?? 'Search ${widget.label}...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary(widget.isDark),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary(widget.isDark),
                ),
                filled: true,
                fillColor: AppColors.card(widget.isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          if (widget.allowCustom)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.teal),
                onPressed: () {
                  final text = _searchCtrl.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.pop(context, text as T);
                  }
                },
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMap.length,
                itemBuilder: (ctx, i) {
                  final item = _filteredMap[i];
                  return ListTile(
                    title: Text(
                      widget.itemAsString(item),
                      style: TextStyle(
                        color: AppColors.textPrimary(widget.isDark),
                      ),
                    ),
                    trailing: widget.onDeleteItem != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.cardElevated(
                                    widget.isDark,
                                  ),
                                  title: const Text('Delete Unit?'),
                                  content: Text(
                                    'Are you sure you want to delete "${widget.itemAsString(item)}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                final success = await widget.onDeleteItem!(
                                  item,
                                );
                                if (success) {
                                  setState(() {
                                    _filteredMap.remove(item);
                                  });
                                }
                              }
                            },
                          )
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
            if (widget.allowCustom &&
                _searchCtrl.text.trim().isNotEmpty &&
                !widget.items.any(
                  (i) =>
                      widget.itemAsString(i).toLowerCase() ==
                      _searchCtrl.text.trim().toLowerCase(),
                ))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, _searchCtrl.text.trim() as T),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Use "${_searchCtrl.text.trim()}"'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
