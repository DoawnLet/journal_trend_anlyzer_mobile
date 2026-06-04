import 'package:flutter/material.dart';
import '../state_management/search_notifier.dart';
import '../services/openalex_api_service.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchNotifier notifier;

  const SearchFilterBottomSheet({super.key, required this.notifier});

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  final OpenAlexApiService _apiService = OpenAlexApiService();
  
  late final TextEditingController _authorController;
  late final TextEditingController _conceptController;
  late final TextEditingController _topicController;

  List<Map<String, dynamic>> _authorSuggestions = [];
  List<Map<String, dynamic>> _conceptSuggestions = [];
  List<Map<String, dynamic>> _topicSuggestions = [];

  bool _isSearchingAuthors = false;
  bool _isSearchingConcepts = false;
  bool _isSearchingTopics = false;

  @override
  void initState() {
    super.initState();
    _authorController = TextEditingController();
    _conceptController = TextEditingController();
    _topicController = TextEditingController();
  }

  @override
  void dispose() {
    _authorController.dispose();
    _conceptController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _onSearchAuthors(String val) async {
    setState(() => _isSearchingAuthors = true);
    final res = await _apiService.searchAuthors(val);
    if (mounted) {
      setState(() {
        _authorSuggestions = res;
        _isSearchingAuthors = false;
      });
    }
  }

  Future<void> _onSearchConcepts(String val) async {
    setState(() => _isSearchingConcepts = true);
    final res = await _apiService.searchConcepts(val);
    if (mounted) {
      setState(() {
        _conceptSuggestions = res;
        _isSearchingConcepts = false;
      });
    }
  }

  Future<void> _onSearchTopics(String val) async {
    setState(() => _isSearchingTopics = true);
    final res = await _apiService.searchTopics(val);
    if (mounted) {
      setState(() {
        _topicSuggestions = res;
        _isSearchingTopics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.notifier.state;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E4646), // matching teal
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bộ lọc & Sắp xếp',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Sắp xếp thời gian
            Text(
              'Sắp xếp theo thời gian xuất bản',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Mặc định', style: TextStyle(fontSize: 12)),
                    selected: state.sortBy == null,
                    onSelected: (selected) {
                      if (selected) widget.notifier.setSortBy(null);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Mới nhất', style: TextStyle(fontSize: 12)),
                    selected: state.sortBy == 'publication_date:desc',
                    onSelected: (selected) {
                      if (selected) widget.notifier.setSortBy('publication_date:desc');
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Cũ nhất', style: TextStyle(fontSize: 12)),
                    selected: state.sortBy == 'publication_date:asc',
                    onSelected: (selected) {
                      if (selected) widget.notifier.setSortBy('publication_date:asc');
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 28),

            // Lọc Tác giả (Author)
            Text(
              'Lọc theo Tác giả',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (state.selectedAuthorName != null) ...[
              InputChip(
                label: Text(state.selectedAuthorName!, style: const TextStyle(color: Colors.white)),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                onDeleted: () {
                  widget.notifier.clearAuthorFilter();
                  setState(() {});
                },
              ),
            ] else ...[
              TextField(
                controller: _authorController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchAuthors,
                onTap: () => _onSearchAuthors(_authorController.text),
                onChanged: _onSearchAuthors,
                decoration: InputDecoration(
                  hintText: 'Nhập tên tác giả cần tìm...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  isDense: true,
                  suffixIcon: _isSearchingAuthors
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                          onPressed: () => _onSearchAuthors(_authorController.text),
                        ),
                ),
              ),
              if (_authorSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _authorSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = _authorSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(item['display_name'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        onTap: () {
                          widget.notifier.setAuthorFilter(item['id'], item['display_name']);
                          setState(() {
                            _authorSuggestions.clear();
                            _authorController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],

            const Divider(color: Colors.white12, height: 28),

            // Lọc Concept
            Text(
              'Lọc theo Khái niệm (Concept)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (state.selectedConceptName != null) ...[
              InputChip(
                label: Text(state.selectedConceptName!, style: const TextStyle(color: Colors.white)),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                onDeleted: () {
                  widget.notifier.clearConceptFilter();
                  setState(() {});
                },
              ),
            ] else ...[
              TextField(
                controller: _conceptController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchConcepts,
                onTap: () => _onSearchConcepts(_conceptController.text),
                onChanged: _onSearchConcepts,
                decoration: InputDecoration(
                  hintText: 'Nhập khái niệm cần tìm (vd: Physics...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  isDense: true,
                  suffixIcon: _isSearchingConcepts
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                          onPressed: () => _onSearchConcepts(_conceptController.text),
                        ),
                ),
              ),
              if (_conceptSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _conceptSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = _conceptSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(item['display_name'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        onTap: () {
                          widget.notifier.setConceptFilter(item['id'], item['display_name']);
                          setState(() {
                            _conceptSuggestions.clear();
                            _conceptController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],

            const Divider(color: Colors.white12, height: 28),

            // Lọc Topic
            Text(
              'Lọc theo Chủ đề (Topic)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (state.selectedTopicName != null) ...[
              InputChip(
                label: Text(state.selectedTopicName!, style: const TextStyle(color: Colors.white)),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                onDeleted: () {
                  widget.notifier.clearTopicFilter();
                  setState(() {});
                },
              ),
            ] else ...[
              TextField(
                controller: _topicController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchTopics,
                onTap: () => _onSearchTopics(_topicController.text),
                onChanged: _onSearchTopics,
                decoration: InputDecoration(
                  hintText: 'Nhập chủ đề cần tìm (vd: Neural...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  isDense: true,
                  suffixIcon: _isSearchingTopics
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                          onPressed: () => _onSearchTopics(_topicController.text),
                        ),
                ),
              ),
              if (_topicSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _topicSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = _topicSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(item['display_name'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        onTap: () {
                          widget.notifier.setTopicFilter(item['id'], item['display_name']);
                          setState(() {
                            _topicSuggestions.clear();
                            _topicController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF80CBC4),
                  foregroundColor: const Color(0xFF1E4646),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Hoàn tất', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
