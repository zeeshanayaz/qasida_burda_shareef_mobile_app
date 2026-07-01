import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قصيدة البردة',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: .fromSeed(seedColor: Colors.green),
      ),
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png'),
            Text('قصيدة البردة', style: TextStyle(fontSize: 20),),
          ],
        ),
      ),
    );
  }
}