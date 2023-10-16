import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DatabaseService {
  final String? reporteId;

  DatabaseService(this.reporteId);

  final CollectionReference reportesCollection =
      FirebaseFirestore.instance.collection("reportes");

//guardar datos usuario
  Future guardarDataReporte(
      {
      required String motivo,
      required String hora,
      required String descripcion,
      required String latitud,
      required String longitud,
      required String usuario,
      required String cedula,
      }) async {
         final report = FirebaseFirestore.instance.collection("reportes").doc();
        
    return await reportesCollection.doc(reporteId).set({
      "motivo": motivo,
      "hora": hora,
      "descripcion": descripcion,
      "latitud": latitud,
      "longitud": longitud,
      "usuario": usuario,
      "cedula": cedula,
      "reporteId": report!.id,
    });
  }

//traer datos del usuario
  Future getDataReportesUsuario(String cedula) async {
    QuerySnapshot dataUsuario =
        await reportesCollection.where("cedula", isEqualTo: cedula).get();
    return dataUsuario;
  }

//traer sesiones del usuario
  getSesionesUsuario() async {
    return reportesCollection.doc(reporteId).snapshots();
  }










 




}
