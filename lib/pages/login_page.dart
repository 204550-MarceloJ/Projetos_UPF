import 'package:flutter/material.dart';
import 'package:flutterapp/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //logo
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Image.asset("assets/logotipo_firma.png"),
          ),
          //email input
          TextField(
            maxLength: 50,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                hintText: "Informe o email",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(37),
                    borderSide: BorderSide.none)),
          ),
          //pwd input
          TextField(
            obscureText: showPassword,
            maxLength: 10,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
                icon: showPassword
                    ? const Icon(Icons.visibility_off)
                    : const Icon(Icons.visibility),
              ),
              hintText: "Informe a senha",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(37),
                  borderSide: BorderSide.none),
            ),
          ),
          //btn login
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: () {
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
              child: const Text("Entrar"),
            ),
          )
        ],
      ),
    );
  }
}