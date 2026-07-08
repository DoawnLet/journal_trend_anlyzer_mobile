import 'package:flutter/material.dart';

class AnalysisLoadingView extends StatelessWidget {
  const AnalysisLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Analyzing research trends...',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class AnalysisEmptyView extends StatelessWidget {
  const AnalysisEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No publications available for analysis.\nTry changing your topic or filters.',
          style: TextStyle(color: Colors.white70, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AnalysisErrorView extends StatelessWidget {
  final String message;

  const AnalysisErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to analyze research trend.\n$message',
          style: const TextStyle(color: Colors.white70, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
