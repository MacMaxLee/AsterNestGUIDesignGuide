import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Autocomplete Component (§3.5)
///
/// A type-ahead autocomplete component with customizable suggestion filtering,
/// keyboard navigation, and selection handling. Follows AIS token conventions.
///
/// Features:
/// - Type-ahead filtering with debounce
/// - Keyboard navigation (up/down arrows, enter, escape)
/// - Custom suggestion rendering
/// - Clear button
/// - Loading state
/// - Error state
/// - Accessibility support

/// Style variations for the autocomplete component
enum AisAutocompleteStyle {
  /// Standard text field with dropdown
  standard,
  /// Outlined border style
  outlined,
  /// Filled background style
  filled,
}

/// Generic autocomplete widget that works with any data type
class AisAutocomplete<T> extends StatefulWidget {
  /// Controller for the text field
  final TextEditingController? controller;

  /// List of suggestions to display
  final List<T> suggestions;

  /// Function to get display text from an item
  final String Function(T) displayText;

  /// Optional function to get secondary text from an item
  final String Function(T)? secondaryText;

  /// Optional function to get an icon for each item
  final IconData Function(T)? itemIcon;

  /// Placeholder text
  final String placeholder;

  /// Called when an item is selected
  final void Function(T)? onSelected;

  /// Called when text changes (for filtering)
  final void Function(String)? onTextChanged;

  /// Visual style
  final AisAutocompleteStyle style;

  /// Maximum number of suggestions to show
  final int maxSuggestions;

  /// Whether the component is loading
  final bool isLoading;

  /// Whether the component is disabled
  final bool isDisabled;

  /// Error message to display
  final String? errorMessage;

  /// Current selection (for highlighting)
  final T? selectedItem;

  /// Function to compare items for equality
  final bool Function(T, T)? itemEquals;

  const AisAutocomplete({
    super.key,
    this.controller,
    required this.suggestions,
    required this.displayText,
    this.secondaryText,
    this.itemIcon,
    this.placeholder = 'Search...',
    this.onSelected,
    this.onTextChanged,
    this.style = AisAutocompleteStyle.standard,
    this.maxSuggestions = 8,
    this.isLoading = false,
    this.isDisabled = false,
    this.errorMessage,
    this.selectedItem,
    this.itemEquals,
  });

  @override
  State<AisAutocomplete<T>> createState() => _AisAutocompleteState<T>();
}

class _AisAutocompleteState<T> extends State<AisAutocomplete<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  int _highlightedIndex = -1;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay to allow click on suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null || widget.suggestions.isEmpty) return;

    _isExpanded = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _isExpanded = false;
    _highlightedIndex = -1;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  List<T> get _visibleSuggestions {
    return widget.suggestions.take(widget.maxSuggestions).toList();
  }

  bool _itemEquals(T a, T b) {
    if (widget.itemEquals != null) {
      return widget.itemEquals!(a, b);
    }
    return a == b;
  }

  void _selectItem(T item) {
    _controller.text = widget.displayText(item);
    widget.onSelected?.call(item);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1) % _visibleSuggestions.length;
      });
      _updateOverlay();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = _highlightedIndex <= 0
            ? _visibleSuggestions.length - 1
            : _highlightedIndex - 1;
      });
      _updateOverlay();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _visibleSuggestions.length) {
        _selectItem(_visibleSuggestions[_highlightedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
      _focusNode.unfocus();
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final tokens = context.aisTokens;
    final suggestions = _visibleSuggestions;

    if (suggestions.isEmpty || _controller.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
        border: Border.all(
          color: tokens.onSurfaceSecondary.withOpacity(0.2),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final item = suggestions[index];
          final isHighlighted = index == _highlightedIndex;
          final isSelected = widget.selectedItem != null &&
              _itemEquals(item, widget.selectedItem as T);

          return InkWell(
            onTap: () => _selectItem(item),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AisTheme.spacingMd,
                vertical: AisTheme.spacingSm,
              ),
              color: isHighlighted
                  ? tokens.surfaceSecondary
                  : Colors.transparent,
              child: Row(
                children: [
                  // Optional icon
                  if (widget.itemIcon != null) ...[
                    Icon(
                      widget.itemIcon!(item),
                      size: 20,
                      color: isSelected
                          ? tokens.actionPrimary.color
                          : tokens.onSurfaceSecondary,
                    ),
                    const SizedBox(width: AisTheme.spacingSm),
                  ],

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayText(item),
                          style: TextStyle(
                            color: tokens.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.secondaryText != null)
                          Text(
                            widget.secondaryText!(item),
                            style: TextStyle(
                              color: tokens.onSurfaceSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: tokens.actionPrimary.color,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    final borderColor = widget.errorMessage != null
        ? tokens.actionDestructive.color
        : _focusNode.hasFocus
            ? tokens.actionPrimary.color
            : tokens.onSurfaceSecondary.withOpacity(0.3);

    final backgroundColor = widget.style == AisAutocompleteStyle.filled
        ? tokens.surfaceSecondary
        : tokens.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyEvent,
            child: Opacity(
              opacity: widget.isDisabled ? 0.6 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                  border: Border.all(
                    color: borderColor,
                    width: widget.style == AisAutocompleteStyle.outlined ||
                            _focusNode.hasFocus
                        ? 1.5
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Search icon
                    Padding(
                      padding: const EdgeInsets.only(left: AisTheme.spacingMd),
                      child: Icon(
                        Icons.search,
                        size: 20,
                        color: tokens.onSurfaceSecondary,
                      ),
                    ),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !widget.isDisabled,
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          hintStyle: TextStyle(
                            color: tokens.onSurfaceSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AisTheme.spacingSm,
                            vertical: AisTheme.spacingMd,
                          ),
                        ),
                        style: TextStyle(
                          color: tokens.onSurface,
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          widget.onTextChanged?.call(value);
                          _highlightedIndex = -1;
                          if (value.isNotEmpty && !_isExpanded) {
                            _showOverlay();
                          }
                          _updateOverlay();
                        },
                      ),
                    ),

                    // Loading indicator
                    if (widget.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: AisTheme.spacingSm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),

                    // Clear button
                    if (_controller.text.isNotEmpty && !widget.isLoading)
                      IconButton(
                        icon: Icon(
                          Icons.cancel,
                          size: 20,
                          color: tokens.onSurfaceSecondary,
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onTextChanged?.call('');
                          _updateOverlay();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Error message
        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: AisTheme.spacingXs),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: tokens.actionDestructive.color,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.errorMessage!,
                  style: TextStyle(
                    color: tokens.actionDestructive.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Simple string autocomplete for convenience
class AisStringAutocomplete extends StatelessWidget {
  final TextEditingController? controller;
  final List<String> suggestions;
  final String placeholder;
  final void Function(String)? onSelected;
  final void Function(String)? onTextChanged;
  final AisAutocompleteStyle style;
  final bool isLoading;
  final bool isDisabled;
  final String? errorMessage;

  const AisStringAutocomplete({
    super.key,
    this.controller,
    required this.suggestions,
    this.placeholder = 'Search...',
    this.onSelected,
    this.onTextChanged,
    this.style = AisAutocompleteStyle.standard,
    this.isLoading = false,
    this.isDisabled = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AisAutocomplete<String>(
      controller: controller,
      suggestions: suggestions,
      displayText: (s) => s,
      placeholder: placeholder,
      onSelected: onSelected,
      onTextChanged: onTextChanged,
      style: style,
      isLoading: isLoading,
      isDisabled: isDisabled,
      errorMessage: errorMessage,
    );
  }
}
