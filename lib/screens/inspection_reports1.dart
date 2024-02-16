import 'dart:convert';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hascol_dealer/utils/constants.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:toggle_switch/toggle_switch.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';



class InspectionReports extends StatefulWidget {
  static const Color contentColorOrange = Color(0xFF00705B);
  final Color leftBarColor = Color(0xFFCB6600);
  final Color rightBarColor = Color(0xFF5BECD2);
  @override
  InspectionReportsState createState() => InspectionReportsState();
}

String searchQuery = ''; // State to store the search query
List<Map<String, dynamic>> filteredData = []; // Filtered list based on search
List<Map<String, dynamic>> apiData = [];
int value1 = 1;

class InspectionReportsState extends State<InspectionReports> {

  @override
  void initState() {
    super.initState();
    fetchDataFromAPI();
  }

  Future<List<Map<String, dynamic>>?> fetchDataFromAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealers_inspections.php?id=$id&key=03201232927'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    else {
      throw Exception('Failed to load data from the API');
    }
  }
  void filterData(String query, int toggleIndex) {
    setState(() {
      searchQuery = query.toLowerCase(); // Convert search query to lowercase

      filteredData = List<Map<String, dynamic>>.from(apiData);

      if (searchQuery.isNotEmpty) {
        filteredData = filteredData
            .where((report) =>
        report['name'].toLowerCase().contains(searchQuery) &&
            (toggleIndex == 0
                ? report['current_status'] == 'Complete'
                : (toggleIndex == 2
                ? report['current_status'] == 'Pending'
                : true)))
            .toList();
      } else {
        filteredData = filteredData
            .where((report) =>
        toggleIndex == 0
            ? report['current_status'] == 'Complete'
            : (toggleIndex == 2
            ? report['current_status'] == 'Pending'
            : true))
            .toList();
      }
    });
  }

  //Sales Performance PDF MAKER
  Future<List<Map<String, dynamic>>> getSalesPerformance(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealers_sales_performance.php?key=03201232927&task_id=$taskId&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> salesPerformanceData = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print("MysalesPerformanceData: $salesPerformanceData");
      return salesPerformanceData;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load sales performance data');
    }
  }
  Future<void> generateSalesPerformancePDF(List<Map<String, dynamic>> salesPerformanceData, String taskId) async {
    final pdf = pw.Document();

    // Load a font (replace with your desired font)
    final font = pw.Font.helvetica(); // Use the built-in Helvetica font

    // Number format for formatting numbers with a comma for thousands
    final NumberFormat numberFormat = NumberFormat('#,##0');

    // Load the image from assets
    final ByteData data = await rootBundle.load('assets/images/puma icon.png');
    final List<int> bytes = data.buffer.asUint8List();

    // Convert List<int> to Uint8List
    final Uint8List uint8List = Uint8List.fromList(bytes);

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Add the image
              pw.Image(pw.MemoryImage(uint8List), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text('Sales Performance Report', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Task ID: $taskId', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Time: ${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['created_at'] : ""}', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              // Add a table for sales performance data
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1), // Name column
                  1: pw.FlexColumnWidth(1), // Monthly Target column
                  2: pw.FlexColumnWidth(1), // Target Achieved column
                  3: pw.FlexColumnWidth(1), // Difference column
                  4: pw.FlexColumnWidth(2), // Reason column
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child: pw.Text('Name', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Monthly\nTarget', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Target\nAchieved', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Difference', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Reason', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Table data
                  for (var item in salesPerformanceData)
                    pw.TableRow(
                      children: [
                        pw.Center(child: pw.Text('${item['name']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${numberFormat.format(int.parse(item['monthly_target']))}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${numberFormat.format(int.parse(item['target_achived']))}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${numberFormat.format(int.parse(item['differnce']))}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['reason']}', style: pw.TextStyle(font: font))),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a file
    final file = File('${(await getTemporaryDirectory()).path}/sales_performance_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using the open_file package
    OpenFile.open(file.path);
  }

  //Measurements Pricing PDF MAKER
  Future<List<Map<String, dynamic>>> getMeasurementsPricing(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealers_measurement_price_inspection.php?key=03201232927&inspection_id=$taskId&task_id=$taskId&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> MeasurementsPricing = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print("MyMeasurementsPricing: $MeasurementsPricing");
      return MeasurementsPricing;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load sales performance data');
    }
  }
  Future<void> generateMeasurementsPricingPDF(List<Map<String, dynamic>> salesPerformanceData, String taskId) async {
    final pdf = pw.Document();

    // Load a font (replace with your desired font)
    final font = pw.Font.helvetica(); // Use the built-in Helvetica font

    // Number format for formatting numbers with a comma for thousands
    final NumberFormat numberFormat = NumberFormat('#,##0');

    // Load the image from assets
    final ByteData data = await rootBundle.load('assets/images/puma icon.png');
    final List<int> bytes = data.buffer.asUint8List();

    // Convert List<int> to Uint8List
    final Uint8List uint8List = Uint8List.fromList(bytes);

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Add the image
              pw.Image(pw.MemoryImage(uint8List), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text('Measurement and Pricing Report', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Task ID: $taskId', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Time: ${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['main_data']['created_at'] : ""}', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              // Add the first table for main_data
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child: pw.Text('Dispenser Name', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('PMG Accurate', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Shortage PMG', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('HSD Accurate', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Shortage HSD', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Table data
                  for (var item in salesPerformanceData[0]['sub_data'])
                    pw.TableRow(
                      children: [
                        pw.Center(child: pw.Text('${item['dispensor_name']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['pmg_accurate']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['shortage_pmg']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['hsd_accurate']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['shortage_hsd']}', style: pw.TextStyle(font: font))),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Add the second table for sub_data
              // Add the second table for sub_data
              // Add the second table for sub_data (first part)
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child: pw.Text('Category', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Table data for Appreciation, Measure, and Warning
                  for (var key in ["appreation", "measure_taken", "warning"])
                    pw.TableRow(
                      children: [
                        pw.Text(getHeaderText(key), style: pw.TextStyle(font: font)),
                        pw.Text('${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['main_data'][key] : ""}', style: pw.TextStyle(font: font)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child: pw.Text('Product', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Ogra Price', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Pump Price', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Variance', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Table data for PMG and HSD
                  for (var productKey in ["PMG", "HSD"])
                    pw.TableRow(
                      children: [
                        pw.Center(child:pw.Text('$productKey', style: pw.TextStyle(font: font))),
                        pw.Center(child:pw.Text('${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['main_data']['${productKey.toLowerCase()}_ogra_price'] : ""}', style: pw.TextStyle(font: font))),
                        pw.Center(child:pw.Text('${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['main_data']['${productKey.toLowerCase()}_pump_price'] : ""}', style: pw.TextStyle(font: font))),
                        pw.Center(child:pw.Text('${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['main_data']['${productKey.toLowerCase()}_variance'] : ""}', style: pw.TextStyle(font: font))),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a file
    final file = File('${(await getTemporaryDirectory()).path}/Measurement_and_Pricing_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using the open_file package
    OpenFile.open(file.path);
  }
  String getHeaderText(String key) {
    switch (key) {
      case "appreation":
        return "Appreciation of the dealer if correct";
      case "measure_taken":
        return "Measures taken to overcome shortage";
      case "warning":
        return "Warning";
      default:
        return key;
    }
  }

  //Wet Stock Management PDF MAKER
  Future<List<Map<String, dynamic>>> getWetStock(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealer_wet_stock.php?key=03201232927&task_id=$taskId&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> WetStockData = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print("MyWetStockData: $WetStockData");
      return WetStockData;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load sales performance data');
    }
  }
  Future<void> generateWetStockPDF(List<Map<String, dynamic>> salesPerformanceData, String taskId) async {
    final pdf = pw.Document();

    // Load a font (replace with your desired font)
    final font = pw.Font.helvetica(); // Use the built-in Helvetica font

    // Number format for formatting numbers with a comma for thousands
    final NumberFormat numberFormat = NumberFormat('#,##0');

    // Load the image from assets
    final ByteData data = await rootBundle.load('assets/images/puma icon.png');
    final List<int> bytes = data.buffer.asUint8List();

    // Convert List<int> to Uint8List
    final Uint8List uint8List = Uint8List.fromList(bytes);

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Add the image
              pw.Image(pw.MemoryImage(uint8List), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text('Wet Stock Management Report', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Task ID: $taskId', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Time: ${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['created_at'] : ""}', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              // Add a table for sales performance data
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1), // Name column
                  1: pw.FlexColumnWidth(1), // Monthly Target column
                  2: pw.FlexColumnWidth(1), // Target Achieved column
                  3: pw.FlexColumnWidth(1), // Difference column
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child: pw.Text('Product', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Tank', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Previous Dip', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      pw.Center(child: pw.Text('Present Dip', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Table data
                  for (var item in salesPerformanceData)
                    pw.TableRow(
                      children: [
                        pw.Center(child: pw.Text('${item['name']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['lorry_no']}', style: pw.TextStyle(font: font))),
                        pw.Center(
                          child: pw.Text(
                            '${numberFormat.format(int.tryParse(item['dip_old'] ?? '0') ?? 0)}',
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                        pw.Center(
                          child: pw.Text(
                            '${numberFormat.format(int.tryParse(item['dip_new'] ?? '0') ?? 0)}',
                            style: pw.TextStyle(font: font),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a file
    final file = File('${(await getTemporaryDirectory()).path}/Wet_Stock_Management_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using the open_file package
    OpenFile.open(file.path);
  }

  //Dispensing Unit Meter Reading PDF MAKER
  Future<List<Map<String, dynamic>>> getDispensingReading(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealer_task_despensing_unit.php?key=03201232927&task_id=$taskId&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> DispensingReading = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print("MyDispensingReading: $DispensingReading");
      return DispensingReading;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load sales performance data');
    }
  }
  Future<void> generateDispensingReadingPDF(List<Map<String, dynamic>> salesPerformanceData, String taskId) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final NumberFormat numberFormat = NumberFormat('#,##0');

    final ByteData data = await rootBundle.load('assets/images/puma icon.png');
    final List<int> bytes = data.buffer.asUint8List();
    final Uint8List uint8List = Uint8List.fromList(bytes);

    // Group the salesPerformanceData by dispenser_id
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in salesPerformanceData) {
      String dispenserId = item['dispenser_id'];
      if (!groupedData.containsKey(dispenserId)) {
        groupedData[dispenserId] = [];
      }
      groupedData[dispenserId]?.add(item);
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(pw.MemoryImage(uint8List), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text('Dispensing Unit Meter Reading Report', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Task ID: $taskId', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Time: ${salesPerformanceData.isNotEmpty ? salesPerformanceData[0]['created_at'] : ""}', style: pw.TextStyle(font: font, fontSize: 14)),
              // Add any other common information here
            ],
          ),
          for (var dispenserId in groupedData.keys)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Center(child: pw.Text('Product Name', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                        pw.Center(child: pw.Text('Nozzle Name', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                        pw.Center(child: pw.Text('Old Reading', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                        pw.Center(child: pw.Text('New Reading', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    for (var item in groupedData[dispenserId]!)
                      pw.TableRow(
                        children: [
                          pw.Center(child: pw.Text('${item['product_name']}', style: pw.TextStyle(font: font))),
                          pw.Center(child: pw.Text('${item['nozle_name']}', style: pw.TextStyle(font: font))),
                          pw.Center(
                            child: pw.Text(
                              '${numberFormat.format(double.tryParse(item['old_reading'] ?? '0.0') ?? 0.0)}',
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                          pw.Center(
                            child: pw.Text(
                              '${numberFormat.format(double.tryParse(item['new_reading'] ?? '0.0') ?? 0.0)}',
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Add a gap between sections
                pw.SizedBox(height: 20),
              ],
            ),
        ],
      ),
    );

    // Save the PDF to a file
    final file = File('${(await getTemporaryDirectory()).path}/Dispensing_Unit_Meter_Reading_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using the open_file package
    OpenFile.open(file.path);
  }

  //Stock Variation PDF MAKER
  Future<List<Map<String, dynamic>>> getStockVariation(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealer_task_stock_variation.php?key=03201232927&task_id=$taskId&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> DispensingReading = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print("MyDispensingReading: $DispensingReading");
      return DispensingReading;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load sales performance data');
    }
  }
  Future<void> generateStockVariationPDF(List<Map<String, dynamic>> stockData, String taskId) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica(); // Use the built-in Helvetica font
    final NumberFormat numberFormat = NumberFormat('#,##0');

    final ByteData data = await rootBundle.load('assets/images/puma icon.png');
    final List<int> bytes = data.buffer.asUint8List();
    final Uint8List uint8List = Uint8List.fromList(bytes);

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(pw.MemoryImage(uint8List), width: 100, height: 100),
              pw.SizedBox(height: 20),
              pw.Text('Stock Variation Report', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Task ID: $taskId', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Time: ${stockData.isNotEmpty ? stockData[0]['created_at'] : ""}', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              // Add a table for stock data
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1), // Name column
                  1: pw.FlexColumnWidth(1), // Opening Stock column
                  2: pw.FlexColumnWidth(1), // Purchase during Inspection Period column
                  3: pw.FlexColumnWidth(1), // Total Product Available for Sale column
                  4: pw.FlexColumnWidth(1), // Sales as per Meter Reading column
                  5: pw.FlexColumnWidth(1), // Book Stock column
                  6: pw.FlexColumnWidth(1), // Current Physical Stock column
                  7: pw.FlexColumnWidth(1), // Gain Loss column
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child: _buildPaddedText('Product', font)),
                      pw.Center(child: _buildPaddedText('Opening Stock', font)),
                      pw.Center(child: _buildPaddedText('Purchase during Inspection Period', font)),
                      pw.Center(child: _buildPaddedText('Total Product Available for Sale', font)),
                      pw.Center(child: _buildPaddedText('Sales as per Meter Reading', font)),
                      pw.Center(child: _buildPaddedText('Book Stock', font)),
                      pw.Center(child: _buildPaddedText('Current Physical Stock', font)),
                      pw.Center(child: _buildPaddedText('Gain Loss', font)),
                    ],
                  ),
                  // Table data
                  for (var item in stockData)
                    pw.TableRow(
                      children: [
                        pw.Center(child: pw.Text('${item['name']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['opening_stock']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['purchase_during_inspection_period']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['total_product_available_for_sale']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['sales_as_per_meter_reading']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['book_stock']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['current_physical_stock']}', style: pw.TextStyle(font: font))),
                        pw.Center(child: pw.Text('${item['gain_loss']}', style: pw.TextStyle(font: font))),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a file
    final file = File('${(await getTemporaryDirectory()).path}/Stock_Variation_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using the open_file package
    OpenFile.open(file.path);
  }
  pw.Container _buildPaddedText(String text, pw.Font font) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5.0), // Adjust the padding value as needed
      child: pw.Text(text, style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
    );
  }

  //Inspections PDF MAKER
  Future<List<Map<String, dynamic>>> getInspection(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("Id");
    final response = await http.get(
      Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/get_dealer_survey_response.php?key=03201232927&inspection_id=$taskId&task_id=$taskId&dealer_id=$id'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> DispensingReading = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print("MyDispensingReading: $DispensingReading");
      return DispensingReading;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception.
      throw Exception('Failed to load sales performance data');
    }
  }
  Future<void> generateInspectionPDF(List<Map<String, dynamic>> surveyResponseData, String taskId) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    //Puma.png
    final ByteData data = await rootBundle.load('assets/images/puma icon.png');
    final List<int> bytes = data.buffer.asUint8List();
    final Uint8List uint8List = Uint8List.fromList(bytes);
    //image.png
    final ByteData data1 = await rootBundle.load('assets/images/image-files.png');
    final List<int> bytes1 = data1.buffer.asUint8List();
    final Uint8List uint8List1 = Uint8List.fromList(bytes1);
    //
    final ByteData datacheck = await rootBundle.load('assets/images/check-mark.png');
    final List<int> bytescheck = datacheck.buffer.asUint8List();
    final Uint8List uint8Listcheck = Uint8List.fromList(bytescheck);

    //total table data
    int totalQuestions = surveyResponseData.map((category) => category['Questions'].length).reduce((value, element) => value + element);
    int yesCount = surveyResponseData.expand((category) => category['Questions']).where((q) => q['response'] == 'Yes').length;
    int noCount = surveyResponseData.expand((category) => category['Questions']).where((q) => q['response'] == 'No').length;
    int naCount = surveyResponseData.expand((category) => category['Questions']).where((q) => q['response'] == 'N/A').length;
    double percentage = (yesCount / (totalQuestions - naCount) * 100).toDouble();

    bool isFirstPage = true;

    for (var category in surveyResponseData) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Image(pw.MemoryImage(uint8List), width: 100, height: 100),
            pw.SizedBox(height: 20),
            pw.Text('Inspection Report', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Date & Time: ${category['Questions'].isNotEmpty ? category['Questions'][0]['created_at'] : ""}', style: pw.TextStyle(font: font, fontSize: 14)),
            pw.SizedBox(height: 20),
            if (isFirstPage)
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(160),
                },
                border: pw.TableBorder.all(),
                children: [
                  // 1st column
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Retail Site Name & Station Code:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Location:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Address:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('City:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Province:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Region:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Last Audit Date:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Name of Retailer Representative/ Manager:')),
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(160),
                },
                border: pw.TableBorder.all(),
                children: [
                  // 1st column
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Name of Auditor(s):')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Designation of Auditor(s):')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Date of Audit:')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Retail Product (CNG ____, Diesel _____, Petrol _____, HOBC _____) (Y/N)')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('Number of U/G Storage Tanks (HOBC _____, Petrol______, Diesel _____) (Write the total capacity)')),
                  ]),
                  pw.TableRow(children: [
                    pw.Container(padding: pw.EdgeInsets.all(5), child: pw.Text('NFR Facilities: (Tuck Shop _____, Car Wash _____, Tyre Shop _____, Oil Change_____) (Y/N)')),
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                columnWidths: {
                  0: pw.FixedColumnWidth(100),
                  1: pw.FixedColumnWidth(100),
                  2: pw.FixedColumnWidth(100),
                  3: pw.FixedColumnWidth(100),
                  4: pw.FixedColumnWidth(100),
                },
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Center(child:pw.Text('Total Questions', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('Yes', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('No', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('N/A', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('Percentage', style: pw.TextStyle(font: font))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Center(child: pw.Text('$totalQuestions', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('$yesCount', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('$noCount', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('$naCount', style: pw.TextStyle(font: font))),
                      pw.Center(child:pw.Text('${percentage.toStringAsFixed(2)}%', style: pw.TextStyle(font: font))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            pw.Table(
              columnWidths: {
                0: pw.FixedColumnWidth(260), // Question column width
                1: pw.FixedColumnWidth(40),  // Yes column width
                2: pw.FixedColumnWidth(40),  // No column width
                3: pw.FixedColumnWidth(40),  // N/A column width
                4: pw.FixedColumnWidth(180), // Comment column width
                5: pw.FixedColumnWidth(80),  // Image column width
              },
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    pw.Center(child: pw.Text('${category['name']}', style: pw.TextStyle(font: font))),
                    pw.Center(child: pw.Text('Yes', style: pw.TextStyle(font: font))),
                    pw.Center(child: pw.Text('No', style: pw.TextStyle(font: font))),
                    pw.Center(child: pw.Text('N/A', style: pw.TextStyle(font: font))),
                    pw.Center(child: pw.Text('Comment', style: pw.TextStyle(font: font))),
                    pw.Center(child: pw.Text('Image', style: pw.TextStyle(font: font))),
                  ],
                ),
                for (var question in category['Questions'])
                  pw.TableRow(
                    children: [
                      pw.Text('${question['question']}', style: pw.TextStyle(font: font)),
                      pw.Center(
                        child: question['response'] == 'Yes'
                            ? pw.Image(pw.MemoryImage(uint8Listcheck), width: 25, height: 25)
                            : pw.Text('-', style: pw.TextStyle(font: font)),
                      ),
                      pw.Center(
                        child: question['response'] == 'No'
                            ? pw.Image(pw.MemoryImage(uint8Listcheck), width: 25, height: 25)
                            : pw.Text('-', style: pw.TextStyle(font: font)),
                      ),
                      pw.Center(
                        child: question['response'] == 'N/A'
                            ? pw.Image(pw.MemoryImage(uint8Listcheck), width: 25, height: 25)
                            :pw.Text('-', style: pw.TextStyle(font: font)),
                      ),
                      pw.Text('${question['comment'] ?? ''}', style: pw.TextStyle(font: font)),
                      pw.Center(
                        child: question['cancel_file'] != null && question['cancel_file'] != ""
                            ? pw.Image(pw.MemoryImage(uint8List1), width: 25, height: 25)
                            :pw.Text('-', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
      isFirstPage = false;
    }

    // Save the PDF to a file
    final file = File('${(await getTemporaryDirectory()).path}/Inspection_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using the open_file package
    OpenFile.open(file.path);
  }



  //Submit Dialog Box
  Future<void> _showDialog(BuildContext context, bool isCompulsory) async {
    TextEditingController _reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remarks'),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Set the content padding
          content: Container(
            width: 300.0, // Set the desired width
            child: TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              maxLines: 3,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                if (isCompulsory && (_reasonController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reason is compulsory. Please enter a reason.'),
                    ),
                  );
                } else {
                  print('Entered Reason: ${_reasonController.text}');
                  Navigator.of(context).pop();
                }
              },
              child: Text('Submit', style: TextStyle(color: Colors.white)),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
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
            'Inspection Reports',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
                color: Colors.white,
                fontSize: 16),
          ),
          actions: [
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  Card(
                    child: ToggleSwitch(
                      initialLabelIndex: value1,
                      totalSwitches: 3,
                      minWidth: 100.0,
                      activeBgColor: [Colors.green],
                      activeFgColor: Colors.white,
                      inactiveBgColor: Colors.white,
                      inactiveFgColor: Colors.green,
                      animate: true,
                      labels: ['Complete','All', 'Pending'],
                      onToggle: (index) {
                        print('switched to: $index');
                        setState(() {
                          value1 = index!;
                          filterData(searchQuery, value1);
                        });
                      },
                    ),
                    elevation: 10,
                  ),
                  SizedBox(height: 10,),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    elevation: 5,
                    child: TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(FluentIcons.search_12_regular,
                              color: Color(0xff8d8d8d)),
                          hintText: 'Search  using Inspector Name',
                          hintStyle: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.normal,
                              color: Color(0xff12283D),
                              fontSize: 16),
                          border: InputBorder.none),
                      onChanged: (value) {
                        filterData(value,value1);
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
                      }
                      else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      else if (snapshot.hasData) {
                        final apiData = snapshot.data!;
                        filteredData = List<Map<String, dynamic>>.from(apiData); // Assign to filtered data initially
                        if (searchQuery.isNotEmpty) {
                          filteredData = filteredData
                              .where((report) =>
                          report['name'].toLowerCase().contains(searchQuery) &&
                              (value1 == 0
                                  ? report['current_status'] == 'Complete'
                                  : (value1 == 2
                                  ? report['current_status'] == 'Pending'
                                  : true)))
                              .toList();
                        } else {
                          filteredData = filteredData
                              .where((report) =>
                          value1 == 0
                              ? report['current_status'] == 'Complete'
                              : (value1 == 2
                              ? report['current_status'] == 'Pending'
                              : true))
                              .toList();
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final item = filteredData[index];
                            bool isComplete = item['current_status'] == 'Complete';
                            return Card(
                              color: Colors.white,
                              elevation: 5,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['name']}',
                                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 12.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${item['time']}',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(width: 16.0),
                                        if (isComplete)
                                          ElevatedButton(
                                            onPressed: () {
                                              // Open dialog box logic goes here
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text('Details'),
                                                    content: Container(
                                                      width: MediaQuery.of(context).size.width, // Set the width as per your requirement
                                                      height: 300.0,
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Sales Performances:',
                                                                  style: TextStyle(fontSize: 14.0),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  List<Map<String, dynamic>> salesPerformanceData = await getSalesPerformance(item['id']);
                                                                  await generateSalesPerformancePDF(salesPerformanceData,item['id']);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.blue, // Customize the PDF button color
                                                                ),
                                                                child: Text('PDF',style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Measurement & Pricing:',
                                                                  style: TextStyle(fontSize: 14.0),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  List<Map<String, dynamic>> MeasurementsPricingData = await getMeasurementsPricing(item['id']);
                                                                  await generateMeasurementsPricingPDF(MeasurementsPricingData,item['id']);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.blue, // Customize the PDF button color
                                                                ),
                                                                child: Text('PDF',style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Wet Stock Management',
                                                                  style: TextStyle(fontSize: 14.0),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  List<Map<String, dynamic>> WetStockData = await getWetStock(item['id']);
                                                                  await generateWetStockPDF(WetStockData,item['id']);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.blue, // Customize the PDF button color
                                                                ),
                                                                child: Text('PDF',style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  "Dispensing Unit Meter Reading",
                                                                  style: TextStyle(fontSize: 14.0),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  List<Map<String, dynamic>> DispensingReadingData = await getDispensingReading(item['id']);
                                                                  await generateDispensingReadingPDF(DispensingReadingData,item['id']);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.blue, // Customize the PDF button color
                                                                ),
                                                                child: Text('PDF',style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Stock Variation',
                                                                  style: TextStyle(fontSize: 14.0),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  List<Map<String, dynamic>> StockVariationData = await getStockVariation(item['id']);
                                                                  await generateStockVariationPDF(StockVariationData,item['id']);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.blue, // Customize the PDF button color
                                                                ),
                                                                child: Text('PDF',style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  'Inspection',
                                                                  style: TextStyle(fontSize: 14.0),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  List<Map<String, dynamic>> InspectionData = await getInspection(item['id']);
                                                                  await generateInspectionPDF(InspectionData,item['id']);

                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.blue, // Customize the PDF button color
                                                                ),
                                                                child: Text('PDF',style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: Text('Close',style: TextStyle(color: Colors.red)),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: null, // No background color
                                            ),
                                            child: Text(
                                              'View',
                                              style: TextStyle(color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isComplete)
                                          ElevatedButton(
                                            onPressed: () {
                                              _showDialog(context, false);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green, // Green background color for Approved button
                                            ),
                                            child: Text('Approved', style: TextStyle(color: Colors.white)),
                                          ),
                                        SizedBox(width: 10),
                                        if (isComplete)
                                          ElevatedButton(
                                            onPressed: () {
                                              _showDialog(context, true);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red, // Red background color for Declined button
                                            ),
                                            child: Text('Declined', style: TextStyle(color: Colors.white)),
                                          ),
                                        if(isComplete==false)
                                          Card(
                                            elevation: 5,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30.0),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(12.0),
                                              child: Text(
                                                'Pending',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
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
        ],
              ),
            )
        ),
      );
    });
  }
}
