import { useState, useMemo } from 'react';
import { AISAutocomplete } from '../../components/AISAutocomplete';
import { useAISTokens } from '../../core/AISProvider';
import { Globe, Building } from 'lucide-react';

// Sample data types
interface Country {
  id: string;
  name: string;
  code: string;
  region: string;
}

interface City {
  id: string;
  name: string;
  country: string;
  population: number;
}

// Sample data
const countries: Country[] = [
  { id: 'us', name: 'United States', code: 'US', region: 'North America' },
  { id: 'uk', name: 'United Kingdom', code: 'GB', region: 'Europe' },
  { id: 'ca', name: 'Canada', code: 'CA', region: 'North America' },
  { id: 'au', name: 'Australia', code: 'AU', region: 'Oceania' },
  { id: 'de', name: 'Germany', code: 'DE', region: 'Europe' },
  { id: 'fr', name: 'France', code: 'FR', region: 'Europe' },
  { id: 'jp', name: 'Japan', code: 'JP', region: 'Asia' },
  { id: 'br', name: 'Brazil', code: 'BR', region: 'South America' },
  { id: 'in', name: 'India', code: 'IN', region: 'Asia' },
  { id: 'mx', name: 'Mexico', code: 'MX', region: 'North America' },
  { id: 'es', name: 'Spain', code: 'ES', region: 'Europe' },
  { id: 'it', name: 'Italy', code: 'IT', region: 'Europe' },
  { id: 'nl', name: 'Netherlands', code: 'NL', region: 'Europe' },
  { id: 'se', name: 'Sweden', code: 'SE', region: 'Europe' },
  { id: 'sg', name: 'Singapore', code: 'SG', region: 'Asia' },
];

const cities: City[] = [
  { id: 'nyc', name: 'New York City', country: 'United States', population: 8336817 },
  { id: 'la', name: 'Los Angeles', country: 'United States', population: 3979576 },
  { id: 'chicago', name: 'Chicago', country: 'United States', population: 2693976 },
  { id: 'london', name: 'London', country: 'United Kingdom', population: 8982000 },
  { id: 'paris', name: 'Paris', country: 'France', population: 2161000 },
  { id: 'tokyo', name: 'Tokyo', country: 'Japan', population: 13960000 },
  { id: 'berlin', name: 'Berlin', country: 'Germany', population: 3645000 },
  { id: 'sydney', name: 'Sydney', country: 'Australia', population: 5312000 },
  { id: 'toronto', name: 'Toronto', country: 'Canada', population: 2731571 },
  { id: 'mumbai', name: 'Mumbai', country: 'India', population: 12442373 },
];

const programmingLanguages = [
  'JavaScript', 'TypeScript', 'Python', 'Java', 'C++', 'C#', 'Go', 'Rust',
  'Swift', 'Kotlin', 'Ruby', 'PHP', 'Scala', 'Dart', 'R', 'Julia',
];

