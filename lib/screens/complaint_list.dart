import 'dart:convert';

import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hascol_dealer/screens/home.dart';
import 'package:hascol_dealer/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';



class Complaints extends StatefulWidget {
  static const Color contentColorOrange = Color(0xFF00705B);
  final Color leftBarColor = Color(0xFFCB6600);
  final Color rightBarColor = Color(0xFF5BECD2);
  @override
  _ComplaintsState createState() => _ComplaintsState();
}

List<String> object_type_list = [];
List<String> object_id_list = [];
String? selectedobjformId;
String? selectedobjformType;

List<String> damage_type_list = [];
List<String> damage_id_list = [];
String? selecteddamformId;
String? selecteddamformType;

final TextEditingController damage = TextEditingController();
final TextEditingController dam_text = TextEditingController();
final TextEditingController cause_text = TextEditingController();

String searchQuery = ''; // State to store the search query
List<Map<String, dynamic>> filteredData = []; // Filtered list based on search
List<Map<String, dynamic>> apiData = []; // Define apiData outside the widget build function

class _ComplaintsState extends State<Complaints> {
  @override
  void initState() {
    super.initState();
    Object_type_data();
    Damage_type_data();
  }
  Future<void> Object_type_data() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
        Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/complaint_objects.php?key=03201232927&dealer_id=$id'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> typeList = data.map((item) => item['object_name'].toString()).toList();
      List<String> idList = data.map((item) => item['id'].toString()).toList();
      setState(() {
        object_type_list = typeList;
        object_id_list = idList;
      });
    } else {
      throw Exception('Failed to fetch data from the API');
    }
  }
  Future<void> Damage_type_data() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
        Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/complaint_damage.php?key=03201232927&dealer_id=$id'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> typeList = data.map((item) => item['name'].toString()).toList();
      List<String> idList = data.map((item) => item['id'].toString()).toList();
      setState(() {
        damage_type_list = typeList;
        damage_id_list = idList;
      });
    } else {
      throw Exception('Failed to fetch data from the API');
    }
  }
  void sendOrderDataToAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final apiUrl = "http://151.106.17.246:8080/OMCS-CMS-APIS/create/create_dealer_complaint.php";
    final data = {
      "dealer_id": id,
      "row_id": '',
      "object_part": selectedobjformId,
      "damage_overview": selecteddamformId,
      "damage": damage.text.toString(),
      "text": dam_text.text.toString(),
      "cause_text": cause_text.text.toString(),
    };

    final response = await http.post(Uri.parse(apiUrl), body: data);

    if (response.statusCode == 200) {
      print("Order data sent successfully!");
      Fluttertoast.showToast(
        msg: "Order sent successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      fetchDataFromAPI();
      Navigator.of(context).pop();
      damage.clear();
      dam_text.clear();
      cause_text.clear();
    } else {
      print("Error sending order data. Status code: ${response.statusCode}");
      Fluttertoast.showToast(
        msg: "Order Not Created",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      fetchDataFromAPI();
      Navigator.of(context).pop();
      damage.clear();
      dam_text.clear();
      cause_text.clear();
    }
  }
  Future<List<Map<String, dynamic>>?> fetchDataFromAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealers_new_complaints.php?key=03201232927&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load data from the API');
    }
  }
  void filterData(String query) {
    setState(() {
      searchQuery = query;
      if (query.isNotEmpty) {
        filteredData = apiData.where((order) => order['id'].contains(query)).toList();
      } else {
        filteredData = List<Map<String, dynamic>>.from(apiData);
      }
    });
  }

  int _selectedIndex = 1;
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEE d MMM kk:mm:ss').format(now);
    return Builder(builder: (context) {
      return Scaffold(
        backgroundColor: Color(0xffffffff),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Constants.primary_color,
          elevation: 10,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios), // Use the back arrow icon
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(); // Pop the current page when the back button is pressed
            },
          ),
          title: Text(
            'Complaint',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
                color: Colors.white,
                fontSize: 16),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                    ),
                    builder: (BuildContext context) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Padding(padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Padding(padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'Complaint  Form',
                                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    TextDropdownFormField(
                                      options:object_type_list,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(18.0),
                                        ),
                                        suffixIcon: Icon(Icons.arrow_drop_down_circle_outlined),
                                        labelText: "Object Part",
                                      ),
                                      dropdownHeight: 100,
                                      onChanged: (dynamic value) {
                                        setState(() {
                                          selectedobjformType = value; // Set the selected type
                                          // Find the index of the selected type in uniform_type_list
                                          int index = object_type_list.indexOf(value);
                                          if (index >= 0 && index < object_id_list.length) {
                                            selectedobjformId = object_id_list[index]; // Set the corresponding ID
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(height:18,),
                                    TextDropdownFormField(
                                      options: damage_type_list,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(18.0),
                                        ),
                                        suffixIcon: Icon(Icons.arrow_drop_down_circle_outlined),
                                        labelText: "Damage Overview",
                                      ),
                                      dropdownHeight: 100,
                                      onChanged: (dynamic value) {
                                        setState(() {
                                          selecteddamformType = value; // Set the selected type
                                          // Find the index of the selected type in uniform_type_list
                                          int index = damage_type_list.indexOf(value);
                                          if (index >= 0 && index < damage_id_list.length) {
                                            selecteddamformId = damage_id_list[index]; // Set the corresponding ID
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(height:18,),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: damage,
                                            decoration: InputDecoration(
                                              labelText: 'Damage',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18.0),),

                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10), // Add some spacing between the two text fields
                                        Expanded(
                                          child: TextField(
                                            controller: dam_text,
                                            decoration: InputDecoration(
                                              labelText: 'Text',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18.0),),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height:18,),
                                    TextField(
                                      controller:cause_text,
                                      decoration: InputDecoration(
                                        labelText: 'Cause Text',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18.0),),

                                      ),
                                    ),
                                    SizedBox(height:18,),
                                    Container(
                                      child:Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Text(
                                                  'Place Complaint',
                                                  style: GoogleFonts.raleway(
                                                    fontWeight: FontWeight.w700,
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: 16,
                                                    color: Colors.white
                                                  ),
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Constants.secondary_color,
                                              ),
                                              onPressed: sendOrderDataToAPI,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: Icon(
                  // <-- Icon
                  Icons.add,
                  size: 24.0,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff3B8D5A), // Background color
                ),
                label: Text(
                  'Create Complaint',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                  ),
                ), // <-- Text
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
          padding: EdgeInsets.all(18),
          child: Column(
            children: [
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                elevation: 5,
                child: TextField(
                  decoration: InputDecoration(
                      prefixIcon: Icon(FluentIcons.search_12_regular,
                          color: Color(0xff8d8d8d)),
                      hintText: 'Search using Complaint Number',
                      hintStyle: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.normal,
                          color: Color(0xff12283D),
                          fontSize: 16),
                      border: InputBorder.none),
                  onChanged: (value) {
                    filterData(value);
                  },
                ),
              ),
              SizedBox(
                height: 10,
              ),
              FutureBuilder<List<Map<String, dynamic>>?>(
                future: fetchDataFromAPI(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final apiData = snapshot.data!;
                    filteredData = List<Map<String, dynamic>>.from(apiData); // Assign to filtered data initially
                    if (searchQuery.isNotEmpty) {
                      filteredData = apiData.where((order) => order['id'].contains(searchQuery)).toList();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final item = filteredData[index];
                        return Card(
                          elevation: 10,
                          color: Color(0xffFFFFFF),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: CircleAvatar(
                                            radius:
                                            28, // Adjust the size of the circular avatar
                                            backgroundColor: Color(0xffE7AD18),
                                            child: Image.asset(
                                              "assets/images/complain.png",
                                              width: 38,
                                              height: 38,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  Text(
                                                    'COMPLAINT#: ${item['id']}',
                                                    style: GoogleFonts.montserrat(
                                                      fontWeight: FontWeight.w600,
                                                      fontStyle: FontStyle.normal,
                                                      color: Color(0xff12283D),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Color(0xffE7AD18),
                                                      borderRadius: BorderRadius.only(
                                                        topLeft: Radius.circular(12.0), // Curved top left corner
                                                        bottomLeft: Radius.circular(12.0), // Curved bottom left corner
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                      child: Text(
                                                        ' PROCESSING ',
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w500,
                                                          fontStyle: FontStyle.normal,
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Object:"),
                                              Text(' ${item['object_name']}',
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff3B8D5A),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Damage Overview:"),
                                              Text(' ${item['damage_name']}',
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff3B8D5A),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text('Damage: ${item['damage']}',
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text('Text: ${item['text']}',
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text('Cause Text: ${item['cause_text']}',
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0,),
                                            child: Row(
                                              children: [
                                                Text('${item['created_at']}',
                                                  style: GoogleFonts.montserrat(
                                                    fontWeight: FontWeight.w200,
                                                    fontStyle: FontStyle.normal,
                                                    color: Color(0xff737373),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),


                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text('No data available.'),
                    );
                  }
                },
              ),
              /*
              Card(
                elevation: 10,
                color: Color(0xffF0F0F0),
                child: Container(

                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PMG',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                  color: Color(0xff12283D),
                                  fontSize: 16),
                            ),
                            Text(
                              'Quantity: 23000 Ltr.',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w200,
                                  fontStyle: FontStyle.normal,
                                  color: Color(0xff737373),
                                  fontSize: 12),
                            ),
                            Text(
                              '54,000 Rs.',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                  color: Color(0xff3B8D5A),
                                  fontSize: 12),
                            ),
                            SizedBox(
                              height: 32,
                            ),
                            Text(
                              '9/20/2023  5:00 PM',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.normal,
                                  color: Color(0xff9b9b9b),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Card(
                              color: Color(0xffFFF3D4),
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Text(
                                  'In Progress',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                      color: Color(0xffE7AD18),
                                      fontSize: 12),
                                ),
                              ),
                            ),
                            Text(
                              'Waiting For Approval',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.normal,
                                  color: Color(0xff9b9b9b),
                                  fontSize: 12),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            SizedBox(
                              width: 90,
                              height: 20,
                              child: ElevatedButton(
                                child: Text(
                                  'Shortage',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w100,
                                    fontSize: 11,
                                    fontStyle: FontStyle.normal,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    primary: Color(0xff12283D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    )),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        color: Colors.white54,
                                        child: Column(
                                          children: [
                                            SizedBox(height: 30,),
                                            Icon(
                                              FontAwesomeIcons.cameraRetro,
                                              color: Color(0xff12283d),
                                              size: 160,
                                            ),
                                            Text(
                                              'Click Here To Upload Photos',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(18.0),
                                              child: SizedBox(
                                                height: 50,
                                                child: TextFormField(

                                                  onFieldSubmitted: (value) {
                                                    print(value);

                                                  },
                                                  keyboardType: TextInputType.number,
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xffa8a8a8),
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 16,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintStyle: GoogleFonts.poppins(
                                                      color: Color(0xffa8a8a8),
                                                      fontWeight: FontWeight.w300,
                                                      fontSize: 16,
                                                      fontStyle: FontStyle.normal,
                                                    ),
                                                    labelStyle: GoogleFonts.poppins(
                                                      color: Color(0xffa8a8a8),
                                                      fontWeight: FontWeight.w300,
                                                      fontSize: 16,
                                                      fontStyle: FontStyle.normal,
                                                    ),
                                                    filled: true,
                                                    fillColor: Color(0xffF1F4FF),
                                                    hintText: 'Recieved',
                                                    focusedBorder: OutlineInputBorder(
                                                        borderSide:
                                                        BorderSide(width: 2, color: Color(0xff3b5fe0)),
                                                        borderRadius:
                                                        BorderRadius.all(Radius.circular(10))),
                                                    border: OutlineInputBorder(
                                                        borderSide:
                                                        BorderSide(width: 2, color: Color(0xffF1F4FF)),
                                                        borderRadius:
                                                        BorderRadius.all(Radius.circular(10))),
                                                    labelText: 'Recieved Qty',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(top: 20),
                                              child: MaterialButton(
                                                onPressed: () {

                                                },
                                                child: Text(
                                                  'Add Shortage',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'SFUIDisplay',
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white),
                                                ),
                                                color: Color(0xff12283d),
                                                elevation: 0,
                                                minWidth: 350,
                                                height: 60,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            TextButton.icon(
                              // <-- TextButton
                              onPressed: () {},
                              icon: Icon(
                                FluentIcons.drawer_arrow_download_24_regular,
                                size: 16.0,
                                color: Color(0xff12283D),
                              ),
                              label: Text(
                                'Invoice',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FontStyle.normal,
                                    color: Color(0xff12283D),
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                ),
              )*/
            ],
          ),
        )),
        /*
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
                color: Color(0xff12283D),
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
                    label: 'Orders',
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
              selectedItemColor: Color(0xff12283D),
              iconSize: 40,
              onTap: _onItemTapped,
              elevation: 15),
        ),
        */
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
              unselectedLabelStyle: const TextStyle(
                  color: Color(0xff8d8d8d), fontSize: 14),
              unselectedFontSize: 14,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedIconTheme: IconThemeData(
                color: Color(0xff12283D),

              ),
              type: BottomNavigationBarType.shifting,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(FluentIcons.home_32_regular, size: 20,),
                    label: 'Home',
                    backgroundColor: Colors.white
                ),
                BottomNavigationBarItem(
                    icon: Icon(FluentIcons.weather_sunny_16_regular, size: 20,),
                    label: 'Complaint',
                    backgroundColor: Colors.white
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.inprivate_account_16_regular, size: 20,),
                  label: 'Profile',
                  backgroundColor: Colors.white,
                ),
              ],

              selectedItemColor: Color(0xff12283D),
              iconSize: 40,
              onTap: _onItemTapped,
              elevation: 15
          ),
        ),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // if (_selectedIndex == 1) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => Orders()),
    //   );
    // }
    if (_selectedIndex == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    }
    if (_selectedIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Profile()),
      );
    }
  }
}
