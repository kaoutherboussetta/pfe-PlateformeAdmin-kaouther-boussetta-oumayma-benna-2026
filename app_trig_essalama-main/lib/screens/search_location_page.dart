import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../l10n/context_l10n.dart';
import '../l10n/search_constants.dart';
import '../services/nominatim_service.dart';
import '../services/search_history_service.dart';

String _slAroundMe(AppStrings s) {
  switch (s.lang) {
    case AppLanguage.fr:
      return 'Autour de moi';
    case AppLanguage.en:
      return 'Near me';
    case AppLanguage.tnd:
      return '7awli';
  }
}

String _slNoResultsSubtitle(AppStrings s) {
  switch (s.lang) {
    case AppLanguage.fr:
      return 'Essayez une autre recherche';
    case AppLanguage.en:
      return 'Try a different search';
    case AppLanguage.tnd:
      return 'Jarreb recherche okhra';
  }
}

String _slPlaceSaved(AppStrings s) {
  switch (s.lang) {
    case AppLanguage.fr:
      return 'Lieu enregistré';
    case AppLanguage.en:
      return 'Place saved';
    case AppLanguage.tnd:
      return 'Blasa msjl';
  }
}

String _slCurrentSection(AppStrings s) {
  switch (s.lang) {
    case AppLanguage.fr:
      return 'Position actuelle';
    case AppLanguage.en:
      return 'Current location';
    case AppLanguage.tnd:
      return 'Position taw';
  }
}

String _slGpsSubtitle(AppStrings s) {
  switch (s.lang) {
    case AppLanguage.fr:
      return 'Utiliser le GPS';
    case AppLanguage.en:
      return 'Use GPS';
    case AppLanguage.tnd:
      return 'GPS';
  }
}

String _slSavedSection(AppStrings s) {
  switch (s.lang) {
    case AppLanguage.fr:
      return 'Lieux enregistrés';
    case AppLanguage.en:
      return 'Saved places';
    case AppLanguage.tnd:
      return 'Blayess msojlin';
  }
}

class _PlaceCategory {
  final IconData icon;
  final String label;
  final String query;
  const _PlaceCategory(this.icon, this.label, this.query);
}

class SearchLocationPage extends StatefulWidget {
  final String hintText;
  final String? initialQuery;
  final String historyType;
  final LatLng? currentLocation;
  final void Function(LatLng point, String label)? onLocationSelected;

  const SearchLocationPage({
    super.key,
    required this.hintText,
    this.initialQuery,
    this.historyType = 'destination',
    this.currentLocation,
    this.onLocationSelected,
  });

  @override
  State<SearchLocationPage> createState() => _SearchLocationPageState();
}

