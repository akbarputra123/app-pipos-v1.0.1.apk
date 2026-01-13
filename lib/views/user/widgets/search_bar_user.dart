import 'package:flutter/material.dart';

class SearchBarUser extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const SearchBarUser({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(9.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium, // ✅ ikut dark/light
        cursorColor: theme.colorScheme.primary,
        decoration: InputDecoration(
          hintText: "Cari user...",
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.iconTheme.color,
          ),
          filled: true,
          fillColor: theme.cardColor, // ✅ card color theme
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: theme.dividerColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
