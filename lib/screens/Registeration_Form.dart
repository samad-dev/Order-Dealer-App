import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _sapNumberController = TextEditingController();
  TextEditingController _stationNameController = TextEditingController();
  TextEditingController _cnicController = TextEditingController();
  TextEditingController _cellNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.primary_color,
        elevation: 10,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          'Registration Form',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.normal,
              color: Colors.white,
              fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sap Number:',style: TextStyle(fontWeight: FontWeight.bold),),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      controller: _sapNumberController,
                      decoration: InputDecoration(
                          hintText: 'Enter Sap Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Adjust the value as needed
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter Sap Number';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Filling Station Name:',style: TextStyle(fontWeight: FontWeight.bold),),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      controller: _stationNameController,
                      decoration: InputDecoration(
                        hintText: ' Enter Filling Station Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Adjust the value as needed
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter Filling Station Name';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Owner's CNIC:",style: TextStyle(fontWeight: FontWeight.bold),),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      controller: _cnicController,
                      decoration: InputDecoration(
                        hintText: "Enter Owner's CNIC",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Adjust the value as needed
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter Owner's CNIC";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Cell Number:',style: TextStyle(fontWeight: FontWeight.bold),),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      controller: _cellNumberController,
                      decoration: InputDecoration(
                        hintText: 'Enter Cell Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0), // Adjust the value as needed
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter Cell Number';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // If the form is valid, display a Snackbar.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration Submitted')),
                        );
                        // You can perform your submission logic here
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Constants.secondary_color),
                      padding: MaterialStateProperty.all(EdgeInsets.all(16.0))
                    ),
                    child: Text('Submit',style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
