import 'package:flutter/material.dart';
import 'package:sm_animations/sm_animations.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const _TransitionsHomePage(),
    );
  }
}

class _TransitionsHomePage extends StatefulWidget {
  const _TransitionsHomePage({super.key});

  @override
  State<_TransitionsHomePage> createState() => _TransitionsHomePageState();
}

class _TransitionsHomePageState extends State<_TransitionsHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KIPageTransition(
        transitionBuilder: (Animation<double> primaryAnimation, Animation<double> secondaryAnimation, Widget child) {
          return FadeTransition(opacity: primaryAnimation, child: child);
        },
        initialAnimate: true,
        child: SizedBox(
          height: 100,
          width: 100,
          child: Container(
            child: Text("Test"),
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
