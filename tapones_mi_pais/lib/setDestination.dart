import 'dart:async';
import 'package:TMP/login.dart';
import 'package:TMP/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart' as geoLoc;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_webservice/places.dart' as gmw;
import 'package:google_api_headers/google_api_headers.dart';

class Destino extends StatefulWidget {
  const Destino({
    super.key,
  });

  @override
  State<Destino> createState() => _DestinoState();
}

const kGoogleApiKey = 'AIzaSyD8DhAnQu6XuskeyxiZSB_6MRqN46TrjRk';
final homeScaffoldKey = GlobalKey<ScaffoldState>();

class _DestinoState extends State<Destino> {
  late CameraPosition initialCameraPosition;

  Set<Marker> markersList = {};

  late GoogleMapController googleMapController;

  final Mode _mode = Mode.overlay;

  late LatLng? destLocation;
  Location location = Location();
  loc.LocationData? _currentPosition;
  final Completer<GoogleMapController?> _controller = Completer();

  TextEditingController buscador = TextEditingController();
  String? _address;
  bool mostrar = true;
  bool mostrarPantalla = false;
  final List<String> opciones = [
    'Opción 1',
    'Opción 2',
    'Opción 3',
    'Opción 4',
    'Opción 5',
  ];
  String selectedOption = '';
  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    buscador.addListener(() {
      setState(() {
        selectedOption = '';
      });
    });
    _getCurrentLocation().then((position) {
      // Asignar la posición de la cámara con la ubicación actual
      setState(() {
        destLocation = LatLng(position.latitude, position.longitude);
        mostrarPantalla = true;
      });
    });
  }

  Future<geoLoc.Position> _getCurrentLocation() async {
    return await geoLoc.Geolocator.getCurrentPosition(
        desiredAccuracy: geoLoc.LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Tapones Mi Pais'),
        leading: IconButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.clear();
              Get.offAll(() => const LoginScreen());
            },
            icon: const Icon(Icons.close_rounded)),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.place_outlined),
        onPressed: () => Get.to(() => NavigationScreen(
            lat: destLocation!.latitude!, lng: destLocation!.longitude!)),
      ),
      body: !mostrarPantalla
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 4,
              ),
            )
          : Stack(children: [
              GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                markers: markersList,
                initialCameraPosition:
                    CameraPosition(target: destLocation!, zoom: 16),
                onCameraMove: (position) {
                  if (destLocation != position.target) {
                    setState(() {
                      destLocation = position.target;
                    });
                  }
                },
                onCameraIdle: () {
                  debugPrint('cameraIdle');
                },
                onTap: (argument) {
                  debugPrint(argument.toString());
                },
                onMapCreated: (controller) {
                  googleMapController = controller;
                  _controller.complete(controller);
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ElevatedButton(
                    onPressed: _handlePressButton,
                    child: const Text("Buscar dirección")),
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 35),
                  child: Image.asset(
                    "assets/ping.png",
                    height: 45,
                    width: 45,
                  ),
                ),
              ),
            ]),
    );
  }

  Future<void> _handlePressButton() async {
    gmw.Prediction? p = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiKey,
        onError: onError,
        mode: _mode,
        language: 'es',
        strictbounds: false,
        types: [""],
        decoration: InputDecoration(
            hintText: 'Search',
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white))),
        components: [
          gmw.Component(gmw.Component.country, "DO"),
          gmw.Component(gmw.Component.country, "CRI")
        ]);

    displayPrediction(p!, homeScaffoldKey.currentState);
  }

  void onError(gmw.PlacesAutocompleteResponse response) {
    debugPrint("ERROR");
  }

  Future<void> displayPrediction(
      gmw.Prediction p, ScaffoldState? currentState) async {
    gmw.GoogleMapsPlaces places = gmw.GoogleMapsPlaces(
        apiKey: kGoogleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders());

    gmw.PlacesDetailsResponse detail =
        await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    markersList.clear();
    destLocation = LatLng(lat, lng);
    markersList.add(Marker(
        markerId: const MarkerId("0"),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: detail.result.name)));

    setState(() {});

    googleMapController
        .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 18.0));
  }

  void getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    final GoogleMapController? controller = await _controller.future;

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

    if (_permissionGranted != loc.PermissionStatus.granted) {
      location.changeSettings(accuracy: loc.LocationAccuracy.high);
      _currentPosition = await location.getLocation();
      controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target:
              LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
          zoom: 16)));

      setState(() {
        destLocation =
            LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!);
      });
    }
  }
}
