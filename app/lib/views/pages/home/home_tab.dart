import 'package:flutter/material.dart';
import 'package:chainmetric/views/components/navigation_tab.dart';

class HomeTab extends NavigationTab {
  HomeTab({GlobalKey key}) : super(key: key ?? GlobalKey());

  _HomeTabState get _currentState =>
      (key as GlobalKey)?.currentState as _HomeTabState;

  @override
  _HomeTabState createState() => _HomeTabState();

  @override
  Future refreshData() => _currentState._loadData();
}

class _HomeTabState extends State<HomeTab> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(context) => RefreshIndicator(
    key: _refreshKey,
    onRefresh: _loadData,
    child: Center(child: Text("Home"),),
  );

  Future<void> _loadData() {
    return null;
  }
}
