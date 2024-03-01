import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hascol_dealer/screens/Registeration_Form.dart';
import 'package:hascol_dealer/screens/home.dart';
import 'package:hascol_dealer/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,]);
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sales Bridge',
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    initializeVideoController(); // Call the function to initialize the video controller
  }

  void initializeVideoController() {
    _controller = VideoPlayerController.asset('assets/images/puma_video.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown
        if (mounted) {
          setState(() {});
        }
        _controller?.setLooping(true); // Use _controller safely
        _controller?.play(); // Use _controller safely
      });
  }

  /*
  void initializeVideoController() {
    _controller = VideoPlayerController.networkUrl(
        Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/vedio/landing.mp4'))
      ..initialize().then((_) {
        // Ensure the first frame is shown
        if (mounted) {
          setState(() {
            _controller?.play();
          });
        }
        _controller?.setLooping(true); // Use _controller safely
        _controller?.play(); // Use _controller safely
      });
  }*/

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Navigate to the appropriate screen based on the login status
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => Home(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children: <Widget>[
            if (_controller != null)
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height, child: VideoPlayer(_controller!)),

            Column(
              children: [
                /*
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(children: [
                  Positioned(
                      top: 0,
                      right: -100,
                      child: Image.asset('assets/images/circle.png')),
                  Positioned(
                    child: SvgPicture.asset(
                      'assets/images/welcome image.svg',
                      width: MediaQuery.of(context).size.width / 1.1,
                    ),
                  ),
                ]),
              ],
            ),
            */
                SizedBox(
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.08,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  // Align children at the top
                  children: <Widget>[
                    Container(
                      child: SvgPicture.asset(
                        'assets/images/puma_logo.svg',), // Replace with your image asset
                    ),
                  ],
                ),
                SizedBox(height: 5,),
                Text(
                  'Welcome to Order App',
                  style: GoogleFonts.raleway(
                    textStyle: Theme
                        .of(context)
                        .textTheme
                        .displayLarge,
                    fontSize: 28,
                    color: Color(0xfff4f5f5),
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        'Login',
                                        style: GoogleFonts.raleway(
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 16,
                                          color: Colors.white
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xffe81329),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              30.0)),
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement<void, void>(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (BuildContext context) =>
                                              Login(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 5,),
                                TextButton(
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all<
                                        Color>(Colors.transparent),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        side: BorderSide(
                                            color: Colors.green.shade700),
                                        // Add a blue border
                                        borderRadius: BorderRadius.circular(
                                            30.0),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        // Add the question icon
                                        color: Colors
                                            .white, // Set the icon color to blue
                                      ),
                                      Text(
                                        '  Help ',
                                        style: GoogleFonts.poppins(
                                          color: Color(0xfff4f5f5),
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Add some spacing between the rows

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /*
                                Expanded(
                                  child: TextButton(
                                    style: ButtonStyle(
                                      overlayColor: MaterialStateProperty.all<
                                          Color>(Colors.transparent),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: Color(0xfff4f5f5),),
                                          // Add a blue border
                                          borderRadius: BorderRadius.circular(
                                              30.0),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push<void>(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (BuildContext context) => RegistrationForm(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Register here',
                                      style: GoogleFonts.raleway(
                                        color: Color(0xfff4f5f5),
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                */
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.08,
                      ),
                      /*
                      Container(
                        padding: EdgeInsets.only(left: 40, right: 40, top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/gas-station.png',
                                      // Replace with the actual path to your image
                                      width: 48.0,
                                      height: 48.0,
                                    ),
                                    Text(
                                      'Open an Account',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/gps (1).png',
                                      // Replace with the actual path to your image
                                      width: 48.0,
                                      height: 48.0,
                                    ),
                                    Text(
                                      'Locate Us',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      */
                    ],
                  ),
                )

              ],
              /*
        Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  child: Text(
                    'Welcome to Puma Order App Pakistan',
                    style: GoogleFonts.poppins(
                      textStyle: Theme.of(context).textTheme.displayLarge,
                      fontSize: 28,
                      color: Color(0xff1F41BB),
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
                Container(
                  child: Text(
                    'On Your FingerTips',
                    style: GoogleFonts.poppins(
                      textStyle: Theme.of(context).textTheme.displayLarge,
                      fontSize: 28,
                      color: Color(0xff1F41BB),
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 18,
            ),
            /*
            Image.asset(
              'assets/images/hascol_logo.png',
              width: 200,
            ),
             */
            Container(
              child: Text(
                'Sales Bridge',
                style: GoogleFonts.poppins(
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  fontSize: 24,
                  color: Color(0xff1F41BB),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),

         */
            ),
          ]),
    );
  }
/*void getValue() async {
    var prefs = await SharedPreferences.getInstance();
    var getName = (prefs.getString("userId") ?? "");
    // nameValue = getName != null ? getName : "No Value Saved ";
    if (getName == "") {
      Timer(Duration(seconds: 3), () {

        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                Home(),
          ),
        );
      });
    } else {
      Timer(Duration(seconds: 3), () {

        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                MyHomePage(),
          ),
        );
      });

    }
    setState(() {

    });
  }*/
}


