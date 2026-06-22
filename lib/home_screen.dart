import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter/services.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'theme.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

// شاشة التطبيق الرئيسية:
// تعرض الخريطة، موقع المستخدم الحالي، وأدوات حفظ/نسخ الإحداثيات.

// ══════════════════════════════════════════════
//  موديل الموقع المحفوظ
// ══════════════════════════════════════════════
class SavedLocation {
  final String id;
  String name;
  final double lat;
  final double lng;
  final DateTime savedAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    id: json['id'],
    name: json['name'],
    lat: json['lat'],
    lng: json['lng'],
    savedAt: DateTime.parse(json['savedAt']),
  );

  String get coordsString =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}

enum BottomPanelMode { defaultActions, selectedLocation, routePreview, routing }

class _RouteOption {
  final String id;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final Color color;

  const _RouteOption({
    required this.id,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.color,
  });
}

class _MapTileStyle {
  final String cacheKey;
  final String urlTemplate;
  final List<String> subdomains;
  final String attribution;

  const _MapTileStyle({
    required this.cacheKey,
    required this.urlTemplate,
    required this.subdomains,
    required this.attribution,
  });
}

const _osmLightTileStyle = _MapTileStyle(
  cacheKey: 'osm_light',
  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  subdomains: ['a', 'b', 'c'],
  attribution: '© OpenStreetMap contributors',
);

const _cartoDarkMatterTileStyle = _MapTileStyle(
  cacheKey: 'carto_dark_matter',
  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
  subdomains: ['a', 'b', 'c', 'd'],
  attribution: '© OpenStreetMap contributors & CARTO',
);

