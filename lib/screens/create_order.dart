import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_plus/dropdown_plus.dart';

import '../utils/constants.dart';
import 'order_list.dart';

class Create_Order extends StatefulWidget {
  static const Color contentColorOrange = Color(0xFF00705B);
  final Color leftBarColor = Color(0xFFCB6600);
  final Color rightBarColor = Color(0xFF5BECD2);
  @override
  _CreateOrderState createState() => _CreateOrderState();
}

class _CreateOrderState extends State<Create_Order> {
  late Future<List<Map<String, dynamic>>?> data1;
  List<dynamic>? sapi;
  List<int> product_values1 = [];
  List<TextEditingController> controllers = [];
  List<int> myQuantity=[];
  late List<int> selectedOptions;
  late List<double> hsdtValues;
  int? total;
  double hsd = 0;
  int hobc = 330;
  int pmg = 332;
  int hsdt = 0;
  int hobct = 0;
  int pmgt = 0;
  List data = [];
  String? _mySelection='0';
  String? account;
  TextEditingController hsdController = new TextEditingController();
  TextEditingController pmgController = new TextEditingController();
  TextEditingController hobcController = new TextEditingController();
  TextEditingController depotController = new TextEditingController();
  TextEditingController tlController = new TextEditingController();
  List<String> size_type_list = [];
  List<String> size_id_list = [];
  String? selectedsizeformId;
  String? selectedsizeformType;
  double freight_value = 0.0;
  var _site = "Self";
  double sum = 0.0;

  void updateSum() {
    sum = 0;
    List<double> numbers = hsdtValues;
    double Negself = newsum();
    sum = numbers.reduce((value, element) => value + element);
    if(_site == 'Self'){
      sum = sum - Negself;
    }else{
      sum = sum;
    }

    print("Sum: $sum");
  }

  double newsum(){
    double total = selectedOptions.fold(0, (prev, curr) => prev + curr);
    print(total);
    print(sapi?[0]["freight_value"]);
    print('Print Moiz ${total * double.parse(sapi?[0]["freight_value"])}');
    return total *double.parse(sapi?[0]["freight_value"]);
  }

  create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    var sap_no = prefs.getString("sap_no");
    var legder_balance = prefs.getString("account");
    String result = _site == "self" ? "ZXR" : "ZDL";
    List<Map<String, dynamic>> jsonArray = [];
    for (int i = 0; i < hsdtValues.length; i++) {
      print('Moiz:====${controllers[i].text.toString()}');
      print('Moiz2:====${sapi?[i]['indent_price']}');
      Map<String, dynamic> jsonObject = {
        'p_id': '${sapi?[i]['id']}',
        'quantity': selectedOptions[i].toString(),
        'indent_price': '${sapi?[i]['indent_price']}',
        'product_name': '${sapi?[i]['name']}',
        'amount': hsdtValues[i],
        'dealer_sap':'$sap_no',
        'product_sap':'${sapi?[i]['sap_no']}',
        'dealer_order_type':'$result',
      };
      jsonArray.add(jsonObject);
    }
    // Convert the array to a JSON string
    String jsonString = json.encode(jsonArray);

