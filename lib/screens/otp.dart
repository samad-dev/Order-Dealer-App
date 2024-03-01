import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'login.dart';


class Otp extends StatefulWidget {
  @override
  _Otp createState() => _Otp();
}

class _Otp extends State<Otp> {
  late String _username;

  Future<String> fetchVerificationCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    // await prefs.setBool("loggedIn", true);

    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealer_verify_code.php?key=03201232927&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final jsonData = json.decode(response.body);
      // Extract and return the verification code
      return jsonData[0]['verification_code'];
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load verification code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Stack(
                children: [
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xff607d8b),
                          Color(0xff263238),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, left: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 100,
                            ),
                            Image.asset(
                              "assets/images/puma icon.png",
                            ),
                            SizedBox(
                              height: 100,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Code",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  height: 60,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                      color: Color(0xffebefff),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                        )
                                      ]),
                                  child: TextFormField(
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Code is required';
                                      }
                                    },
                                    onChanged: (value) {
                                      _username = value.toString();
                                    },
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(top: 14),
                                        prefixIcon: Icon(
                                          Icons.password_sharp,
                                          color: Color(0xff4c5166),
                                        ),
                                        hintText: 'Verification Code',
                                        hintStyle: TextStyle(color: Colors.black38)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 25),
                              child: Container(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      var value = await fetchVerificationCode();
                                      if(_username == value){
                                        print('correct password');
                                        SharedPreferences prefs = await SharedPreferences.getInstance();
                                        await prefs.setBool("isLoggedIn", true);
                                        Navigator.pushReplacement<void, void>(context,MaterialPageRoute<void>(builder: (BuildContext context) => Home(),),);
                                      }else{
                                        print('incorrect password');
                                        Fluttertoast.showToast(
                                            msg: "incorrect password",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.SNACKBAR,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Colors.red,
                                            textColor: Colors.white,
                                            fontSize: 16.0
                                        );

                                      }
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                      MaterialStateProperty.all<Color>(Color(0xff78909c)),
                                      elevation: MaterialStateProperty.all(3),
                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18.0),
                                              side: BorderSide(color: Colors.red))),
                                    ),
                                    child: Text(
                                      "Login",
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.setBool("loggedIn", true);
}