// ══════════════════════════════════════════════
//  Home Screen
// ══════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ThemeMode currentTheme;
  final String currentLanguage;

  const HomeScreen({
    super.key,
    required this.prefs,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentTheme,
    required this.currentLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── الخريطة ───────────────────────────────
  final MapController _mapController = MapController();
  late final AnimationController _mapCameraAnimationController;
  late final Future<CacheStore> _tileCacheStore;
  int _mapAnimationId = 0;
  bool _mapReady = false;
  LatLng? _pendingCameraTarget;
  double? _pendingCameraZoom;
  LatLng? _currentLocation;
  bool _isLocating = false;

  // ── Bottom Sheet ──────────────────────────
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _sheetExpanded = false;

  // ── المحفوظات ─────────────────────────────
  List<SavedLocation> _savedLocations = [];

  // ── نوع الخريطة ───────────────────────────
  String _mapType = 'auto'; // auto, normal, dark

  // ── الاتصال بالإنترنت ─────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  // ── وضع الشريط السفلي ─────────────────────
  BottomPanelMode _panelMode = BottomPanelMode.defaultActions;
  SavedLocation? _selectedLocation;
  bool _isRouteLoading = false;
  List<_RouteOption> _routeOptions = [];
  int _selectedRouteIndex = 0;
  StreamSubscription<Position>? _positionSub;
  double? _remainingDistanceMeters;

  @override
  void initState() {
    super.initState();
    _mapCameraAnimationController = AnimationController(vsync: this);
    _tileCacheStore = _createTileCacheStore();
    _mapType = widget.prefs.getString('map_type') ?? 'auto';
    _loadSavedLocations();
    _setupConnectivityMonitoring();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _positionSub?.cancel();
    _mapAnimationId++;
    _mapCameraAnimationController.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  static Future<CacheStore> _createTileCacheStore() async {
    final cachePath = kIsWeb
        ? null
        : '${(await getTemporaryDirectory()).path}/raqib_map_tiles';
    return HiveCacheStore(
      cachePath,
      hiveBoxName: 'RaqibMapTiles',
    );
  }

  // ── تحميل المواقع ─────────────────────────
  void _loadSavedLocations() {
    final raw = widget.prefs.getString('saved_locations') ?? '[]';
    final List decoded = jsonDecode(raw);
    setState(() {
      _savedLocations = decoded.map((e) => SavedLocation.fromJson(e)).toList();
    });
  }

  void _saveToDisk() {
    final encoded = jsonEncode(_savedLocations.map((e) => e.toJson()).toList());
    widget.prefs.setString('saved_locations', encoded);
  }

  // ── الأذونات والموقع ──────────────────────
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLocating) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDialog();
      return;
    }

    final s = S(widget.currentLanguage == 'ar');
    setState(() => _isLocating = true);
    _showSnackbar(s.locating, type: SnackType.warning);

    unawaited(_showLastKnownLocationIfAvailable());

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLocation = loc;
        _isLocating = false;
      });
      _moveMapTo(loc, zoom: 16);
      _showSnackbar(s.locationFound, type: SnackType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      if (_currentLocation != null) {
        _moveMapTo(_currentLocation!, zoom: 16);
        _showSnackbar(s.locationFound, type: SnackType.success);
      } else {
        _showSnackbar(s.locationFailed, type: SnackType.error);
      }
    }
  }

  Future<void> _showLastKnownLocationIfAvailable() async {
    try {
      final cachedPos = await Geolocator.getLastKnownPosition();
      if (cachedPos == null || !mounted) return;
      final cachedLoc = LatLng(cachedPos.latitude, cachedPos.longitude);
      setState(() => _currentLocation = cachedLoc);
      _moveMapTo(cachedLoc, zoom: 16);
    } catch (_) {
      // آخر موقع معروف مجرد تحسين للسرعة؛ فشله لا يجب أن يكسر GPS الحالي.
    }
  }

  // ── حفظ الموقع ────────────────────────────
  void _showSaveDialog() {
    final s = S(widget.currentLanguage == 'ar');
    final isAr = widget.currentLanguage == 'ar';
    if (_currentLocation == null) {
      _showSnackbar(s.locateFirst, type: SnackType.error);
      return;
    }
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.add_location_alt_rounded),
        title: Text(s.saveLocation),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: s.locationName,
            hintText: s.locationHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.label_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final loc = SavedLocation(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                lat: _currentLocation!.latitude,
                lng: _currentLocation!.longitude,
                savedAt: DateTime.now(),
              );
              setState(() => _savedLocations.add(loc));
              _saveToDisk();
              Navigator.pop(ctx);
              _showSnackbar(s.locationSaved, type: SnackType.success);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  // ── نسخ الإحداثيات ────────────────────────
  void _copyCoords() {
    final s = S(widget.currentLanguage == 'ar');
    if (_currentLocation == null) {
      _showSnackbar(s.noCoordsMsg, type: SnackType.error);
      return;
    }
    Clipboard.setData(
      ClipboardData(
        text:
            '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
      ),
    );
    _showSnackbar(s.coordsCopied, type: SnackType.success);
  }

  void _showGpsDialog() {
    final s = S(widget.currentLanguage == 'ar');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.location_off_rounded, size: 48),
        title: Text(s.gpsOff),
        content: Text(s.gpsOffMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: Text(s.enableGps),
          ),
        ],
      ),
    );
  }

  Future<void> _setupConnectivityMonitoring() async {
    final initial = await Connectivity().checkConnectivity();
    _isOnline = !initial.contains(ConnectivityResult.none);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final onlineNow = !results.contains(ConnectivityResult.none);
      if (onlineNow == _isOnline) return;
      setState(() => _isOnline = onlineNow);
    });
  }

  void _openSavedLocationOnMap(SavedLocation location) {
    final target = LatLng(location.lat, location.lng);
    setState(() {
      _selectedLocation = location;
      _panelMode = BottomPanelMode.selectedLocation;
      _routeOptions = [];
      _selectedRouteIndex = 0;
      _remainingDistanceMeters = null;
      _positionSub?.cancel();
      _positionSub = null;
    });
    _moveMapTo(target, zoom: 16);
  }

  void _moveMapTo(LatLng target, {double zoom = 15}) {
    _pendingCameraTarget = target;
    _pendingCameraZoom = zoom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _pendingCameraTarget = null;
      _pendingCameraZoom = null;
      _animateMapCamera(target: target, zoom: zoom);
    });
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      final fit = CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(48, 96, 48, 220),
        maxZoom: 17,
      ).fit(_mapController.camera);
      _animateMapCamera(target: fit.center, zoom: fit.zoom);
    });
  }

  void _animateMapCamera({
    required LatLng target,
    required double zoom,
    Duration duration = const Duration(milliseconds: 650),
  }) {
    if (!_mapReady) {
      _pendingCameraTarget = target;
      _pendingCameraZoom = zoom;
      return;
    }
    final animationId = ++_mapAnimationId;
    final camera = _mapController.camera;
    final start = camera.center;
    final startZoom = camera.zoom;

    _mapCameraAnimationController
      ..stop()
      ..duration = duration
      ..reset();

    void listener() {
      if (animationId != _mapAnimationId) return;
      final t = Curves.easeInOutCubic.transform(
        _mapCameraAnimationController.value,
      );
      _mapController.move(
        LatLng(
          start.latitude + ((target.latitude - start.latitude) * t),
          start.longitude + ((target.longitude - start.longitude) * t),
        ),
        startZoom + ((zoom - startZoom) * t),
      );
    }

    _mapCameraAnimationController.addListener(listener);
    _mapCameraAnimationController.forward().whenCompleteOrCancel(() {
      _mapCameraAnimationController.removeListener(listener);
      if (mounted && animationId == _mapAnimationId) {
        _mapController.move(target, zoom);
      }
    });
  }

  Future<void> _loadRouteOptions() async {
    final s = S(widget.currentLanguage == 'ar');
    if (_selectedLocation == null) {
      _showSnackbar(s.pickLocationFirst, type: SnackType.error);
      return;
    }
    if (!_isOnline) {
      _showSnackbar(s.routeNeedsInternet, type: SnackType.error);
      return;
    }
    if (_currentLocation == null) {
      await _getCurrentLocation();
      if (_currentLocation == null) return;
    }

    setState(() => _isRouteLoading = true);
    final options = await _fetchRoadRouteOptions(
      start: _currentLocation!,
      end: LatLng(_selectedLocation!.lat, _selectedLocation!.lng),
    );
    if (!mounted) return;
    setState(() => _isRouteLoading = false);

    if (options.isEmpty) {
      _showSnackbar(s.routeFailed, type: SnackType.error);
      return;
    }

    setState(() {
      _routeOptions = options;
      _selectedRouteIndex = 0;
      _panelMode = BottomPanelMode.routePreview;
    });
    _fitMapToPoints(options[_selectedRouteIndex].points);
    if (options.length == 1) {
      _showSnackbar(s.routeSingleOnly, type: SnackType.warning);
    }
  }

  Future<void> _startRoutingToSelected() async {
    final s = S(widget.currentLanguage == 'ar');
    if (_routeOptions.isEmpty) {
      await _loadRouteOptions();
      if (_routeOptions.isEmpty) return;
    }
    _positionSub?.cancel();
    final selected = _routeOptions[_selectedRouteIndex];
    setState(() {
      _panelMode = BottomPanelMode.routing;
      _remainingDistanceMeters = _computeRemainingMeters(
        _currentLocation!,
        selected.points,
      );
    });
    _showSnackbar(s.routeStarted, type: SnackType.success);
    _startPositionTracking();
  }

  void _startPositionTracking() {
    final s = S(widget.currentLanguage == 'ar');
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final current = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentLocation = current;
        if (_routeOptions.isNotEmpty) {
          final points = _routeOptions[_selectedRouteIndex].points;
          _remainingDistanceMeters = _computeRemainingMeters(
            current,
            points,
          );
        }
      });
      if (_panelMode == BottomPanelMode.routing) {
        _moveMapTo(current, zoom: 17);
      }
      if (_remainingDistanceMeters != null && _remainingDistanceMeters! < 30) {
        _showSnackbar(s.arrived, type: SnackType.success);
        _cancelRouting(showNotice: false);
      }
    });
  }

  void _cancelRouting({bool showNotice = true}) {
    _positionSub?.cancel();
    _positionSub = null;
    if (mounted) {
      setState(() {
        _routeOptions = [];
        _remainingDistanceMeters = null;
        _panelMode = _selectedLocation != null
            ? BottomPanelMode.selectedLocation
            : BottomPanelMode.defaultActions;
      });
    }
    if (showNotice) {
      _showSnackbar(
        S(widget.currentLanguage == 'ar').routeCancelled,
        type: SnackType.warning,
      );
    }
  }

  Future<List<_RouteOption>> _fetchRoadRouteOptions({
    required LatLng start,
    required LatLng end,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson&alternatives=true',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) return [];
      const palette = [Color(0xff0078D4), Color(0xff34A853), Color(0xffF9A825)];
      final out = <_RouteOption>[];
      for (var i = 0; i < routes.length; i++) {
        final route = routes[i] as Map<String, dynamic>;
        final geometry = route['geometry'] as Map<String, dynamic>?;
        final coordinates = geometry?['coordinates'] as List<dynamic>? ?? [];
        final points = coordinates
            .map((e) => LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()))
            .toList();
        if (points.length < 2) continue;
        out.add(
          _RouteOption(
            id: 'r$i',
            points: points,
            distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
            color: palette[i % palette.length],
          ),
        );
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  double _computeRemainingMeters(LatLng current, List<LatLng> points) {
    if (points.length < 2) return 0;
    final distance = const Distance();
    final nearestIndex = _findNearestPointIndex(current, points);
    var meters = distance(current, points[nearestIndex]);
    for (var i = nearestIndex; i < points.length - 1; i++) {
      meters += distance(points[i], points[i + 1]);
    }
    return meters;
  }

  int _findNearestPointIndex(LatLng current, List<LatLng> points) {
    final distance = const Distance();
    var best = 0;
    var bestValue = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final d = distance(current, points[i]);
      if (d < bestValue) {
        bestValue = d;
        best = i;
      }
    }
    return best;
  }

  // ── Snackbar ──────────────────────────────
  void _showSnackbar(String msg, {required SnackType type}) {
    final colors = switch (type) {
      SnackType.success => (
        RaqibColors.successGreen,
        RaqibColors.successGreenLight,
      ),
      SnackType.warning => (
        RaqibColors.warningYellow,
        RaqibColors.warningYellowLight,
      ),
      SnackType.error => (RaqibColors.errorRed, RaqibColors.errorRedLight),
    };
    final icon = switch (type) {
      SnackType.success => Icons.check_circle_rounded,
      SnackType.warning => Icons.info_rounded,
      SnackType.error => Icons.error_rounded,
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    // نحسب ارتفاع الـ Bottom Sheet الحالي لنضع الـ Snackbar فوقه
    final sheetHeight =
        MediaQuery.of(context).size.height * (_sheetExpanded ? 0.38 : 0.13);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.$2,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, sheetHeight + 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: colors.$1, size: 20),
            const SizedBox(width: 8),
            Text(
              msg,
              style: TextStyle(color: colors.$1, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── الانتقال للمحفوظات ────────────────────
  void _goToSaved() {
    Navigator.push(
      context,
      _slideRoute(
        SavedScreen(
          savedLocations: _savedLocations,
          currentLanguage: widget.currentLanguage,
          onUpdate: (updated) {
            setState(() => _savedLocations = updated);
            _saveToDisk();
          },
          onShowOnMap: _openSavedLocationOnMap,
        ),
      ),
    );
  }

  // ── الانتقال للإعدادات ────────────────────
  void _goToSettings() {
    Navigator.push(
      context,
      _slideRoute(
        SettingsScreen(
          prefs: widget.prefs,
          currentTheme: widget.currentTheme,
          currentLanguage: widget.currentLanguage,
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
          onMapTypeChanged: (t) {
            setState(() => _mapType = t);
            widget.prefs.setString('map_type', t);
          },
          currentMapType: _mapType,
        ),
      ),
    );
  }

  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: anim.drive(tween), child: child);
      },
    );
  }

  Widget _buildBottomPanelContent(BuildContext context) {
    final s = S(widget.currentLanguage == 'ar');
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLocating || _isRouteLoading) {
      return _BottomShimmer(
        label: _isRouteLoading ? s.loadingRoute : s.loadingLocation,
      );
    }

    if (_panelMode == BottomPanelMode.routing) {
      final guidance = _buildLiveGuidance();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.directions_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.remainingDistance}: ${_formatDistance(_remainingDistanceMeters)} • ${s.estimatedTime}: ${_formatDuration(_routeOptions[_selectedRouteIndex].durationSeconds)}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _cancelRouting,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: s.cancelRoute,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${s.nextDirection}: $guidance',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            if (_sheetExpanded) ...[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),
              _buildRoutingExpandedPanel(s),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _panelMode == BottomPanelMode.selectedLocation &&
                              _selectedLocation != null
                          ? _selectedLocation!.name
                          : s.currentLocation,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      _panelMode == BottomPanelMode.selectedLocation &&
                              _selectedLocation != null
                          ? _selectedLocation!.coordsString
                          : _currentLocation != null
                              ? '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}'
                              : s.noLocation,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _sheetExpanded ? 1 : 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          builder: (context, factor, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: factor,
                child: IgnorePointer(
                  ignoring: factor < 0.99,
                  child: Opacity(opacity: factor, child: child),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildActionButtonsByMode(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsByMode(S s) {
    if (_panelMode == BottomPanelMode.selectedLocation) {
      return Row(
        children: [
          _ActionButton(
            icon: Icons.copy_rounded,
            label: s.copyBtn,
            onTap: () {
              if (_selectedLocation == null) return;
              Clipboard.setData(ClipboardData(text: _selectedLocation!.coordsString));
              _showSnackbar(s.coordsCopied, type: SnackType.success);
            },
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.alt_route_rounded,
            label: s.routeToPlace,
            onTap: _loadRouteOptions,
            primary: true,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.keyboard_backspace_rounded,
            label: s.back,
            onTap: () {
              setState(() {
                _selectedLocation = null;
                _routeOptions = [];
                _panelMode = BottomPanelMode.defaultActions;
              });
            },
          ),
        ],
      );
    }

    if (_panelMode == BottomPanelMode.routePreview) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.chooseRoute,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...List.generate(_routeOptions.length, (index) {
            final route = _routeOptions[index];
            final selected = index == _selectedRouteIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedRouteIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? route.color : route.color.withOpacity(0.4),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route_rounded, color: route.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_routeTitle(s, index)} • ${_formatDistance(route.distanceMeters)} • ${_formatDuration(route.durationSeconds)}',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              _ActionButton(
                icon: Icons.navigation_rounded,
                label: s.startNavigation,
                onTap: _startRoutingToSelected,
                primary: true,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _ActionButton(icon: Icons.settings_rounded, label: s.settingsBtn, onTap: _goToSettings),
        const SizedBox(width: 8),
        _ActionButton(icon: Icons.bookmark_rounded, label: s.savedBtn, onTap: _goToSaved),
        const SizedBox(width: 8),
        _ActionButton(icon: Icons.copy_rounded, label: s.copyBtn, onTap: _copyCoords),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.save_rounded,
          label: s.saveBtn,
          onTap: _showSaveDialog,
          primary: true,
        ),
      ],
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  String _routeTitle(S s, int index) {
    if (index == 0) return s.routeOptionFast;
    return '${s.routeOptionAlt} ${index + 1}';
  }

  String _buildLiveGuidance() {
    if (_routeOptions.isEmpty || _currentLocation == null) return '--';
    final points = _routeOptions[_selectedRouteIndex].points;
    if (points.length < 2) return '--';
    final nearest = _findNearestPointIndex(_currentLocation!, points);
    final next = points[(nearest + 1).clamp(0, points.length - 1)];
    final bearing = _bearingBetween(_currentLocation!, next);
    if (bearing >= 315 || bearing < 45) return 'اتجه شمالاً';
    if (bearing < 135) return 'اتجه شرقاً';
    if (bearing < 225) return 'اتجه جنوباً';
    return 'اتجه غرباً';
  }

  Widget _buildRoutingExpandedPanel(S s) {
    final selectedRoute = _routeOptions[_selectedRouteIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.chooseRoute,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(_routeOptions.length, (index) {
          final route = _routeOptions[index];
          final selected = index == _selectedRouteIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedRouteIndex = index;
                  if (_currentLocation != null) {
                    _remainingDistanceMeters = _computeRemainingMeters(
                      _currentLocation!,
                      _routeOptions[_selectedRouteIndex].points,
                    );
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? route.color : route.color.withOpacity(0.4),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route_rounded, color: route.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_routeTitle(s, index)} • ${_formatDistance(route.distanceMeters)} • ${_formatDuration(route.durationSeconds)}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.estimatedTime}: ${_formatDuration(selectedRoute.durationSeconds)}',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
              Text(
                '${s.remainingDistance}: ${_formatDistance(_remainingDistanceMeters)}',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 6),
              Text(
                '${s.nextDirection}: ${_buildLiveGuidance()}',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_routeOptions.isEmpty) return;
                  final nextIndex = (_selectedRouteIndex + 1) % _routeOptions.length;
                  setState(() {
                    _selectedRouteIndex = nextIndex;
                    if (_currentLocation != null) {
                      _remainingDistanceMeters = _computeRemainingMeters(
                        _currentLocation!,
                        _routeOptions[_selectedRouteIndex].points,
                      );
                    }
                  });
                },
                icon: const Icon(Icons.compare_arrows_rounded),
                label: Text(s.chooseRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s.tapRouteHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Cairo',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _ActionButton(
              icon: Icons.close_rounded,
              label: s.cancelRoute,
              onTap: _cancelRouting,
              primary: true,
            ),
          ],
        ),
      ],
    );
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * (3.141592653589793 / 180);
    final lat2 = to.latitude * (3.141592653589793 / 180);
    final dLon = (to.longitude - from.longitude) * (3.141592653589793 / 180);
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x) * (180 / 3.141592653589793);
    return (brng + 360) % 360;
  }

  bool _useDarkMap(BuildContext context) {
    if (_mapType == 'dark') return true;
    if (_mapType == 'normal') return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  _MapTileStyle _activeTileStyle(BuildContext context) {
    return _useDarkMap(context)
        ? _cartoDarkMatterTileStyle
        : _osmLightTileStyle;
  }

  String _mapAttribution(BuildContext context) {
    return _activeTileStyle(context).attribution;
  }

  Widget _buildCachedTileLayer(_MapTileStyle tileStyle) {
    return FutureBuilder<CacheStore>(
      future: _tileCacheStore,
      builder: (context, snapshot) {
        final cacheStore = snapshot.data;
        return TileLayer(
          key: ValueKey(tileStyle.cacheKey),
          urlTemplate: tileStyle.urlTemplate,
          subdomains: tileStyle.subdomains,
          userAgentPackageName: 'com.raqib.myapp',
          maxNativeZoom: 19,
          maxZoom: 19,
          tileProvider: cacheStore == null
              ? null
              : CachedTileProvider(
                  store: cacheStore,
                  maxStale: const Duration(days: 30),
                ),
        );
      },
    );
  }

  LatLng get _initialMapCenter =>
      _currentLocation ?? const LatLng(35.7065, -0.6292);

  Widget _buildMap(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileStyle = _activeTileStyle(context);
    final selectedPoint = _selectedLocation == null
        ? null
        : LatLng(_selectedLocation!.lat, _selectedLocation!.lng);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialMapCenter,
        initialZoom: _currentLocation == null ? 13 : 16,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;
          final pendingTarget = _pendingCameraTarget ?? _currentLocation;
          final pendingZoom = _pendingCameraZoom ?? 16;
          if (pendingTarget != null) {
            _pendingCameraTarget = null;
            _pendingCameraZoom = null;
            _animateMapCamera(target: pendingTarget, zoom: pendingZoom);
          }
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        _buildCachedTileLayer(tileStyle),
        if (_routeOptions.isNotEmpty) _buildRoutePolylineLayer(),
        MarkerLayer(markers: _buildMapMarkers(colorScheme, selectedPoint)),
      ],
    );
  }

  PolylineLayer _buildRoutePolylineLayer() {
    final polylines = <Polyline>[];
    for (var i = 0; i < _routeOptions.length; i++) {
      final route = _routeOptions[i];
      final selected = i == _selectedRouteIndex;
      polylines.add(
        Polyline(
          points: route.points,
          strokeWidth: selected ? 7 : 4,
          color: route.color.withOpacity(selected ? 0.95 : 0.45),
        ),
      );
    }
    return PolylineLayer(polylines: polylines);
  }

  List<Marker> _buildMapMarkers(
    ColorScheme colorScheme,
    LatLng? selectedPoint,
  ) {
    final markers = <Marker>[];

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 64,
          height: 64,
          child: _LocationMarker(),
        ),
      );
    }

    if (selectedPoint != null) {
      markers.add(
        Marker(
          point: selectedPoint,
          width: 56,
          height: 56,
          child: Icon(
            Icons.location_on_rounded,
            color: colorScheme.primary,
            size: 46,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 8)],
          ),
        ),
      );
    }

    for (var i = 0; i < _routeOptions.length; i++) {
      final route = _routeOptions[i];
      if (route.points.isEmpty) continue;
      markers.add(
        Marker(
          point: route.points[route.points.length ~/ 2],
          width: 118,
          height: 44,
          child: _RouteBadge(
            label: _routeTitle(S(widget.currentLanguage == 'ar'), i),
            color: route.color,
            selected: i == _selectedRouteIndex,
            onTap: () => setState(() => _selectedRouteIndex = i),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildMapAttribution(BuildContext context) {
    return Positioned(
      left: 12,
      bottom: MediaQuery.of(context).size.height * 0.13 + 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.86),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _mapAttribution(context),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: 'Cairo',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── خريطة OSM/CARTO الحقيقية ─────────
          Positioned.fill(child: _buildMap(context)),
          _buildMapAttribution(context),

          // ── زر تحديد الموقع (أعلى يمين) ───
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _AnimatedButton(
                  onPressed: _getCurrentLocation,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLocating
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Sheet ───────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.13,
            minChildSize: 0.09,
            maxChildSize: 0.38,
            snap: true,
            snapSizes: const [0.13, 0.38],
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  final expanded = n.extent > 0.2;
                  if (expanded != _sheetExpanded) {
                    setState(() => _sheetExpanded = expanded);
                  }
                  return true;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        // مقبض السحب
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildBottomPanelContent(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  Widgets مساعدة
// ══════════════════════════════════════════════

// النقطة الزرقاء للموقع الحالي
class _LocationMarker extends StatefulWidget {
  @override
  State<_LocationMarker> createState() => _LocationMarkerState();
}

class _LocationMarkerState extends State<_LocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // الحلقة الخارجية النابضة
          Container(
            width: 60 * _pulse.value,
            height: 60 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RaqibColors.blueMid.withOpacity(
                0.15 * (1 - _pulse.value + 0.5),
              ),
            ),
          ),
          // الحلقة الوسطى
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RaqibColors.blueMid.withOpacity(0.3),
              border: Border.all(color: RaqibColors.blueMid, width: 1.5),
            ),
          ),
          // النقطة المركزية
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RaqibColors.blueMid,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: RaqibColors.blueMid.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _RouteBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RouteBadge({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color, width: selected ? 2 : 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_rounded,
              color: selected ? Colors.white : color,
              size: 16,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomShimmer extends StatelessWidget {
  final String label;
  const _BottomShimmer({required this.label});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 18,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// زر الإجراء في Bottom Sheet
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: _AnimatedButton(
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: primary
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: primary ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: primary
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// زر متحرك (scale animation)
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _AnimatedButton({required this.child, required this.onPressed});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

enum SnackType { success, warning, error }
