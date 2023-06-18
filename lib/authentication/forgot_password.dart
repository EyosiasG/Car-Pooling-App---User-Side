import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Receive an email to\nreset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: emailController,
                  textInputAction: TextInputAction.done,
                  decoration:
                      const InputDecoration(labelText: 'Enter your email'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    resetPassword();
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Reset Password'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                )
              ],
            )),
      ),
    );
  }

  Future resetPassword() async {
    try {
      if (!emailController.text.contains("@")) {
        Fluttertoast.showToast(msg: "email is not valid.");
      } else {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: emailController.text.trim());
        Fluttertoast.showToast(msg: 'Password reset email sent');
        //Navigator.of(context).popUntil((route) => route);
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: '$e.message');
      Navigator.of(context).pop();
    }
  }
}
