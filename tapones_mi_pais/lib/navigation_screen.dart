import 'dart:async';

import 'package:TMP/reporte_controller.dart';
import 'package:TMP/setDestination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:math' show cos, sqrt, asin;

import 'package:location/location.dart';
import 'package:lottie/lottie.dart' as lot;
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatefulWidget {
  final double lat;
  final double lng;
  const NavigationScreen({super.key, required this.lat, required this.lng});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  Location location = Location();
  PolylinePoints polylinePoints = PolylinePoints();
  Marker? sourePosition, destinationPosition;
  loc.LocationData? _currentPosition;
  LatLng curLocation = const LatLng(23.0525, 72.5667);
  StreamSubscription<loc.LocationData>? locationSubscription;

  @override
  void initState() {
    super.initState();
    getNavigation();
    addMarker();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    ReporteController _reporteController = Get.put(ReporteController());
    return SafeArea(
      child: Scaffold(
        body: sourePosition == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  GoogleMap(
                    zoomControlsEnabled: false,
                    polylines: Set<Polyline>.of(polylines.values),
                    initialCameraPosition:
                        CameraPosition(target: curLocation, zoom: 16),
                    markers: {sourePosition!, destinationPosition!},
                    onTap: (latLng) {
                      print(latLng);
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                  Positioned(
                    top: 30,
                    left: 15,
                    child: GestureDetector(
                      onTap: () {
                        Get.offAll(() => const Destino());
                      },
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.blue),
                      child: Center(
                          child: IconButton(
                        icon: const Icon(
                          Icons.navigation_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          // await launchUrl(Uri.parse(
                          //     'google.navigation:q=${widget.lat}, ${widget.lng}, AIzaSyD8DhAnQu6XuskeyxiZSB_6MRqN46TrjRk'));

                          if (await canLaunchUrl(Uri.parse(
                              'google.navigation:q=${widget.lat}, ${widget.lng}&key=AIzaSyD8DhAnQu6XuskeyxiZSB_6MRqN46TrjRk'))) {
                            await launchUrl(Uri.parse(
                                'google.navigation:q=${widget.lat}, ${widget.lng}&key=AIzaSyD8DhAnQu6XuskeyxiZSB_6MRqN46TrjRk'));
                          } else {
                            throw 'Could not launch google.navigation:q=${widget.lat}, ${widget.lng}&key=AIzaSyD8DhAnQu6XuskeyxiZSB_6MRqN46TrjRk';
                          }
                        },
                      )),
                    ),
                  ),
                  Positioned(
                      bottom: 80,
                      right: 15,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red),
                        child: IconButton(
                          icon: const Icon(
                            Icons.report_gmailerrorred_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            hacerReporte(
                                height: screenHeight,
                                width: screenWidth,
                                reporteController: _reporteController);
                          },
                        ),
                      ))
                ],
              ),
      ),
    );
  }

  void getNavigation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    final GoogleMapController? controller = await _controller.future;
    location.changeSettings(accuracy: loc.LocationAccuracy.high);
    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    if (_permissionGranted == loc.PermissionStatus.granted) {
      _currentPosition = await location.getLocation();
      curLocation =
          LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!);
      locationSubscription =
          location.onLocationChanged.listen((LocationData currentLocation) {
        controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target:
                LatLng(currentLocation.latitude!, currentLocation.longitude!),
            zoom: 16)));

        if (mounted) {
          controller
              ?.showMarkerInfoWindow(MarkerId(sourePosition!.markerId.value));
          setState(() {
            curLocation =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            sourePosition = Marker(
                markerId: MarkerId(currentLocation.toString()),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                position: LatLng(
                    currentLocation.latitude!, currentLocation.longitude!),
                infoWindow: InfoWindow(
                  title: getDistance(LatLng(widget.lat, widget.lng)),
                  onTap: () {
                    print('marcador topado');
                  },
                ));

            getDirections(LatLng(widget.lat, widget.lng));
          });
        }
      });
    }
  }

  void addMarker() {
    setState(() {
      sourePosition = Marker(
          markerId: const MarkerId('source'),
          position: curLocation,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));

      destinationPosition = Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(widget.lat, widget.lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan));
    });
  }

  void getDirections(LatLng dst) async {
    List<LatLng> polylineCoordinates = [];
    List<dynamic> points = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyD8DhAnQu6XuskeyxiZSB_6MRqN46TrjRk',
        PointLatLng(curLocation.latitude, curLocation.longitude),
        PointLatLng(dst.latitude, dst.longitude),
        travelMode: TravelMode.driving);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        points.add({'lat': point.latitude, 'lng': point.longitude});
      });
    } else {
      print(result.errorMessage);
    }
    addPolyLine(polylineCoordinates);
  }

  void addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        points: polylineCoordinates,
        width: 3);
    polylines[id] = polyline;
    setState(() {});
  }

  String getDistance(LatLng destposition) {
    return calculateDistance(curLocation.latitude, curLocation.longitude,
            destposition.latitude, destposition.longitude)
        .toString();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a));
  }

  Future hacerReporte({
    required double height,
    required double width,
    required ReporteController reporteController,
  }) {
    return Get.dialog(
      GetBuilder<ReporteController>(
        init: reporteController,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                lot.Lottie.asset('assets/reporte.json', height: 150),
                const Text(
                  'Explicanos la razón del congestionamiento',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<dynamic>(
                  isExpanded: true,
                  value: _.motivo,
                  items: _.motivos
                      .map((item) => DropdownMenuItem<String>(
                          value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) {
                    _.actualizarMotivo(value!);
                    setState(() {
                      // depSeleccionado = value.toString();
                    });
                  },
                  menuMaxHeight: height * 0.6,
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                  iconSize: width * 0.07,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                  dropdownColor: Colors.white,
                  decoration: dropDownDecoration(),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (descipcion) {
                    _.actualizarDescripcion(descipcion);
                  },
                  decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      isDense: true,
                      prefixIcon: Icon(Icons.edit, color: Colors.black),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.all(Radius.circular(15)))),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => Get.close(1),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '    Cancelar    ',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        var response = await _.reportar(
                            latitud: curLocation.latitude.toString(),
                            longitud: curLocation.longitude.toString());

                        if (response) {
                          Get.close(1);
                          Get.showSnackbar(GetSnackBar(
                            backgroundColor: Colors.green[900]!,
                            mainButton: TextButton(
                              child: const Text(
                                '',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () {},
                            ),
                            title: 'Reporte Enviado',
                            message:
                                'Su reporte sobre ${"este incidente"} fue enviado exitosamente',
                            duration: const Duration(milliseconds: 1500),
                          ));
                        } else {
                          Get.showSnackbar(GetSnackBar(
                            backgroundColor: Colors.red[900]!,
                            mainButton: TextButton(
                              child: const Text(
                                '',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () {},
                            ),
                            title: 'Error al enviar',
                            message: 'Error al procesar su reporte',
                            duration: const Duration(milliseconds: 1500),
                          ));
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 43, 82, 143)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration dropDownDecoration() {
  return const InputDecoration(
      labelText: 'Tipo de Reporte',
      alignLabelWithHint: true,
      isDense: true,
      prefixIcon: Icon(Icons.type_specimen_outlined, color: Colors.black),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))));
}
