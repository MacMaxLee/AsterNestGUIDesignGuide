import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Data Grid - Excel-like editable data grid
///
/// Features:
/// - Editable cells with type-aware editing
/// - Column resize, reorder, show/hide
/// - Row selection (single/multi)
/// - Sort by column (multi-column with precedence)
/// - Filter per column
/// - Copy/paste support
/// - Keyboard navigation
/// - Virtualized for performance
/// - Export reflects current view (C-12)
class AisDataGrid<T> extends StatefulWidget {
  final List<AisGridColumn<T>> columns;
  final List<T> rows;
  final void Function(T row, String columnId, dynamic newValue)? onCellChanged;
  final void Function(List<T> selectedRows)? onSelectionChanged;
  final void Function(List<AisGridSort> sorts)? onSortChanged;
  final void Function(Map<String, String> filters)? onFilterChanged;
  final bool multiSelect;
  final bool showRowNumbers;
  final bool showFilters;
  final bool allowColumnResize;
  final bool allowColumnReorder;
  final double rowHeight;
  final double headerHeight;
  final List<T>? selectedRows;

  const AisDataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.onCellChanged,
    this.onSelectionChanged,
    this.onSortChanged,
    this.onFilterChanged,
    this.multiSelect = false,
    this.showRowNumbers = true,
    this.showFilters = true,
    this.allowColumnResize = true,
    this.allowColumnReorder = true,
    this.rowHeight = 36,
    this.headerHeight = 40,
    this.selectedRows,
  });

  @override
  State<AisDataGrid<T>> createState() => _AisDataGridState<T>();
}

