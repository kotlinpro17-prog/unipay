import 'package:flutter/material.dart';
import 'home_view.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // In future this can have BottomNavigationBar
    return const HomeView();
  }
}
