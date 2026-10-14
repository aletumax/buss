import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CotizaViajesApp());
}

class CotizaViajesApp extends StatefulWidget {
  const CotizaViajesApp({super.key});

  @override
  State<CotizaViajesApp> createState() => _CotizaViajesAppState();
}

class _CotizaViajesAppState extends State<CotizaViajesApp> {
  final Configuracion configuracion = Configuracion();
  final List<Map<String, dynamic>> historial = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    final configuracionGuardada = prefs.getString('configuracion');
    final historialGuardado = prefs.getString('historial');

    if (configuracionGuardada != null) {
      configuracion.fromJson(
        jsonDecode(configuracionGuardada) as Map<String, dynamic>,
      );
    }

    if (historialGuardado != null) {
      final datos = jsonDecode(historialGuardado) as List<dynamic>;

      historial.clear();

      historial.addAll(
        datos.map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
    }

    if (mounted) {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'configuracion',
      jsonEncode(configuracion.toJson()),
    );

    await prefs.setString(
      'historial',
      jsonEncode(historial),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CotizaViajes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0868B7),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: cargando
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : PaginaPrincipal(
              configuracion: configuracion,
              historial: historial,
              guardarDatos: guardarDatos,
            ),
    );
  }
}

// ======================================================
// CONFIGURACIÓN
// ======================================================

class Configuracion {
  double precioPorKm = 5.00;
  double pilotoPorDia = 200.00;
  double viaticosPorDia = 150.00;
  double hospedajePorNoche = 300.00;
  double desgastePorDia = 100.00;
  double descuentoPorDia = 200.00;
  double gananciaPorDia = 250.00;

  Map<String, dynamic> toJson() {
    return {
      'precioPorKm': precioPorKm,
      'pilotoPorDia': pilotoPorDia,
      'viaticosPorDia': viaticosPorDia,
      'hospedajePorNoche': hospedajePorNoche,
      'desgastePorDia': desgastePorDia,
      'descuentoPorDia': descuentoPorDia,
      'gananciaPorDia': gananciaPorDia,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    precioPorKm = (json['precioPorKm'] ?? 5.00).toDouble();
    pilotoPorDia = (json['pilotoPorDia'] ?? 200.00).toDouble();
    viaticosPorDia = (json['viaticosPorDia'] ?? 150.00).toDouble();

    hospedajePorNoche =
        (json['hospedajePorNoche'] ?? 300.00).toDouble();

    desgastePorDia =
        (json['desgastePorDia'] ?? 100.00).toDouble();

    descuentoPorDia =
        (json['descuentoPorDia'] ?? 200.00).toDouble();

    gananciaPorDia =
        (json['gananciaPorDia'] ?? 250.00).toDouble();
  }
}

// ======================================================
// PRINCIPAL
// ======================================================

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({
    super.key,
    required this.configuracion,
    required this.historial,
    required this.guardarDatos,
  });

