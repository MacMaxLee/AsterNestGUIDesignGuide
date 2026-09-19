/**
 * MediaPickerDemo.tsx
 * Demo page for AISMediaPicker components
 */

import React, { useState } from 'react';
import { useAISTokens } from '../../core/AISProvider';
import { AISSpacing } from '../../core/tokens';
import {
  AISMediaPicker,
  AISFileChip,
  AISFileInfoDisplay,
  AISFileInfo,
} from '../../components/AISMediaPicker';
import { AISButton } from '../../components/AISButton';

function MediaPickerDemo() {
  const tokens = useAISTokens();
  const [basicFiles, setBasicFiles] = useState<AISFileInfo[]>([]);
  const [imageFiles, setImageFiles] = useState<AISFileInfo[]>([]);
  const [multiFiles, setMultiFiles] = useState<AISFileInfo[]>([]);
  const [selectedFile, setSelectedFile] = useState<AISFileInfo | null>(null);

  return (
    <div className="p-6 space-y-8">
      <div>
        <h1
          className="text-2xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Media Picker
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          File selection with metadata extraction for database storage.
          Supports drag-and-drop, file type filtering, and size limits.
        </p>
      </div>

      {/* Basic Usage */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Basic Usage
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Simple file picker that accepts any file type.
        </p>

        <AISMediaPicker
          label="Attach File"
          hint="Drop a file here or click to browse"
          onFilesSelected={setBasicFiles}
          selectedFiles={basicFiles}
        />
      </section>

      {/* Images Only */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Images Only
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Restrict to image files with preview thumbnails and 5MB size limit.
        </p>

        <AISMediaPicker
          label="Upload Image"
          allowedTypes={['image']}
          maxSizeBytes={5 * 1024 * 1024}
          onFilesSelected={setImageFiles}
          selectedFiles={imageFiles}
          showPreviews={true}
        />
      </section>

      {/* Multiple Files */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Multiple Files
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Allow selecting multiple files (up to 5) with document types only.
        </p>

        <AISMediaPicker
          label="Upload Documents"
          allowedTypes={['pdf', 'document', 'spreadsheet', 'csv']}
          multiple={true}
          maxFiles={5}
          maxSizeBytes={10 * 1024 * 1024}
          onFilesSelected={setMultiFiles}
          selectedFiles={multiFiles}
          computeChecksums={true}
        />
      </section>

      {/* File Chips */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          File Chips
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Compact file display for inline use in forms or lists.
        </p>

        <div className="flex flex-wrap gap-2">
          {[...basicFiles, ...imageFiles, ...multiFiles].map((file) => (
            <AISFileChip
              key={file.id}
              file={file}
              onClick={() => setSelectedFile(file)}
              onRemove={() => {
                // Remove from appropriate list
                setBasicFiles((files) => files.filter((f) => f.id !== file.id));
                setImageFiles((files) => files.filter((f) => f.id !== file.id));
                setMultiFiles((files) => files.filter((f) => f.id !== file.id));
              }}
            />
          ))}
          {[...basicFiles, ...imageFiles, ...multiFiles].length === 0 && (
            <span
              className="text-sm italic"
              style={{ color: tokens.onSurfaceSecondary }}
            >
              Upload some files above to see chips here
            </span>
          )}
        </div>
      </section>

      {/* File Info Display */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          File Details
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: tokens.onSurfaceSecondary }}
        >
          Click on a file chip above to see its full metadata.
        </p>

        {selectedFile ? (
          <AISFileInfoDisplay
            file={selectedFile}
            showFullPath={true}
            showMetadata={true}
          />
        ) : (
          <div
            className="text-center py-8 rounded-lg border border-dashed"
            style={{
              borderColor: tokens.onSurface + '30',
              color: tokens.onSurfaceSecondary,
            }}
          >
            Select a file to view its metadata
          </div>
        )}
      </section>

      {/* Disabled State */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Disabled State
        </h2>

        <AISMediaPicker
          label="Disabled Picker"
          disabled={true}
          hint="This picker is disabled"
        />
      </section>

      {/* API Reference */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          API Reference
        </h2>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr
                style={{
                  borderBottom: `1px solid ${tokens.onSurface}20`,
                }}
              >
                <th className="text-left py-2 font-semibold">Prop</th>
                <th className="text-left py-2 font-semibold">Type</th>
                <th className="text-left py-2 font-semibold">Description</th>
              </tr>
            </thead>
            <tbody style={{ color: tokens.onSurfaceSecondary }}>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">allowedTypes</td>
                <td className="py-2 font-mono text-xs">AISMediaType[]</td>
                <td className="py-2">Allowed file types (image, video, audio, pdf, etc.)</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">maxSizeBytes</td>
                <td className="py-2 font-mono text-xs">number</td>
                <td className="py-2">Maximum file size in bytes</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">multiple</td>
                <td className="py-2 font-mono text-xs">boolean</td>
                <td className="py-2">Allow multiple file selection</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">maxFiles</td>
                <td className="py-2 font-mono text-xs">number</td>
                <td className="py-2">Maximum number of files when multiple is true</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">computeChecksums</td>
                <td className="py-2 font-mono text-xs">boolean</td>
                <td className="py-2">Compute SHA-256 checksum for files</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">onFilesSelected</td>
                <td className="py-2 font-mono text-xs">(files: AISFileInfo[]) =&gt; void</td>
                <td className="py-2">Callback when files are selected</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

export default MediaPickerDemo;
