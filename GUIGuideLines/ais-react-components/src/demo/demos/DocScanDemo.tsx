/**
 * DocScanDemo.tsx
 * Demo page for AIS Document Scanning components
 * Uses Tesseract.js for real browser-based OCR
 */

import { useState, useRef, useCallback } from 'react';
import Tesseract from 'tesseract.js';
import { useAISTokens } from '../../core/AISProvider';
import { AISButton } from '../../components/AISButton';
import { AISStateBadge } from '../../components/AISStateBadge';
import type { AISBadgeState } from '../../core/tokens';
import {
  FileText,
  Cpu,
  Eye,
  Cloud,
  User,
  CheckCircle,
  Building2,
  DollarSign,
  Calendar,
  Upload,
  Loader2,
  X,
  Image as ImageIcon,
  Copy,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';

// Demo types (mirroring AISDocScan types)
enum AIProviderTier {
  SelfMapping = 0,
  BrowserVision = 1,
  LocalAgentic = 2,
  CloudLLM = 3,
}

interface DemoLineItem {
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
  taxCode?: string;
}

interface DemoDocScanResult {
  id: string;
  invoiceNumber: string;
  vendorName: string;
  vendorAddress: string;
  totalAmount: string;
  subtotal: string;
  taxAmount: string;
  invoiceDate: string;
  status: 'pending' | 'review' | 'approved';
  providerUsed: AIProviderTier;
  processingTimeMs: number;
  rawOCRText?: string;
  lineItems: DemoLineItem[];
  fileName?: string;
  fileSize?: number;
}

// Sample data
const sampleResults: DemoDocScanResult[] = [
  {
    id: '1',
    invoiceNumber: 'INV-2024-001',
    vendorName: 'Acme Corp',
    vendorAddress: '123 Business St, City, ST 12345',
    totalAmount: '1,250.00',
    subtotal: '1,157.41',
    taxAmount: '92.59',
    invoiceDate: '2024-03-15',
    status: 'approved',
    providerUsed: AIProviderTier.BrowserVision,
    processingTimeMs: 342,
    lineItems: [
      { description: 'Widget A', quantity: 10, unitPrice: 50.00, amount: 500.00 },
      { description: 'Widget B', quantity: 5, unitPrice: 131.48, amount: 657.41 },
    ],
  },
  {
    id: '2',
    invoiceNumber: 'INV-2024-002',
    vendorName: 'TechSupply Inc',
    vendorAddress: '456 Tech Ave, Metro, CA 90210',
    totalAmount: '3,875.50',
    subtotal: '3,588.43',
    taxAmount: '287.07',
    invoiceDate: '2024-03-18',
    status: 'review',
    providerUsed: AIProviderTier.CloudLLM,
    processingTimeMs: 1250,
    lineItems: [
      { description: 'Server Rack', quantity: 1, unitPrice: 2500.00, amount: 2500.00 },
      { description: 'Network Switch', quantity: 2, unitPrice: 544.22, amount: 1088.43 },
    ],
  },
];

const providerConfig = {
  [AIProviderTier.SelfMapping]: {
    name: 'Manual Entry',
    icon: User,
  },
  [AIProviderTier.BrowserVision]: {
    name: 'Browser OCR',
    icon: Eye,
  },
  [AIProviderTier.LocalAgentic]: {
    name: 'Local AI',
    icon: Cpu,
  },
  [AIProviderTier.CloudLLM]: {
    name: 'Cloud AI',
    icon: Cloud,
  },
};

const statusConfig: Record<'pending' | 'review' | 'approved', { label: string; state: AISBadgeState }> = {
  pending: { label: 'Pending', state: 'pending' },
  review: { label: 'Review', state: 'warning' },
  approved: { label: 'Approved', state: 'completed' },
};

function DocScanDemo() {
  const tokens = useAISTokens();
  const [capturedResults, setCapturedResults] = useState<DemoDocScanResult[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [processingProgress, setProcessingProgress] = useState(0);
  const [selectedResultForDetails, setSelectedResultForDetails] = useState<DemoDocScanResult | null>(null);
  const [expandedResults, setExpandedResults] = useState<Set<string>>(new Set());
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Toggle line items expansion
  const toggleExpanded = (resultId: string) => {
    setExpandedResults(prev => {
      const newSet = new Set(prev);
      if (newSet.has(resultId)) {
        newSet.delete(resultId);
      } else {
        newSet.add(resultId);
      }
      return newSet;
    });
  };

  // Generate JSON output for a result
  const generateJsonOutput = (result: DemoDocScanResult): string => {
    const lineItemsJson = result.lineItems.map(item => ({
      description: item.description,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      amount: item.amount,
      ...(item.taxCode && { taxCode: item.taxCode }),
    }));

    const output = {
      store: {
        name: result.vendorName,
        ...(result.vendorAddress && { address: result.vendorAddress }),
      },
      transaction: {
        invoiceNumber: result.invoiceNumber,
        date: result.invoiceDate,
      },
      items: lineItemsJson,
      totals: {
        subtotal: parseFloat(result.subtotal.replace(',', '')) || 0,
        tax: parseFloat(result.taxAmount.replace(',', '')) || 0,
        total: parseFloat(result.totalAmount.replace(',', '')) || 0,
      },
      extraction: {
        provider: providerConfig[result.providerUsed].name,
        processingTimeMs: result.processingTimeMs,
        status: result.status,
      },
    };

    return JSON.stringify(output, null, 2);
  };

  // Copy to clipboard
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      // Create preview URL for images
      if (file.type.startsWith('image/')) {
        const url = URL.createObjectURL(file);
        setPreviewUrl(url);
      }
    }
  }, []);

  const handleDrop = useCallback((event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    const file = event.dataTransfer.files?.[0];
    if (file && (file.type.startsWith('image/') || file.type === 'application/pdf')) {
      setSelectedFile(file);
      if (file.type.startsWith('image/')) {
        const url = URL.createObjectURL(file);
        setPreviewUrl(url);
      }
    }
  }, []);

  const handleDragOver = useCallback((event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
  }, []);

  // Parse invoice fields from OCR text
  const parseInvoiceFields = useCallback((text: string) => {
    const lines = text.split('\n').filter(l => l.trim());

    // Known retail store names with common OCR variations
    const knownStores: Array<{ name: string; patterns: RegExp[] }> = [
      { name: 'COSTCO WHOLESALE', patterns: [/COSTCO/i, /WHOL[EI]SALE/i, /WHOILESALE/i] },
      { name: 'WALMART', patterns: [/WALMART/i, /WAL.?MART/i] },
      { name: 'TARGET', patterns: [/TARGET/i] },
      { name: 'SAFEWAY', patterns: [/SAFEWAY/i] },
      { name: 'KROGER', patterns: [/KROGER/i] },
      { name: 'HOME DEPOT', patterns: [/HOME\s*DEPOT/i] },
      { name: 'LOWES', patterns: [/LOWE'?S/i] },
      { name: 'BEST BUY', patterns: [/BEST\s*BUY/i] },
    ];

    let vendorName = '';
    let vendorAddress = '';
    let invoiceNumber = '';
    let invoiceDate = '';
    let totalAmount = '';
    let subtotal = '';
    let taxAmount = '';

    // Find vendor from known stores (handles OCR errors)
    let storeNumber = '';
    for (const store of knownStores) {
      const matched = store.patterns.some(pattern => pattern.test(text));
      if (matched) {
        vendorName = store.name;
        // Try to find store number (e.g., "Eastvale #1317" or "Whse:1317")
        const storeNumMatch = text.match(/(?:#|Whse:?\s*)(\d{3,5})/i);
        if (storeNumMatch) {
          storeNumber = storeNumMatch[1];
          vendorName = `${store.name} #${storeNumber}`;
        }
        break;
      }
    }

    // Invoice/Receipt number patterns
    const invoiceMatch = text.match(/(?:invoice|receipt|trans(?:action)?|order|ref)\s*(?:#|no\.?|number|:)?\s*[:\s]?([A-Z0-9\-]+)/i);
    if (invoiceMatch) invoiceNumber = invoiceMatch[1];

    // Date patterns
    const dateMatch = text.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
    if (dateMatch) invoiceDate = dateMatch[1];

    // Total amount
    const totalMatch = text.match(/(?:total|grand\s*total|amount\s*due)\s*[:\s]?\s*\$?\s*([\d,]+\.\d{2})/i);
    if (totalMatch) totalAmount = totalMatch[1].replace(',', '');

    // Subtotal
    const subtotalMatch = text.match(/(?:subtotal|sub\s*total)\s*[:\s]?\s*\$?\s*([\d,]+\.\d{2})/i);
    if (subtotalMatch) subtotal = subtotalMatch[1].replace(',', '');

    // Tax
    const taxMatch = text.match(/(?:tax|vat|gst)\s*[:\s]?\s*\$?\s*([\d,]+\.\d{2})/i);
    if (taxMatch) taxAmount = taxMatch[1].replace(',', '');

    // Address pattern - match street address with city, state, zip
    // Avoid matching store numbers at the start
    const addressMatch = text.match(/(\d+\s+[\w\s]+(?:street|st|avenue|ave|road|rd|drive|dr|blvd)[,\s]+[\w\s]+,?\s*[A-Z]{2}\s*\d{5})/i);
    if (addressMatch) {
      vendorAddress = addressMatch[1].trim();
    } else {
      // Try simpler pattern: number + street name + city + state zip
      const simpleAddressMatch = text.match(/(\d{3,5}\s+\w+\s+(?:Ave|St|Rd|Dr|Blvd|Way|Ln|Ct)[\s\S]*?(?:[A-Z]{2}\s+\d{5}))/i);
      if (simpleAddressMatch) {
        // Remove store number if it's at the very start (4 digits followed by newline)
        let addr = simpleAddressMatch[1].trim();
        // If address starts with just a store number (3-4 digits) followed by newline, remove it
        addr = addr.replace(/^\d{3,4}\n/, '');
        vendorAddress = addr;
      }
    }

    // If no vendor found, use first substantial line
    if (!vendorName && lines.length > 0) {
      for (const line of lines.slice(0, 5)) {
        if (/[a-zA-Z]/.test(line) && !/\$/.test(line) && line.length > 3) {
          vendorName = line.trim();
          break;
        }
      }
    }

    return { vendorName, vendorAddress, invoiceNumber, invoiceDate, totalAmount, subtotal, taxAmount };
  }, []);

  // Parse line items from OCR text
  const parseLineItems = useCallback((text: string): DemoLineItem[] => {
    const lines = text.split('\n').filter(l => l.trim());
    const items: DemoLineItem[] = [];

    const skipKeywords = [
      'SUBTOTAL', 'SUB TOTAL', 'TOTAL', 'TAX', 'CASH', 'CREDIT', 'DEBIT', 'CHANGE', 'BALANCE',
      'PAYMENT', 'THANK YOU', 'WELCOME', 'MEMBER', 'CARD', 'VISA', 'MASTERCARD', 'AMEX',
      'DISCOVER', 'DATE', 'TIME', 'RECEIPT', 'TRANSACTION', 'REGISTER', 'CASHIER', 'STORE',
      'TEL', 'PHONE', 'ADDRESS', 'WWW', 'HTTP', '.COM', 'SAVINGS', 'DISCOUNT', 'ITEMS SOLD',
      'AMOUNT', 'WHSE', 'TRM', 'TRN', 'OP#', 'SEG#', 'AID', 'WHOLESALE', 'APPROVAL', 'REF',
      'ENTRY', 'CHIP READ', 'COSTCO'
    ];

    const skipPatterns = [
      /^[A-Za-z]+\s*#\s*\d+$/,           // "Eastvale #1317"
      /^X{4,}/i,                          // Masked card numbers "XXXXXXXXXXXX8071"
      /^\*{4,}/,                          // Masked card "****1234"
      /^\d{1,2}\/\d{1,2}\/\d{2,4}/,       // Dates
      /^\d+\s+[A-Za-z]+\s+(Ave|St|Rd|Blvd|Dr)/i, // Address lines
      /^[A-Z]{2}\s+\d{5}/,                // State ZIP
      /^Member\s/i,                       // Member info
      /^\(\d{3}\)/,                       // Phone numbers
      /^\d{3}[-.\s]\d{3}[-.\s]\d{4}/,     // Phone numbers
      /^AMOUNT:/i,                        // "AMOUNT:" line
    ];

    // Costco SKU pattern: 6-7 digit SKU followed by description
    const skuPattern = /^(\d{6,7})\s+(.+)$/;

    // Helper function to extract price and tax code from a price line
    // Handles OCR errors like "399.90 Ii" by extracting price and valid tax code
    const extractPriceAndTax = (text: string): { price: number; taxCode?: string } | null => {
      // Match price at start, optionally followed by anything
      const match = text.match(/^-?(\d+\.\d{2})(.*)$/);
      if (!match) return null;

      const price = parseFloat(match[1]);
      const remainder = match[2].trim();

      // Check if remainder is a valid single uppercase tax code
      let taxCode: string | undefined;
      if (/^[A-Z]$/.test(remainder)) {
        taxCode = remainder;
      }
      // If remainder is garbage (like "Ii", "A1", etc.), ignore it

      return { price, taxCode };
    };

    // Helper function to extract price and tax code from end of line
    const extractPriceFromEnd = (text: string): { price: number; taxCode?: string; index: number } | null => {
      // Match price at end, optionally preceded by $ and followed by optional single letter
      const match = text.match(/\$?\s*(\d+\.\d{2})\s*([A-Za-z]*)?\s*$/);
      if (!match) return null;

      const price = parseFloat(match[1]);
      const remainder = (match[2] || '').trim();

      // Check if remainder is a valid single uppercase tax code
      let taxCode: string | undefined;
      if (/^[A-Z]$/.test(remainder)) {
        taxCode = remainder;
      }

      return { price, taxCode, index: match.index || 0 };
    };

    let i = 0;
    while (i < lines.length) {
      const line = lines[i].trim();
      if (!line) { i++; continue; }

      const upperLine = line.toUpperCase();
      let shouldSkip = skipKeywords.some(kw => upperLine.includes(kw));
      if (!shouldSkip) {
        shouldSkip = skipPatterns.some(p => p.test(line));
      }
      if (shouldSkip) { i++; continue; }

      // Costco format: SKU + description, then price on next line
      const skuMatch = line.match(skuPattern);
      if (skuMatch && i + 1 < lines.length) {
        const nextLine = lines[i + 1].trim();
        const priceResult = extractPriceAndTax(nextLine);

        if (priceResult && priceResult.price > 0 && priceResult.price <= 10000) {
          items.push({
            description: skuMatch[2].trim(),
            quantity: 1,
            unitPrice: priceResult.price,
            amount: priceResult.price,
            taxCode: priceResult.taxCode,
          });
          i += 2;
          continue;
        }
      }

      // Standard format: description + price on same line
      const priceResult = extractPriceFromEnd(line);
      if (priceResult && priceResult.price >= 0.01 && priceResult.price <= 10000) {
        let description = line.substring(0, priceResult.index).trim();
        description = description.replace(/^\d{6,}\s+/, '').trim();
        if (description.length >= 2 && /[a-zA-Z]{2,}/.test(description)) {
          items.push({
            description,
            quantity: 1,
            unitPrice: priceResult.price,
            amount: priceResult.price,
            taxCode: priceResult.taxCode,
          });
        }
      }

      i++;
      if (items.length >= 50) break;
    }

    return items;
  }, []);

  const processDocument = useCallback(async () => {
    if (!selectedFile) return;

    setIsProcessing(true);
    setProcessingProgress(0);
    const startTime = Date.now();

    try {
      // Use Tesseract.js for real OCR
      const result = await Tesseract.recognize(
        selectedFile,
        'eng',
        {
          logger: (m) => {
            if (m.status === 'recognizing text') {
              setProcessingProgress(Math.round(m.progress * 100));
            }
          },
        }
      );

      const ocrText = result.data.text;
      const processingTime = Date.now() - startTime;

      // Parse fields from OCR text
      const fields = parseInvoiceFields(ocrText);
      const lineItems = parseLineItems(ocrText);

      const scanResult: DemoDocScanResult = {
        id: `scan-${Date.now()}`,
        invoiceNumber: fields.invoiceNumber || `SCAN-${Date.now().toString().slice(-6)}`,
        vendorName: fields.vendorName || 'Unknown Vendor',
        vendorAddress: fields.vendorAddress || '',
        totalAmount: fields.totalAmount || '0.00',
        subtotal: fields.subtotal || '',
        taxAmount: fields.taxAmount || '',
        invoiceDate: fields.invoiceDate || new Date().toISOString().split('T')[0],
        status: 'review',
        providerUsed: AIProviderTier.BrowserVision,
        processingTimeMs: processingTime,
        fileName: selectedFile.name,
        fileSize: selectedFile.size,
        lineItems,
        rawOCRText: ocrText,
      };

      setCapturedResults(prev => [scanResult, ...prev]);
      setSelectedFile(null);
      setPreviewUrl(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (error) {
      console.error('OCR failed:', error);
      // Fallback to manual entry
      const scanResult: DemoDocScanResult = {
        id: `scan-${Date.now()}`,
        invoiceNumber: '',
        vendorName: 'OCR Failed - Manual Entry Required',
        vendorAddress: '',
        totalAmount: '0.00',
        subtotal: '',
        taxAmount: '',
        invoiceDate: new Date().toISOString().split('T')[0],
        status: 'review',
        providerUsed: AIProviderTier.SelfMapping,
        processingTimeMs: Date.now() - startTime,
        fileName: selectedFile.name,
        fileSize: selectedFile.size,
        lineItems: [],
        rawOCRText: 'OCR processing failed. Please enter data manually.',
      };
      setCapturedResults(prev => [scanResult, ...prev]);
    } finally {
      setIsProcessing(false);
      setProcessingProgress(0);
    }
  }, [selectedFile, parseInvoiceFields, parseLineItems]);

  const handleSimulateCapture = () => {
    // Add sample results
    setCapturedResults((prev) => [...sampleResults, ...prev]);
  };

  const handleClearAll = () => {
    setCapturedResults([]);
  };

  const cancelFileSelection = () => {
    setSelectedFile(null);
    setPreviewUrl(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const features = [
    {
      icon: Cpu,
      title: 'AI Router',
      description: 'Tiered AI provider fallback chain',
    },
    {
      icon: Eye,
      title: 'OCR Extraction',
      description: 'Automatic field recognition',
    },
    {
      icon: CheckCircle,
      title: 'Validation',
      description: 'Built-in approval workflow',
    },
    {
      icon: FileText,
      title: 'Editable Fields',
      description: 'Review and correct values',
    },
  ];

  return (
    <div className="p-6 space-y-8">
      {/* Header */}
      <div>
        <h1
          className="text-2xl font-bold mb-2"
          style={{ color: tokens.onSurface }}
        >
          Document Scan
        </h1>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          AI-powered document scanning with OCR extraction for Accounts Payable processing.
        </p>
      </div>

      {/* Header Card */}
      <section
        className="p-6 rounded-lg flex items-center gap-4"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <div
          className="p-4 rounded-lg"
          style={{ backgroundColor: tokens.actionPrimary.color + '20' }}
        >
          <FileText size={48} style={{ color: tokens.actionPrimary.color }} />
        </div>
        <div>
          <h2
            className="text-xl font-bold"
            style={{ color: tokens.onSurface }}
          >
            AIS DocScan
          </h2>
          <p style={{ color: tokens.onSurfaceSecondary }}>
            AI-Powered Document Scanning
          </p>
        </div>
      </section>

      {/* About Section */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-3"
          style={{ color: tokens.onSurface }}
        >
          About DocScan
        </h2>
        <p style={{ color: tokens.onSurfaceSecondary }}>
          DocScan combines AISMediaPicker for file selection with AI-powered OCR extraction.
          It supports multiple AI providers in a tiered fallback chain, from client-side
          Tesseract.js OCR to cloud LLMs for intelligent field extraction.
        </p>
      </section>

      {/* Features Grid */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Features
        </h2>
        <div className="grid grid-cols-2 gap-4">
          {features.map((feature, index) => (
            <div
              key={index}
              className="flex items-start gap-3 p-4 rounded-lg"
              style={{ backgroundColor: tokens.surface }}
            >
              <div
                className="p-2 rounded-lg shrink-0"
                style={{ backgroundColor: tokens.actionPrimary.color + '15' }}
              >
                <feature.icon size={20} style={{ color: tokens.actionPrimary.color }} />
              </div>
              <div>
                <h3
                  className="font-semibold text-sm"
                  style={{ color: tokens.onSurface }}
                >
                  {feature.title}
                </h3>
                <p
                  className="text-xs"
                  style={{ color: tokens.onSurfaceSecondary }}
                >
                  {feature.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Document Upload Section */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Scan Document
        </h2>

        {/* Hidden file input */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*,.pdf"
          onChange={handleFileSelect}
          className="hidden"
        />

        {!selectedFile ? (
          // Drop zone
          <div
            onClick={() => fileInputRef.current?.click()}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            className="border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors hover:border-opacity-60"
            style={{
              borderColor: tokens.onSurface + '40',
              backgroundColor: tokens.surfaceSecondary,
            }}
          >
            <Upload
              size={48}
              className="mx-auto mb-4"
              style={{ color: tokens.onSurfaceSecondary }}
            />
            <p className="font-medium mb-1" style={{ color: tokens.onSurface }}>
              Click to upload or drag and drop
            </p>
            <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
              PNG, JPG, or PDF (max 10MB)
            </p>
          </div>
        ) : (
          // File preview
          <div className="space-y-4">
            <div
              className="flex items-center gap-4 p-4 rounded-lg"
              style={{ backgroundColor: tokens.surfaceSecondary }}
            >
              {previewUrl ? (
                <img
                  src={previewUrl}
                  alt="Preview"
                  className="w-20 h-20 object-cover rounded-lg"
                />
              ) : (
                <div
                  className="w-20 h-20 rounded-lg flex items-center justify-center"
                  style={{ backgroundColor: tokens.surface }}
                >
                  <ImageIcon size={32} style={{ color: tokens.onSurfaceSecondary }} />
                </div>
              )}
              <div className="flex-1">
                <p className="font-medium" style={{ color: tokens.onSurface }}>
                  {selectedFile.name}
                </p>
                <p className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
                  {(selectedFile.size / 1024).toFixed(1)} KB
                </p>
              </div>
              <button
                onClick={cancelFileSelection}
                className="p-2 rounded-lg hover:bg-opacity-80"
                style={{ backgroundColor: tokens.surface }}
              >
                <X size={20} style={{ color: tokens.onSurfaceSecondary }} />
              </button>
            </div>

            {isProcessing && (
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Loader2 className="animate-spin" size={16} style={{ color: tokens.actionPrimary.color }} />
                  <span className="text-sm" style={{ color: tokens.onSurface }}>
                    Processing document... {processingProgress}%
                  </span>
                </div>
                <div
                  className="h-2 rounded-full overflow-hidden"
                  style={{ backgroundColor: tokens.surfaceSecondary }}
                >
                  <div
                    className="h-full transition-all duration-300"
                    style={{
                      width: `${processingProgress}%`,
                      backgroundColor: tokens.actionPrimary.color,
                    }}
                  />
                </div>
              </div>
            )}

            <div className="flex gap-3">
              <AISButton
                actionType="primary"
                onClick={processDocument}
                disabled={isProcessing}
              >
                {isProcessing ? 'Processing...' : 'Process Document'}
              </AISButton>
              <AISButton
                actionType="neutral"
                variant="outlined"
                onClick={cancelFileSelection}
                disabled={isProcessing}
              >
                Cancel
              </AISButton>
            </div>
          </div>
        )}

        <div className="mt-4 pt-4" style={{ borderTop: `1px solid ${tokens.onSurface}10` }}>
          <button
            onClick={handleSimulateCapture}
            className="text-sm hover:underline"
            style={{ color: tokens.actionPrimary.color }}
          >
            Or load sample data for demo
          </button>
        </div>
      </section>

      {/* Captured Results */}
      {capturedResults.length > 0 && (
        <section
          className="p-6 rounded-lg"
          style={{ backgroundColor: tokens.surface }}
        >
          <div className="flex justify-between items-center mb-4">
            <h2
              className="text-lg font-semibold"
              style={{ color: tokens.onSurface }}
            >
              Captured Documents ({capturedResults.length})
            </h2>
            <button
              onClick={handleClearAll}
              className="text-sm hover:underline"
              style={{ color: tokens.actionDestructive.color }}
            >
              Clear All
            </button>
          </div>

          <div className="space-y-3">
            {capturedResults.map((result) => {
              const ProviderIcon = providerConfig[result.providerUsed].icon;
              const statusInfo = statusConfig[result.status];
              const isExpanded = expandedResults.has(result.id);

              return (
                <div
                  key={result.id}
                  className="p-4 rounded-lg"
                  style={{ backgroundColor: tokens.surfaceSecondary }}
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <FileText size={18} style={{ color: tokens.actionPrimary.color }} />
                      <span
                        className="font-semibold"
                        style={{ color: tokens.onSurface }}
                      >
                        Invoice #{result.invoiceNumber}
                      </span>
                    </div>
                    <AISStateBadge
                      state={statusInfo.state}
                      label={statusInfo.label}
                      size="small"
                    />
                  </div>

                  <div className="flex gap-6 text-sm mb-3">
                    {result.vendorName && (
                      <div className="flex items-center gap-1.5" style={{ color: tokens.onSurfaceSecondary }}>
                        <Building2 size={14} />
                        <span>{result.vendorName}</span>
                      </div>
                    )}
                    {result.totalAmount && (
                      <div className="flex items-center gap-1.5" style={{ color: tokens.onSurfaceSecondary }}>
                        <DollarSign size={14} />
                        <span>${result.totalAmount}</span>
                      </div>
                    )}
                    {result.invoiceDate && (
                      <div className="flex items-center gap-1.5" style={{ color: tokens.onSurfaceSecondary }}>
                        <Calendar size={14} />
                        <span>{result.invoiceDate}</span>
                      </div>
                    )}
                  </div>

                  {/* Line Items Section */}
                  {result.lineItems.length > 0 && (
                    <div className="mb-3">
                      <button
                        onClick={() => toggleExpanded(result.id)}
                        className="flex items-center gap-1 text-sm font-medium mb-2"
                        style={{ color: tokens.actionPrimary.color }}
                      >
                        {isExpanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                        Line Items ({result.lineItems.length})
                      </button>

                      {isExpanded && (
                        <div
                          className="rounded-lg overflow-hidden text-sm"
                          style={{ backgroundColor: tokens.surface }}
                        >
                          <table className="w-full">
                            <thead>
                              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}15` }}>
                                <th className="text-left py-2 px-3 font-semibold" style={{ color: tokens.onSurface }}>Description</th>
                                <th className="text-right py-2 px-3 font-semibold" style={{ color: tokens.onSurface }}>Qty</th>
                                <th className="text-right py-2 px-3 font-semibold" style={{ color: tokens.onSurface }}>Unit Price</th>
                                <th className="text-right py-2 px-3 font-semibold" style={{ color: tokens.onSurface }}>Amount</th>
                                {result.lineItems.some(i => i.taxCode) && (
                                  <th className="text-center py-2 px-3 font-semibold" style={{ color: tokens.onSurface }}>Tax</th>
                                )}
                              </tr>
                            </thead>
                            <tbody>
                              {result.lineItems.map((item, idx) => (
                                <tr
                                  key={idx}
                                  style={{ borderBottom: idx < result.lineItems.length - 1 ? `1px solid ${tokens.onSurface}10` : undefined }}
                                >
                                  <td className="py-2 px-3" style={{ color: tokens.onSurface }}>{item.description}</td>
                                  <td className="py-2 px-3 text-right" style={{ color: tokens.onSurfaceSecondary }}>{item.quantity}</td>
                                  <td className="py-2 px-3 text-right" style={{ color: tokens.onSurfaceSecondary }}>${item.unitPrice.toFixed(2)}</td>
                                  <td className="py-2 px-3 text-right font-medium" style={{ color: tokens.onSurface }}>${item.amount.toFixed(2)}</td>
                                  {result.lineItems.some(i => i.taxCode) && (
                                    <td className="py-2 px-3 text-center" style={{ color: tokens.onSurfaceSecondary }}>{item.taxCode || '-'}</td>
                                  )}
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      )}
                    </div>
                  )}

                  <div className="flex items-center justify-between">
                    <div
                      className="flex items-center gap-1.5 text-xs"
                      style={{ color: tokens.onSurfaceSecondary }}
                    >
                      <ProviderIcon size={12} />
                      <span>
                        Processed with {providerConfig[result.providerUsed].name} in {result.processingTimeMs}ms
                      </span>
                    </div>

                    <button
                      onClick={() => setSelectedResultForDetails(result)}
                      className="flex items-center gap-1 text-xs font-medium hover:underline"
                      style={{ color: tokens.actionPrimary.color }}
                    >
                      <FileText size={12} />
                      View Details
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      )}

      {/* Usage Example */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          Usage Example
        </h2>
        <pre
          className="p-4 rounded-lg text-sm overflow-x-auto"
          style={{
            backgroundColor: tokens.surfaceSecondary,
            color: tokens.onSurface,
          }}
        >
{`import Tesseract from 'tesseract.js';
import { AISDocScan, parseLineItems } from 'ais-react-components';

function InvoiceCaptureScreen() {
  const [result, setResult] = useState<DocScanResult | null>(null);

  const handleFileUpload = async (file: File) => {
    // Perform OCR using Tesseract.js
    const ocrResult = await Tesseract.recognize(file, 'eng');
    const rawText = ocrResult.data.text;

    // Parse invoice fields
    const invoiceMatch = rawText.match(/invoice.*#?\\s*(\\w+)/i);
    const totalMatch = rawText.match(/total.*\\$?([\\d,.]+)/i);

    // Parse line items using built-in parser
    const lineItems = parseLineItems(rawText);

    setResult({
      invoiceNumber: invoiceMatch?.[1] || '',
      totalAmount: totalMatch?.[1] || '0.00',
      lineItems, // Array of { description, quantity, unitPrice, amount, taxCode }
      rawOCRText: rawText,
    });
  };

  return (
    <AISDocScan
      documentType="invoice"
      onFileSelect={handleFileUpload}
      onComplete={(result) => api.createAPEntry(result)}
    />
  );
}`}
        </pre>
      </section>

      {/* AI Provider Tiers */}
      <section
        className="p-6 rounded-lg"
        style={{ backgroundColor: tokens.surface }}
      >
        <h2
          className="text-lg font-semibold mb-4"
          style={{ color: tokens.onSurface }}
        >
          AI Provider Tiers
        </h2>
        <div className="space-y-3">
          {Object.entries(providerConfig).map(([tier, config]) => {
            const Icon = config.icon;
            return (
              <div
                key={tier}
                className="flex items-center gap-4 p-3 rounded-lg"
                style={{ backgroundColor: tokens.surfaceSecondary }}
              >
                <div
                  className="p-2 rounded-lg"
                  style={{ backgroundColor: tokens.actionPrimary.color + '15' }}
                >
                  <Icon size={20} style={{ color: tokens.actionPrimary.color }} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span
                      className="font-semibold text-sm"
                      style={{ color: tokens.onSurface }}
                    >
                      Tier {tier}: {config.name}
                    </span>
                  </div>
                  <p
                    className="text-xs"
                    style={{ color: tokens.onSurfaceSecondary }}
                  >
                    {tier === '0' && 'Manual user entry - no AI processing'}
                    {tier === '1' && 'Client-side OCR using Tesseract.js'}
                    {tier === '2' && 'On-device AI model (WebNN/ONNX)'}
                    {tier === '3' && 'Cloud LLM API (Claude, GPT, Gemini)'}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
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
                <th className="text-left py-2 font-semibold" style={{ color: tokens.onSurface }}>Prop</th>
                <th className="text-left py-2 font-semibold" style={{ color: tokens.onSurface }}>Type</th>
                <th className="text-left py-2 font-semibold" style={{ color: tokens.onSurface }}>Description</th>
              </tr>
            </thead>
            <tbody style={{ color: tokens.onSurfaceSecondary }}>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">documentType</td>
                <td className="py-2 font-mono text-xs">DocumentType</td>
                <td className="py-2">Type of document (invoice, receipt, contract)</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">preferredProvider</td>
                <td className="py-2 font-mono text-xs">AIProviderTier</td>
                <td className="py-2">Preferred AI provider for OCR/extraction</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">onComplete</td>
                <td className="py-2 font-mono text-xs">(result: DocScanResult) =&gt; void</td>
                <td className="py-2">Callback when document is captured and approved</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">onCancel</td>
                <td className="py-2 font-mono text-xs">() =&gt; void</td>
                <td className="py-2">Callback when user cancels the workflow</td>
              </tr>
              <tr style={{ borderBottom: `1px solid ${tokens.onSurface}10` }}>
                <td className="py-2 font-mono text-xs">extractLineItems</td>
                <td className="py-2 font-mono text-xs">boolean</td>
                <td className="py-2">Whether to extract line items (default: true)</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* OCR Output Modal */}
      {selectedResultForDetails && (
        <OCROutputModal
          result={selectedResultForDetails}
          onClose={() => setSelectedResultForDetails(null)}
          generateJsonOutput={generateJsonOutput}
          copyToClipboard={copyToClipboard}
        />
      )}
    </div>
  );
}

// OCR Output Modal Component
interface OCROutputModalProps {
  result: DemoDocScanResult;
  onClose: () => void;
  generateJsonOutput: (result: DemoDocScanResult) => string;
  copyToClipboard: (text: string) => void;
}

function OCROutputModal({ result, onClose, generateJsonOutput, copyToClipboard }: OCROutputModalProps) {
  const tokens = useAISTokens();
  const [activeTab, setActiveTab] = useState<'text' | 'json'>('text');

  // Generate formatted text output (cleaned, not raw OCR)
  const formattedText = generateMockOCRText(result);
  const jsonOutput = generateJsonOutput(result);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ backgroundColor: 'rgba(0, 0, 0, 0.5)' }}
      onClick={onClose}
    >
      <div
        className="w-full max-w-3xl max-h-[80vh] rounded-lg overflow-hidden flex flex-col"
        style={{ backgroundColor: tokens.surface }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between p-4"
          style={{ borderBottom: `1px solid ${tokens.onSurface}15` }}
        >
          <h2 className="text-lg font-semibold" style={{ color: tokens.onSurface }}>
            OCR Output
          </h2>
          <div className="flex items-center gap-2">
            <button
              onClick={() => copyToClipboard(activeTab === 'text' ? formattedText : jsonOutput)}
              className="p-2 rounded-lg hover:opacity-80"
              style={{ backgroundColor: tokens.surfaceSecondary }}
              title="Copy to clipboard"
            >
              <Copy size={18} style={{ color: tokens.onSurfaceSecondary }} />
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-lg hover:opacity-80"
              style={{ backgroundColor: tokens.surfaceSecondary }}
            >
              <X size={18} style={{ color: tokens.onSurfaceSecondary }} />
            </button>
          </div>
        </div>

        {/* Tab selector */}
        <div className="p-4 pb-0">
          <div
            className="inline-flex rounded-lg p-1"
            style={{ backgroundColor: tokens.surfaceSecondary }}
          >
            <button
              onClick={() => setActiveTab('text')}
              className="px-4 py-2 text-sm font-medium rounded-md transition-colors"
              style={{
                backgroundColor: activeTab === 'text' ? tokens.surface : 'transparent',
                color: activeTab === 'text' ? tokens.actionPrimary.color : tokens.onSurfaceSecondary,
              }}
            >
              Text
            </button>
            <button
              onClick={() => setActiveTab('json')}
              className="px-4 py-2 text-sm font-medium rounded-md transition-colors"
              style={{
                backgroundColor: activeTab === 'json' ? tokens.surface : 'transparent',
                color: activeTab === 'json' ? tokens.actionPrimary.color : tokens.onSurfaceSecondary,
              }}
            >
              JSON
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto p-4">
          <pre
            className="p-4 rounded-lg text-sm whitespace-pre-wrap font-mono"
            style={{
              backgroundColor: tokens.surfaceSecondary,
              color: tokens.onSurface,
            }}
          >
            {activeTab === 'text' ? formattedText : jsonOutput}
          </pre>
        </div>
      </div>
    </div>
  );
}

// Generate mock OCR text when no raw text is available
function generateMockOCRText(result: DemoDocScanResult): string {
  const lineItemsText = result.lineItems.length > 0
    ? result.lineItems.map(item =>
        `${item.description.padEnd(30)} ${item.quantity} x $${item.unitPrice.toFixed(2).padStart(8)} = $${item.amount.toFixed(2).padStart(8)}${item.taxCode ? ` ${item.taxCode}` : ''}`
      ).join('\n')
    : 'No line items detected';

  return `==========================================
INVOICE
==========================================

Invoice Number: ${result.invoiceNumber}
Invoice Date: ${result.invoiceDate}

FROM:
${result.vendorName}
${result.vendorAddress || '123 Business Street\nCity, ST 12345'}

------------------------------------------
ITEMS:
------------------------------------------
${lineItemsText}

------------------------------------------
SUBTOTAL:                       $${result.subtotal || result.totalAmount}
TAX:                            $${result.taxAmount || '0.00'}
------------------------------------------
TOTAL DUE:                      $${result.totalAmount}
==========================================

Thank you for your business!
`;
}

export default DocScanDemo;