  final Configuracion configuracion;
  final List<Map<String, dynamic>> historial;
  final Future<void> Function() guardarDatos;

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int paginaActual = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      NuevaCotizacion(
        configuracion: widget.configuracion,
        historial: widget.historial,
        guardarDatos: widget.guardarDatos,
      ),
      HistorialCotizaciones(
        historial: widget.historial,
      ),
      ConfiguracionPagina(
        configuracion: widget.configuracion,
        guardarDatos: widget.guardarDatos,
      ),
    ];

    const titulos = [
      'Buss San Antonio',
      'Historial',
      'Configuración',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[paginaActual]),
        centerTitle: true,
        backgroundColor: const Color(0xFF0868B7),
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: paginaActual,
        children: paginas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: paginaActual,
        onDestinationSelected: (index) {
          setState(() {
            paginaActual = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Cotizar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// NUEVA COTIZACIÓN
// ======================================================

class NuevaCotizacion extends StatefulWidget {
  const NuevaCotizacion({
    super.key,
    required this.configuracion,
    required this.historial,
    required this.guardarDatos,
  });

  final Configuracion configuracion;
  final List<Map<String, dynamic>> historial;
  final Future<void> Function() guardarDatos;

  @override
  State<NuevaCotizacion> createState() => _NuevaCotizacionState();
}

class _NuevaCotizacionState extends State<NuevaCotizacion> {
  final origenController = TextEditingController(
    text: 'Ciudad de Guatemala',
  );

  final destinoController = TextEditingController();
  final kilometrosController = TextEditingController();

  DateTime? fechaSalida;
  DateTime? fechaRegreso;

  bool idaYVuelta = true;

  String vehiculoSeleccionado = 'Microbús';

  final List<String> vehiculos = [
    'Microbús',
    'sedán',
    'Bus',
  ];

  int get cantidadDias {
    if (fechaSalida == null || fechaRegreso == null) {
      return 0;
    }

    return fechaRegreso!.difference(fechaSalida!).inDays + 1;
  }

  int get cantidadNoches {
    if (cantidadDias <= 1) {
      return 0;
    }

    return cantidadDias - 1;
  }

  @override
  void dispose() {
    origenController.dispose();
    destinoController.dispose();
    kilometrosController.dispose();

    super.dispose();
  }

  Future<void> seleccionarFechaSalida() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSalida ?? hoy,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de salida',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (fecha != null) {
      setState(() {
        fechaSalida = fecha;

        if (fechaRegreso != null &&
            fechaRegreso!.isBefore(fechaSalida!)) {
          fechaRegreso = null;
        }
      });
    }
  }

  Future<void> seleccionarFechaRegreso() async {
    if (fechaSalida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero selecciona la fecha de salida.',
          ),
        ),
      );

      return;
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaRegreso ?? fechaSalida!,
      firstDate: fechaSalida!,
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de regreso',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (fecha != null) {
      setState(() {
        fechaRegreso = fecha;
      });
    }
  }

  void calcularCotizacion() {
    final origen = origenController.text.trim();
    final destino = destinoController.text.trim();

    final kilometrosIda = double.tryParse(
      kilometrosController.text.replaceAll(',', '.'),
    );

    if (origen.isEmpty ||
        destino.isEmpty ||
        kilometrosIda == null ||
        kilometrosIda <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa origen, destino y kilómetros.',
          ),
        ),
      );

      return;
    }

    if (fechaSalida == null || fechaRegreso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona la fecha de salida y de regreso.',
          ),
        ),
      );

      return;
    }

    final dias = cantidadDias;
    final noches = cantidadNoches;

    final config = widget.configuracion;

    final kilometrosTotales =
        idaYVuelta ? kilometrosIda * 2 : kilometrosIda;

    final costoKilometros =
        kilometrosTotales * config.precioPorKm;

    final costoPiloto =
        config.pilotoPorDia * dias;

    final costoViaticos =
        config.viaticosPorDia * dias;

    final costoHospedaje =
        config.hospedajePorNoche * noches;

    final costoDesgaste =
        config.desgastePorDia * dias;

    final ganancia =
        config.gananciaPorDia * dias;

    final descuento = dias >= 2
        ? config.descuentoPorDia * dias
        : 0.00;

   final subtotal =
       costoKilometros +
       costoPiloto +
       costoViaticos +
       costoHospedaje +
       costoDesgaste +
       ganancia;

   final totalSinRedondear = subtotal - descuento;

   final total = redondearPrecio(totalSinRedondear);

   final numeroCotizacion =
       widget.historial.length + 1;

    final cotizacion = <String, dynamic>{
      'numero': numeroCotizacion,
      'origen': origen,
      'destino': destino,
      'fechaSalida': fechaSalida!.toIso8601String(),
      'fechaRegreso': fechaRegreso!.toIso8601String(),
      'kilometrosIda': kilometrosIda,
      'kilometrosTotales': kilometrosTotales,
      'dias': dias,
      'noches': noches,
      'idaYVuelta': idaYVuelta,
      'vehiculo': vehiculoSeleccionado,
      'precioPorKm': config.precioPorKm,
      'costoKilometros': costoKilometros,
      'piloto': costoPiloto,
      'viaticos': costoViaticos,
      'hospedaje': costoHospedaje,
      'desgaste': costoDesgaste,
      'ganancia': ganancia,
      'descuento': descuento,
      'subtotal': subtotal,
      'total': total,
      'fechaCreacion': DateTime.now().toIso8601String(),
    };

    widget.historial.insert(
      0,
      cotizacion,
    );

    widget.guardarDatos();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoCotizacion(
          cotizacion: cotizacion,
        ),
      ),
    );
  }

  Widget campoFecha({
    required String titulo,
    required DateTime? fecha,
    required VoidCallback onTap,
    required IconData icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: decoracionCampo(
            titulo,
            icono,
          ),
          child: Text(
            fecha == null
                ? 'Seleccionar fecha'
                : formatearFecha(fecha),
            style: TextStyle(
              color: fecha == null
                  ? Colors.grey.shade600
                  : Colors.black87,
              fontWeight: fecha == null
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Datos del viaje',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Selecciona las fechas y completa los datos del viaje.',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 22),

        campoTexto(
          titulo: 'Origen',
          controller: origenController,
          icono: Icons.trip_origin,
        ),

        campoTexto(
          titulo: 'Destino',
          controller: destinoController,
          icono: Icons.location_on_outlined,
        ),

        campoTexto(
          titulo: 'Kilómetros de ida',
          controller: kilometrosController,
          icono: Icons.route,
          numerico: true,
        ),

        const Text(
          'Tipo de viaje',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Solo ida',
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: !idaYVuelta,
                onSelected: (_) {
                  setState(() {
                    idaYVuelta = false;
                  });
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ChoiceChip(
                label: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Ida y vuelta',
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: idaYVuelta,
                onSelected: (_) {
                  setState(() {
                    idaYVuelta = true;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const Text(
          'Fechas del viaje',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        campoFecha(
          titulo: 'Fecha de salida',
          fecha: fechaSalida,
          onTap: seleccionarFechaSalida,
          icono: Icons.calendar_month,
        ),

        campoFecha(
          titulo: 'Fecha de regreso',
          fecha: fechaRegreso,
          onTap: seleccionarFechaRegreso,
          icono: Icons.event_available_outlined,
        ),

        if (cantidadDias > 0)
          Card(
            color: const Color(0xFFE7F2FF),
            margin: const EdgeInsets.only(
              bottom: 18,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF0868B7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Duración: $cantidadDias día(s) • '
                      '$cantidadNoches noche(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0868B7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        DropdownButtonFormField<String>(
          value: vehiculoSeleccionado,
          decoration: decoracionCampo(
            'Tipo de vehículo',
            Icons.directions_bus_outlined,
          ),
          items: vehiculos.map(
            (vehiculo) {
              return DropdownMenuItem<String>(
                value: vehiculo,
                child: Text(vehiculo),
              );
            },
          ).toList(),
          onChanged: (valor) {
            if (valor != null) {
              setState(() {
                vehiculoSeleccionado = valor;
              });
            }
          },
        ),

        const SizedBox(height: 28),

        SizedBox(
          height: 55,
          child: FilledButton.icon(
            onPressed: calcularCotizacion,
            icon: const Icon(
              Icons.calculate_outlined,
            ),
            label: const Text(
              'CALCULAR COTIZACIÓN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// RESULTADO Y COMPARTIR IMAGEN
// ======================================================

class ResultadoCotizacion extends StatefulWidget {
  const ResultadoCotizacion({
    super.key,
    required this.cotizacion,
  });

  final Map<String, dynamic> cotizacion;

  @override
  State<ResultadoCotizacion> createState() =>
      _ResultadoCotizacionState();
}

class _ResultadoCotizacionState
    extends State<ResultadoCotizacion> {

  final GlobalKey tarjetaKey = GlobalKey();

  bool compartiendo = false;

  Map<String, dynamic> get cotizacion =>
      widget.cotizacion;

  Future<void> compartirCotizacion() async {
    setState(() {
      compartiendo = true;
    });

    try {
      await Future.delayed(
        const Duration(milliseconds: 100),
      );

      final boundary = tarjetaKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final ui.Image imagen = await boundary.toImage(
        pixelRatio: 3.0,
      );

      final byteData = await imagen.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception(
          'No se pudo crear la imagen.',
        );
      }

      final bytes =
          byteData.buffer.asUint8List();

      final directorio =
          await getTemporaryDirectory();

      final numero =
          cotizacion['numero'].toString();

      final archivo = File(
        '${directorio.path}/cotizacion_$numero.png',
      );

      await archivo.writeAsBytes(bytes);

      await Share.shareXFiles(
        [
          XFile(
            archivo.path,
          ),
        ],
        text:
            'Cotización de viaje: '
            '${cotizacion['origen']} → '
            '${cotizacion['destino']} - '
            '${dinero(cotizacion['total'])}',
        subject: 'Cotización de viaje',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo compartir la cotización: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          compartiendo = false;
        });
      }
    }
  }

  Widget filaCosto(
    String nombre,
    num cantidad, {
    Color? color,
    bool negativo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(nombre),
          ),
          Text(
            negativo
                ? '-${dinero(cantidad)}'
                : dinero(cantidad),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget tarjetaCompartible() {
    final salida = DateTime.parse(
      cotizacion['fechaSalida'],
    );

    final regreso = DateTime.parse(
      cotizacion['fechaRegreso'],
    );

    return RepaintBoundary(
      key: tarjetaKey,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Color(0xFF0868B7),
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                  ),
                ),

                SizedBox(width: 14),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CotizaViajes',
                      style: TextStyle(
                        color: Color(0xFF0868B7),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cotización de viaje',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FD),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RUTA',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.trip_origin,
                        color: Color(0xFF0868B7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cotizacion['origen'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.only(
                      left: 11,
                    ),
                    child: SizedBox(
                      height: 25,
                      child: VerticalDivider(
                        color: Color(0xFF0868B7),
                        thickness: 2,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cotizacion['destino'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: _datoTarjeta(
                    'SALIDA',
                    formatearFecha(salida),
                    Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoTarjeta(
                    'REGRESO',
                    formatearFecha(regreso),
                    Icons.event_available_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _datoTarjeta(
                    'DURACIÓN',
                    '${cotizacion['dias']} día(s)',
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoTarjeta(
                    'VEHÍCULO',
                    cotizacion['vehiculo'],
                    Icons.directions_bus_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0868B7),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL DE LA COTIZACIÓN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    dinero(
                      cotizacion['total'],
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                'Cotización #${cotizacion['numero'].toString().padLeft(4, '0')}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoTarjeta(
    String titulo,
    String valor,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0E5EB),
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 20,
            color: const Color(0xFF0868B7),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salida =
        DateTime.parse(cotizacion['fechaSalida']);

    final regreso =
        DateTime.parse(cotizacion['fechaRegreso']);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resultado',
        ),
        backgroundColor:
            const Color(0xFF0868B7),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cotización #${cotizacion['numero'].toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      color: Color(0xFF0868B7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${cotizacion['origen']} → ${cotizacion['destino']}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Salida: ${formatearFecha(salida)}',
                  ),

                  Text(
                    'Regreso: ${formatearFecha(regreso)}',
                  ),

                  Text(
                    'Duración: ${cotizacion['dias']} día(s)',
                  ),

                  Text(
                    'Noches: ${cotizacion['noches']}',
                  ),

                  Text(
                    'Vehículo: ${cotizacion['vehiculo']}',
                  ),

                  Text(
                    'Kilómetros totales: '
                    '${numero(cotizacion['kilometrosTotales'])} km',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Desglose',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  filaCosto(
                    'Costo por kilómetros',
                    cotizacion['costoKilometros'],
                  ),
                  filaCosto(
                    'Piloto',
                    cotizacion['piloto'],
                  ),
                  filaCosto(
                    'Viáticos',
                    cotizacion['viaticos'],
                  ),
                  filaCosto(
                    'Hospedaje',
                    cotizacion['hospedaje'],
                  ),
                  filaCosto(
                    'Desgaste del vehículo',
                    cotizacion['desgaste'],
                  ),
                  filaCosto(
                    'Ganancia',
                    cotizacion['ganancia'],
                    color: Colors.green,
                  ),

                  const Divider(),

                  filaCosto(
                    'Subtotal',
                    cotizacion['subtotal'],
                  ),

                  if ((cotizacion['descuento']
                          as num) >
                      0)
                    filaCosto(
                      'Descuento por días',
                      cotizacion['descuento'],
                      color: Colors.red,
                      negativo: true,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            color: const Color(0xFFE7F2FF),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dinero(cotizacion['total']),
                    style: const TextStyle(
                      color: Color(0xFF0868B7),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Vista para compartir',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            clipBehavior: Clip.antiAlias,
            child: tarjetaCompartible(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed:
                  compartiendo
                      ? null
                      : compartirCotizacion,
              icon: compartiendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.share_outlined,
                    ),
              label: Text(
                compartiendo
                    ? 'GENERANDO IMAGEN...'
                    : 'COMPARTIR COTIZACIÓN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ======================================================
// HISTORIAL
// ======================================================

class HistorialCotizaciones extends StatefulWidget {
  const HistorialCotizaciones({
    super.key,
    required this.historial,
  });

  final List<Map<String, dynamic>> historial;

  @override
  State<HistorialCotizaciones> createState() =>
      _HistorialCotizacionesState();
}

class _HistorialCotizacionesState
    extends State<HistorialCotizaciones> {

  String busqueda = '';

  @override
  Widget build(BuildContext context) {

    final resultados =
        widget.historial.where(
      (cotizacion) {
        final texto =
            '${cotizacion['numero']} '
            '${cotizacion['origen']} '
            '${cotizacion['destino']} '
            '${cotizacion['vehiculo']}';

        return texto
            .toLowerCase()
            .contains(
              busqueda.toLowerCase(),
            );
      },
    ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (valor) {
              setState(() {
                busqueda = valor;
              });
            },
            decoration: decoracionCampo(
              'Buscar cotización',
              Icons.search,
            ),
          ),
        ),

        Expanded(
          child: resultados.isEmpty
              ? const Center(
                  child: Text(
                    'No hay cotizaciones guardadas.',
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  itemCount:
                      resultados.length,
                  itemBuilder:
                      (context, index) {

                    final cotizacion =
                        resultados[index];

                    final tieneFechas =
                        cotizacion['fechaSalida'] != null &&
                        cotizacion['fechaRegreso'] != null;

                    String fechas = '';

                    if (tieneFechas) {
                      fechas =
                          '${formatearFecha(DateTime.parse(cotizacion['fechaSalida']))} '
                          '→ '
                          '${formatearFecha(DateTime.parse(cotizacion['fechaRegreso']))}';
                    }

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.route,
                          ),
                        ),

                        title: Text(
                          '#${cotizacion['numero'].toString().padLeft(4, '0')} '
                          '${cotizacion['origen']} → '
                          '${cotizacion['destino']}',
                        ),

                        subtitle: Text(
                          tieneFechas
                              ? '$fechas\n'
                                  '${cotizacion['dias']} día(s) • '
                                  '${cotizacion['vehiculo']}'
                              : '${cotizacion['dias']} día(s) • '
                                  '${cotizacion['vehiculo']}',
                        ),

                        isThreeLine:
                            tieneFechas,

                        trailing: Text(
                          dinero(
                            cotizacion['total'],
                          ),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        onTap: tieneFechas
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) {
                                      return ResultadoCotizacion(
                                        cotizacion:
                                            cotizacion,
                                      );
                                    },
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ======================================================
// CONFIGURACIÓN
// ======================================================

class ConfiguracionPagina extends StatefulWidget {
  const ConfiguracionPagina({
    super.key,
    required this.configuracion,
    required this.guardarDatos,
  });

  final Configuracion configuracion;
  final Future<void> Function() guardarDatos;

  @override
  State<ConfiguracionPagina> createState() =>
      _ConfiguracionPaginaState();
}

class _ConfiguracionPaginaState
    extends State<ConfiguracionPagina> {

  late TextEditingController precioPorKm;
  late TextEditingController piloto;
  late TextEditingController viaticos;
  late TextEditingController hospedaje;
  late TextEditingController desgaste;
  late TextEditingController descuento;
  late TextEditingController ganancia;

  @override
  void initState() {
    super.initState();

    final config =
        widget.configuracion;

    precioPorKm =
        controladorNumero(config.precioPorKm);

    piloto =
        controladorNumero(config.pilotoPorDia);

    viaticos =
        controladorNumero(config.viaticosPorDia);

    hospedaje =
        controladorNumero(
      config.hospedajePorNoche,
    );

    desgaste =
        controladorNumero(
      config.desgastePorDia,
    );

    descuento =
        controladorNumero(
      config.descuentoPorDia,
    );

    ganancia =
        controladorNumero(
      config.gananciaPorDia,
    );
  }

  @override
  void dispose() {
    precioPorKm.dispose();
    piloto.dispose();
    viaticos.dispose();
    hospedaje.dispose();
    desgaste.dispose();
    descuento.dispose();
    ganancia.dispose();

    super.dispose();
  }

  double obtenerNumero(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.replaceAll(',', '.'),
        ) ??
        0;
  }

  Future<void> guardarConfiguracion() async {
    final nuevoPrecioKm =
        obtenerNumero(precioPorKm);

    if (nuevoPrecioKm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El precio por kilómetro debe ser mayor que cero.',
          ),
        ),
      );

      return;
    }

    final config =
        widget.configuracion;

    config.precioPorKm =
        nuevoPrecioKm;

    config.pilotoPorDia =
        obtenerNumero(piloto);

    config.viaticosPorDia =
        obtenerNumero(viaticos);

    config.hospedajePorNoche =
        obtenerNumero(hospedaje);

    config.desgastePorDia =
        obtenerNumero(desgaste);

    config.descuentoPorDia =
        obtenerNumero(descuento);

    config.gananciaPorDia =
        obtenerNumero(ganancia);

    await widget.guardarDatos();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Configuración guardada correctamente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Precios y tarifas',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Configura los valores utilizados en las cotizaciones.',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 22),

        campoTexto(
          titulo: 'Precio por kilómetro (Q)',
          controller: precioPorKm,
          icono: Icons.route,
          numerico: true,
        ),

        campoTexto(
          titulo: 'Piloto por día (Q)',
          controller: piloto,
          icono: Icons.person_outline,
          numerico: true,
        ),

        campoTexto(
          titulo: 'Viáticos por día (Q)',
          controller: viaticos,
          icono: Icons.restaurant_outlined,
          numerico: true,
        ),

        campoTexto(
          titulo: 'Hospedaje por noche (Q)',
          controller: hospedaje,
          icono: Icons.hotel_outlined,
          numerico: true,
        ),

        campoTexto(
          titulo:
              'Desgaste del vehículo por día (Q)',
          controller: desgaste,
          icono: Icons.car_repair_outlined,
          numerico: true,
        ),

        campoTexto(
          titulo:
              'Descuento por día desde 2 días (Q)',
          controller: descuento,
          icono: Icons.discount_outlined,
          numerico: true,
        ),

        campoTexto(
          titulo: 'Ganancia por día (Q)',
          controller: ganancia,
          icono: Icons.trending_up,
          numerico: true,
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 55,
          child: FilledButton.icon(
            onPressed:
                guardarConfiguracion,
            icon:
                const Icon(
              Icons.save_outlined,
            ),
            label:
                const Text(
              'GUARDAR CONFIGURACIÓN',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// UTILIDADES
// ======================================================

TextEditingController controladorNumero(
  double valor,
) {
  return TextEditingController(
    text: valor.toStringAsFixed(2),
  );
}

InputDecoration decoracionCampo(
  String titulo,
  IconData icono,
) {
  return InputDecoration(
    labelText: titulo,
    prefixIcon: Icon(icono),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(12),
    ),
  );
}

Widget campoTexto({
  required String titulo,
  required TextEditingController controller,
  required IconData icono,
  bool numerico = false,
}) {
  return Padding(
    padding:
        const EdgeInsets.only(
      bottom: 16,
    ),
    child: TextField(
      controller: controller,
      keyboardType: numerico
          ? const TextInputType.numberWithOptions(
              decimal: true,
            )
          : TextInputType.text,
      decoration: decoracionCampo(
        titulo,
        icono,
      ),
    ),
  );
}

String formatearFecha(
  DateTime fecha,
) {
  final dia =
      fecha.day.toString().padLeft(2, '0');

  final mes =
      fecha.month.toString().padLeft(2, '0');

  final anio =
      fecha.year.toString();

  return '$dia/$mes/$anio';
}

String dinero(
  num valor,
) {
  return 'Q ${valor.toDouble().toStringAsFixed(2)}';
}

String numero(
  dynamic valor,
) {
  final valorNumero =
      (valor as num).toDouble();

  if (valorNumero ==
      valorNumero.roundToDouble()) {
    return valorNumero
        .toInt()
        .toString();
  }

  return valorNumero.toStringAsFixed(2);
}

double redondearPrecio(double precio) {
  return (precio / 50).ceil() * 50.0;
}
