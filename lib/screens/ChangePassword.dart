import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  Color _oldPasswordBorderColor = Colors.grey;
  Color _newPasswordBorderColor = Colors.grey;
  Color _confirmPasswordBorderColor = Colors.grey;

  Future<void> updatePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/update/update_dealers_password.php'),
    );

    request.fields.addAll({
      'row_id': '$id',
      'edit_password': _newPasswordController.text,
    });

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print(await response.stream.bytesToString());
        print(id);
        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "Password is Updated",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

      } else {
        print('Request failed with status: ${response.statusCode}. ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error during request: $error');
    }
  }

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
          'Change Password',
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
          child: Column(
            children: [
              // Lock icon at the top
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Icon(
                  Icons.lock_open,
                  size: 100,
                  color: Colors.black, // Customize the color of the lock icon
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: buildPasswordField(
                  controller: _oldPasswordController,
                  labelText: 'Old Password',
                  showPassword: _showOldPassword,
                  onToggle: () {
                    setState(() {
                      _showOldPassword = !_showOldPassword;
                    });
                  },
                    borderColor: _oldPasswordBorderColor,
                    onChanged: (String value) {},
                    passwordStrengthText: getPasswordStrengthText('')
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: buildPasswordField(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  showPassword: _showNewPassword,
                  onToggle: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  borderColor: _newPasswordBorderColor,
                  onChanged: (value) {
                    setState(() {
                      _newPasswordBorderColor = getPasswordStrengthColor(value);
                    });

                  },
                  passwordStrengthText: getPasswordStrengthText(_newPasswordController.text),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: buildPasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  showPassword: _showConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  borderColor: _confirmPasswordBorderColor,
                  onChanged: (value) {
                    setState(() {
                      _confirmPasswordBorderColor =
                          getPasswordStrengthColor(value);
                    });
                  },
                    passwordStrengthText: getPasswordStrengthText(_confirmPasswordController.text)
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  var old_pass = prefs.getString("password");
                  if(_oldPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty && _confirmPasswordController.text.isNotEmpty) {
                    if (old_pass == _oldPasswordController.text) {
                      if (_newPasswordController.text == _confirmPasswordController.text) {
                        updatePassword();
                      } else {
                        Fluttertoast.showToast(
                          msg: "New password and confirmed password do not match",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    }
                    else {
                      Fluttertoast.showToast(
                        msg: "Wrong Old password",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  }else{
                    Fluttertoast.showToast(
                      msg: "Please Filled all field",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  }

                  print('Old Password: ${_oldPasswordController.text}');
                  print('New Password: ${_newPasswordController.text}');
                  print('Confirm Password: ${_confirmPasswordController.text}');
                },
                style: ElevatedButton.styleFrom(
                  primary: Constants
                      .secondary_color, // Set the background color here
                ),
                child: Text(
                  'Change Password', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getPasswordStrengthColor(String password) {
    // Implement your password strength logic here.
    // This is a placeholder. You may use a library or custom logic.
    if (password.length >= 12) {
      return Colors.green;
    } else if (password.length >= 8) {
      return Colors.yellow;
    } else if(password==''){
      return Colors.grey;
    }else {
      return Colors.red;
    }
  }
  String getPasswordStrengthText(String password) {

    if (password.length >= 12) {
      return 'Strong';
    } else if (password.length >= 8) {
      return 'Medium';
    } else if(password==''){
      return '';
    }else {
      return 'Weak';
    }
  }


  Widget buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool showPassword,
    required VoidCallback onToggle,
    required Color borderColor,
    required ValueChanged<String> onChanged,
    required String passwordStrengthText,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !showPassword,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    labelText: labelText,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 8.0,top: 8,bottom: 8), // Adjust the value as needed
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggle,
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right:8.0),
              child: Text(
                passwordStrengthText,
                style: TextStyle(
                  color: getPasswordStrengthColor(controller.text),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
