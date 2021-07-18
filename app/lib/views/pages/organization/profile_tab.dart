import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/navigation_tab.dart';

class ProfileTab extends NavigationTab {
  ProfileTab({GlobalKey key}) : super(key: key ?? GlobalKey());

  _ProfileTabState get _currentState =>
      (key as GlobalKey)?.currentState as _ProfileTabState;

  @override
  _ProfileTabState createState() => _ProfileTabState();

  @override
  Future refreshData() => _currentState._refreshData();
}

class _ProfileTabState extends State<ProfileTab> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  Widget build(context) => RefreshIndicator(
    key: _refreshKey,
    onRefresh: _refreshData,
    child: Center(child: Text("Profile"),),
  );

  Future _refreshData() {
    return null;
  }
}
