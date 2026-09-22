import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_autocomplete.dart';

/// Demo screen for AISAutocomplete component
class AutocompleteDemoScreen extends StatefulWidget {
  const AutocompleteDemoScreen({super.key});

  @override
  State<AutocompleteDemoScreen> createState() => _AutocompleteDemoScreenState();
}

class _AutocompleteDemoScreenState extends State<AutocompleteDemoScreen> {
  // Country autocomplete
  final _countryController = TextEditingController();
  _Country? _selectedCountry;
  String _countryFilter = '';

  // City autocomplete
  final _cityController = TextEditingController();
  _City? _selectedCity;
  String _cityFilter = '';

  // Simple string autocomplete
  final _langController = TextEditingController();
  String _langFilter = '';

  // Loading state demo
  final _loadingController = TextEditingController();
  bool _isLoading = false;

  // Error state demo
  final _errorController = TextEditingController();
  String _errorFilter = '';

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _langController.dispose();
    _loadingController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  List<_Country> get _filteredCountries {
    if (_countryFilter.isEmpty) return _countries;
    final search = _countryFilter.toLowerCase();
    return _countries.where((c) =>
      c.name.toLowerCase().contains(search) ||
      c.code.toLowerCase().contains(search) ||
      c.region.toLowerCase().contains(search)
    ).toList();
  }

  List<_City> get _filteredCities {
    if (_cityFilter.isEmpty) return _cities;
    final search = _cityFilter.toLowerCase();
    return _cities.where((c) =>
      c.name.toLowerCase().contains(search) ||
      c.country.toLowerCase().contains(search)
    ).toList();
  }

  List<String> get _filteredLangs {
    if (_langFilter.isEmpty) return _programmingLanguages;
    return _programmingLanguages.where((l) =>
      l.toLowerCase().contains(_langFilter.toLowerCase())
    ).toList();
  }

  void _handleLoadingSearch(String value) {
    if (value.isNotEmpty && !_isLoading) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  String? get _errorMessage {
    if (_errorFilter.isNotEmpty && _errorFilter.length < 3) {
      return 'Please enter at least 3 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        title: const Text('Autocomplete'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AisTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'AISAutocomplete',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: tokens.onSurface,
              ),
            ),
            const SizedBox(height: AisTheme.spacingSm),
            Text(
              'Type-ahead autocomplete with keyboard navigation, custom rendering, and AIS token styling. Follows AIS section 3.5 specifications.',
              style: TextStyle(
                fontSize: 14,
                color: tokens.onSurfaceSecondary,
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),

            // Features
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  ...[
                    '- Type-ahead filtering with customizable matching',
                    '- Keyboard navigation (Arrow Up/Down, Enter, Escape)',
                    '- Custom suggestion rendering with icons and secondary text',
                    '- Loading and error states',
                    '- Clear button and selection indicator',
                    '- Full accessibility support',
                  ].map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.onSurfaceSecondary,
                      ),
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),

            // Demo Grid
            Wrap(
              spacing: AisTheme.spacingXl,
              runSpacing: AisTheme.spacingXl,
              children: [
                // Country Autocomplete
                _buildDemoCard(
                  title: 'Country Search (with icons)',
                  tokens: tokens,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Country',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: AisTheme.spacingXs),
                      AisAutocomplete<_Country>(
                        controller: _countryController,
                        suggestions: _filteredCountries,
                        displayText: (c) => c.name,
                        secondaryText: (c) => '${c.code} - ${c.region}',
                        itemIcon: (c) => Icons.public,
                        placeholder: 'Search countries...',
                        selectedItem: _selectedCountry,
                        itemEquals: (a, b) => a.id == b.id,
                        onTextChanged: (v) => setState(() => _countryFilter = v),
                        onSelected: (c) => setState(() => _selectedCountry = c),
                      ),
                      if (_selectedCountry != null) ...[
                        const SizedBox(height: AisTheme.spacingSm),
                        Text(
                          'Selected: ${_selectedCountry!.name} (${_selectedCountry!.code})',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // City Autocomplete
                _buildDemoCard(
                  title: 'City Search (with population)',
                  tokens: tokens,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'City',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: AisTheme.spacingXs),
                      AisAutocomplete<_City>(
                        controller: _cityController,
                        suggestions: _filteredCities,
                        displayText: (c) => c.name,
                        secondaryText: (c) => '${c.country} - Pop: ${_formatNumber(c.population)}',
                        itemIcon: (c) => Icons.location_city,
                        placeholder: 'Search cities...',
                        style: AisAutocompleteStyle.outlined,
                        selectedItem: _selectedCity,
                        itemEquals: (a, b) => a.id == b.id,
                        onTextChanged: (v) => setState(() => _cityFilter = v),
                        onSelected: (c) => setState(() => _selectedCity = c),
                      ),
                      if (_selectedCity != null) ...[
                        const SizedBox(height: AisTheme.spacingSm),
                        Text(
                          'Selected: ${_selectedCity!.name}, ${_selectedCity!.country}',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Simple String Autocomplete
                _buildDemoCard(
                  title: 'Programming Languages (simple strings)',
                  tokens: tokens,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: AisTheme.spacingXs),
                      AisStringAutocomplete(
                        controller: _langController,
                        suggestions: _filteredLangs,
                        placeholder: 'Search languages...',
                        style: AisAutocompleteStyle.filled,
                        onTextChanged: (v) => setState(() => _langFilter = v),
                      ),
                    ],
                  ),
                ),

                // Loading State
                _buildDemoCard(
                  title: 'Loading State Demo',
                  tokens: tokens,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'With Loading',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: AisTheme.spacingXs),
                      AisStringAutocomplete(
                        controller: _loadingController,
                        suggestions: _isLoading ? [] : _programmingLanguages,
                        placeholder: 'Type to see loading...',
                        isLoading: _isLoading,
                        onTextChanged: _handleLoadingSearch,
                      ),
                    ],
                  ),
                ),

                // Error State
                _buildDemoCard(
                  title: 'Error State Demo',
                  tokens: tokens,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'With Validation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: AisTheme.spacingXs),
                      AisStringAutocomplete(
                        controller: _errorController,
                        suggestions: _errorFilter.length >= 3 ? _programmingLanguages : [],
                        placeholder: 'Type at least 3 characters...',
                        errorMessage: _errorMessage,
                        onTextChanged: (v) => setState(() => _errorFilter = v),
                      ),
                    ],
                  ),
                ),

                // Disabled State
                _buildDemoCard(
                  title: 'Disabled State',
                  tokens: tokens,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disabled Input',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: AisTheme.spacingXs),
                      AisStringAutocomplete(
                        controller: TextEditingController(text: 'Cannot edit'),
                        suggestions: const [],
                        placeholder: 'Disabled...',
                        isDisabled: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required String title,
    required AisTokens tokens,
    required Widget child,
  }) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          child,
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}