    // Print the JSON string
    print(jsonString);
    print("${id}||${_mySelection}||${_site}||${tlController.text.toString()}||${sum}||${legder_balance}");
    var request = http.MultipartRequest('POST', Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/create/create_dealers_orders.php'));
    if (_site == "Self") {
      if (tlController.text.isNotEmpty) {
        request.fields.addAll({
          'dealer_id': '${id}',
          'row_id': '',
          'depot': '${_mySelection}',
          'type': '$result',
          'tl_no': '${tlController.text.toString()}',
          'total': '${sum}',
          'product': '${jsonString}',
          'legder_balance': '${legder_balance}',
          'user_id': '${id}',
          'dealer_sap':'${sap_no}',
        });
        http.StreamedResponse response = await request.send();
        if (response.statusCode == 200) {
          var ret = await response.stream.bytesToString();
          if (ret == '1') {
            Fluttertoast.showToast(
                msg: 'Order Created Successfully',
                backgroundColor: Colors.greenAccent,
                textColor: Colors.black);
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        Orders()));
          } else {
            Fluttertoast.showToast(
                msg: 'Order Not Created',
                backgroundColor: Colors.redAccent,
                textColor: Colors.white);
          }
          print(ret);
        } else {
          print(response.reasonPhrase);
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Please Enter TL# ',
            backgroundColor: Colors.redAccent,
            textColor: Colors.white);
      }
    }
    else{
      request.fields.addAll({
        'dealer_id': '${id}',
        'row_id': '',
        'depot': '${_mySelection}',
        'type': '$result',
        'tl_no': '${tlController.text.toString()}',
        'total': '${sum}',
        'product': '${jsonString}',
        'legder_balance': '$legder_balance',
        'user_id': '${id}',
        'dealer_sap':'${sap_no}',
      });
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        var ret = await response.stream.bytesToString();
        if (ret == '1') {
          Fluttertoast.showToast(
              msg: 'Order Created Successfully',
              backgroundColor: Colors.greenAccent,
              textColor: Colors.black);
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
              msg: 'Order Not Created',
              backgroundColor: Colors.redAccent,
              textColor: Colors.white);
        }
        // print(await response.stream.bytesToString());
      }
      else {
        print(response.reasonPhrase);
      }
    }
  }



  @override
  void initState() {
    super.initState();
    this.getDepot();
    data1 = fetchData();
    Containers_sizes();
  }

  Future<void> Containers_sizes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(Uri.parse(
        'http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_containers_sizes.php?key=03201232927&id=1'));

    if (response.statusCode == 200) {
      print("Hello world");
      List<dynamic> data = json.decode(response.body);
      List<String> sizeList =
          data.map((item) => item['sizes'].toString()).toList();
      List<String> idList = data.map((item) => item['id'].toString()).toList();
      setState(() {
        size_type_list = sizeList;
        size_id_list = idList;
        print("MOIZ-1: $size_type_list");
      });
    } else {
      print("object-error");
      throw Exception('Failed to fetch data from the API');
    }
  }
  Future<List<Map<String, dynamic>>?> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    account = prefs.getString("account");

    final url = Uri.parse(
        "http://151.106.17.246:8080/OMCS-CMS-APIS/get/dealers_products.php?key=03201232927&dealer_id=${id}");
    print("http://151.106.17.246:8080/OMCS-CMS-APIS/get/dealers_products.php?key=03201232927&dealer_id=${id}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        print(jsonResponse);
        sapi = jsonResponse;
        List<Map<String, dynamic>> data = jsonResponse.cast<Map<String, dynamic>>();
        print('Samad ${data.length}');
        hsdtValues = List.filled(data.length, 0);
        selectedOptions = List.filled(data.length, 0);
        return data;
      } else {
        // Handle the error, e.g., show an error message
        return null;
      }
    } catch (exception) {
      // Handle exceptions
      return null;
    }
  }

  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEE d MMM kk:mm:ss').format(now);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
          //replace with our own icon data.
        ),
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        backgroundColor: Constants.primary_color,
        elevation: 10,
        title: Text(
          'Create Order',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.normal,
              color: Colors.white,
              fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
          child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Card(
              color: Color(0xffF0F0F0),
              elevation: 15,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //CircleAvatar
                      const SizedBox(
                        height: 10,
                      ), //SizedBox
                      Text(
                        'Account Balance',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xff000000),
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.normal,
                        ),
                      ), //Text
                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                              backgroundColor: Color(0xff12283D),
                              radius: 15,
                              child: Icon(
                                FontAwesomeIcons.cableCar,
                                color: Colors.white,
                                size: 15,
                              ) //Text
                              ),
                          SizedBox(
                            width: 5,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PKR. ${account}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xff000000),
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                'Updated On : ${formattedDate}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Color(0xff8A8A8A),
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ), //Column
                ),
              ), //SizedBox,
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: ListTile(
                    title: Text(
                      'Self',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Color(0xff12283D),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    leading: Radio(
                      fillColor: MaterialStateProperty.all(Color(0xff12283D)),
                      overlayColor:
                      MaterialStateProperty.all(Color(0xff12283D)),
                      value: "Self",
                      groupValue: _site,
                      onChanged: (value) {
                        setState(() {
                          _site = value!;
                          updateSum();
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(
                      'Deliver',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Color(0xff12283D),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    leading: Radio(
                      fillColor: MaterialStateProperty.all(Color(0xff12283D)),
                      overlayColor:
                      MaterialStateProperty.all(Color(0xff12283D)),
                      value: "GC / Coco",
                      groupValue: _site,
                      onChanged: (value) {
                        setState(() {
                          _site = value!;
                          updateSum();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            FutureBuilder<List<Map<String, dynamic>>?>(
              future: data1,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Text('No data available.');
                } else {
                  List<Map<String, dynamic>> apiData = snapshot.data!;

                  // Ensure that controllers has the same length as apiData
                  if (controllers.length < apiData.length) {
                    controllers.addAll(List.generate(
                        apiData.length - controllers.length,
                        (index) => TextEditingController()));
                  }
                  // List<String> selectedOptions = List.generate(apiData.length, (index) => '');
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: apiData.length,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: SizedBox(
                                width: 150,
                                child: TextDropdownFormField(
                                  options: size_type_list,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                    suffixIcon: Icon(
                                        Icons.arrow_drop_down_circle_outlined),
                                    labelText: "${apiData[index]['name']}",
                                  ),
                                  dropdownHeight: 100,
                                  onChanged: (dynamic value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        selectedOptions[index] = int.parse(value);
                                        hsd = int.parse(value) * double.parse("${apiData[index]['indent_price']}");
                                        hsdtValues[index] = hsd;

                                        print("Hellow brother $hsdtValues");
                                        print("Hellow brother $selectedOptions");

                                        updateSum();
                                        newsum();
                                      });
                                    } else {
                                      print("Enter value");
                                    };
                                  },
                                  onSaved: (dynamic value) {
                                    if (value.isNotempty) {
                                      setState(() {
                                        controllers[index] = value;
                                        print("my value2 $value");
                                        hsd = int.parse(value) *
                                            double.parse(
                                                "${apiData[index]['indent_price']}");
                                        hsdtValues[index] = hsd;
                                        print("Hellow brother $hsdtValues");
                                        updateSum();
                                      });
                                    } else {
                                      print("Enter value");
                                      newsum();
                                    }
                                    ;
                                  },
                                ),
                                /*
                                TextFormField(
                                  onFieldSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        hsd = int.parse(value) * int.parse("${apiData[index]['indent_price']}");
                                        hsdtValues[index] = hsd;
                                        print (hsdtValues);
                                        updateSum();
                                      });
                                    } else {
                                      print("Enter value");
                                    }
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        hsd = int.parse(value) * int.parse("${apiData[index]['indent_price']}");
                                        hsdtValues[index] = hsd;
                                        print (hsdtValues);
                                        updateSum();
                                      });
                                    } else {
                                      print("Enter value");
                                    }
                                  },
                                  onTapOutside: (value) {
                                    print(value);
                                  },
                                  controller: controllers[index],
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
                                    hintText: 'Quantity for ${apiData[index]['name']}',
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
                                    labelText: '${apiData[index]['name']}',
                                  ),
                                ),

                                     */
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "x",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${apiData[index]['indent_price']}',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "=",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                hsdtValues[index].toStringAsFixed(2),
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
            /*
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: SizedBox(
                    width: 150,
                    child: TextFormField(
                      onFieldSubmitted: (value) {
                        print(value);
                        setState(() {
                          hsdt = int.parse(value) * 350;
                        });
                      },
                      onTapOutside: (value) {
                        print(value);
                      },
                      controller: hsdController,
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
                        hintText: 'Quantity for HSD',
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
                        labelText: 'HSD',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "x",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hsd.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "=",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hsdt.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 13,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: SizedBox(
                    width: 150,
                    child: TextFormField(
                      onFieldSubmitted: (value) {
                        print(value);
                        setState(() {
                          hobct = int.parse(value) * 330;
                        });
                      },
                      controller: hobcController,
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
                        hintText: 'Quantity for HOBC',
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
                        labelText: 'HOBC',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "x",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hobc.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "=",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hobct.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 13,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: SizedBox(
                    width: 150,
                    child: TextFormField(
                      onFieldSubmitted: (value) {
                        print(value);
                        setState(() {
                          pmgt = int.parse(value) * 332;
                        });
                      },
                      controller: pmgController,
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
                        hintText: 'Quantity for PMG',
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
                        labelText: 'PMG',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "x",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pmg.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "=",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pmgt.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            */
            SizedBox(height: 10),
            Text(
              'Total Amount: ${sum}',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: Color(0xff12283D),
                  fontSize: 13),
            ),
            /*
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(
                    color: Color(0xff12283d),
                    style: BorderStyle.solid,
                    width: 0.80),
              ),

              child: DropdownButton(
                underline: Container(), //remove underline
                isExpanded: true,
                icon: Padding(
                    //Icon at tail, arrow bottom is default icon
                    padding: EdgeInsets.only(left: 20),
                    child: Icon(Icons.arrow_circle_down_sharp)),
                iconEnabledColor: Color(0xff12283d),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                items: data.map((item) {
                  return DropdownMenuItem(
                    child: new Text(
                      item['consignee_name'],
                      style: GoogleFonts.poppins(
                        color: Color(0xffa8a8a8),
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    value: item['id'].toString(),
                  );
                }).toList(),
                onChanged: (String? newVal) {
                  setState(() {
                    _mySelection = newVal!;
                    // print(_mySelection);
                  });
                },
                value: _mySelection,
                hint: Text(
                  "Select Depot",
                  style: GoogleFonts.poppins(
                    color: Color(0xff000000),
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
            ),
            */
            if (_site == "Self")
              TextFormField(
                controller: tlController,
                keyboardType: TextInputType.text,
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
                  hintText: 'TL #',
                  focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2, color: Color(0xff3b5fe0)),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  border: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2, color: Color(0xffF1F4FF)),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  labelText: 'Enter TL #',
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: MaterialButton(
                onPressed: () {
                  var amount = hsdt + pmgt + hobct;
                  create();
                },
                child: Text(
                  'Create Order',
                  style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'SFUIDisplay',
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                color: Constants.secondary_color,
                elevation: 0,
                minWidth: 350,
                height: 60,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Future<String> getDepot() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var user_id = await sharedPreferences.getString("userId");
    var res = await http.get(Uri.parse(
        "http://151.106.17.246:8080/hascol/api/dealer_depot.php?accesskey=12345&user_id=3"));
    var resBody = json.decode(res.body);

    setState(() {
      data = resBody;
      print(data.length);
    });

    // print(data[0]["id"]);
    // print("Sapcode " + code.toString());

    return Future.value("Data download successfully");
  }
}
