import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:crypto/crypto.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// Supported media types for AisMediaPicker
enum AisMediaType {
  image('Image', Icons.image_rounded, ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp']),
  video('Video', Icons.video_file_rounded, ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v']),
  audio('Audio', Icons.audio_file_rounded, ['.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a']),
  pdf('PDF', Icons.picture_as_pdf_rounded, ['.pdf']),
  csv('CSV', Icons.table_chart_rounded, ['.csv']),
  text('Text', Icons.description_rounded, ['.txt', '.md', '.json', '.xml', '.html']),
  document('Document', Icons.article_rounded, ['.doc', '.docx', '.odt', '.rtf']),
  spreadsheet('Spreadsheet', Icons.grid_on_rounded, ['.xls', '.xlsx', '.ods']),
  any('Any', Icons.insert_drive_file_rounded, []);

  final String label;
  final IconData icon;
  final List<String> extensions;

  const AisMediaType(this.label, this.icon, this.extensions);

  /// Get media type from file extension
  static AisMediaType fromExtension(String extension) {
    final ext = extension.toLowerCase();
    for (final type in AisMediaType.values) {
      if (type.extensions.contains(ext)) {
        return type;
      }
    }
    return AisMediaType.any;
  }
}

/// File information returned by AisMediaPicker
/// Contains all necessary information for database handling
class AisFileInfo {
  /// Original file name with extension
  final String fileName;

  /// File extension (e.g., '.pdf', '.jpg')
  final String extension;

  /// MIME type (e.g., 'image/jpeg', 'application/pdf')
  final String mimeType;

  /// File size in bytes
  final int sizeBytes;

  /// Folder/directory path where file is located
  final String folderPath;

  /// Full file path including filename
  final String fullPath;

  /// Media type classification
  final AisMediaType mediaType;

  /// File creation timestamp
  final DateTime? createdAt;

  /// File modification timestamp
  final DateTime? modifiedAt;

  /// Unique identifier for database reference
  final String id;

  /// Optional thumbnail path for images/videos
  final String? thumbnailPath;

  /// Duration in seconds (for audio/video)
  final int? durationSeconds;

  /// Width in pixels (for images/videos)
  final int? width;

  /// Height in pixels (for images/videos)
  final int? height;

  /// Checksum/hash for integrity verification
  final String? checksum;

  /// Upload status
  final AisUploadStatus status;

  /// Error message if upload failed
  final String? errorMessage;

  /// File bytes (for in-memory handling)
  final List<int>? bytes;

  const AisFileInfo({
    required this.fileName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.folderPath,
    required this.fullPath,
    required this.mediaType,
    required this.id,
    this.createdAt,
    this.modifiedAt,
    this.thumbnailPath,
    this.durationSeconds,
    this.width,
    this.height,
    this.checksum,
    this.status = AisUploadStatus.pending,
    this.errorMessage,
    this.bytes,
  });

  /// Human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Duration formatted as HH:MM:SS or MM:SS
  String? get formattedDuration {
    if (durationSeconds == null) return null;
    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dimensions formatted as WxH
  String? get formattedDimensions {
    if (width == null || height == null) return null;
    return '${width}x$height';
  }

  /// Check if file exists on disk
  bool get existsOnDisk => fullPath.isNotEmpty && File(fullPath).existsSync();

  /// Copy with updated status
  AisFileInfo copyWith({
    AisUploadStatus? status,
    String? errorMessage,
    String? checksum,
    String? thumbnailPath,
    int? width,
    int? height,
    int? durationSeconds,
  }) {
    return AisFileInfo(
      fileName: fileName,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      folderPath: folderPath,
      fullPath: fullPath,
      mediaType: mediaType,
      id: id,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      width: width ?? this.width,
      height: height ?? this.height,
      checksum: checksum ?? this.checksum,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      bytes: bytes,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'extension': extension,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'folderPath': folderPath,
      'fullPath': fullPath,
      'mediaType': mediaType.name,
      'createdAt': createdAt?.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'durationSeconds': durationSeconds,
      'width': width,
      'height': height,
      'checksum': checksum,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  /// Create from database map
  factory AisFileInfo.fromMap(Map<String, dynamic> map) {
    return AisFileInfo(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      extension: map['extension'] as String,
      mimeType: map['mimeType'] as String,
      sizeBytes: map['sizeBytes'] as int,
      folderPath: map['folderPath'] as String,
      fullPath: map['fullPath'] as String,
      mediaType: AisMediaType.values.firstWhere(
        (t) => t.name == map['mediaType'],
        orElse: () => AisMediaType.any,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      modifiedAt: map['modifiedAt'] != null
          ? DateTime.parse(map['modifiedAt'] as String)
          : null,
      thumbnailPath: map['thumbnailPath'] as String?,
      durationSeconds: map['durationSeconds'] as int?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      checksum: map['checksum'] as String?,
      status: AisUploadStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => AisUploadStatus.pending,
      ),
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// Create from PlatformFile (file_picker result)
  static Future<AisFileInfo> fromPlatformFile(PlatformFile file) async {
    final ext = '.${file.extension ?? ''}';
    final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';
    final mediaType = AisMediaType.fromExtension(ext);

    DateTime? createdAt;
    DateTime? modifiedAt;
    String? checksum;

    // Get file stats if path is available
    if (file.path != null) {
      try {
        final fileStat = await File(file.path!).stat();
        createdAt = fileStat.changed;
        modifiedAt = fileStat.modified;

        // Calculate MD5 checksum for smaller files (< 10MB)
        if (file.size < 10 * 1024 * 1024) {
          final bytes = await File(file.path!).readAsBytes();
          checksum = md5.convert(bytes).toString();
        }
      } catch (_) {
        // Ignore stat errors
      }
    }

    return AisFileInfo(
      id: '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}',
      fileName: file.name,
      extension: ext,
      mimeType: mimeType,
      sizeBytes: file.size,
      folderPath: file.path != null ? p.dirname(file.path!) : '',
      fullPath: file.path ?? '',
      mediaType: mediaType,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      checksum: checksum,
      status: AisUploadStatus.completed,
      bytes: file.bytes,
    );
  }
}

/// Upload status for files
enum AisUploadStatus {
  pending,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Media picker widget with upload/download support
class AisMediaPicker extends StatefulWidget {
  /// Allowed media types
  final List<AisMediaType> allowedTypes;

  /// Maximum file size in bytes (null = unlimited)
  final int? maxSizeBytes;

  /// Allow multiple file selection
  final bool multiple;

  /// Maximum number of files (for multiple selection)
  final int? maxFiles;

  /// Called when files are selected
  final void Function(List<AisFileInfo> files)? onFilesSelected;

  /// Called when upload completes
  final void Function(AisFileInfo file)? onUploadComplete;

  /// Called when upload fails
  final void Function(AisFileInfo file, String error)? onUploadError;

  /// Called when download is requested
  final void Function(AisFileInfo file)? onDownloadRequested;

  /// Custom upload handler
  final Future<AisFileInfo> Function(AisFileInfo file)? uploadHandler;

  /// Currently selected files
  final List<AisFileInfo>? selectedFiles;

  /// Whether to show preview thumbnails
  final bool showPreviews;

  /// Whether to show file details
  final bool showDetails;

  /// Custom label
  final String? label;

  /// Hint text
  final String? hint;

  /// Whether picker is enabled
  final bool enabled;

  const AisMediaPicker({
    super.key,
    this.allowedTypes = const [AisMediaType.any],
    this.maxSizeBytes,
    this.multiple = false,
    this.maxFiles,
    this.onFilesSelected,
    this.onUploadComplete,
    this.onUploadError,
    this.onDownloadRequested,
    this.uploadHandler,
    this.selectedFiles,
    this.showPreviews = true,
    this.showDetails = true,
    this.label,
    this.hint,
    this.enabled = true,
  });

  @override
  State<AisMediaPicker> createState() => _AisMediaPickerState();
}

class _AisMediaPickerState extends State<AisMediaPicker> {
  List<AisFileInfo> _files = [];
  bool _isDragging = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _files = widget.selectedFiles ?? [];
  }

  @override
  void didUpdateWidget(AisMediaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFiles != oldWidget.selectedFiles) {
      _files = widget.selectedFiles ?? [];
    }
  }

  List<String> get _allowedExtensionsList {
    return widget.allowedTypes
        .expand((t) => t.extensions)
        .map((e) => e.replaceFirst('.', ''))
        .toSet()
        .toList();
  }

  String get _allowedExtensions {
    final exts = widget.allowedTypes
        .expand((t) => t.extensions)
        .toSet()
        .toList();
    if (exts.isEmpty) return 'All files';
    return exts.join(', ');
  }

  String get _maxSizeText {
    if (widget.maxSizeBytes == null) return '';
    final mb = widget.maxSizeBytes! / (1024 * 1024);
    return 'Max ${mb.toStringAsFixed(0)} MB';
  }

  FileType get _fileType {
    if (widget.allowedTypes.contains(AisMediaType.any)) {
      return FileType.any;
    }
    if (widget.allowedTypes.length == 1) {
      switch (widget.allowedTypes.first) {
        case AisMediaType.image:
          return FileType.image;
        case AisMediaType.video:
          return FileType.video;
        case AisMediaType.audio:
          return FileType.audio;
        default:
          return FileType.custom;
      }
    }
    return FileType.custom;
  }

  Future<void> _pickFiles() async {
    if (!widget.enabled || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: _fileType,
        allowMultiple: widget.multiple,
        allowedExtensions: _fileType == FileType.custom ? _allowedExtensionsList : null,
        withData: true, // Include bytes for web compatibility
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = <AisFileInfo>[];

        for (final file in result.files) {
          // Check file size
          if (widget.maxSizeBytes != null && file.size > widget.maxSizeBytes!) {
            setState(() {
              _errorMessage = '${file.name} exceeds maximum size of $_maxSizeText';
            });
            continue;
          }

          // Check file extension
          final ext = '.${file.extension ?? ''}'.toLowerCase();
          if (!widget.allowedTypes.contains(AisMediaType.any)) {
            final isAllowed = widget.allowedTypes.any((t) => t.extensions.contains(ext));
            if (!isAllowed) {
              setState(() {
                _errorMessage = '${file.name} is not an allowed file type';
              });
              continue;
            }
          }

          // Create file info
          final fileInfo = await AisFileInfo.fromPlatformFile(file);
          newFiles.add(fileInfo);
        }

        if (newFiles.isNotEmpty) {
          setState(() {
            if (widget.multiple) {
              // Check max files limit
              final totalFiles = _files.length + newFiles.length;
              if (widget.maxFiles != null && totalFiles > widget.maxFiles!) {
                final allowedCount = widget.maxFiles! - _files.length;
                _files.addAll(newFiles.take(allowedCount));
                _errorMessage = 'Maximum ${widget.maxFiles} files allowed';
              } else {
                _files.addAll(newFiles);
              }
            } else {
              _files = [newFiles.first];
            }
          });

          widget.onFilesSelected?.call(_files);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking files: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeFile(AisFileInfo file) {
    setState(() {
      _files.removeWhere((f) => f.id == file.id);
      _errorMessage = null;
    });
    widget.onFilesSelected?.call(_files);
  }

  void _showFileDetails(AisFileInfo file) {
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
          if (file.fullPath.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Show in Folder'),
              onPressed: () async {
                Navigator.of(context).pop();
                // Platform-specific folder reveal would go here
              },
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: widget.enabled ? tokens.onSurface : tokens.onSurfaceSecondary,
            ),
          ),
          const SizedBox(height: AisTheme.spacingSm),
        ],

        // Drop zone
        _buildDropZone(tokens),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: AisTheme.spacingSm),
          Container(
            padding: const EdgeInsets.all(AisTheme.spacingSm),
            decoration: BoxDecoration(
              color: tokens.stateError.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  tokens.stateError.icon,
                  size: 16,
                  color: tokens.stateError.color,
                ),
                const SizedBox(width: AisTheme.spacingSm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.stateError.color,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => setState(() => _errorMessage = null),
                ),
              ],
            ),
          ),
        ],

        // Selected files list
        if (_files.isNotEmpty) ...[
          const SizedBox(height: AisTheme.spacingMd),
          _buildFileList(tokens),
        ],
      ],
    );
  }

  Widget _buildDropZone(AisTokens tokens) {
    return GestureDetector(
      onTap: widget.enabled ? _pickFiles : null,
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (_) {
          if (!widget.enabled) return false;
          setState(() => _isDragging = true);
          return true;
        },
        onLeave: (_) {
          setState(() => _isDragging = false);
        },
        onAcceptWithDetails: (_) {
          setState(() => _isDragging = false);
          _pickFiles();
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = widget.enabled && !_isLoading;
          return Container(
            padding: const EdgeInsets.all(AisTheme.spacingLg),
            decoration: BoxDecoration(
              color: _isDragging
                  ? tokens.actionPrimary.color.withOpacity(0.1)
                  : isActive
                      ? tokens.surface
                      : tokens.surfaceSecondary,
              border: Border.all(
                color: _isDragging
                    ? tokens.actionPrimary.color
                    : isActive
                        ? tokens.onSurface.withOpacity(0.2)
                        : tokens.onSurface.withOpacity(0.1),
                width: _isDragging ? 2 : 1,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(AisTheme.radiusMd),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: tokens.actionPrimary.color,
                    ),
                  )
                else
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 48,
                    color: _isDragging
                        ? tokens.actionPrimary.color
                        : isActive
                            ? tokens.onSurfaceSecondary
                            : tokens.onSurfaceSecondary.withOpacity(0.5),
                  ),
                const SizedBox(height: AisTheme.spacingSm),
                Text(
                  _isLoading
                      ? 'Processing files...'
                      : widget.hint ?? 'Drop files here or click to browse',
                  style: TextStyle(
                    color: _isDragging
                        ? tokens.actionPrimary.color
                        : isActive
                            ? tokens.onSurfaceSecondary
                            : tokens.onSurfaceSecondary.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AisTheme.spacingXs),
                Text(
                  _allowedExtensions,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary.withOpacity(isActive ? 1 : 0.5),
                  ),
                ),
                if (_maxSizeText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _maxSizeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.onSurfaceSecondary.withOpacity(isActive ? 1 : 0.5),
                    ),
                  ),
                ],
                if (widget.multiple) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.maxFiles != null
                        ? 'Up to ${widget.maxFiles} files'
                        : 'Multiple files allowed',
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.onSurfaceSecondary.withOpacity(isActive ? 1 : 0.5),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileList(AisTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AisTheme.spacingMd,
              vertical: AisTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AisTheme.radiusMd),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: tokens.onSurfaceSecondary,
                ),
                const SizedBox(width: AisTheme.spacingSm),
                Text(
                  '${_files.length} file${_files.length > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
                const Spacer(),
                if (_files.length > 1)
                  TextButton(
                    onPressed: () {
                      setState(() => _files.clear());
                      widget.onFilesSelected?.call(_files);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.actionDestructive.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // File items
          ..._files.map((file) => _buildFileItem(file, tokens)),
        ],
      ),
    );
  }

