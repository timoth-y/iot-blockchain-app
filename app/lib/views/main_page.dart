import 'package:flutter/material.dart';
import 'package:chainmetric/shared/utils.dart';
import 'pages/devices/devices_tab.dart';
import 'pages/home/home_tab.dart';
import 'pages/organization/profile_tab.dart';
import 'pages/assets/asset_form.dart';

import 'components/bottom_app_bar.dart';
import 'components/navigation_tab.dart';
import 'pages/assets/assets_tab.dart';
import 'pages/devices/device_form.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<NavigationTabItem> tabs = [
    NavigationTabItem(
        title: "IoT Chain",
        navBarItem: CustomAppBarItem(icon: Icons.home),
        tab: HomeTab(),
        buttonIcon: Icon(Icons.cached, color: Colors.black),
        pageAction: (ctx) => print("Home")
    ),
    NavigationTabItem(
        title: "Assets",
        navBarItem: CustomAppBarItem(icon: Icons.shopping_cart),
        tab: AssetsTab(key: GlobalKey()),
        buttonIcon: Icon(Icons.add, color: Colors.black),
        pageAction: (state) => openPage(
          state.context, AssetForm(),
            then: (state as _MainPageState).currentTab().refreshData
        )
    ),
    NavigationTabItem(
        title: "Devices",
        navBarItem: CustomAppBarItem(icon: Icons.memory),
        tab: DevicesTab(key: GlobalKey()),
        buttonIcon: Icon(Icons.qr_code_scanner, color: Colors.black),
        pageAction: (state) => openPage(
            state.context, DeviceForm(),
            then: (state as _MainPageState).currentTab().refreshData
        )
    ),
    NavigationTabItem(
        title: "Profile",
        navBarItem: CustomAppBarItem(icon: Icons.person),
        tab: ProfileTab(),
        buttonIcon: Icon(Icons.person, color: Colors.black),
        pageAction: (ctx) => print("Profile")
    ),
  ];

  void selectedTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  NavigationTab currentTab() => tabs[_currentIndex].tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(tabs[_currentIndex].title)),
      ),
      body: tabs[_currentIndex].tab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => tabs[_currentIndex].pageAction(this),
        child: tabs[_currentIndex].buttonIcon,
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onTabSelected: selectedTab,
        items: List.generate(tabs.length, (index) => tabs[index].navBarItem),
      ),
    );
  }
}
