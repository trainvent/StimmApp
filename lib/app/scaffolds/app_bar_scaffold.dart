import 'package:flutter/material.dart';

class AppBarScaffold extends StatelessWidget {
  const AppBarScaffold({
    super.key,
    required this.title,
    this.actions,
    required this.child,
  });

  final String title;
  final List<Widget>? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text(title),
            toolbarHeight: 60,
            collapsedHeight: 60,
            pinned: true,
            surfaceTintColor: null,
            scrolledUnderElevation: 0,
            actions: actions,
          ),
          SliverToBoxAdapter(child: child),
        ],
      ),
    );
  }
}
