import 'package:TMP/setDestination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  bool _isLoggedIn = false;
  int cedulaLength = -1;
  int nombreLength = -1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de sesión'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Lottie.asset('assets/login.json'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Nombre de usuario',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Ingrese su nombre de usuario',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // Bordes redondeados
                    ),
                    errorText: nombreLength <= 4
                        ? nombreLength < 0
                            ? null
                            : 'El Nombre debe tener más de 4 caracteres.'
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Actualiza el indicador de error
                      nombreLength = _usernameController.text.length;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Cédula',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Ingrese su cédula',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // Bordes redondeados
                    ),
                    errorText: cedulaLength <= 10
                        ? cedulaLength < 0
                            ? null
                            : 'Debe ingresar su cédula completa.'
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Actualiza el indicador de error
                      cedulaLength = _cedulaController.text.length;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    // Validar los datos
                    String error = '';
                    if (_usernameController.text.trim().isEmpty) {
                      error = 'El nombre de usuario no puede estar vacío.';
                    } else if (_usernameController.text.trim().length < 4) {
                      error =
                          'El nombre de usuario debe tener al menos 4 letras.';
                    } else if (_cedulaController.text.trim().isEmpty) {
                      error = 'La cédula no puede estar vacía.';
                    } else if (_cedulaController.text.trim().length != 11) {
                      error = 'La cédula debe tener 11 dígitos.';
                    }

                    if (error.isNotEmpty) {
                      // Mostrar el error al usuario
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hay errores en los datos ingresados.'),
                        ),
                      );
                      return;
                    }

                    // Guardar los datos en el localStorage
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('username', _usernameController.text);
                    prefs.setString('cedula', _cedulaController.text);
                    prefs.setBool('isLoggedIn', true);

                    // Actualizar el estado de inicio de sesión
                    Get.to(() => const Destino());

                    // Redibujar la pantalla
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Iniciar sesión',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
