import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/constants.dart';

class OilTankMapPage extends StatefulWidget {
  final String SaleOrder;

  const OilTankMapPage({Key? key, required this.SaleOrder}) : super(key: key);
  @override
  _OilTankMapPageState createState() => _OilTankMapPageState(SaleOrder,);
}
class _OilTankMapPageState extends State<OilTankMapPage> {
  final String SaleOrder;

  _OilTankMapPageState(this.SaleOrder);

  late GoogleMapController mapController;
  late Future<List<dynamic>> futureData;
  // Co-odinates
  double dealerLatitude = 0.0;
  double dealerLongitude = 0.0;

  double driverLatitude = 0.0;
  double driverLongitude = 0.0;

  double depoLatitude = 0.0;
  double depoLongitude = 0.0;

  String Time = '--/--/----';
  String Speed = '--';


  String deponame='DEPO';
  String status='';

  List<Map<String, dynamic>> _TripTrack = [];
  late BitmapDescriptor _markerIcon;

  // Initial camera position (Karachi coordinates)
  static const LatLng karachiLatLng = LatLng(30.375321,70.605583);

  // Function to simulate car movement
  Future<List<dynamic>> Order_Detail() async {
    final response = await http.get(Uri.parse(
        'http://151.106.17.246:8080/OMCS-CMS-APIS/get/puma_sap_order/get_sap_order_subtripdata_by_salesOrders.php?key=03201232927&salesOrders=$SaleOrder'));

    if (response.statusCode == 200) {
      List<dynamic> orderDetails = json.decode(response.body);
      String lastId = orderDetails.last['id'];
      status = orderDetails.last['tracker_status'];
      if(orderDetails.last['tracker_status'] != 'Without-Tracker'){
        await co_odinates(lastId);
        DateTime currentTime = DateTime.now();
        String formattedCloseTime;
        if (orderDetails.last['close_time'] == null || orderDetails.last['close_time'] == "") {
          formattedCloseTime = "${currentTime.year}-${currentTime.month.toString().padLeft(2, '0')}-${currentTime.day.toString().padLeft(2, '0')} ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}";
        } else {
          DateTime closeTime = DateTime.parse(orderDetails.last['close_time']);
          formattedCloseTime =
          "${closeTime.year}-${closeTime.month.toString().padLeft(2, '0')}-${closeTime.day.toString().padLeft(2, '0')} ${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}:${closeTime.second.toString().padLeft(2, '0')}";
        }
        print('hellow world pakistan: $formattedCloseTime');
        await CarTracking(orderDetails.last['vehicle_id'], orderDetails.last['start_time'], formattedCloseTime);
      }
      else{
        setState(() {
          var dealerCoordinates =orderDetails.last['dealer_co'];
          var coordinates = dealerCoordinates.split(',');
          dealerLatitude = double.tryParse(coordinates[0]) ?? 0.0;
          dealerLongitude = double.tryParse(coordinates[1]) ?? 0.0;
          var depoCoordinates = orderDetails.last['depo_co'];
          var depocoordinates = depoCoordinates.split(',');
          depoLatitude = double.tryParse(depocoordinates[0]) ?? 0.0;
          depoLongitude = double.tryParse(depocoordinates[1]) ?? 0.0;
          deponame=orderDetails.last['consignee_name'];
        });
      }
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch data');
    }
  }
  Future<void> co_odinates(String lastId) async {
    List<dynamic> __co_odinates = [];
    final response = await http.get(Uri.parse('http://151.106.17.246:8080/OMCS-CMS-APIS/get/puma_sap_order/get_order_co.php?key=03201232927&id=$lastId'));

    if (response.statusCode == 200) {
      setState(() {
        __co_odinates = json.decode(response.body);
        var dealerCoordinates = __co_odinates[0]['dealer_co'];
        var coordinates = dealerCoordinates.split(',');
        dealerLatitude = double.tryParse(coordinates[0]) ?? 0.0;
        dealerLongitude = double.tryParse(coordinates[1]) ?? 0.0;

        driverLatitude = double.tryParse(__co_odinates[0]['d_lat']) ?? 0.0;
        driverLongitude = double.tryParse(__co_odinates[0]['d_lng']) ?? 0.0;

        var depoCoordinates = __co_odinates[0]['depo_co'];
        var depocoordinates = depoCoordinates.split(',');
        depoLatitude = double.tryParse(depocoordinates[0]) ?? 0.0;
        depoLongitude = double.tryParse(depocoordinates[1]) ?? 0.0;

        deponame=__co_odinates[0]['consignee_name'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }
  Future<void> CarTracking(vehicle_id,start_time,end_time) async {
    final String apiUrl = 'http://151.106.17.246:8080/OMCS-CMS-APIS/get/puma_sap_order/get_trip_routes.php?key=03201232927&vehicle_id=$vehicle_id&start_time=$start_time&end_time=$end_time';
    //final String apiUrl = 'http://151.106.17.246:8080/OMCS-CMS-APIS/get/puma_sap_order/get_trip_routes.php?key=03201232927&vehicle_id=40&start_time=2024-02-22 20:32:32&end_time=2024-02-23 12:32:32';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<Map<String, dynamic>> data = [];
        for (var item in jsonData) {
          data.add(Map<String, dynamic>.from(item));
        }
        setState(() {
          if (data.isNotEmpty){
            _TripTrack = data;
            Time =_TripTrack.last['time']??'0';
            Speed =_TripTrack.last['speed'] ?? '0';
          }
          else{
            String Time = '--/--/----';
            String Speed = '--';
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
  Set<Polyline> _createPolylines() {
    print('Creating polylines...');
    List<LatLng> points = _TripTrack.map((point) {
      return LatLng(double.parse(point['latitude']), double.parse(point['longitude']));
    }).toList();

    print('Points length: ${points.length}');

    return {
      Polyline(
        polylineId: PolylineId('route'),
        points: points,
        color: Colors.red,
        width: 3,
        // Define dash pattern for dotted line
      ),
    };
  }
  Future<void> _loadMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 1),
      'assets/images/cargomap.png',
    );
    setState(() {}); // This is necessary to trigger a rebuild with the loaded icon
  }


  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
    futureData = Order_Detail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios), // Use the back arrow icon
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop(); // Pop the current page when the back button is pressed
          },
        ),
        title: Text(
          'Tracking',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.normal,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: Constants.primary_color,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<dynamic>? data = snapshot.data;
            String? activeTime = data?[0]['active_time'];
            String? closeTime = data?[0]['close_time'];
            String? eta = data?[0]['eta'];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        color: Constants.secondary_color,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text('$deponame', style: TextStyle(fontSize: 14.0, color: Colors.white)),
                                    Icon(Icons.arrow_right_alt, color: Colors.white),
                                    Text('${data?[0]['name']}', style: TextStyle(fontSize: 14.0, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ) ,
                      ),
                      Card(
                        color: Constants.secondary_color,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline,color: Colors.white,),
                                  Text(' : ${data?[0]['driver_name']}',style: TextStyle(fontSize: 14.0, color: Colors.white)),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(FontAwesomeIcons.idCard,color: Colors.white,),
                                  Text('  : ${data?[0]['driver_cnic']}',style: TextStyle(fontSize: 14.0, color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ) ,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: karachiLatLng, zoom: 5.0),
                    mapType: MapType.terrain,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: {
                      if(status != 'Without-Tracker')
                          Marker(
                            markerId: MarkerId('driver location'),
                            position: LatLng(driverLatitude, driverLongitude),
                            icon: _markerIcon,
                            infoWindow: InfoWindow(
                              title: 'Current Driver Position',
                              snippet: 'Time: ${Time}\nSpeed: ${Speed}',
                            ),
                          ),

                      Marker(
                        markerId: MarkerId('dealerLocation'),
                        position: LatLng(dealerLatitude,dealerLongitude),
                        infoWindow: InfoWindow(title: '${data?[0]['name']}'),
                      ),
                      Marker(
                        markerId: MarkerId('depoLocation'),
                        position: LatLng(depoLatitude,depoLongitude),
                        infoWindow: InfoWindow(title: '$deponame'),
                      ),
                    },
                    polylines: _createPolylines(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Constants.secondary_color,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.box, color: Colors.white),
                                      SizedBox(width: 10,),
                                      Column(
                                        children: [
                                          Text('${data?[0]['product_name']} - ${data?[0]['qty']} ltr.',style: TextStyle(fontSize: 14.0, color: Colors.white),),
                                        ],
                                      )
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: (){},
                                        child: Text(
                                          '${data?[0]['tracker_status']}',
                                          style: TextStyle(color: Constants.secondary_color),
                                        ),
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.all(Colors.white),
                                          shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero, // Set borderRadius to zero for square shape
                                            ),
                                          ),
                                        ),

                                      ),
                                      Text('Order #${data?[0]['salesapNo']}',style: TextStyle(fontSize: 14.0, color: Colors.white),),
                                    ],
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.fire_truck,color: Colors.white),
                                      SizedBox(width: 10,),
                                      Text("${data?[0]['vehicle']}",style: TextStyle(fontSize: 14.0, color: Colors.white),),
                                    ],
                                  ),
                                  Text("PKR. ${NumberFormat("#,##0.00", "en_US").format(double.parse(data?[0]['price']))}",style: TextStyle(fontSize: 14.0, color: Colors.white),),
                                ],
                              ),
                              SizedBox(height: 10,),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,color: Colors.white),
                                  Text(' Departure:',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),),
                                  SizedBox(width: 5,),
                                  Text("${activeTime != null && activeTime.isNotEmpty ? activeTime : '--/--/----'}",style: TextStyle(fontSize: 14.0, color: Colors.white),),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,color: Colors.white),
                                  Text(' Arrival:',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),),
                                  SizedBox(width: 10,),
                                  Text("${closeTime != null && closeTime.isNotEmpty ? closeTime : '--/--/----'}",style: TextStyle(fontSize: 14.0, color: Colors.white),),
                                ],
                              ),
                              SizedBox(height: 10,),
                              Row(
                                children: [
                                  Icon(Icons.timelapse,color: Colors.white,),
                                  Text(' ETA:',style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),),
                                  SizedBox(width: 10,),
                                  Text(
                                    "${eta != null && eta.isNotEmpty ? eta.split('.').first : '--/--/----'}",
                                    style: TextStyle(fontSize: 14.0, color: Colors.white),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