class _SearchLocationPageState extends State<SearchLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  List<Map<String, dynamic>> _savedPlaces = [];
  bool _isLoading = false;
  bool _showEmptyResults = false;
  Timer? _debounce;
  String? _currentLocationName;

  static const List<_PlaceCategory> _categories = [
    _PlaceCategory(Icons.local_gas_station, 'Stations', 'station essence'),
    _PlaceCategory(Icons.restaurant, 'Restaurants', 'restaurant'),
    _PlaceCategory(Icons.local_cafe, 'Cafés', 'cafe'),
    _PlaceCategory(Icons.shopping_cart, 'Supermarchés', 'supermarché'),
    _PlaceCategory(Icons.hotel, 'Hôtels', 'hôtel'),
    _PlaceCategory(Icons.local_hospital, 'Hôpitaux', 'hôpital'),
    _PlaceCategory(Icons.park, 'Parcs', 'parc'),
    _PlaceCategory(Icons.directions_bus, 'Transports', 'gare'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _loadRecentSearches();
    _loadSavedPlaces();
    _getCurrentLocationName();

    _searchController.addListener(_onControllerTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final skip = context.stringsRead.mapYourCurrentLocation;
      if (_searchController.text == skip) {
        _searchController.clear();
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onControllerTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerTextChanged() {
    if (!mounted) return;
    setState(() {});
    final query = _searchController.text;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _showEmptyResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocation(query.trim());
    });
  }

  Future<void> _getCurrentLocationName() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final address = await NominatimService.getReverseGeocoding(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        final fallback = context.stringsRead.mapYourCurrentLocation;
        setState(() {
          _currentLocationName = address ?? fallback;
        });
      }
    } catch (_) {
      if (mounted) {
        final fallback = context.stringsRead.mapYourCurrentLocation;
        setState(() => _currentLocationName = fallback);
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    final searches = await SearchHistoryService.getHistory(widget.historyType);
    if (mounted) {
      setState(() {
        _recentSearches = searches.take(10).toList();
      });
    }
  }

  Future<void> _loadSavedPlaces() async {
    final saved = await SearchHistoryService.getSavedPlaces();
    if (mounted) {
      setState(() => _savedPlaces = saved);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _showEmptyResults = false;
    });

    try {
      final results = await NominatimService.getSuggestions(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _showEmptyResults = query.length > 2 && results.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showEmptyResults = false;
      });
    }
  }

  Future<void> _searchNearby(String query) async {
    final origin = widget.currentLocation;
    if (origin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.stringsRead.mapPositionError)),
        );
      }
      return;
    }

    final q = query.trim().isEmpty ? 'commerce' : query;

    setState(() {
      _isLoading = true;
      _showEmptyResults = false;
    });

    try {
      final results = await NominatimService.searchNearby(
        origin.latitude,
        origin.longitude,
        q,
        radiusMeters: 8000,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _showEmptyResults = results.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _readCoord(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }

  Future<void> _selectLocation(Map<String, dynamic> location) async {
    final s = context.stringsRead;
    try {
      final lat = location['lat'];
      final lon = location['lon'];
      final name =
          '${location['display_name'] ?? location['name'] ?? ''}'.trim();

      final latVal = _readCoord(lat);
      final lonVal = _readCoord(lon);

      await SearchHistoryService.addSearch(location, widget.historyType);

      final payload = <String, dynamic>{
        'lat': latVal,
        'lon': lonVal,
        'display_name': name.isEmpty ? s.unknown : name,
        'raw': location,
      };

      widget.onLocationSelected?.call(LatLng(latVal, lonVal), payload['display_name'] as String);

      if (mounted) Navigator.pop(context, payload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.mapInvalidCoordinates)),
        );
      }
    }
  }

  Future<void> _selectCurrentLocation() async {
    final s = context.stringsRead;
    try {
      if (widget.historyType == 'departure') {
        if (mounted) {
          Navigator.pop(context, {
            'name': kSearchCurrentLocationName,
            'lat': null,
            'lon': null,
            'display_name': s.mapYourCurrentLocation,
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final label =
          _currentLocationName ?? s.mapYourCurrentLocation;

      if (!mounted) return;
      Navigator.pop(context, {
        'lat': position.latitude,
        'lon': position.longitude,
        'display_name': label,
        'isCurrentLocation': true,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.mapPositionError)),
        );
      }
    }
  }

  Future<void> _savePlace(Map<String, dynamic> location) async {
    await SearchHistoryService.savePlace(location);
    await _loadSavedPlaces();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_slPlaceSaved(context.stringsRead)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _removeRecentSearch(Map<String, dynamic> search) async {
    await SearchHistoryService.removeSearch(search, widget.historyType);
    await _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = context.strings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showEmptyResults = false;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: const TextStyle(color: Colors.teal)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchController.text.trim().length < 3)
            _buildSearchFilters(isDark, s),
          Expanded(child: _buildContent(s)),
        ],
      ),
    );
  }

  Widget _buildSearchFilters(bool isDark, AppStrings s) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            icon: Icons.my_location,
            label: _slAroundMe(s),
            isDark: isDark,
            onTap: () => _searchNearby(''),
          ),
          const SizedBox(width: 8),
          ..._categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                icon: c.icon,
                label: c.label,
                isDark: isDark,
                onTap: () => _searchNearby(c.query),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppStrings s) {
    if (_isLoading &&
        _searchController.text.trim().length >= 3 &&
        _searchResults.isEmpty) {
      return Column(
        children: [
          const LinearProgressIndicator(minHeight: 2, color: Colors.teal),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          ),
        ],
      );
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return _buildLocationTile(
            icon: Icons.place_rounded,
            title: _getMainTitle(result),
            subtitle: _getSubtitle(result),
            color: Colors.teal,
            onTap: () => _selectLocation(result),
            trailing: IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, size: 20),
              onPressed: () => _savePlace(result),
            ),
          );
        },
      );
    }

    if (_showEmptyResults && _searchController.text.trim().length > 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              s.mapSearchNoResults,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _slNoResultsSubtitle(s),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_currentLocationName != null) ...[
          Text(
            _slCurrentSection(s),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildLocationTile(
            icon: Icons.my_location,
            title: _currentLocationName!,
            subtitle: _slGpsSubtitle(s),
            color: const Color(0xFF4285F4),
            onTap: _selectCurrentLocation,
          ),
          const SizedBox(height: 16),
        ],
        if (_savedPlaces.isNotEmpty) ...[
          Text(
            _slSavedSection(s),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ..._savedPlaces.take(5).map(
                (place) => _buildLocationTile(
                  icon: Icons.bookmark_rounded,
                  title: '${place['name'] ?? place['display_name'] ?? ''}',
                  subtitle: '${place['display_name'] ?? place['address'] ?? ''}',
                  color: const Color(0xFF34A853),
                  onTap: () => _selectLocation(place),
                ),
              ),
          const SizedBox(height: 16),
        ],
        if (_recentSearches.isNotEmpty) ...[
          Text(
            s.searchRecentTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ..._recentSearches.map(
            (search) => _buildLocationTile(
              icon: Icons.history,
              title: _getMainTitle(search),
              subtitle: _getSubtitle(search),
              color: Colors.grey,
              onTap: () => _selectLocation(search),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeRecentSearch(search),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLocationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  String _getMainTitle(Map<String, dynamic> location) {
    final name = '${location['name'] ?? ''}'.trim();
    final displayName = '${location['display_name'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    final parts = displayName.split(',');
    if (parts.isNotEmpty) return parts.first.trim();
    return displayName;
  }

  String _getSubtitle(Map<String, dynamic> location) {
    final displayName = '${location['display_name'] ?? ''}'.trim();
    final parts = displayName.split(',');
    if (parts.length > 1) {
      return parts.sublist(1).join(',').trim();
    }
    final type = location['type'];
    return type == null ? '' : '$type'.toUpperCase();
  }
}