export function AutocompleteDemo() {
  const tokens = useAISTokens();

  // Country autocomplete
  const [countrySearch, setCountrySearch] = useState('');
  const [selectedCountry, setSelectedCountry] = useState<Country | null>(null);

  const filteredCountries = useMemo(() => {
    if (!countrySearch) return countries;
    const search = countrySearch.toLowerCase();
    return countries.filter(
      (c) =>
        c.name.toLowerCase().includes(search) ||
        c.code.toLowerCase().includes(search) ||
        c.region.toLowerCase().includes(search)
    );
  }, [countrySearch]);

  // City autocomplete
  const [citySearch, setCitySearch] = useState('');
  const [selectedCity, setSelectedCity] = useState<City | null>(null);

  const filteredCities = useMemo(() => {
    if (!citySearch) return cities;
    const search = citySearch.toLowerCase();
    return cities.filter(
      (c) =>
        c.name.toLowerCase().includes(search) ||
        c.country.toLowerCase().includes(search)
    );
  }, [citySearch]);

  // Simple string autocomplete
  const [langSearch, setLangSearch] = useState('');
  const filteredLangs = useMemo(() => {
    if (!langSearch) return programmingLanguages;
    return programmingLanguages.filter((l) =>
      l.toLowerCase().includes(langSearch.toLowerCase())
    );
  }, [langSearch]);

  // Loading state demo
  const [loadingSearch, setLoadingSearch] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLoadingSearch = (value: string) => {
    setLoadingSearch(value);
    if (value.length > 0) {
      setIsLoading(true);
      setTimeout(() => setIsLoading(false), 1000);
    }
  };

  // Error state demo
  const [errorSearch, setErrorSearch] = useState('');
  const errorMessage = errorSearch.length > 0 && errorSearch.length < 3
    ? 'Please enter at least 3 characters'
    : undefined;

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1
          className="text-3xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          AISAutocomplete
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          Type-ahead autocomplete with keyboard navigation, custom rendering,
          and AIS token styling. Follows AIS section 3.5 specifications.
        </p>
      </div>

      {/* Features */}
      <div
        className="p-4 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h3 className="font-semibold mb-2" style={{ color: tokens.onSurface }}>
          Features
        </h3>
        <ul className="text-sm space-y-1" style={{ color: tokens.onSurfaceSecondary }}>
          <li>- Type-ahead filtering with customizable matching</li>
          <li>- Keyboard navigation (Arrow Up/Down, Enter, Escape)</li>
          <li>- Custom suggestion rendering with icons and secondary text</li>
          <li>- Loading and error states</li>
          <li>- Clear button and selection indicator</li>
          <li>- Full accessibility support (ARIA attributes)</li>
        </ul>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Country Autocomplete */}
        <div className="space-y-4">
          <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
            Country Search (with icons)
          </h3>
          <AISAutocomplete<Country>
            value={countrySearch}
            onChange={setCountrySearch}
            suggestions={filteredCountries}
            displayText={(c) => c.name}
            secondaryText={(c) => `${c.code} - ${c.region}`}
            itemIcon={() => <Globe size={18} />}
            placeholder="Search countries..."
            onSelect={setSelectedCountry}
            selectedItem={selectedCountry}
            itemKey={(c) => c.id}
            label="Country"
          />
          {selectedCountry && (
            <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
              Selected: <strong>{selectedCountry.name}</strong> ({selectedCountry.code})
            </p>
          )}
        </div>

        {/* City Autocomplete */}
        <div className="space-y-4">
          <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
            City Search (with population)
          </h3>
          <AISAutocomplete<City>
            value={citySearch}
            onChange={setCitySearch}
            suggestions={filteredCities}
            displayText={(c) => c.name}
            secondaryText={(c) => `${c.country} - Pop: ${c.population.toLocaleString()}`}
            itemIcon={() => <Building size={18} />}
            placeholder="Search cities..."
            onSelect={setSelectedCity}
            selectedItem={selectedCity}
            itemKey={(c) => c.id}
            style="outlined"
            label="City"
          />
          {selectedCity && (
            <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
              Selected: <strong>{selectedCity.name}</strong>, {selectedCity.country}
            </p>
          )}
        </div>

        {/* Simple String Autocomplete */}
        <div className="space-y-4">
          <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
            Programming Languages (simple strings)
          </h3>
          <AISAutocomplete<string>
            value={langSearch}
            onChange={setLangSearch}
            suggestions={filteredLangs}
            displayText={(s) => s}
            placeholder="Search languages..."
            itemKey={(s) => s}
            style="filled"
            label="Language"
          />
        </div>

        {/* Loading State */}
        <div className="space-y-4">
          <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
            Loading State Demo
          </h3>
          <AISAutocomplete<string>
            value={loadingSearch}
            onChange={handleLoadingSearch}
            suggestions={isLoading ? [] : programmingLanguages}
            displayText={(s) => s}
            placeholder="Type to see loading..."
            itemKey={(s) => s}
            isLoading={isLoading}
            label="With Loading"
          />
        </div>

        {/* Error State */}
        <div className="space-y-4">
          <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
            Error State Demo
          </h3>
          <AISAutocomplete<string>
            value={errorSearch}
            onChange={setErrorSearch}
            suggestions={errorSearch.length >= 3 ? programmingLanguages : []}
            displayText={(s) => s}
            placeholder="Type at least 3 characters..."
            itemKey={(s) => s}
            errorMessage={errorMessage}
            label="With Validation"
          />
        </div>

        {/* Disabled State */}
        <div className="space-y-4">
          <h3 className="font-semibold" style={{ color: tokens.onSurface }}>
            Disabled State
          </h3>
          <AISAutocomplete<string>
            value="Cannot edit"
            onChange={() => {}}
            suggestions={[]}
            displayText={(s) => s}
            placeholder="Disabled..."
            itemKey={(s) => s}
            isDisabled
            label="Disabled Input"
          />
        </div>
      </div>

      {/* Usage Example */}
      <div
        className="p-4 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h3 className="font-semibold mb-2" style={{ color: tokens.onSurface }}>
          Usage Example
        </h3>
        <pre
          className="text-xs overflow-auto p-3 rounded"
          style={{ backgroundColor: tokens.surface, color: tokens.onSurface }}
        >
{`<AISAutocomplete<Country>
  value={searchText}
  onChange={setSearchText}
  suggestions={filteredCountries}
  displayText={(c) => c.name}
  secondaryText={(c) => c.region}
  itemIcon={() => <Globe size={18} />}
  placeholder="Search countries..."
  onSelect={handleSelect}
  selectedItem={selectedCountry}
  itemKey={(c) => c.id}
  label="Country"
/>`}
        </pre>
      </div>
    </div>
  );
}
