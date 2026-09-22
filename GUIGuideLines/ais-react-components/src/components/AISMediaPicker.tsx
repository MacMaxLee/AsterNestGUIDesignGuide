/**
 * AISMediaPicker.tsx
 * Asternest Interface Standard (AIS) v1.0 - React/TypeScript Implementation
 *
 * PURPOSE:
 * Provides file and media selection capabilities with complete metadata
 * extraction for database storage. This component bridges the gap between
 * user file selection and structured data persistence.
 *
 * KEY REQUIREMENTS (AIS Conformance):
 * 1. FILE METADATA: Extract complete file information for database storage
 * 2. CHECKSUM VALIDATION: Compute MD5/SHA hash for file integrity verification
 * 3. MIME TYPE DETECTION: Properly identify file types for handling
 * 4. ERROR HANDLING: Graceful failure with informative error states
 */

import React, { useRef, useState, useCallback, useEffect } from 'react';
import clsx from 'clsx';
import type { LucideIcon } from 'lucide-react';
import {
  Upload,
  X,
  File as FileIcon,
  Image,
  Video,
  Music,
  FileText,
  Table,
  Check,
  AlertCircle,
  Clock,
  Loader2,
  Copy,
  Camera,
  Clipboard,
  Folder,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';

// ============================================================================
// Input Source Types
// ============================================================================

/**
 * Input sources for media picker
 */
export type AISInputSource = 'files' | 'camera' | 'clipboard';

/**
 * Input source configuration
 */
interface InputSourceConfig {
  label: string;
  icon: LucideIcon;
  isAvailable: boolean;
}

const INPUT_SOURCE_CONFIG: Record<AISInputSource, InputSourceConfig> = {
  files: {
    label: 'Browse Files',
    icon: Folder,
    isAvailable: true,
  },
  camera: {
    label: 'Camera',
    icon: Camera,
    // Camera is available via MediaDevices API in modern browsers
    isAvailable: typeof navigator !== 'undefined' && !!navigator.mediaDevices?.getUserMedia,
  },
  clipboard: {
    label: 'Paste',
    icon: Clipboard,
    isAvailable: typeof navigator !== 'undefined' && !!navigator.clipboard?.read,
  },
};

// ============================================================================
// Types
// ============================================================================

/**
 * Supported media types for AISMediaPicker
 */
export type AISMediaType =
  | 'image'
  | 'video'
  | 'audio'
  | 'pdf'
  | 'csv'
  | 'text'
  | 'document'
  | 'spreadsheet'
  | 'any';

/**
 * Upload status for files
 */
export type AISUploadStatus =
  | 'pending'
  | 'uploading'
  | 'completed'
  | 'failed'
  | 'cancelled';

/**
 * File information returned by AISMediaPicker
 * Contains all necessary information for database handling
 */
export interface AISFileInfo {
  /** Unique identifier for database reference */
  id: string;
  /** Original file name with extension */
  fileName: string;
  /** File extension (e.g., '.pdf', '.jpg') */
  extension: string;
  /** MIME type (e.g., 'image/jpeg', 'application/pdf') */
  mimeType: string;
  /** File size in bytes */
  sizeBytes: number;
  /** Folder/directory path where file is located */
  folderPath: string;
  /** Full file path including filename */
  fullPath: string;
  /** Media type classification */
  mediaType: AISMediaType;
  /** File creation timestamp */
  createdAt?: Date;
  /** File modification timestamp */
  modifiedAt?: Date;
  /** Checksum/hash for integrity verification */
  checksum?: string;
  /** Upload status */
  status: AISUploadStatus;
  /** Error message if upload failed */
  errorMessage?: string;
  /** Raw File object for upload */
  file?: File;
  /** Preview URL for images */
  previewUrl?: string;
  /** Width in pixels (for images/videos) */
  width?: number;
  /** Height in pixels (for images/videos) */
  height?: number;
  /** Duration in seconds (for audio/video) */
  durationSeconds?: number;
}

/**
 * Media type configuration
 */
interface MediaTypeConfig {
  label: string;
  icon: LucideIcon;
  extensions: string[];
  accept: string;
}

const MEDIA_TYPE_CONFIG: Record<AISMediaType, MediaTypeConfig> = {
  image: {
    label: 'Image',
    icon: Image,
    extensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'],
    accept: 'image/*',
  },
  video: {
    label: 'Video',
    icon: Video,
    extensions: ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'],
    accept: 'video/*',
  },
  audio: {
    label: 'Audio',
    icon: Music,
    extensions: ['.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a'],
    accept: 'audio/*',
  },
  pdf: {
    label: 'PDF',
    icon: FileText,
    extensions: ['.pdf'],
    accept: 'application/pdf',
  },
  csv: {
    label: 'CSV',
    icon: Table,
    extensions: ['.csv'],
    accept: '.csv,text/csv',
  },
  text: {
    label: 'Text',
    icon: FileText,
    extensions: ['.txt', '.md', '.json', '.xml', '.html'],
    accept: 'text/*,.md,.json,.xml',
  },
  document: {
    label: 'Document',
    icon: FileText,
    extensions: ['.doc', '.docx', '.odt', '.rtf'],
    accept: '.doc,.docx,.odt,.rtf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  },
  spreadsheet: {
    label: 'Spreadsheet',
    icon: Table,
    extensions: ['.xls', '.xlsx', '.ods'],
    accept: '.xls,.xlsx,.ods,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  },
  any: {
    label: 'Any',
    icon: FileIcon,
    extensions: [],
    accept: '*/*',
  },
};

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Get media type from file extension
 */
function getMediaTypeFromExtension(extension: string): AISMediaType {
  const ext = extension.toLowerCase();
  for (const [type, config] of Object.entries(MEDIA_TYPE_CONFIG)) {
    if (config.extensions.includes(ext)) {
      return type as AISMediaType;
    }
  }
  return 'any';
}

/**
 * Format file size for display
 */
export function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
}

/**
 * Generate a unique ID for a file
 */
function generateFileId(file: File): string {
  return `${Date.now()}_${file.name.replace(/\s+/g, '_')}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Compute simple checksum (hash) for a file
 * Uses SubtleCrypto API for SHA-256 hash
 */
async function computeChecksum(file: File): Promise<string> {
  try {
    const buffer = await file.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
  } catch {
    return '';
  }
}

/**
 * Create AISFileInfo from a File object
 */
async function createFileInfo(
  file: File,
  computeHash: boolean = false
): Promise<AISFileInfo> {
  const extension = '.' + (file.name.split('.').pop() || '');
  const mediaType = getMediaTypeFromExtension(extension);

  let checksum: string | undefined;
  if (computeHash && file.size < 10 * 1024 * 1024) {
    // Only for files < 10MB
    checksum = await computeChecksum(file);
  }

  let previewUrl: string | undefined;
  if (mediaType === 'image') {
    previewUrl = URL.createObjectURL(file);
  }

  return {
    id: generateFileId(file),
    fileName: file.name,
    extension,
    mimeType: file.type || 'application/octet-stream',
    sizeBytes: file.size,
    folderPath: '',
    fullPath: file.name,
    mediaType,
    modifiedAt: new Date(file.lastModified),
    checksum,
    status: 'completed',
    file,
    previewUrl,
  };
}

// ============================================================================
// AISMediaPicker Component
// ============================================================================

export interface AISMediaPickerProps {
  /** Allowed media types */
  allowedTypes?: AISMediaType[];
  /** Allowed input sources (files, camera, clipboard) */
  inputSources?: AISInputSource[];
  /** Maximum file size in bytes (null = unlimited) */
  maxSizeBytes?: number;
  /** Allow multiple file selection */
  multiple?: boolean;
  /** Maximum number of files (for multiple selection) */
  maxFiles?: number;
  /** Called when files are selected */
  onFilesSelected?: (files: AISFileInfo[]) => void;
  /** Called when a file is removed */
  onFileRemoved?: (file: AISFileInfo) => void;
  /** Custom upload handler */
  uploadHandler?: (file: AISFileInfo) => Promise<AISFileInfo>;
  /** Currently selected files */
  selectedFiles?: AISFileInfo[];
  /** Whether to show preview thumbnails */
  showPreviews?: boolean;
  /** Whether to show file details */
  showDetails?: boolean;
  /** Custom label */
  label?: string;
  /** Hint text */
  hint?: string;
  /** Whether picker is enabled */
  disabled?: boolean;
  /** Whether to compute file checksums */
  computeChecksums?: boolean;
  /** Show input source selector (when multiple sources available) */
  showSourceSelector?: boolean;
  /** Enable built-in review mode before confirming selection */
  enableReview?: boolean;
  /** Called when files are confirmed in review mode */
  onFilesConfirmed?: (files: AISFileInfo[]) => void;
  /** CSS class name */
  className?: string;
}

export function AISMediaPicker({
  allowedTypes = ['any'],
  inputSources = ['files', 'clipboard'],
  maxSizeBytes,
  multiple = false,
  maxFiles,
  onFilesSelected,
  onFileRemoved,
  selectedFiles: controlledFiles,
  showPreviews = true,
  showDetails = true,
  label,
  hint,
  disabled = false,
  computeChecksums = false,
  showSourceSelector = true,
  enableReview = false,
  onFilesConfirmed,
  className,
}: AISMediaPickerProps) {
  const tokens = useAISTokens();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const [internalFiles, setInternalFiles] = useState<AISFileInfo[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [_clipboardHasContent, setClipboardHasContent] = useState(false);
  // Review mode state
  const [showReviewPanel, setShowReviewPanel] = useState(false);
  const [selectedFileForPreview, setSelectedFileForPreview] = useState<AISFileInfo | null>(null);
  // Note: _clipboardHasContent could be used to conditionally show clipboard paste button
  void _clipboardHasContent;

  const files = controlledFiles ?? internalFiles;

  // Get available input sources
  const availableSources = inputSources.filter(
    (source) => INPUT_SOURCE_CONFIG[source].isAvailable
  );

  // Check clipboard content on mount
  useEffect(() => {
    checkClipboardContent();
  }, []);

  // Check if clipboard has compatible content
  const checkClipboardContent = async () => {
    try {
      // Check if clipboard API is available
      if (typeof navigator.clipboard?.read === 'function') {
        setClipboardHasContent(true);
      }
    } catch {
      setClipboardHasContent(false);
    }
  };

  // Build accept string for file input
  const acceptString = allowedTypes.includes('any')
    ? '*/*'
    : allowedTypes.map((type) => MEDIA_TYPE_CONFIG[type].accept).join(',');

  // Get allowed extensions for display
  const allowedExtensions = allowedTypes.includes('any')
    ? 'All files'
    : allowedTypes
        .flatMap((type) => MEDIA_TYPE_CONFIG[type].extensions)
        .join(', ');

  // Max size text
  const maxSizeText = maxSizeBytes
    ? `Max ${formatFileSize(maxSizeBytes)}`
    : '';

  // Handle file selection
  const handleFiles = useCallback(
    async (fileList: FileList | null) => {
      if (!fileList || fileList.length === 0 || disabled) return;

      setIsLoading(true);
      setErrorMessage(null);

      try {
        const newFiles: AISFileInfo[] = [];

        for (const file of Array.from(fileList)) {
          // Check file size
          if (maxSizeBytes && file.size > maxSizeBytes) {
            setErrorMessage(`${file.name} exceeds maximum size of ${maxSizeText}`);
            continue;
          }

          // Check file extension
          const ext = '.' + (file.name.split('.').pop() || '').toLowerCase();
          if (!allowedTypes.includes('any')) {
            const isAllowed = allowedTypes.some((type) =>
              MEDIA_TYPE_CONFIG[type].extensions.includes(ext)
            );
            if (!isAllowed) {
              setErrorMessage(`${file.name} is not an allowed file type`);
              continue;
            }
          }

          // Create file info
          const fileInfo = await createFileInfo(file, computeChecksums);
          newFiles.push(fileInfo);
        }

        if (newFiles.length > 0) {
          let updatedFiles: AISFileInfo[];

          if (multiple) {
            const totalFiles = files.length + newFiles.length;
            if (maxFiles && totalFiles > maxFiles) {
              const allowedCount = maxFiles - files.length;
              updatedFiles = [...files, ...newFiles.slice(0, allowedCount)];
              setErrorMessage(`Maximum ${maxFiles} files allowed`);
            } else {
              updatedFiles = [...files, ...newFiles];
            }
          } else {
            updatedFiles = [newFiles[0]];
          }

          if (!controlledFiles) {
            setInternalFiles(updatedFiles);
          }
          onFilesSelected?.(updatedFiles);
          // Show review panel if enableReview is true
          if (enableReview) {
            setShowReviewPanel(true);
          }
        }
      } catch (error) {
        setErrorMessage(`Error processing files: ${error}`);
      } finally {
        setIsLoading(false);
        if (fileInputRef.current) {
          fileInputRef.current.value = '';
        }
      }
    },
    [
      allowedTypes,
      computeChecksums,
      controlledFiles,
      disabled,
      enableReview,
      files,
      maxFiles,
      maxSizeBytes,
      maxSizeText,
      multiple,
      onFilesSelected,
    ]
  );

  // Remove file
  const removeFile = useCallback(
    (file: AISFileInfo) => {
      const updatedFiles = files.filter((f) => f.id !== file.id);

      // Revoke preview URL to prevent memory leaks
      if (file.previewUrl) {
        URL.revokeObjectURL(file.previewUrl);
      }

      if (!controlledFiles) {
        setInternalFiles(updatedFiles);
      }
      onFileRemoved?.(file);
      onFilesSelected?.(updatedFiles);
      setErrorMessage(null);
    },
    [files, controlledFiles, onFileRemoved, onFilesSelected]
  );

  // Handle input source selection
  const handleSourceSelection = useCallback(
    (source: AISInputSource) => {
      switch (source) {
        case 'files':
          fileInputRef.current?.click();
          break;
        case 'camera':
          cameraInputRef.current?.click();
          break;
        case 'clipboard':
          pasteFromClipboard();
          break;
      }
    },
    []
  );

  // Paste from clipboard
  const pasteFromClipboard = useCallback(async () => {
    if (disabled || isLoading) return;

    setIsLoading(true);
    setErrorMessage(null);

    try {
      // Try to read from clipboard
      const clipboardItems = await navigator.clipboard.read();

      for (const item of clipboardItems) {
        // Try to get image
        if (item.types.includes('image/png') || item.types.includes('image/jpeg')) {
          const imageType = item.types.find((t) => t.startsWith('image/'));
          if (imageType) {
            const blob = await item.getType(imageType);
            const file = new File(
              [blob],
              `pasted_image_${Date.now()}.${imageType.split('/')[1]}`,
              { type: imageType }
            );
            const fileInfo = await createFileInfo(file, computeChecksums);

            // Check file size
            if (maxSizeBytes && fileInfo.sizeBytes > maxSizeBytes) {
              setErrorMessage(`Pasted image exceeds maximum size of ${maxSizeText}`);
              continue;
            }

            const updatedFiles = multiple ? [...files, fileInfo] : [fileInfo];
            if (!controlledFiles) {
              setInternalFiles(updatedFiles);
            }
            onFilesSelected?.(updatedFiles);
            if (enableReview) {
              setShowReviewPanel(true);
            }
            setIsLoading(false);
            return;
          }
        }

        // Try to get text
        if (item.types.includes('text/plain')) {
          const blob = await item.getType('text/plain');
          const text = await blob.text();

          // Create a text file from clipboard content
          const file = new File(
            [text],
            `pasted_text_${Date.now()}.txt`,
            { type: 'text/plain' }
          );
          const fileInfo = await createFileInfo(file, computeChecksums);

          const updatedFiles = multiple ? [...files, fileInfo] : [fileInfo];
          if (!controlledFiles) {
            setInternalFiles(updatedFiles);
          }
          onFilesSelected?.(updatedFiles);
          if (enableReview) {
            setShowReviewPanel(true);
          }
          setIsLoading(false);
          return;
        }
      }

      setErrorMessage('No compatible content found in clipboard');
    } catch (error) {
      // Fallback: try to read text from clipboard
      try {
        const text = await navigator.clipboard.readText();
        if (text) {
          const file = new File(
            [text],
            `pasted_text_${Date.now()}.txt`,
            { type: 'text/plain' }
          );
          const fileInfo = await createFileInfo(file, computeChecksums);

          const updatedFiles = multiple ? [...files, fileInfo] : [fileInfo];
          if (!controlledFiles) {
            setInternalFiles(updatedFiles);
          }
          onFilesSelected?.(updatedFiles);
          if (enableReview) {
            setShowReviewPanel(true);
          }
        } else {
          setErrorMessage('No compatible content found in clipboard');
        }
      } catch {
        setErrorMessage('Unable to read from clipboard. Please use Ctrl+V or check permissions.');
      }
    } finally {
      setIsLoading(false);
    }
  }, [
    disabled,
    enableReview,
    isLoading,
    computeChecksums,
    maxSizeBytes,
    maxSizeText,
    multiple,
    files,
    controlledFiles,
    onFilesSelected,
  ]);

  // Handle camera capture
  const handleCameraCapture = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      handleFiles(e.target.files);
      if (cameraInputRef.current) {
        cameraInputRef.current.value = '';
      }
    },
    [handleFiles]
  );

  // Drag handlers
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    if (!disabled) {
      setIsDragging(true);
    }
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (!disabled) {
      handleFiles(e.dataTransfer.files);
    }
  };

  // Click handler
  const handleClick = () => {
    if (!disabled && !isLoading) {
      fileInputRef.current?.click();
    }
  };

  // Get icon for media type
  const getMediaIcon = (mediaType: AISMediaType) => {
    const IconComponent = MEDIA_TYPE_CONFIG[mediaType].icon;
    return IconComponent;
  };

  // Get color for media type
  const getMediaColor = (mediaType: AISMediaType): string => {
    switch (mediaType) {
      case 'image':
        return '#22c55e';
      case 'video':
        return '#a855f7';
      case 'audio':
        return '#f97316';
      case 'pdf':
        return '#ef4444';
      case 'csv':
      case 'spreadsheet':
        return '#14b8a6';
      case 'text':
      case 'document':
        return '#3b82f6';
      default:
        return tokens.onSurfaceSecondary;
    }
  };

  // Get status icon
  const getStatusIcon = (status: AISUploadStatus) => {
    switch (status) {
      case 'pending':
        return <Clock size={16} style={{ color: tokens.stateWarning.color }} />;
      case 'uploading':
        return (
          <Loader2
            size={16}
            className="animate-spin"
            style={{ color: tokens.actionPrimary.color }}
          />
        );
      case 'completed':
        return <Check size={16} style={{ color: tokens.actionConfirm.color }} />;
      case 'failed':
        return <AlertCircle size={16} style={{ color: tokens.stateError.color }} />;
      case 'cancelled':
        return <X size={16} style={{ color: tokens.onSurfaceSecondary }} />;
    }
  };

  return (
    <div className={clsx('flex flex-col gap-2', className)}>
      {/* Label */}
      {label && (
        <label
          className="text-sm font-medium"
          style={{ color: disabled ? tokens.onSurfaceSecondary : tokens.onSurface }}
        >
          {label}
        </label>
      )}

      {/* Source selector (if multiple sources available) */}
      {showSourceSelector && availableSources.length > 1 && (
        <div className="flex flex-wrap gap-2">
          {availableSources.map((source) => {
            const config = INPUT_SOURCE_CONFIG[source];
            const Icon = config.icon;
            return (
              <button
                key={source}
                onClick={() => handleSourceSelection(source)}
                disabled={disabled}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded text-xs transition-colors"
                style={{
                  backgroundColor: tokens.surfaceSecondary,
                  color: disabled
                    ? tokens.onSurfaceSecondary + '50'
                    : tokens.onSurface,
                }}
              >
                <Icon size={14} />
                <span>{config.label}</span>
              </button>
            );
          })}
        </div>
      )}

      {/* Drop zone */}
      <div
        onClick={handleClick}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        className={clsx(
          'flex flex-col items-center justify-center p-6 rounded-lg border-2 border-dashed cursor-pointer transition-colors',
          !disabled && 'hover:border-opacity-50'
        )}
        style={{
          backgroundColor: isDragging
            ? tokens.actionPrimary.color + '10'
            : disabled
            ? tokens.surfaceSecondary
            : tokens.surface,
          borderColor: isDragging
            ? tokens.actionPrimary.color
            : disabled
            ? tokens.onSurface + '10'
            : tokens.onSurface + '30',
          cursor: disabled ? 'not-allowed' : 'pointer',
        }}
      >
        {/* File input */}
        <input
          ref={fileInputRef}
          type="file"
          accept={acceptString}
          multiple={multiple}
          onChange={(e) => handleFiles(e.target.files)}
          className="hidden"
          disabled={disabled}
        />

        {/* Camera input (for mobile) */}
        <input
          ref={cameraInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          onChange={handleCameraCapture}
          className="hidden"
          disabled={disabled}
        />

        {isLoading ? (
          <Loader2
            size={48}
            className="animate-spin"
            style={{ color: tokens.actionPrimary.color }}
          />
        ) : (
          <Upload
            size={48}
            style={{
              color: isDragging
                ? tokens.actionPrimary.color
                : disabled
                ? tokens.onSurfaceSecondary + '50'
                : tokens.onSurfaceSecondary,
            }}
          />
        )}

        <p
          className="mt-2 text-sm font-medium"
          style={{
            color: isDragging
              ? tokens.actionPrimary.color
              : disabled
              ? tokens.onSurfaceSecondary + '50'
              : tokens.onSurfaceSecondary,
          }}
        >
          {isLoading
            ? 'Processing files...'
            : hint || 'Drop files here or click to browse'}
        </p>

        <p
          className="text-xs mt-1"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          {allowedExtensions}
        </p>

        {maxSizeText && (
          <p
            className="text-xs"
            style={{ color: tokens.onSurfaceSecondary }}
          >
            {maxSizeText}
          </p>
        )}

        {multiple && (
          <p
            className="text-xs"
            style={{ color: tokens.onSurfaceSecondary }}
          >
            {maxFiles ? `Up to ${maxFiles} files` : 'Multiple files allowed'}
          </p>
        )}
      </div>

      {/* Error message */}
      {errorMessage && (
        <div
          className="flex items-center gap-2 p-2 rounded"
          style={{
            backgroundColor: tokens.stateError.color + '10',
            color: tokens.stateError.color,
          }}
        >
          <AlertCircle size={16} />
          <span className="text-xs flex-1">{errorMessage}</span>
          <button
            onClick={() => setErrorMessage(null)}
            className="p-0.5 rounded hover:bg-opacity-20"
          >
            <X size={14} />
          </button>
        </div>
      )}

      {/* Selected files list */}
      {files.length > 0 && (
        <div
          className="rounded-lg overflow-hidden border"
          style={{ borderColor: tokens.onSurface + '10' }}
        >
          {/* Header */}
          <div
            className="flex items-center gap-2 px-4 py-2"
            style={{ backgroundColor: tokens.surface }}
          >
            <FileIcon size={16} style={{ color: tokens.onSurfaceSecondary }} />
            <span
              className="text-xs font-medium"
              style={{ color: tokens.onSurfaceSecondary }}
            >
              {files.length} file{files.length > 1 ? 's' : ''} selected
            </span>
            <div className="flex-1" />
            {files.length > 1 && (
              <button
                onClick={() => {
                  files.forEach((f) => {
                    if (f.previewUrl) URL.revokeObjectURL(f.previewUrl);
                  });
                  if (!controlledFiles) {
                    setInternalFiles([]);
                  }
                  onFilesSelected?.([]);
                }}
                className="text-xs hover:underline"
                style={{ color: tokens.actionDestructive.color }}
              >
                Clear All
              </button>
            )}
          </div>

          {/* File items */}
          {files.map((file) => {
            const Icon = getMediaIcon(file.mediaType);
            const color = getMediaColor(file.mediaType);

            return (
              <div
                key={file.id}
                className="flex items-center gap-3 px-4 py-3 border-t"
                style={{ borderColor: tokens.onSurface + '10' }}
              >
                {/* Icon/Preview */}
                <div
                  className="w-12 h-12 rounded flex items-center justify-center overflow-hidden"
                  style={{ backgroundColor: color + '15' }}
                >
                  {showPreviews && file.previewUrl ? (
                    <img
                      src={file.previewUrl}
                      alt={file.fileName}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <Icon size={24} style={{ color }} />
                  )}
                </div>

                {/* File info */}
                <div className="flex-1 min-w-0">
                  <p
                    className="text-sm font-medium truncate"
                    style={{ color: tokens.onSurface }}
                  >
                    {file.fileName}
                  </p>
                  {showDetails && (
                    <div className="flex items-center gap-2 text-xs">
                      <span style={{ color: tokens.onSurfaceSecondary }}>
                        {formatFileSize(file.sizeBytes)}
                      </span>
                      <span style={{ color: tokens.onSurfaceSecondary }}>
                        {file.extension.toUpperCase().replace('.', '')}
                      </span>
                    </div>
                  )}
                </div>

                {/* Status */}
                {getStatusIcon(file.status)}

                {/* Remove button */}
                <button
                  onClick={() => removeFile(file)}
                  disabled={disabled}
                  className="p-1 rounded hover:bg-opacity-10"
                  style={{ color: tokens.actionDestructive.color }}
                >
                  <X size={18} />
                </button>
              </div>
            );
          })}
        </div>
      )}

      {/* Built-in Review Panel */}
      {enableReview && files.length > 0 && showReviewPanel && (
        <div
          className="mt-4 rounded-lg border"
          style={{
            backgroundColor: tokens.surface,
            borderColor: `${tokens.onSurface}20`,
          }}
        >
          {/* Review header */}
          <div
            className="flex items-center justify-between px-4 py-3 border-b"
            style={{
              backgroundColor: tokens.surfaceSecondary,
              borderColor: `${tokens.onSurface}10`,
            }}
          >
            <div className="flex items-center gap-2">
              <Check size={16} style={{ color: tokens.actionPrimary.color }} />
              <span className="text-sm font-bold" style={{ color: tokens.onSurface }}>
                Review Selected Files
              </span>
            </div>
            <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
              {files.length} file{files.length > 1 ? 's' : ''}
            </span>
          </div>

          {/* Thumbnail grid */}
          <div className="flex flex-wrap gap-2 p-4">
            {files.map((file) => {
              const isSelected = selectedFileForPreview?.id === file.id;
              const Icon = MEDIA_TYPE_CONFIG[file.mediaType].icon;
              const color = getMediaColor(file.mediaType);

              return (
                <div
                  key={file.id}
                  onClick={() => setSelectedFileForPreview(isSelected ? null : file)}
                  className="relative w-20 h-20 rounded cursor-pointer overflow-hidden"
                  style={{
                    backgroundColor: `${color}15`,
                    border: isSelected
                      ? `2px solid ${tokens.actionPrimary.color}`
                      : `1px solid ${tokens.onSurface}10`,
                  }}
                >
                  {file.previewUrl ? (
                    <img
                      src={file.previewUrl}
                      alt={file.fileName}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="flex items-center justify-center w-full h-full">
                      <Icon size={32} style={{ color }} />
                    </div>
                  )}
                  {/* Remove button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      removeFile(file);
                    }}
                    className="absolute top-1 right-1 rounded-full p-0.5"
                    style={{ backgroundColor: tokens.actionDestructive.color }}
                  >
                    <X size={10} style={{ color: 'white' }} />
                  </button>
                  {/* Selection indicator */}
                  {isSelected && (
                    <div
                      className="absolute bottom-1 left-1 rounded-full p-0.5"
                      style={{ backgroundColor: tokens.actionPrimary.color }}
                    >
                      <Check size={10} style={{ color: 'white' }} />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Selected file details */}
          {selectedFileForPreview && (
            <div
              className="mx-4 mb-4 p-3 rounded"
              style={{ backgroundColor: tokens.surfaceSecondary }}
            >
              <p className="font-medium text-sm" style={{ color: tokens.onSurface }}>
                {selectedFileForPreview.fileName}
              </p>
              <div className="flex gap-3 text-xs mt-1">
                <span style={{ color: tokens.onSurfaceSecondary }}>
                  {formatFileSize(selectedFileForPreview.sizeBytes)}
                </span>
                <span style={{ color: tokens.onSurfaceSecondary }}>
                  {selectedFileForPreview.extension.toUpperCase().replace('.', '')}
                </span>
              </div>
            </div>
          )}

          {/* Confirm/Cancel buttons */}
          <div className="flex gap-3 px-4 pb-4">
            <button
              onClick={() => {
                setShowReviewPanel(false);
                setSelectedFileForPreview(null);
              }}
              className="flex-1 py-2 px-4 rounded text-sm"
              style={{
                border: `1px solid ${tokens.onSurface}30`,
                color: tokens.onSurfaceSecondary,
              }}
            >
              Cancel
            </button>
            <button
              onClick={() => {
                onFilesConfirmed?.(files);
                setShowReviewPanel(false);
                setSelectedFileForPreview(null);
              }}
              className="flex-1 flex items-center justify-center gap-2 py-2 px-4 rounded text-sm"
              style={{
                backgroundColor: tokens.actionConfirm.color,
                color: 'white',
              }}
            >
              <Check size={16} />
              Confirm Selection
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================================================
// AISFileChip Component
// ============================================================================

export interface AISFileChipProps {
  file: AISFileInfo;
  onRemove?: () => void;
  onClick?: () => void;
}

export function AISFileChip({ file, onRemove, onClick }: AISFileChipProps) {
  const tokens = useAISTokens();
  const Icon = MEDIA_TYPE_CONFIG[file.mediaType].icon;

  return (
    <div
      onClick={onClick}
      className={clsx(
        'inline-flex items-center gap-1 px-2 py-1 rounded border',
        onClick && 'cursor-pointer hover:bg-opacity-50'
      )}
      style={{
        backgroundColor: tokens.surface,
        borderColor: tokens.onSurface + '20',
      }}
    >
      <Icon size={14} style={{ color: tokens.onSurfaceSecondary }} />
      <span
        className="text-xs max-w-[120px] truncate"
        style={{ color: tokens.onSurface }}
      >
        {file.fileName}
      </span>
      <span
        className="text-xs"
        style={{ color: tokens.onSurfaceSecondary }}
      >
        {formatFileSize(file.sizeBytes)}
      </span>
      {onRemove && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            onRemove();
          }}
          className="ml-1"
        >
          <X size={14} style={{ color: tokens.onSurfaceSecondary }} />
        </button>
      )}
    </div>
  );
}

// ============================================================================
// AISFileInfoDisplay Component
// ============================================================================

export interface AISFileInfoDisplayProps {
  file: AISFileInfo;
  showFullPath?: boolean;
  showMetadata?: boolean;
}

export function AISFileInfoDisplay({
  file,
  showFullPath = true,
  showMetadata = true,
}: AISFileInfoDisplayProps) {
  const tokens = useAISTokens();
  const Icon = MEDIA_TYPE_CONFIG[file.mediaType].icon;

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const InfoRow = ({
    label,
    value,
    monospace = false,
    copyable = false,
  }: {
    label: string;
    value: string;
    monospace?: boolean;
    copyable?: boolean;
  }) => (
    <div className="flex gap-2 py-1">
      <span
        className="w-24 text-xs shrink-0"
        style={{ color: tokens.onSurfaceSecondary }}
      >
        {label}
      </span>
      <span
        className={clsx(
          'text-xs flex-1 break-all',
          monospace && 'font-mono'
        )}
        style={{ color: tokens.onSurface }}
      >
        {value}
      </span>
      {copyable && (
        <button
          onClick={() => copyToClipboard(value)}
          className="p-1 rounded hover:bg-opacity-10"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          <Copy size={12} />
        </button>
      )}
    </div>
  );

  return (
    <div
      className="rounded-lg p-4 border"
      style={{
        backgroundColor: tokens.surface,
        borderColor: tokens.onSurface + '10',
      }}
    >
      {/* Header */}
      <div className="flex items-center gap-3 mb-4">
        <div
          className="w-12 h-12 rounded flex items-center justify-center"
          style={{ backgroundColor: tokens.stateInfo.color + '10' }}
        >
          <Icon size={24} style={{ color: tokens.stateInfo.color }} />
        </div>
        <div className="flex-1">
          <p className="font-medium" style={{ color: tokens.onSurface }}>
            {file.fileName}
          </p>
          <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
            {MEDIA_TYPE_CONFIG[file.mediaType].label} • {formatFileSize(file.sizeBytes)}
          </p>
        </div>
      </div>

      {showMetadata && (
        <>
          <div
            className="border-t my-3"
            style={{ borderColor: tokens.onSurface + '10' }}
          />

          <InfoRow label="ID" value={file.id} monospace copyable />
          <InfoRow label="Extension" value={file.extension} />
          <InfoRow label="MIME Type" value={file.mimeType} />
          <InfoRow
            label="Size"
            value={`${file.sizeBytes.toLocaleString()} bytes (${formatFileSize(file.sizeBytes)})`}
          />
          {showFullPath && file.folderPath && (
            <InfoRow label="Folder" value={file.folderPath} copyable />
          )}
          {showFullPath && file.fullPath && (
            <InfoRow label="Full Path" value={file.fullPath} monospace copyable />
          )}
          {file.modifiedAt && (
            <InfoRow
              label="Modified"
              value={file.modifiedAt.toISOString()}
            />
          )}
          {file.checksum && (
            <InfoRow
              label="Checksum"
              value={file.checksum}
              monospace
              copyable
            />
          )}
          <InfoRow
            label="Status"
            value={file.status.toUpperCase()}
          />
        </>
      )}
    </div>
  );
}

export default AISMediaPicker;