  Widget _buildFileItem(AisFileInfo file, AisTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.onSurface.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // File type icon with preview
          GestureDetector(
            onTap: () => _showFileDetails(file),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getMediaColor(file.mediaType, tokens).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusSm),
              ),
              child: widget.showPreviews &&
                     file.mediaType == AisMediaType.image &&
                     file.fullPath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                      child: Image.file(
                        File(file.fullPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          file.mediaType.icon,
                          color: _getMediaColor(file.mediaType, tokens),
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      file.mediaType.icon,
                      color: _getMediaColor(file.mediaType, tokens),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: AisTheme.spacingMd),

          // File info
          Expanded(
            child: GestureDetector(
              onTap: () => _showFileDetails(file),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: tokens.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.showDetails) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          file.formattedSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          file.extension.toUpperCase().replaceFirst('.', ''),
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.onSurfaceSecondary,
                          ),
                        ),
                        if (file.formattedDimensions != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            file.formattedDimensions!,
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.onSurfaceSecondary,
                            ),
                          ),
                        ],
                        if (file.formattedDuration != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            file.formattedDuration!,
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.onSurfaceSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (file.folderPath.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        file.folderPath,
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.onSurfaceSecondary.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Status indicator
          _buildStatusIndicator(file, tokens),

          const SizedBox(width: AisTheme.spacingSm),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (file.status == AisUploadStatus.completed)
                IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: tokens.stateInfo.color,
                  ),
                  tooltip: 'View Details',
                  onPressed: () => _showFileDetails(file),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: tokens.actionDestructive.color,
                ),
                tooltip: 'Remove',
                onPressed: widget.enabled ? () => _removeFile(file) : null,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(AisFileInfo file, AisTokens tokens) {
    switch (file.status) {
      case AisUploadStatus.pending:
        return Icon(
          Icons.schedule_rounded,
          size: 16,
          color: tokens.stateWarning.color,
        );
      case AisUploadStatus.uploading:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(tokens.actionPrimary.color),
          ),
        );
      case AisUploadStatus.completed:
        return Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: tokens.actionConfirm.color,
        );
      case AisUploadStatus.failed:
        return Tooltip(
          message: file.errorMessage ?? 'Upload failed',
          child: Icon(
            Icons.error_rounded,
            size: 16,
            color: tokens.stateError.color,
          ),
        );
      case AisUploadStatus.cancelled:
        return Icon(
          Icons.cancel_rounded,
          size: 16,
          color: tokens.stateUnavailable.color,
        );
    }
  }

  Color _getMediaColor(AisMediaType type, AisTokens tokens) {
    switch (type) {
      case AisMediaType.image:
        return Colors.green;
      case AisMediaType.video:
        return Colors.purple;
      case AisMediaType.audio:
        return Colors.orange;
      case AisMediaType.pdf:
        return Colors.red;
      case AisMediaType.csv:
      case AisMediaType.spreadsheet:
        return Colors.teal;
      case AisMediaType.text:
      case AisMediaType.document:
        return Colors.blue;
      case AisMediaType.any:
        return tokens.onSurfaceSecondary;
    }
  }
}

