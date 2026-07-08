import 'package:flutter/material.dart';

/// Widget ô nhập liệu tìm kiếm (Search Bar) dùng trong SearchPage.
class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchTriggered;

  const SearchInputField({
    super.key,
    required this.controller,
    required this.onSearchTriggered,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: (_) => onSearchTriggered(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Nhập topic, keyword hoặc DOI để tìm publications...',
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          onPressed: onSearchTriggered,
        ),
      ),
    );
  }
}
