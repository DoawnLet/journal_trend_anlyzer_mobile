import 'package:flutter/material.dart';
import 'package:journal_trend_analysis_mb/viewmodels/search_notifier.dart';
import 'package:journal_trend_analysis_mb/widgets/search_filter_bottom_sheet.dart';

class SearchAdvancedFilterDrawer extends StatelessWidget {
  final SearchNotifier notifier;

  const SearchAdvancedFilterDrawer({
    super.key,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Drawer(
      width: width < 420 ? width * 0.92 : 390,
      backgroundColor: Colors.transparent,
      elevation: 18,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: SearchFilterBottomSheet(notifier: notifier),
        ),
      ),
    );
  }
}
