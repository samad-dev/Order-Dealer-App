import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: RegisterUser(),
  ));
}

class RegisterUser extends StatelessWidget {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register User'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Register User',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _userNameController,
                              decoration: InputDecoration(labelText: 'Username'),
                            ),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(labelText: 'Email'),
                            ),
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(labelText: 'Password'),
                              obscureText: true,
                            ),
                            TextField(
                              controller: _phoneNumberController,
                              decoration: InputDecoration(labelText: 'Phone Number'),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                // Handle registration logic here
                                String username = _userNameController.text;
                                String email = _emailController.text;
                                String password = _passwordController.text;
                                String phoneNumber = _phoneNumberController.text;

                                // For demonstration purposes, print the entered data
                                print('Username: $username');
                                print('Email: $email');
                                print('Password: $password');
                                print('Phone Number: $phoneNumber');

                                // You can implement your registration logic here
                                // Once registered, you can close the bottom sheet
                                Navigator.pop(context);
                                // Optionally, you can show a snackbar or any other feedback to the user
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('User registered successfully!'),
                                  ),
                                );
                              },
                              child: Text('Submit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Your main content goes here'),
      ),
    );
  }
}
