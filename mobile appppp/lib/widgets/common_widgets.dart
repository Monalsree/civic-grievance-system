import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key});
  @override
  Widget build(BuildContext context) => const TextField();
}

class CustomButton extends StatelessWidget {
  const CustomButton({super.key});
  @override
  Widget build(BuildContext context) => ElevatedButton(onPressed: () {}, child: const Text(''));
}