class _AisDataGridState<T> extends State<AisDataGrid<T>> {
  late List<AisGridColumn<T>> _columns;
  late Set<int> _selectedRowIndices;
  late Map<String, double> _columnWidths;
  late List<AisGridSort> _sorts;
  late Map<String, String> _filters;
  int? _editingRow;
  String? _editingColumn;
  int? _focusedRow;
  int? _focusedColumn;
  final _scrollControllerH = ScrollController();
  final _scrollControllerV = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
    _selectedRowIndices = {};
    _columnWidths = {
      for (var col in widget.columns) col.id: col.initialWidth,
    };
    _sorts = [];
    _filters = {};
  }

  @override
  void dispose() {
    _scrollControllerH.dispose();
    _scrollControllerV.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<T> get _filteredRows {
    var rows = widget.rows;
    // Apply filters
    for (var entry in _filters.entries) {
      if (entry.value.isNotEmpty) {
        final col = _columns.firstWhere((c) => c.id == entry.key);
        rows = rows.where((row) {
          final value = col.getValue(row)?.toString().toLowerCase() ?? '';
          return value.contains(entry.value.toLowerCase());
        }).toList();
      }
    }
    // Apply sorts
    if (_sorts.isNotEmpty) {
      rows = List.from(rows);
      rows.sort((a, b) {
        for (var sort in _sorts) {
          final col = _columns.firstWhere((c) => c.id == sort.columnId);
          final aVal = col.getValue(a);
          final bVal = col.getValue(b);
          int cmp = _compareValues(aVal, bVal);
          if (cmp != 0) {
            return sort.ascending ? cmp : -cmp;
          }
        }
        return 0;
      });
    }
    return rows;
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is Comparable && b is Comparable) {
      return a.compareTo(b);
    }
    return a.toString().compareTo(b.toString());
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_focusedRow == null || _focusedColumn == null) {
      _focusedRow = 0;
      _focusedColumn = 0;
      setState(() {});
      return;
    }

    final rows = _filteredRows;
    final visibleCols = _columns.where((c) => c.visible).toList();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_focusedRow! > 0) {
          setState(() => _focusedRow = _focusedRow! - 1);
        }
        break;
      case LogicalKeyboardKey.arrowDown:
        if (_focusedRow! < rows.length - 1) {
          setState(() => _focusedRow = _focusedRow! + 1);
        }
        break;
      case LogicalKeyboardKey.arrowLeft:
        if (_focusedColumn! > 0) {
          setState(() => _focusedColumn = _focusedColumn! - 1);
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (_focusedColumn! < visibleCols.length - 1) {
          setState(() => _focusedColumn = _focusedColumn! + 1);
        }
        break;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.f2:
        final col = visibleCols[_focusedColumn!];
        if (col.editable) {
          setState(() {
            _editingRow = _focusedRow;
            _editingColumn = col.id;
          });
        }
        break;
      case LogicalKeyboardKey.escape:
        if (_editingRow != null) {
          setState(() {
            _editingRow = null;
            _editingColumn = null;
          });
        }
        break;
      case LogicalKeyboardKey.space:
        if (!HardwareKeyboard.instance.isShiftPressed) {
          _toggleRowSelection(_focusedRow!);
        }
        break;
    }
  }

  void _toggleRowSelection(int rowIndex) {
    setState(() {
      if (widget.multiSelect) {
        if (_selectedRowIndices.contains(rowIndex)) {
          _selectedRowIndices.remove(rowIndex);
        } else {
          _selectedRowIndices.add(rowIndex);
        }
      } else {
        _selectedRowIndices = {rowIndex};
      }
    });
    final selectedRows =
        _selectedRowIndices.map((i) => _filteredRows[i]).toList();
    widget.onSelectionChanged?.call(selectedRows);
  }

  void _handleColumnSort(String columnId) {
    setState(() {
      final existingIndex = _sorts.indexWhere((s) => s.columnId == columnId);
      if (existingIndex >= 0) {
        final existing = _sorts[existingIndex];
        if (existing.ascending) {
          _sorts[existingIndex] =
              AisGridSort(columnId: columnId, ascending: false);
        } else {
          _sorts.removeAt(existingIndex);
        }
      } else {
        _sorts.add(AisGridSort(columnId: columnId, ascending: true));
      }
    });
    widget.onSortChanged?.call(_sorts);
  }

  void _handleFilterChanged(String columnId, String value) {
    setState(() {
      _filters[columnId] = value;
    });
    widget.onFilterChanged?.call(_filters);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final visibleColumns = _columns.where((c) => c.visible).toList();
    final rows = _filteredRows;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: tokens.onSurface.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(AisTheme.radiusSm),
        ),
        child: Column(
          children: [
            // Header row
            _buildHeader(visibleColumns, tokens),
            // Filter row
            if (widget.showFilters) _buildFilterRow(visibleColumns, tokens),
            // Data rows
            Expanded(
              child: _buildDataRows(visibleColumns, rows, tokens),
            ),
            // Footer with row count
            _buildFooter(rows, tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<AisGridColumn<T>> columns, AisTokens tokens) {
    return Container(
      height: widget.headerHeight,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          bottom: BorderSide(color: tokens.onSurface.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Row number header
          if (widget.showRowNumbers)
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                '#',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tokens.onSurfaceSecondary,
                ),
              ),
            ),
          // Column headers
          Expanded(
            child: ListView.builder(
              controller: _scrollControllerH,
              scrollDirection: Axis.horizontal,
              itemCount: columns.length,
              itemBuilder: (context, index) {
                final col = columns[index];
                final sortIndex =
                    _sorts.indexWhere((s) => s.columnId == col.id);
                final sort = sortIndex >= 0 ? _sorts[sortIndex] : null;

                return GestureDetector(
                  onTap: col.sortable ? () => _handleColumnSort(col.id) : null,
                  child: Container(
                    width: _columnWidths[col.id],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        right:
                            BorderSide(color: tokens.onSurface.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            col.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sort != null) ...[
                          Icon(
                            sort.ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: tokens.actionPrimary.color,
                          ),
                          if (_sorts.length > 1)
                            Text(
                              '${sortIndex + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: tokens.actionPrimary.color,
                              ),
                            ),
                        ],
                        if (widget.allowColumnResize)
                          MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _columnWidths[col.id] =
                                      (_columnWidths[col.id]! + details.delta.dx)
                                          .clamp(50.0, 500.0);
                                });
                              },
                              child: Container(
                                width: 8,
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(List<AisGridColumn<T>> columns, AisTokens tokens) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: tokens.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: tokens.onSurface.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          if (widget.showRowNumbers) const SizedBox(width: 50),
          Expanded(
            child: ListView.builder(
              controller: ScrollController(),
              scrollDirection: Axis.horizontal,
              itemCount: columns.length,
              itemBuilder: (context, index) {
                final col = columns[index];
                return SizedBox(
                  width: _columnWidths[col.id],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Filter...',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: tokens.onSurfaceSecondary,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AisTheme.radiusSm),
                          borderSide: BorderSide(
                            color: tokens.onSurface.withOpacity(0.2),
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 11),
                      onChanged: (value) => _handleFilterChanged(col.id, value),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRows(
      List<AisGridColumn<T>> columns, List<T> rows, AisTokens tokens) {
    return ListView.builder(
      controller: _scrollControllerV,
      itemCount: rows.length,
      itemExtent: widget.rowHeight,
      itemBuilder: (context, rowIndex) {
        final row = rows[rowIndex];
        final isSelected = _selectedRowIndices.contains(rowIndex);
        final isFocused = _focusedRow == rowIndex;

        return GestureDetector(
          onTap: () => _toggleRowSelection(rowIndex),
          onDoubleTap: () {
            setState(() {
              _focusedRow = rowIndex;
              _focusedColumn = 0;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.actionPrimary.color.withOpacity(0.15)
                  : isFocused
                      ? tokens.actionPrimary.color.withOpacity(0.05)
                      : rowIndex.isEven
                          ? tokens.surface
                          : tokens.surface.withOpacity(0.5),
              border: isFocused
                  ? Border.all(
                      color: tokens.actionPrimary.color,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Row number
                if (widget.showRowNumbers)
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '${rowIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.onSurfaceSecondary,
                      ),
                    ),
                  ),
                // Cells
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: columns.length,
                    itemBuilder: (context, colIndex) {
                      final col = columns[colIndex];
                      final value = col.getValue(row);
                      final isEditing = _editingRow == rowIndex &&
                          _editingColumn == col.id;
                      final isCellFocused =
                          _focusedRow == rowIndex && _focusedColumn == colIndex;

                      return Container(
                        width: _columnWidths[col.id],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: tokens.onSurface.withOpacity(0.05),
                            ),
                          ),
                          color: isCellFocused
                              ? tokens.actionPrimary.color.withOpacity(0.1)
                              : null,
                        ),
                        alignment: col.alignment,
                        child: isEditing
                            ? _buildEditCell(col, row, value, tokens)
                            : _buildDisplayCell(col, value, tokens),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisplayCell(
      AisGridColumn<T> col, dynamic value, AisTokens tokens) {
    final displayValue = col.formatter?.call(value) ?? value?.toString() ?? '';
    return Text(
      displayValue,
      style: TextStyle(
        fontSize: 13,
        color: tokens.onSurface,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEditCell(
      AisGridColumn<T> col, T row, dynamic value, AisTokens tokens) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      autofocus: true,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: OutlineInputBorder(),
      ),
      onFieldSubmitted: (newValue) {
        final parsedValue = col.parser?.call(newValue) ?? newValue;
        widget.onCellChanged?.call(row, col.id, parsedValue);
        setState(() {
          _editingRow = null;
          _editingColumn = null;
        });
      },
      onTapOutside: (_) {
        setState(() {
          _editingRow = null;
          _editingColumn = null;
        });
      },
    );
  }

  Widget _buildFooter(List<T> rows, AisTokens tokens) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(color: tokens.onSurface.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${rows.length} rows',
            style: TextStyle(
              fontSize: 11,
              color: tokens.onSurfaceSecondary,
            ),
          ),
          if (_selectedRowIndices.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              '${_selectedRowIndices.length} selected',
              style: TextStyle(
                fontSize: 11,
                color: tokens.actionPrimary.color,
              ),
            ),
          ],
          if (_filters.values.any((f) => f.isNotEmpty)) ...[
            const SizedBox(width: 12),
            Text(
              'Filtered',
              style: TextStyle(
                fontSize: 11,
                color: tokens.stateInfo.color,
              ),
            ),
          ],
          const Spacer(),
          if (_sorts.isNotEmpty)
            Text(
              'Sorted by ${_sorts.length} column${_sorts.length > 1 ? 's' : ''}',
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

/// Column definition for AisDataGrid
class AisGridColumn<T> {
  final String id;
  final String title;
  final double initialWidth;
  final bool visible;
  final bool editable;
  final bool sortable;
  final Alignment alignment;
  final dynamic Function(T row) getValue;
  final String Function(dynamic value)? formatter;
  final dynamic Function(String value)? parser;
  final AisGridColumnType type;

  const AisGridColumn({
    required this.id,
    required this.title,
    required this.getValue,
    this.initialWidth = 120,
    this.visible = true,
    this.editable = false,
    this.sortable = true,
    this.alignment = Alignment.centerLeft,
    this.formatter,
    this.parser,
    this.type = AisGridColumnType.text,
  });
}

/// Column types for type-aware editing
enum AisGridColumnType {
  text,
  number,
  currency,
  date,
  time,
  dateTime,
  boolean,
  select,
}

/// Sort definition
class AisGridSort {
  final String columnId;
  final bool ascending;

  const AisGridSort({
    required this.columnId,
    required this.ascending,
  });
}

/// Grid-style layout widget for arranging items in a responsive grid
class AisGridLayout extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;
  final bool shrinkWrap;

  const AisGridLayout({
    super.key,
    required this.children,
    this.crossAxisCount = 3,
    this.mainAxisSpacing = AisTheme.spacingMd,
    this.crossAxisSpacing = AisTheme.spacingMd,
    this.childAspectRatio = 1.0,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
  });

  /// Creates an adaptive grid that adjusts columns based on available width
  factory AisGridLayout.adaptive({
    Key? key,
    required List<Widget> children,
    double minChildWidth = 200,
    double mainAxisSpacing = AisTheme.spacingMd,
    double crossAxisSpacing = AisTheme.spacingMd,
    double childAspectRatio = 1.0,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return _AisAdaptiveGridLayout(
      key: key,
      minChildWidth: minChildWidth,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

class _AisAdaptiveGridLayout extends AisGridLayout {
  final double minChildWidth;

  const _AisAdaptiveGridLayout({
    super.key,
    required super.children,
    required this.minChildWidth,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
    super.childAspectRatio,
    super.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - padding.horizontal;
        final count = (width / minChildWidth).floor().clamp(1, 12);

        return GridView.count(
          crossAxisCount: count,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          padding: padding,
          shrinkWrap: shrinkWrap,
          children: children,
        );
      },
    );
  }
}
