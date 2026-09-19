import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_data_grid.dart';
import '../widgets/ais_media_picker.dart';

/// Demo screen for Data Grid and Media Picker widgets
class DataGridDemoScreen extends StatefulWidget {
  const DataGridDemoScreen({super.key});

  @override
  State<DataGridDemoScreen> createState() => _DataGridDemoScreenState();
}

class _DataGridDemoScreenState extends State<DataGridDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_SampleProduct> _products = [];
  List<AisFileInfo> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _products = _generateSampleProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_SampleProduct> _generateSampleProducts() {
    return [
      _SampleProduct(id: 1, name: 'Widget Pro', category: 'Electronics', price: 299.99, stock: 150, active: true),
      _SampleProduct(id: 2, name: 'Gadget Plus', category: 'Electronics', price: 149.50, stock: 75, active: true),
      _SampleProduct(id: 3, name: 'Smart Device', category: 'Electronics', price: 499.00, stock: 30, active: false),
      _SampleProduct(id: 4, name: 'Office Chair', category: 'Furniture', price: 250.00, stock: 45, active: true),
      _SampleProduct(id: 5, name: 'Standing Desk', category: 'Furniture', price: 599.99, stock: 20, active: true),
      _SampleProduct(id: 6, name: 'Monitor Stand', category: 'Accessories', price: 79.99, stock: 200, active: true),
      _SampleProduct(id: 7, name: 'Keyboard Wireless', category: 'Electronics', price: 89.99, stock: 120, active: true),
      _SampleProduct(id: 8, name: 'Mouse Ergonomic', category: 'Electronics', price: 59.99, stock: 180, active: true),
      _SampleProduct(id: 9, name: 'Desk Lamp', category: 'Accessories', price: 45.00, stock: 90, active: false),
      _SampleProduct(id: 10, name: 'Cable Organizer', category: 'Accessories', price: 15.99, stock: 500, active: true),
      _SampleProduct(id: 11, name: 'Webcam HD', category: 'Electronics', price: 129.00, stock: 60, active: true),
      _SampleProduct(id: 12, name: 'USB Hub', category: 'Accessories', price: 39.99, stock: 250, active: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Grid & Media Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Data Grid', icon: Icon(Icons.grid_on)),
            Tab(text: 'Media Picker', icon: Icon(Icons.upload_file)),
            Tab(text: 'Grid Layout', icon: Icon(Icons.grid_view)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDataGridTab(tokens),
          _buildMediaPickerTab(tokens),
          _buildGridLayoutTab(tokens),
        ],
      ),
    );
  }

  Widget _buildDataGridTab(AisTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Excel-like Data Grid',
            subtitle: 'Editable cells, sorting, filtering, keyboard navigation',
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Features list
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            decoration: BoxDecoration(
              color: tokens.stateInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tokens.stateInfo.icon, size: 16, color: tokens.stateInfo.color),
                    const SizedBox(width: AisTheme.spacingSm),
                    const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AisTheme.spacingSm),
                const Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _FeatureChip('Column sorting (multi)'),
                    _FeatureChip('Per-column filters'),
                    _FeatureChip('Editable cells'),
                    _FeatureChip('Row selection'),
                    _FeatureChip('Keyboard navigation'),
                    _FeatureChip('Column resize'),
                    _FeatureChip('Row numbers'),
                    _FeatureChip('Virtualized'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Data grid
          Expanded(
            child: AisDataGrid<_SampleProduct>(
              columns: [
                AisGridColumn<_SampleProduct>(
                  id: 'id',
                  title: 'ID',
                  getValue: (p) => p.id,
                  initialWidth: 60,
                  alignment: Alignment.center,
                ),
                AisGridColumn<_SampleProduct>(
                  id: 'name',
                  title: 'Product Name',
                  getValue: (p) => p.name,
                  initialWidth: 150,
                  editable: true,
                ),
                AisGridColumn<_SampleProduct>(
                  id: 'category',
                  title: 'Category',
                  getValue: (p) => p.category,
                  initialWidth: 120,
                ),
                AisGridColumn<_SampleProduct>(
                  id: 'price',
                  title: 'Price',
                  getValue: (p) => p.price,
                  initialWidth: 100,
                  alignment: Alignment.centerRight,
                  formatter: (v) => '\$${(v as double).toStringAsFixed(2)}',
                  editable: true,
                  type: AisGridColumnType.currency,
                ),
                AisGridColumn<_SampleProduct>(
                  id: 'stock',
                  title: 'Stock',
                  getValue: (p) => p.stock,
                  initialWidth: 80,
                  alignment: Alignment.centerRight,
                  editable: true,
                  type: AisGridColumnType.number,
                ),
                AisGridColumn<_SampleProduct>(
                  id: 'active',
                  title: 'Active',
                  getValue: (p) => p.active,
                  initialWidth: 80,
                  alignment: Alignment.center,
                  formatter: (v) => (v as bool) ? 'Yes' : 'No',
                  type: AisGridColumnType.boolean,
                ),
              ],
              rows: _products,
              multiSelect: true,
              onCellChanged: (row, columnId, newValue) {
                setState(() {
                  final index = _products.indexOf(row);
                  if (index >= 0) {
                    switch (columnId) {
                      case 'name':
                        _products[index] = row.copyWith(name: newValue as String);
                        break;
                      case 'price':
                        _products[index] = row.copyWith(price: double.tryParse(newValue.toString()) ?? row.price);
                        break;
                      case 'stock':
                        _products[index] = row.copyWith(stock: int.tryParse(newValue.toString()) ?? row.stock);
                        break;
                    }
                  }
                });
              },
              onSelectionChanged: (selected) {
                debugPrint('Selected ${selected.length} rows');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPickerTab(AisTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Media Picker - Real File Demo',
            subtitle: 'Click to browse and select real files from your system',
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Features
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingMd),
            decoration: BoxDecoration(
              color: tokens.stateInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tokens.stateInfo.icon, size: 16, color: tokens.stateInfo.color),
                    const SizedBox(width: AisTheme.spacingSm),
                    const Text('Supported Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AisTheme.spacingSm),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: AisMediaType.values
                      .where((t) => t != AisMediaType.any)
                      .map((t) => _MediaTypeChip(type: t))
                      .toList(),
                ),
                const SizedBox(height: AisTheme.spacingMd),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: tokens.actionConfirm.color),
                    const SizedBox(width: 4),
                    Text(
                      'Returns: file path, MIME type, size, checksum, timestamps, and more',
                      style: TextStyle(fontSize: 11, color: tokens.onSurfaceSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AisTheme.spacingLg),

          // Image/Video picker
          _SectionHeader(
            title: 'Image & Video Upload',
            subtitle: 'Select up to 5 images or videos (max 50 MB each)',
          ),
          const SizedBox(height: AisTheme.spacingSm),
          AisMediaPicker(
            allowedTypes: const [AisMediaType.image, AisMediaType.video],
            multiple: true,
            maxFiles: 5,
            maxSizeBytes: 50 * 1024 * 1024, // 50 MB
            label: 'Product Images',
            hint: 'Click to browse images or videos',
            showPreviews: true,
            onFilesSelected: (files) {
              debugPrint('Selected ${files.length} media files');
              for (final file in files) {
                debugPrint('  - ${file.fileName}: ${file.formattedSize} (${file.mimeType})');
                debugPrint('    Path: ${file.fullPath}');
                if (file.checksum != null) {
                  debugPrint('    MD5: ${file.checksum}');
                }
              }
            },
          ),

          const SizedBox(height: AisTheme.spacingXl),

          // Document picker with file info display
          _SectionHeader(
            title: 'Document Upload with Full Metadata',
            subtitle: 'Select a PDF, CSV, or Text file to see all returned metadata',
          ),
          const SizedBox(height: AisTheme.spacingSm),
          AisMediaPicker(
            allowedTypes: const [AisMediaType.pdf, AisMediaType.csv, AisMediaType.text],
            multiple: false,
            maxSizeBytes: 10 * 1024 * 1024, // 10 MB
            label: 'Import Data',
            hint: 'Click to select a document',
            selectedFiles: _selectedFiles,
            onFilesSelected: (files) {
              setState(() {
                _selectedFiles = files;
              });
              // Log the file info to console
              for (final file in files) {
                debugPrint('=== File Info for Database ===');
                debugPrint('ID: ${file.id}');
                debugPrint('Name: ${file.fileName}');
                debugPrint('Extension: ${file.extension}');
                debugPrint('MIME Type: ${file.mimeType}');
                debugPrint('Size: ${file.sizeBytes} bytes (${file.formattedSize})');
                debugPrint('Folder: ${file.folderPath}');
                debugPrint('Full Path: ${file.fullPath}');
                debugPrint('Media Type: ${file.mediaType.name}');
                debugPrint('Created: ${file.createdAt}');
                debugPrint('Modified: ${file.modifiedAt}');
                debugPrint('Checksum: ${file.checksum}');
                debugPrint('Status: ${file.status.name}');
                debugPrint('=== JSON for Database ===');
                debugPrint('${file.toMap()}');
              }
            },
          ),

          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: AisTheme.spacingLg),
            _SectionHeader(
              title: 'File Information (Database Ready)',
              subtitle: 'All metadata returned by the picker - click to copy',
            ),
            const SizedBox(height: AisTheme.spacingSm),
            AisFileInfoDisplay(
              file: _selectedFiles.first,
              showFullPath: true,
              showMetadata: true,
            ),
            const SizedBox(height: AisTheme.spacingMd),
            // JSON export section
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, size: 16, color: tokens.actionPrimary.color),
                      const SizedBox(width: AisTheme.spacingSm),
                      const Text('Database-Ready JSON:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  SelectableText(
                    _formatJson(_selectedFiles.first.toMap()),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: tokens.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AisTheme.spacingXl),

          // Audio picker
          _SectionHeader(
            title: 'Audio Upload',
            subtitle: 'Select MP3, WAV, AAC, or other audio files',
          ),
          const SizedBox(height: AisTheme.spacingSm),
          AisMediaPicker(
            allowedTypes: const [AisMediaType.audio],
            multiple: true,
            maxFiles: 10,
            label: 'Audio Files',
            hint: 'Click to select audio files',
            onFilesSelected: (files) {
              debugPrint('Selected ${files.length} audio files');
            },
          ),

          const SizedBox(height: AisTheme.spacingXl),

          // Any file picker
          _SectionHeader(
            title: 'Any File Type',
            subtitle: 'Select any file type without restrictions',
          ),
          const SizedBox(height: AisTheme.spacingSm),
          AisMediaPicker(
            allowedTypes: const [AisMediaType.any],
            multiple: true,
            maxFiles: 10,
            label: 'Any Files',
            hint: 'Click to select any file',
            onFilesSelected: (files) {
              debugPrint('Selected ${files.length} files of any type');
            },
          ),

          const SizedBox(height: AisTheme.spacingXl),

          // File chips demo with real selected files
          _SectionHeader(
            title: 'File Chips (from selected files)',
            subtitle: 'Compact file display for inline use',
          ),
          const SizedBox(height: AisTheme.spacingSm),
          if (_selectedFiles.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFiles.map((file) => AisFileChip(
                file: file,
                onTap: () => _showFileInfoDialog(file),
                onRemove: () {
                  setState(() {
                    _selectedFiles.removeWhere((f) => f.id == file.id);
                  });
                },
              )).toList(),
            )
          else
            Text(
              'Select a document above to see file chips here',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: tokens.onSurfaceSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.writeln('{');
    final entries = map.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final value = entry.value;
      final valueStr = value is String ? '"$value"' : '$value';
      buffer.write('  "${entry.key}": $valueStr');
      if (i < entries.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.write('}');
    return buffer.toString();
  }

  void _showFileInfoDialog(AisFileInfo file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(file.mediaType.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                file.fileName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: AisFileInfoDisplay(
            file: file,
            showFullPath: true,
            showMetadata: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayoutTab(AisTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Grid Layout',
            subtitle: 'Responsive grid for arranging items',
          ),
          const SizedBox(height: AisTheme.spacingMd),

          // Fixed grid
          Text(
            'Fixed 3-Column Grid',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          SizedBox(
            height: 200,
            child: AisGridLayout(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: List.generate(
                6,
                (i) => _GridItem(index: i, tokens: tokens),
              ),
            ),
          ),

          const SizedBox(height: AisTheme.spacingXl),

          // Adaptive grid
          Text(
            'Adaptive Grid (min width: 150px)',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          SizedBox(
            height: 300,
            child: AisGridLayout.adaptive(
              minChildWidth: 150,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: List.generate(
                12,
                (i) => _GridItem(index: i, tokens: tokens),
              ),
            ),
          ),

          const SizedBox(height: AisTheme.spacingXl),

          // Cards grid
          Text(
            'Card Grid Layout',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: tokens.onSurface,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
          SizedBox(
            height: 250,
            child: AisGridLayout.adaptive(
              minChildWidth: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _CardItem(
                  title: 'Revenue',
                  value: '\$125,430',
                  icon: Icons.attach_money,
                  color: Colors.green,
                  tokens: tokens,
                ),
                _CardItem(
                  title: 'Orders',
                  value: '1,234',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                  tokens: tokens,
                ),
                _CardItem(
                  title: 'Customers',
                  value: '892',
                  icon: Icons.people,
                  color: Colors.purple,
                  tokens: tokens,
                ),
                _CardItem(
                  title: 'Products',
                  value: '156',
                  icon: Icons.inventory,
                  color: Colors.orange,
                  tokens: tokens,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleProduct {
  final int id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final bool active;

  const _SampleProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.active,
  });

  _SampleProduct copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    bool? active,
  }) {
    return _SampleProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      active: active ?? this.active,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: tokens.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: tokens.onSurfaceSecondary,
        ),
      ),
    );
  }
}

class _MediaTypeChip extends StatelessWidget {
  final AisMediaType type;

  const _MediaTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: tokens.onSurfaceSecondary),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 11,
              color: tokens.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final int index;
  final AisTokens tokens;

  const _GridItem({required this.index, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.actionPrimary.color.withOpacity(0.1 + (index % 3) * 0.1),
        borderRadius: BorderRadius.circular(AisTheme.radiusSm),
        border: Border.all(color: tokens.actionPrimary.color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          'Item ${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: tokens.actionPrimary.color,
          ),
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AisTokens tokens;

  const _CardItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
        border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 16,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: tokens.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: tokens.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