// Sample data models
class _Country {
  final String id;
  final String name;
  final String code;
  final String region;

  const _Country({
    required this.id,
    required this.name,
    required this.code,
    required this.region,
  });
}

class _City {
  final String id;
  final String name;
  final String country;
  final int population;

  const _City({
    required this.id,
    required this.name,
    required this.country,
    required this.population,
  });
}

// Sample data
const _countries = [
  _Country(id: 'us', name: 'United States', code: 'US', region: 'North America'),
  _Country(id: 'uk', name: 'United Kingdom', code: 'GB', region: 'Europe'),
  _Country(id: 'ca', name: 'Canada', code: 'CA', region: 'North America'),
  _Country(id: 'au', name: 'Australia', code: 'AU', region: 'Oceania'),
  _Country(id: 'de', name: 'Germany', code: 'DE', region: 'Europe'),
  _Country(id: 'fr', name: 'France', code: 'FR', region: 'Europe'),
  _Country(id: 'jp', name: 'Japan', code: 'JP', region: 'Asia'),
  _Country(id: 'br', name: 'Brazil', code: 'BR', region: 'South America'),
  _Country(id: 'in', name: 'India', code: 'IN', region: 'Asia'),
  _Country(id: 'mx', name: 'Mexico', code: 'MX', region: 'North America'),
  _Country(id: 'es', name: 'Spain', code: 'ES', region: 'Europe'),
  _Country(id: 'it', name: 'Italy', code: 'IT', region: 'Europe'),
  _Country(id: 'nl', name: 'Netherlands', code: 'NL', region: 'Europe'),
  _Country(id: 'se', name: 'Sweden', code: 'SE', region: 'Europe'),
  _Country(id: 'sg', name: 'Singapore', code: 'SG', region: 'Asia'),
];

const _cities = [
  _City(id: 'nyc', name: 'New York City', country: 'United States', population: 8336817),
  _City(id: 'la', name: 'Los Angeles', country: 'United States', population: 3979576),
  _City(id: 'chicago', name: 'Chicago', country: 'United States', population: 2693976),
  _City(id: 'london', name: 'London', country: 'United Kingdom', population: 8982000),
  _City(id: 'paris', name: 'Paris', country: 'France', population: 2161000),
  _City(id: 'tokyo', name: 'Tokyo', country: 'Japan', population: 13960000),
  _City(id: 'berlin', name: 'Berlin', country: 'Germany', population: 3645000),
  _City(id: 'sydney', name: 'Sydney', country: 'Australia', population: 5312000),
  _City(id: 'toronto', name: 'Toronto', country: 'Canada', population: 2731571),
  _City(id: 'mumbai', name: 'Mumbai', country: 'India', population: 12442373),
];

const _programmingLanguages = [
  'JavaScript', 'TypeScript', 'Python', 'Java', 'C++', 'C#', 'Go', 'Rust',
  'Swift', 'Kotlin', 'Ruby', 'PHP', 'Scala', 'Dart', 'R', 'Julia',
];