/// Compact file chip for displaying selected files inline
class AisFileChip extends StatelessWidget {
  final AisFileInfo file;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const AisFileChip({
    super.key,
    required this.file,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AisTheme.spacingSm,
          vertical: AisTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.onSurface.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(AisTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              file.mediaType.icon,
              size: 14,
              color: tokens.onSurfaceSecondary,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                file.fileName,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              file.formattedSize,
              style: TextStyle(
                fontSize: 10,
                color: tokens.onSurfaceSecondary,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: tokens.onSurfaceSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// File info display for showing detailed file information
class AisFileInfoDisplay extends StatelessWidget {
  final AisFileInfo file;
  final bool showFullPath;
  final bool showMetadata;

  const AisFileInfoDisplay({
    super.key,
    required this.file,
    this.showFullPath = true,
    this.showMetadata = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Container(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and name
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tokens.stateInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                  ),
                  child: Icon(
                    file.mediaType.icon,
                    color: tokens.stateInfo.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AisTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${file.mediaType.label} • ${file.formattedSize}',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.onSurfaceSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (showMetadata) ...[
              const SizedBox(height: AisTheme.spacingMd),
              const Divider(height: 1),
              const SizedBox(height: AisTheme.spacingMd),

              // Metadata table
              _buildInfoRow('ID', file.id, tokens),
              _buildInfoRow('Extension', file.extension, tokens),
              _buildInfoRow('MIME Type', file.mimeType, tokens),
              _buildInfoRow('Size', '${file.sizeBytes} bytes (${file.formattedSize})', tokens),
              if (showFullPath && file.folderPath.isNotEmpty) ...[
                _buildInfoRow('Folder', file.folderPath, tokens),
                _buildInfoRow('Full Path', file.fullPath, tokens),
              ],
              if (file.createdAt != null)
                _buildInfoRow('Created', file.createdAt!.toIso8601String(), tokens),
              if (file.modifiedAt != null)
                _buildInfoRow('Modified', file.modifiedAt!.toIso8601String(), tokens),
              if (file.formattedDimensions != null)
                _buildInfoRow('Dimensions', file.formattedDimensions!, tokens),
              if (file.formattedDuration != null)
                _buildInfoRow('Duration', file.formattedDuration!, tokens),
              if (file.checksum != null)
                _buildInfoRow('Checksum (MD5)', file.checksum!, tokens),
              _buildInfoRow('Status', file.status.name.toUpperCase(), tokens),
              _buildInfoRow('Exists on Disk', file.existsOnDisk ? 'Yes' : 'No', tokens),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AisTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AisTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: tokens.onSurfaceSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
