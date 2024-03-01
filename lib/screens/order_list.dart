import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hascol_dealer/screens/create_order.dart';
import 'package:hascol_dealer/screens/home.dart';
import 'package:hascol_dealer/screens/profile.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import '../utils/constants.dart';
import 'Tracking.dart';

class Orders extends StatefulWidget {
  static const Color contentColorOrange = Color(0xFF00705B);
  final Color leftBarColor = Color(0xFFCB6600);
  final Color rightBarColor = Color(0xFF5BECD2);
  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  @override
  void initState() {
    super.initState();
    fetchData();
  }
  late List<int> quantity_input;
  late List<double> quantity_less;
  double hsd = 0;
  TextEditingController imageNameController = TextEditingController();
  GlobalKey<_OrdersState> globalKey = GlobalKey();

  List<Map<String, dynamic>> order_list = [];

  File? selectedImage;
  int _selectedIndex = 1;
  String searchQuery = ''; // State to store the search query
  List<Map<String, dynamic>> filteredData = []; // Filtered list based on search
  List<Map<String, dynamic>> apiData = [];


  post_send(order_ID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    var matchingOrder = order_list.firstWhere((order) => order['id'] == order_ID);

    // Order found, extract product JSON
    var productJson = matchingOrder['product_json'];
    // Decode the product_json
    List<dynamic> decodedProductJson = json.decode(productJson);
    // Create a list to store the new JSON structures
    List<Map<String, dynamic>> newJsonList = [];
    // Iterate over each index in the decoded list
    for (int j = 0; j < decodedProductJson.length; j++) {
      var product = decodedProductJson[j];
      var p_id = product['p_id'];
      var product_name = product['product_name'];
      var quantity = product['quantity'];
      // Create a new JSON structure
      Map<String, dynamic> newJson = {
        'p_id': p_id,
        'product_name': product_name,
        'quantity': quantity,
        'quantity_rec': '${quantity_input[j]}',
        'quantity_less': '${quantity_less[j]}',
      };
      // Add the new JSON structure to the list
      newJsonList.add(newJson);
    }
    print("$newJsonList,,,,,,,$selectedImage");
    var request = http.MultipartRequest('POST', Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/create/create_dealer_dip_shortage.php'));
    request.fields.addAll({
      'order_id': '$order_ID',
      'dealer_id': '$id',
      'row_id': '',
      'product_json': '$newJsonList',
    });

    request.files.add(await http.MultipartFile.fromPath('file', selectedImage!.path));
    http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var ret = await response.stream.bytesToString();
        if (ret == '1') {
          Fluttertoast.showToast(
              msg: 'Shortage Report Submitted',
              backgroundColor: Colors.greenAccent,
              textColor: Colors.black);
          Navigator.of(context as BuildContext).push(MaterialPageRoute(builder: (context) => Orders()));
          selectedImage = null;
          imageNameController.clear();
        } else {
          Fluttertoast.showToast(
              msg: 'Shortage Report Not Submitted',
              backgroundColor: Colors.redAccent,
              textColor: Colors.white);
        }
        print(ret);
      } else {
        print(response.reasonPhrase);
      }
    }
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          selectedImage = File(pickedFile.path);
          imageNameController.text = selectedImage!
              .path
              .split('/')
              .last;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }
  Future<void> createInvoice(BuildContext context, String orderNumber,String SaleOrder) async {
    final List<Map<String, dynamic>>? data = await fetchData();

    if (data != null && data.isNotEmpty) {
      // Filter data based on the orderNumber
      final List<Map<String, dynamic>> filteredData =
      data.where((order) => order['id'].toString() == orderNumber).toList();

      if (filteredData.isEmpty) {
        // Handle the case where no data is found for the orderNumber
        print('No data found for order number: $orderNumber');
        return;
      }

      final pdf = pw.Document();

      final Uint8List logoImage =
      (await rootBundle.load('assets/images/puma_logo.svg'))
          .buffer
          .asUint8List();

      // Generate PDF content
      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          final String orderID = filteredData[0]["id"]?.toString() ?? "";
          final String totalAmount =
              filteredData[0]["total_amount"]?.toString() ?? "";
          final String dateTime = filteredData[0]["created_at"] ?? "";
          final String type = filteredData[0]["type"] ?? "";

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 1,
                text: 'INVOICE',
                textStyle: pw.TextStyle(fontSize: 28),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Invoice#: $SaleOrder',
                style: pw.TextStyle(
                  fontSize: 16,
                ),
              ),
              pw.Text('Total Amount: PKR. $totalAmount'),
              pw.Text('Date and Time: $dateTime'),
              pw.Text('Type: ${type == 'ZDL' ? 'Delivered' : type == 'GC / Coco' ? 'Delivered' : 'Self'}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Product', 'Quantity', 'Indent Price', 'Amount'],
                  // Assuming product details are in the "products" key in the data
                  for (var product
                  in json.decode(filteredData[0]['product_json']))
                    if (product['quantity'] != null &&
                        product['quantity'] != '0')
                      <String>[
                        product['product_name'] ?? "", // Add null check
                        product['quantity']?.toString() ?? "", // Add null check
                        product['indent_price']?.toString() ??
                            "", // Add null check
                        product['amount']?.toString() ?? "", // Add null check
                      ],
                ],
                border: pw.TableBorder.all(
                    color: PdfColor.fromHex('#FFFFFF')), // Remove border
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#CCCCCC'),
                ),
                cellStyle: pw.TextStyle(
                  color: PdfColor.fromHex('#000000'), // Black color in cells
                ),
                cellAlignment: pw.Alignment.center,
              ),
            ],
          );
        },
      ));

      // Get the document bytes
      final Uint8List pdfBytes = await pdf.save();

      // Create a temporary file for the PDF
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;
      final tempFile = File('$tempPath/invoice.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      // Open the PDF
      if (tempFile.existsSync()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFView(filePath: tempFile.path),
          ),
        );
      }
    }
  }
  create() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
  }
  Future<List<Map<String, dynamic>>?> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(Uri.parse(
        'http://151.106.17.246:8080/OMCS-CMS-APIS/get/dealer_orders.php?key=03201232927&id=${id}'));
    print('http://151.106.17.246:8080/OMCS-CMS-APIS/get/dealer_orders.php?key=03201232927&id=${id}');
    //1212

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        filteredData = List<Map<String, dynamic>>.from(data);
        order_list = List<Map<String, dynamic>>.from(data);
      });


      print('Samad:${order_list.length}');
      print('Samad:${order_list.length}');
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch data');
    }
  }
  void filterData(String query) {
    setState(() {
      searchQuery = query;
      if (query.isNotEmpty) {
        filteredData =
            order_list.where((order) => order['SaleOrder'].contains(query)).toList();
      } else {
        filteredData = order_list;
      }
    });
  }

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
            color: Colors.white ,
            onPressed: () {
              Navigator.of(context)
                  .pop(); // Pop the current page when the back button is pressed
            },
          ),
          title: Text(
            'Orders',
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Create_Order()),
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
                  'Create Order',
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
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.refresh,
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
          onPressed: () {
            print("Samad");
            fetchData();
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            fetchData(); // Add code to fetch and update data here
            print("MOIZ AQIL Rasheed");
          },
          child: SingleChildScrollView(
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
                        hintText: 'Search using Order Number',
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
                SingleChildScrollView(
                  physics: ScrollPhysics(),
                  child: Column(
                    children: [
                      ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: filteredData.length,
                          itemBuilder: (BuildContext context, int index2) {
                            List<Map<String, dynamic>> apiData = order_list;
                            // filteredData = List<Map<String, dynamic>>.from(
                            //     apiData); // Assign to filtered data initially
                            if (searchQuery.isNotEmpty) {
                              filteredData = order_list
                                  .where((order) =>
                                      order['SaleOrder'].contains(searchQuery))
                                  .toList();
                            } else {filteredData = order_list;}
                            final orderNumber = filteredData[index2]["id"];
                            final SaleOrder = filteredData[index2]["SaleOrder"];
                            final totalAmount = filteredData[index2]['total_amount'];
                            double amount = double.parse(totalAmount);
                            String formattedAmount = amount.toStringAsFixed(2);
                            final type = filteredData[index2]['type'];
                            final created_at = filteredData[index2]['created_at'];
                            final productJsonString = filteredData[index2]["product_json"];
                            final status = filteredData[index2]["status"];
                            final delivered_status = filteredData[index2]["delivered_status"];
                            final current_status = filteredData[index2]["status_value"];
                            final sap_status = filteredData[index2]["sap_status"];
                            final List<Map<String, dynamic>> products =
                                List<Map<String, dynamic>>.from(json.decode(productJsonString));
                            var c1;
                            late IconData iconData;
                            print("Khan-----> $products");
                            // if (status == '0') {
                            //   c1 = 0xff907e3e;
                            //   iconData = FontAwesomeIcons.hourglassStart;
                            // } else if (status == '1') {
                            //   c1 = 0xffdbb256;
                            //   iconData = FontAwesomeIcons.hourglassHalf;
                            // } else if (delivered_status == '1') {
                            //   c1 = 0xff358e58;
                            //   iconData = FontAwesomeIcons.truckMoving;
                            // } else if (status == "2") {
                            //   c1 = 0xffe02c2f;
                            //   iconData = FontAwesomeIcons.circleCheck;
                            // }
                            // else{
                            //   c1 =0xff339966;
                            // }
                            if (current_status == 'Completely Processed') {
                              c1 = 0xffdbb256;
                              iconData = FontAwesomeIcons.circleCheck;
                            } else {
                              c1 = 0xff907e3e;
                              iconData = FontAwesomeIcons.hourglassStart;
                            }
                            int index = 0;
                            Color backgroundColor = Colors.white;
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                    context: context,
                                    barrierDismissible:
                                        false, // user must tap button!
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Order Detail"),
                                        content: Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              4,
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text('Temp Order#'),
                                                      Text(
                                                        '$SaleOrder',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text('Type:'),
                                                      Text(
                                                        type == 'ZDL' ? 'Delivered' : type == 'GC / Coco' ? 'Delivered' : 'Self',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Product",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Quantity",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Indent Price",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Amount",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              for (var i = 0; i < products.length; i++)
                                                if (products[i]['quantity'] != null && products[i]['quantity'] != '0')
                                                  Container(
                                                    color: backgroundColor =
                                                        i % 2 == 0
                                                            ? Colors.grey
                                                            : Colors.white,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                "${products[i]['product_name']}"),
                                                          ],
                                                        ),
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                                "${products[i]['quantity']}"),
                                                          ],
                                                        ),
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                                "${products[i]['indent_price']}"),
                                                          ],
                                                        ),
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              products[i]['amount'].toStringAsFixed(2),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text('Total Amount: '),
                                                  Text(
                                                    '$formattedAmount Rs.',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                              child: Text("Close"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              })
                                        ],
                                      );
                                    });
                              },
                              child: Card(
                                elevation: 10,
                                color: Color(0xffF0F0F0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order#: $SaleOrder',
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff12283D),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'PKR. $formattedAmount',
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.normal,
                                                  color: Color(0xff3B8D5A),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Card(
                                                color: Color(c1),
                                                child: Padding(padding: const EdgeInsets.all(5.0),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        iconData,
                                                        color: Colors.white,
                                                        size: 16.0,
                                                      ),
                                                      SizedBox(width: 5,),
                                                      Text(
                                                        '$current_status',
                                                        style:
                                                        GoogleFonts.poppins(
                                                          fontWeight:
                                                          FontWeight.w500,
                                                          fontStyle:
                                                          FontStyle.normal,
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Column(
                                            children: [
                                              if(delivered_status == '1'|| sap_status == '1')
                                                TextButton.icon(
                                                  label: Text(
                                                    'Track',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w300,
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.normal,
                                                      color: Color(0xff12283D),
                                                    ),
                                                  ),
                                                  onPressed: (){
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => OilTankMapPage(SaleOrder: SaleOrder)),
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.route,
                                                    color: Color(0xff12283D),
                                                    size: 16,
                                                  ),
                                                ),
                                              if(delivered_status == '2'||sap_status == '2')
                                                TextButton.icon(
                                                  label: Text(
                                                    'Shortage',
                                                    style: GoogleFonts.poppins( // Ensure GoogleFonts.poppins is properly imported
                                                      fontWeight: FontWeight.w300,
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.normal,
                                                      color: Color(0xff12283D),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    quantity_input = List<int>.filled(products.length,0);
                                                    quantity_less = List<double>.filled(products.length,0);
                                                    imageNameController.clear();
                                                    selectedImage = null; // Reset selectedImage
                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,

                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                                                      ),
                                                      builder: (context) {
                                                        return StatefulBuilder(builder: (context, setState){
                                                          return SingleChildScrollView(
                                                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                            child: Padding(padding: const EdgeInsets.all(16.0),
                                                              child: Column(
                                                                children: [
                                                                  Text('Shortage', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                                                                  for(var i=0; i<products.length; i++)
                                                                    if (products[i]['quantity'] != null && products[i]['quantity'] != '0')
                                                                      Padding(padding: const EdgeInsets.all(8.0),
                                                                          child:Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Container(
                                                                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                                                                  child: TextField(
                                                                                    keyboardType: TextInputType.number,
                                                                                    decoration: InputDecoration(
                                                                                      hintText: "Enter Received Quantity ",
                                                                                      labelText: products[i]["product_name"],
                                                                                      border: OutlineInputBorder(
                                                                                        borderRadius: BorderRadius.circular(18.0),
                                                                                      ),
                                                                                    ),
                                                                                    maxLines: 1, // Limit the number of lines
                                                                                    onChanged: (dynamic value) {
                                                                                      if (value.isNotEmpty) {
                                                                                        setState(() {
                                                                                          quantity_input[i] = int.parse(value);
                                                                                          print('${products[i]['quantity']}');
                                                                                          hsd = double.parse("${products[i]['quantity']}")-int.parse(value);
                                                                                          quantity_less[i] = hsd;

                                                                                          print("Hellow brother1 $quantity_input");
                                                                                          print("Hellow brother1 $quantity_less");
                                                                                        });
                                                                                      } else {
                                                                                        print("Enter value");
                                                                                      };
                                                                                    },
                                                                                    onSubmitted: (dynamic value) {
                                                                                      if (value.isNotEmpty) {
                                                                                        setState(() {
                                                                                          quantity_input[i] = int.parse(value);
                                                                                          print('${products[i]['quantity']}');
                                                                                          hsd = double.parse("${products[i]['quantity']}")-int.parse(value);
                                                                                          quantity_less[i] = hsd;

                                                                                          print("Hellow brother1 $quantity_input");
                                                                                          print("Hellow brother1 $quantity_less");
                                                                                        });
                                                                                      } else {
                                                                                        print("Enter value");
                                                                                      };
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Expanded(
                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                    children: [
                                                                                      Text(
                                                                                        " - ",
                                                                                        style: TextStyle(
                                                                                          fontSize: 16.0,),),
                                                                                      Text(
                                                                                          products[i]["quantity"],
                                                                                          style: TextStyle(
                                                                                            fontSize: 16.0,)),
                                                                                      Text(
                                                                                          " = ",
                                                                                          style: TextStyle(
                                                                                            fontSize: 16.0,)),
                                                                                      Text(
                                                                                          quantity_less[i].toString(),
                                                                                          style: TextStyle(
                                                                                            fontSize: 16.0,))
                                                                                    ],
                                                                                  )
                                                                              ),
                                                                            ],
                                                                          )
                                                                      ),


                                                                  /*
                                                                          for (var i = 0; i < products.length; i++)
                                                                            if (products[i]['quantity'] != null && products[i]['quantity'] != '0') {
                                                                              return Padding(
                                                                                padding: const EdgeInsets
                                                                                    .all(
                                                                                    8.0),
                                                                                child: Row(
                                                                                  children: [
                                                                                    Expanded(
                                                                                      child: Container(
                                                                                        padding: EdgeInsets
                                                                                            .symmetric(
                                                                                            horizontal: 16),
                                                                                        child: TextField(
                                                                                          keyboardType: TextInputType
                                                                                              .number,
                                                                                          decoration: InputDecoration(
                                                                                            hintText: "Enter Received Quantity ",
                                                                                            labelText: products[index]["product_name"],
                                                                                            border: OutlineInputBorder(
                                                                                              borderRadius: BorderRadius
                                                                                                  .circular(
                                                                                                  18.0),
                                                                                            ),
                                                                                          ),
                                                                                          maxLines: 1, // Limit the number of lines
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    Expanded(
                                                                                        child: Row(
                                                                                          mainAxisAlignment: MainAxisAlignment
                                                                                              .spaceEvenly,
                                                                                          children: [
                                                                                            Text(
                                                                                              " - ",
                                                                                              style: TextStyle(
                                                                                                fontSize: 16.0,),),
                                                                                            Text(
                                                                                                products[index]["quantity"],
                                                                                                style: TextStyle(
                                                                                                  fontSize: 16.0,)),
                                                                                            Text(
                                                                                                " = ",
                                                                                                style: TextStyle(
                                                                                                  fontSize: 16.0,)),
                                                                                            Text(
                                                                                                " Quantity ",
                                                                                                style: TextStyle(
                                                                                                  fontSize: 16.0,))
                                                                                          ],
                                                                                        )),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            }
                                                                          */
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                                    child: Container(
                                                                      decoration: BoxDecoration(
                                                                        border: Border.all(color: Colors.grey), // Border color
                                                                        borderRadius: BorderRadius.circular(20.0), // Border radius
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: Text(imageNameController.text, maxLines: 1,),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            height: 40,
                                                                            child: ElevatedButton(
                                                                              onPressed: () {
                                                                                // Show an alert dialog to choose the image source
                                                                                showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    return AlertDialog(
                                                                                      title: Center(child: Text('Choose an option')),
                                                                                      actions: <Widget>[
                                                                                        Padding(
                                                                                          padding: EdgeInsets.symmetric(horizontal: 70),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              TextButton(
                                                                                                onPressed: () async {
                                                                                                  Navigator.of(context).pop();
                                                                                                  _pickImage(ImageSource.camera);
                                                                                                },
                                                                                                child: Icon(Icons.camera_alt_outlined, size: 35, color: Color(0xffea1b25),), // Add gallery icon
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: 10,
                                                                                              ),
                                                                                              TextButton(
                                                                                                onPressed: () async {
                                                                                                  Navigator.of(context).pop();
                                                                                                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                                                                                                    allowMultiple: false,
                                                                                                    type: FileType.image,
                                                                                                  );
                                                                                                  if (result != null && result.files.isNotEmpty) {
                                                                                                    setState(() {
                                                                                                      selectedImage = File(result.files.first.path!);
                                                                                                      imageNameController.text = selectedImage!
                                                                                                          .path
                                                                                                          .split('/')
                                                                                                          .last;
                                                                                                    });
                                                                                                  }
                                                                                                },
                                                                                                child: Icon(Icons.image_outlined, size: 35, color: Color(0xffea1b25),),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.only(
                                                                                    topRight: Radius.circular(20.0), // Round only the top-right corner
                                                                                    bottomRight: Radius.circular(20.0),
                                                                                  ),
                                                                                ),
                                                                                backgroundColor: Color(0xffea1b25),
                                                                              ),
                                                                              child: Text('Pick Image',style: TextStyle(fontSize: 16.0,color: Colors.white),),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  if(selectedImage != null)
                                                                    Container(
                                                                      margin: EdgeInsets.all(16.0),
                                                                      child: Image.file(selectedImage!,
                                                                        width: 200.0,
                                                                        height: 200.0,
                                                                        fit: BoxFit.fill,
                                                                        key: globalKey,
                                                                      ),
                                                                    ),
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      post_send(orderNumber);
                                                                      setState(() {
                                                                        quantity_input = List<int>.filled(products.length, 0);
                                                                        quantity_less = List<double>.filled(products.length, 0);
                                                                        imageNameController.clear();
                                                                      });
                                                                      Navigator.pop(context); // Close the bottom sheet
                                                                    },
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Color(0xffea1b25),
                                                                    ),
                                                                    child: Text(
                                                                      'Submit',style: TextStyle(color: Colors.white),),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        });

                                                      },
                                                    );
                                                  },
                                                  icon: Icon(
                                                    FontAwesomeIcons.chartLine,
                                                    color: Color(0xff12283D),
                                                    size: 14.0,
                                                  ),
                                                )
                                            ],
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: const Divider(),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$created_at',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w300,
                                              fontStyle: FontStyle.normal,
                                              color: Color(0xff9b9b9b),
                                              fontSize: 12,
                                            ),
                                          ),
                                          TextButton.icon(
                                            // <-- TextButton
                                            onPressed: () {
                                              createInvoice(
                                                  context, orderNumber,SaleOrder);
                                            },
                                            icon: Icon(
                                              FluentIcons
                                                  .drawer_arrow_download_24_regular,
                                              size: 16.0,
                                              color: Color(0xff12283D),
                                            ),
                                            label: Text(
                                              'Invoice',
                                              style:
                                              GoogleFonts.montserrat(
                                                fontWeight:
                                                FontWeight.w300,
                                                fontStyle:
                                                FontStyle.normal,
                                                color: Color(0xff12283D),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ),
      );
    });
  }
}
