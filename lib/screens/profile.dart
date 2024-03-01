import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hascol_dealer/screens/complaint_list.dart';
import 'package:hascol_dealer/screens/home.dart';
import 'package:hascol_dealer/screens/inspection_reports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../main.dart';
import '../utils/constants.dart';
import 'ChangePassword.dart';

class Profile extends StatefulWidget {
  static const Color contentColorOrange = Color(0xFF00705B);
  final Color leftBarColor = Color(0xFFCB6600);
  final Color rightBarColor = Color(0xFF5BECD2);
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
  }

  _launchURL(String url) async {
    try {
      await launchUrlString(url);
    } catch (e) {
      print("Error launching URL: $e");
    }
  }


  int _selectedIndex = 2;
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEE d MMM kk:mm:ss').format(now);
    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;
    return Builder(builder: (context) {
      return Scaffold(
        backgroundColor: Color(0xffffffff),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Constants.primary_color,
          elevation: 10,
          title: Text(
            'Profile',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
                color: Colors.white,
                fontSize: 16),
          ),
        ),
        body: SingleChildScrollView(

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  color: Color(0xffEBF0F0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height/2.5,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 60,
                            child: Image.asset("assets/images/puma icon.png", width: 85, )
                        ),
                        /*
                        CircleAvatar(
                            backgroundColor: Color(0xffea1b25),
                            radius: 60,
                            child: Opacity(
                              opacity: 0.9,
                                child: Image.asset("assets/images/puma png.png", width: 100)
                            ),
                        ),
                        */
                        Text(
                          'Puma Order App',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18.0,right: 18,top: 10),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      elevation: 15,
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: (){_launchURL('https://www.pumapakistan.com/en/contact');},
                              child: Row(
                                children: [
                                  Icon(
                                    FluentIcons.contact_card_20_regular,
                                    size: 35,
                                  ),
                                  SizedBox(width: 5,),
                                  Text(
                                    'Contact us',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Color(0xff000000),
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: (){
                                _launchURL("https://www.pumapakistan.com/en/products-services/#polices");
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    FluentIcons.lock_multiple_20_regular,
                                    size: 35,
                                  ),
                                  SizedBox(width: 5,),
                                  Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Color(0xff000000),
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => InspectionReports()),);
                              },
                              child: Row(
                                children: [
                                  Image.asset("assets/images/business-report.png", width: 35,),
                                  SizedBox(width: 5,),
                                  Text(
                                    'Inspection Reports',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Color(0xff000000),
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:GestureDetector(
                                onTap: () async {
                                  Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => ChangePasswordPage()),);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_open,
                                        size: 25,
                                      ),
                                      SizedBox(width: 5,),
                                      Container(
                                        child: Text(
                                          'Change Password',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Color(0xff000000),
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                          ),
                          GestureDetector(
                            onTap: () async {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.clear();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => MyApp()),
                                    (route) => false, // Remove all routes from the stack
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    FluentIcons.power_24_regular,
                                    size: 25,
                                  ),
                                  SizedBox(width: 5,),
                                  Container(
                                    child: Text(
                                      'Logout',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Color(0xff000000),
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x8ca9a9a9),
                blurRadius: 20,
              ),
            ],
          ),
          child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              unselectedItemColor: Color(0xff8d8d8d),
              unselectedLabelStyle:
              const TextStyle(color: Color(0xff8d8d8d), fontSize: 14),
              unselectedFontSize: 14,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedIconTheme: IconThemeData(
                color: Color(0xff1F41BB),
              ),
              type: BottomNavigationBarType.shifting,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(
                      FluentIcons.home_32_regular,
                      size: 20,
                    ),
                    label: 'Home',
                    backgroundColor: Colors.white),
                BottomNavigationBarItem(
                    icon: Icon(
                      FluentIcons.weather_sunny_16_regular,
                      size: 20,
                    ),
                    label: 'Complaint',
                    backgroundColor: Colors.white),
                BottomNavigationBarItem(
                  icon: Icon(
                    FluentIcons.inprivate_account_16_regular,
                    size: 20,
                  ),
                  label: 'Profile',
                  backgroundColor: Colors.white,
                ),
              ],
              selectedItemColor: Color(0xff1F41BB),
              iconSize: 40,
              onTap: _onItemTapped,
              elevation: 15),
        ),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_selectedIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Complaints()),
      );
    }
    if (_selectedIndex == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    }
  }

  Widget headerChild(String header, int value) => Expanded(
      child: Column(
        children: <Widget>[
          Text(header),
          SizedBox(
            height: 8.0,
          ),
          Text(
            '$value',
            style: TextStyle(
                fontSize: 14.0,
                color: const Color(0xff1F41BB),
                fontWeight: FontWeight.bold),
          )
        ],
      ));

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false); // Clear login status
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => SplashScreen(),),
    );
  }
}
