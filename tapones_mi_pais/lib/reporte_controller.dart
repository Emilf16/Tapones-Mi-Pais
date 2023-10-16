import 'package:TMP/database_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReporteController extends GetxController {
  // Variables
  RxString _motivo = ''.obs;
  // RxString _hora = ''.obs;
  RxString _descripcion = ''.obs;
  RxString _latitud = ''.obs;
  RxString _longitud = ''.obs;
  RxString _usuario = ''.obs;
  RxString _cedula = ''.obs;
  List<String> motivos = [
    'Accidente',
    'Vehiculo Dañado',
    'Inundación',
    'Obras en Construcción',
    'Semáforo Dañado',
    'Calle Estrecha',
    'Vehiculos Estacionados',
  ];
  // Devolver Variables
  Future<void> onInit() async {
    _motivo.value = motivos[0];
  }

  get motivo => _motivo.value;
  get descripcion => _descripcion.value;
  get latitud => _latitud.value;
  get longitud => _longitud.value;
  get usuario => _usuario.value;
  get cedula => _cedula.value;

  // Métodos
  void actualizarMotivo(String motivo) {
    _motivo.value = motivo;
    update();
  }

  void actualizarDescripcion(String descripcion) {
    _descripcion.value = descripcion;
    update();
  }

  void actualizarLatitud(String latitud) {
    _latitud.value = latitud;
    update();
  }

  void actualizarLongitud(String longitud) {
    _longitud.value = longitud;
    update();
  }

  void actualizarUsuario(String usuario) {
    _usuario.value = usuario;
    update();
  }

  void actualizarCedula(String cedula) {
    _cedula.value = cedula;
    update();
  }

  reportar({required String latitud, required String longitud}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      var nombre = prefs.getString('username') ?? '';
      var cedula = prefs.getString('cedula') ?? '';
      await DatabaseService(null).guardarDataReporte(
          motivo: _motivo.value,
          hora: DateTime.now().toString(),
          descripcion: _descripcion.value,
          latitud: latitud,
          longitud: longitud,
          usuario: nombre,
          cedula: cedula);
      return true;
    } catch (e) {
      return false;
    }
  }
}
