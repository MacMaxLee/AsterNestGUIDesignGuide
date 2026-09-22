/**
 * AISDocScan.tsx
 * AIS DocScan AP Module - React/TypeScript Implementation
 *
 * PURPOSE:
 * Document scanning component for Accounts Payable processing with AI-powered
 * field extraction. Integrates with AISMediaPicker for file selection.
 *
 * AI ROUTER PROVIDER CHAIN:
 * Tier 0: Self mapping (manual user entry)
 * Tier 1: Browser Vision API / Tesseract.js (client-side OCR)
 * Tier 2: Local Agentic AI (on-device model via WebNN/ONNX)
 * Tier 3: LLM Fallback (Claude/ChatGPT/Gemini cloud API)
 *
 * USAGE:
 * ```tsx
 * <AISDocScanWidget
 *   onComplete={(result) => {
 *     // Post to accounting system
 *     viewModel.createAPEntry(result);
 *   }}
 *   onCancel={() => navigate(-1)}
 * />
 * ```
 */

import React, { useState, useCallback, useMemo } from 'react';
import clsx from 'clsx';
import Tesseract from 'tesseract.js';
import type { LucideIcon } from 'lucide-react';
import {
  User,
  Eye,
  Cpu,
  Cloud,
  FileText,
  Clock,
  Scan,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Edit2,
  Check,
  AlertCircle,
  List,
  DollarSign,
  ShieldCheck,
  Settings,
  X,
  Copy,
  Code,
  FileOutput,
} from 'lucide-react';
import { useAISTokens } from '../core/AISProvider';
import type { AISBadgeState } from '../core/tokens';
import { AISButton } from './AISButton';
import { AISStateBadge } from './AISStateBadge';
import { AISMediaPicker, AISFileInfo } from './AISMediaPicker';

// ============================================================================
// Types
// ============================================================================

/** AI Provider Tier */
export enum AIProviderTier {
  SelfMapping = 0,
  BrowserVision = 1,
  LocalAgentic = 2,
  CloudLLM = 3,
}

/** Provider configuration */
interface AIProviderConfig {
  tier: AIProviderTier;
  displayName: string;
  icon: LucideIcon;
  description: string;
  requiresNetwork: boolean;
}

const AI_PROVIDERS: Record<AIProviderTier, AIProviderConfig> = {
  [AIProviderTier.SelfMapping]: {
    tier: AIProviderTier.SelfMapping,
    displayName: 'Manual Entry',
    icon: User,
    description: 'User fills all fields manually',
    requiresNetwork: false,
  },
  [AIProviderTier.BrowserVision]: {
    tier: AIProviderTier.BrowserVision,
    displayName: 'Browser OCR',
    icon: Eye,
    description: 'Client-side OCR (Tesseract.js)',
    requiresNetwork: false,
  },
  [AIProviderTier.LocalAgentic]: {
    tier: AIProviderTier.LocalAgentic,
    displayName: 'Local AI',
    icon: Cpu,
    description: 'On-device AI model (WebNN/ONNX)',
    requiresNetwork: false,
  },
  [AIProviderTier.CloudLLM]: {
    tier: AIProviderTier.CloudLLM,
    displayName: 'Cloud AI',
    icon: Cloud,
    description: 'Cloud LLM (requires API key)',
    requiresNetwork: true,
  },
};

/** Extraction confidence level */
export enum ExtractionConfidence {
  High = 'high',
  Medium = 'medium',
  Low = 'low',
  Manual = 'manual',
}

/** Extracted field */
export interface ExtractedField {
  id: string;
  fieldKey: string;
  displayName: string;
  extractedValue: string;
  mappedValue: string;
  confidence: number;
  confidenceLevel: ExtractionConfidence;
  isRequired: boolean;
  isEdited: boolean;
  boundingBox?: { x: number; y: number; width: number; height: number };
}

/** Invoice line item */
export interface InvoiceLineItem {
  id: string;
  lineNumber: number;
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
  glAccountCode?: string;
  costCenter?: string;
  taxCode?: string;
  confidence: number;
}

/** Document scan status */
export enum DocScanStatus {
  Pending = 'pending',
  Scanning = 'scanning',
  Extracting = 'extracting',
  Review = 'review',
  Approved = 'approved',
  Posted = 'posted',
  Rejected = 'rejected',
  Error = 'error',
}

/** Status configuration */
interface StatusConfig {
  displayName: string;
  icon: LucideIcon;
  badgeState: AISBadgeState;
}

const STATUS_CONFIG: Record<DocScanStatus, StatusConfig> = {
  [DocScanStatus.Pending]: { displayName: 'Pending', icon: Clock, badgeState: 'pending' },
  [DocScanStatus.Scanning]: { displayName: 'Scanning...', icon: Scan, badgeState: 'active' },
  [DocScanStatus.Extracting]: { displayName: 'Extracting...', icon: Cpu, badgeState: 'active' },
  [DocScanStatus.Review]: { displayName: 'Ready for Review', icon: Eye, badgeState: 'warning' },
  [DocScanStatus.Approved]: { displayName: 'Approved', icon: CheckCircle, badgeState: 'completed' },
  [DocScanStatus.Posted]: { displayName: 'Posted', icon: ShieldCheck, badgeState: 'completed' },
  [DocScanStatus.Rejected]: { displayName: 'Rejected', icon: XCircle, badgeState: 'error' },
  [DocScanStatus.Error]: { displayName: 'Error', icon: AlertTriangle, badgeState: 'error' },
};

/** Document scan result */
export interface DocScanResult {
  id: string;
  sourceFileId: string;
  scanDate: Date;
  providerUsed: AIProviderTier;
  processingTimeMs: number;

  // Header fields
  vendorName: ExtractedField;
  vendorAddress: ExtractedField;
  invoiceNumber: ExtractedField;
  invoiceDate: ExtractedField;
  dueDate: ExtractedField;
  poNumber: ExtractedField;

  // Amounts
  subtotal: ExtractedField;
  taxAmount: ExtractedField;
  totalAmount: ExtractedField;
  currency: ExtractedField;

  // Line items
  lineItems: InvoiceLineItem[];

  // Processing state
  status: DocScanStatus;
  validationErrors: string[];

  // Raw OCR text
  rawOCRText?: string;
}

// ============================================================================
// Helper Functions
// ============================================================================

function createExtractedField(
  fieldKey: string,
  displayName: string,
  isRequired: boolean = false,
  extractedValue: string = '',
  confidence: number = 0
): ExtractedField {
  const isEdited = false;
  let confidenceLevel: ExtractionConfidence;
  if (confidence >= 0.9) confidenceLevel = ExtractionConfidence.High;
  else if (confidence >= 0.7) confidenceLevel = ExtractionConfidence.Medium;
  else confidenceLevel = ExtractionConfidence.Low;

  return {
    id: `${Date.now()}_${fieldKey}`,
    fieldKey,
    displayName,
    extractedValue,
    mappedValue: extractedValue,
    confidence,
    confidenceLevel,
    isRequired,
    isEdited,
  };
}

function createEmptyResult(sourceFileId: string): DocScanResult {
  return {
    id: `${Date.now()}_scan`,
    sourceFileId,
    scanDate: new Date(),
    providerUsed: AIProviderTier.SelfMapping,
    processingTimeMs: 0,
    vendorName: createExtractedField('vendor_name', 'Vendor Name', true),
    vendorAddress: createExtractedField('vendor_address', 'Vendor Address'),
    invoiceNumber: createExtractedField('invoice_number', 'Invoice Number', true),
    invoiceDate: createExtractedField('invoice_date', 'Invoice Date', true),
    dueDate: createExtractedField('due_date', 'Due Date'),
    poNumber: createExtractedField('po_number', 'PO Number'),
    subtotal: createExtractedField('subtotal', 'Subtotal'),
    taxAmount: createExtractedField('tax_amount', 'Tax Amount'),
    totalAmount: createExtractedField('total_amount', 'Total Amount', true),
    currency: createExtractedField('currency', 'Currency', false, 'USD', 1.0),
    lineItems: [],
    status: DocScanStatus.Pending,
    validationErrors: [],
  };
}

function getConfidenceColor(level: ExtractionConfidence, tokens: ReturnType<typeof useAISTokens>): string {
  switch (level) {
    case ExtractionConfidence.High:
      return tokens.actionConfirm.color;
    case ExtractionConfidence.Medium:
      return tokens.stateWarning.color;
    case ExtractionConfidence.Low:
      return tokens.stateError.color;
    case ExtractionConfidence.Manual:
      return tokens.stateInfo.color;
  }
}

// ============================================================================
// Component Props
// ============================================================================

export interface AISDocScanWidgetProps {
  /** Called when scan is approved and ready to post */
  onComplete?: (result: DocScanResult) => void;
  /** Called when user cancels */
  onCancel?: () => void;
  /** Cloud API key for LLM provider */
  cloudAPIKey?: string;
  /** Preferred AI provider */
  preferredProvider?: AIProviderTier;
  /** Custom class name */
  className?: string;
}

// ============================================================================
// Main Component
// ============================================================================

export function AISDocScanWidget({
  onComplete,
  onCancel,
  cloudAPIKey: _cloudAPIKey,
  preferredProvider = AIProviderTier.BrowserVision,
  className,
}: AISDocScanWidgetProps) {
  // Note: _cloudAPIKey would be used for actual Cloud LLM API calls
  void _cloudAPIKey;
  const tokens = useAISTokens();

  // State
  const [currentResult, setCurrentResult] = useState<DocScanResult | null>(null);
  const [status, setStatus] = useState<DocScanStatus>(DocScanStatus.Pending);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [activeProvider, setActiveProvider] = useState<AIProviderTier>(AIProviderTier.SelfMapping);
  const [selectedProvider, setSelectedProvider] = useState<AIProviderTier>(preferredProvider);
  const [selectedFile, setSelectedFile] = useState<AISFileInfo | null>(null);
  const [showRawOCR, setShowRawOCR] = useState(false);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [showOCROutputModal, setShowOCROutputModal] = useState(false);

  // Parse invoice fields from OCR text using regex patterns
  const parseInvoiceFields = useCallback((result: DocScanResult, text: string) => {
    if (!text) return;

    const lines = text.split('\n').filter((l) => l.trim());

    // Invoice Number patterns
    const invoiceNumMatch = text.match(
      /(?:invoice\s*(?:#|no\.?|number)?|inv\.?\s*(?:#|no\.?)?)\s*[:\s]?\s*([A-Z0-9\-]+)/i
    );
    if (invoiceNumMatch) {
      result.invoiceNumber.extractedValue = invoiceNumMatch[1] || '';
      result.invoiceNumber.mappedValue = result.invoiceNumber.extractedValue;
      result.invoiceNumber.confidence = 0.85;
      result.invoiceNumber.confidenceLevel = ExtractionConfidence.Medium;
    }

    // Date patterns (various formats)
    const dateMatch = text.match(
      /(?:invoice\s*)?date\s*[:\s]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|\w+\s+\d{1,2},?\s*\d{4})/i
    );
    if (dateMatch) {
      result.invoiceDate.extractedValue = dateMatch[1] || '';
      result.invoiceDate.mappedValue = result.invoiceDate.extractedValue;
      result.invoiceDate.confidence = 0.8;
      result.invoiceDate.confidenceLevel = ExtractionConfidence.Medium;
    }

    // Due Date
    const dueDateMatch = text.match(
      /(?:due\s*(?:date)?|payment\s*due)\s*[:\s]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|\w+\s+\d{1,2},?\s*\d{4})/i
    );
    if (dueDateMatch) {
      result.dueDate.extractedValue = dueDateMatch[1] || '';
      result.dueDate.mappedValue = result.dueDate.extractedValue;
      result.dueDate.confidence = 0.75;
      result.dueDate.confidenceLevel = ExtractionConfidence.Medium;
    }

    // PO Number
    const poMatch = text.match(
      /(?:p\.?o\.?\s*(?:#|no\.?|number)?|purchase\s*order)\s*[:\s]?\s*([A-Z0-9\-]+)/i
    );
    if (poMatch) {
      result.poNumber.extractedValue = poMatch[1] || '';
      result.poNumber.mappedValue = result.poNumber.extractedValue;
      result.poNumber.confidence = 0.8;
      result.poNumber.confidenceLevel = ExtractionConfidence.Medium;
    }

    // Total Amount
    const totalMatch = text.match(
      /(?:total\s*(?:amount|due)?|amount\s*due|balance\s*due|grand\s*total)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)/i
    );
    if (totalMatch) {
      const amount = totalMatch[1]?.replace(/,/g, '') || '';
      result.totalAmount.extractedValue = amount;
      result.totalAmount.mappedValue = amount;
      result.totalAmount.confidence = 0.9;
      result.totalAmount.confidenceLevel = ExtractionConfidence.High;
    }

    // Subtotal
    const subtotalMatch = text.match(
      /(?:subtotal|sub\s*total)\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)/i
    );
    if (subtotalMatch) {
      const amount = subtotalMatch[1]?.replace(/,/g, '') || '';
      result.subtotal.extractedValue = amount;
      result.subtotal.mappedValue = amount;
      result.subtotal.confidence = 0.85;
      result.subtotal.confidenceLevel = ExtractionConfidence.Medium;
    }

    // Tax Amount
    const taxMatch = text.match(
      /(?:tax|vat|gst|hst)\s*(?:amount)?\s*[:\s]?\s*\$?\s*([\d,]+\.?\d*)/i
    );
    if (taxMatch) {
      const amount = taxMatch[1]?.replace(/,/g, '') || '';
      result.taxAmount.extractedValue = amount;
      result.taxAmount.mappedValue = amount;
      result.taxAmount.confidence = 0.85;
      result.taxAmount.confidenceLevel = ExtractionConfidence.Medium;
    }

    // Vendor Name - "From:" section or first non-numeric line
    const fromMatch = text.match(
      /(?:from|vendor|supplier|bill\s*from)\s*[:\s]?\s*(.+)/i
    );
    if (fromMatch) {
      result.vendorName.extractedValue = fromMatch[1]?.trim() || '';
      result.vendorName.mappedValue = result.vendorName.extractedValue;
      result.vendorName.confidence = 0.75;
      result.vendorName.confidenceLevel = ExtractionConfidence.Medium;
    } else if (lines.length > 0) {
      // Fallback: use first non-numeric line as vendor name
      for (const line of lines.slice(0, 5)) {
        if (!/^[\d\s\$\.\,]+$/.test(line) && line.length > 3) {
          result.vendorName.extractedValue = line.trim();
          result.vendorName.mappedValue = result.vendorName.extractedValue;
          result.vendorName.confidence = 0.6;
          result.vendorName.confidenceLevel = ExtractionConfidence.Low;
          break;
        }
      }
    }

    // Vendor Address - address patterns
    const addressMatch = text.match(
      /(\d+\s+[\w\s]+(?:street|st|avenue|ave|road|rd|drive|dr|lane|ln|blvd|boulevard)[\s\S]*?(?:\d{5}(?:\-\d{4})?))/i
    );
    if (addressMatch) {
      result.vendorAddress.extractedValue = addressMatch[1]?.trim() || '';
      result.vendorAddress.mappedValue = result.vendorAddress.extractedValue;
      result.vendorAddress.confidence = 0.7;
      result.vendorAddress.confidenceLevel = ExtractionConfidence.Medium;
    }

    // Parse line items
    result.lineItems = parseLineItems(lines);
  }, []);

  // Parse line items from OCR text lines
  // Supports Costco format: SKU + description on one line, price on next line
  const parseLineItems = useCallback((lines: string[]): InvoiceLineItem[] => {
    const items: InvoiceLineItem[] = [];

    // Skip header/footer keywords
    const skipKeywords = [
      'SUBTOTAL', 'SUB TOTAL', 'TOTAL', 'TAX', 'CASH', 'CREDIT', 'DEBIT',
      'CHANGE', 'BALANCE', 'PAYMENT', 'THANK YOU', 'WELCOME', 'MEMBER',
      'CARD', 'VISA', 'MASTERCARD', 'AMEX', 'DISCOVER', 'DATE', 'TIME',
      'RECEIPT', 'TRANSACTION', 'REGISTER', 'CASHIER', 'STORE', 'TEL',
      'PHONE', 'ADDRESS', 'WWW', 'HTTP', '.COM', 'SAVINGS', 'DISCOUNT',
      'ITEMS SOLD', 'AMOUNT', 'WHSE', 'TRM', 'TRN', 'OP#', 'SEG#', 'AID',
      'WHOLESALE', 'APPROVAL', 'REF', 'ENTRY', 'CHIP READ', 'COSTCO',
    ];

    // Skip patterns for non-item lines (locations, card numbers, identifiers)
    const skipPatterns = [
      /^[A-Za-z]+\s*#\s*\d+$/,                    // "Eastvale #1317"
      /^X{4,}/,                                   // "XXXXXXXXXXXX8071"
      /^\*{4,}/,                                  // "****1234"
      /^\d{1,2}\/\d{1,2}\/\d{2,4}/,               // Date lines
      /^\d+\s+[A-Za-z]+\s+(Ave|St|Rd|Blvd|Dr)/i,  // Address
      /^[A-Z]{2}\s+\d{5}/,                        // State ZIP
      /^Member\s/i,                               // Member info
      /^\(\d{3}\)/,                               // Phone numbers
      /^\d{3}[-.\s]\d{3}[-.\s]\d{4}/,             // Phone numbers
    ];

    // Pattern for Costco SKU line: 6-7 digit SKU followed by description
    const skuPattern = /^(\d{6,7})\s+(.+)$/;

    // Pattern for price line: "399.99 A" or "399.99" (requires decimal)
    const priceLinePattern = /^-?(\d+\.\d{2})\s*([A-Z])?$/;

    // Pattern for price at end of line (requires decimal: ###.##)
    const pricePattern = /\$?\s*(\d+\.\d{2})\s*([A-Z])?\s*$/;

    // Pattern for quantity indicators
    const qtyPatterns = [
      /(\d+)\s*[@xX]\s*\$?(\d+\.\d{2})/, // "2 @ $5.99" or "2 x 5.99"
      /QTY\s*:?\s*(\d+)/i,               // "QTY: 2" or "QTY 2"
    ];

    let lineNumber = 1;
    let i = 0;

    while (i < lines.length) {
      const trimmedLine = lines[i].trim();
      if (!trimmedLine) {
        i++;
        continue;
      }

      // Skip lines that are likely headers/footers by keyword
      const upperLine = trimmedLine.toUpperCase();
      let shouldSkip = skipKeywords.some(keyword => upperLine.includes(keyword));

      // Skip by pattern
      if (!shouldSkip) {
        shouldSkip = skipPatterns.some(pattern => pattern.test(trimmedLine));
      }

      if (shouldSkip) {
        i++;
        continue;
      }

      // Costco format: SKU (6-7 digits) + description on one line, price on next line
      // Example: "1806222 KOHLER SINK" followed by "399.99 A"
      const skuMatch = trimmedLine.match(skuPattern);
      if (skuMatch) {
        const description = skuMatch[2]?.trim() || '';

        // Look at next line for price
        if (i + 1 < lines.length) {
          const nextLine = lines[i + 1].trim();
          const priceLineMatch = nextLine.match(priceLinePattern);

          if (priceLineMatch) {
            const priceStr = priceLineMatch[1] || '0';
            const taxCode = priceLineMatch[2];
            const amount = parseFloat(priceStr) || 0;

            // Skip negative amounts (discounts) and invalid amounts
            if (amount > 0 && amount <= 10000 && description) {
              items.push({
                id: `${Date.now()}_line${lineNumber}`,
                lineNumber: lineNumber++,
                description,
                quantity: 1,
                unitPrice: amount,
                amount,
                taxCode,
                confidence: 0.8,
              });
              i += 2; // Skip both lines
              continue;
            }
          }
        }
      }

      // Standard format: description + price on same line
      // Require price to have decimal point (###.##)
      const priceMatch = trimmedLine.match(pricePattern);
      if (priceMatch) {
        const priceStr = priceMatch[1] || '0';
        const taxCode = priceMatch[2];
        const amount = parseFloat(priceStr) || 0;

        // Skip very small amounts or very large (likely totals)
        if (amount >= 0.01 && amount <= 10000) {
          // Extract description (everything before the price)
          let description = trimmedLine.substring(0, priceMatch.index).trim();

          // Default quantity and unit price
          let quantity = 1;
          let unitPrice = amount;

          // Check for quantity patterns
          for (const qtyPattern of qtyPatterns) {
            const qtyMatch = description.match(qtyPattern);
            if (qtyMatch) {
              const qty = parseFloat(qtyMatch[1] || '1') || 1;
              if (qty > 0 && qty < 1000) {
                quantity = qty;
                // If we have "2 @ $5.99", extract unit price
                if (qtyMatch[2]) {
                  const parsedUnit = parseFloat(qtyMatch[2]);
                  unitPrice = parsedUnit > 0 ? parsedUnit : amount / quantity;
                } else {
                  unitPrice = amount / quantity;
                }
                // Remove quantity pattern from description
                description = description.replace(qtyPattern, '').trim();
              }
              break;
            }
          }

          // Clean up description - remove SKU numbers at start
          description = description
            .replace(/^\d{6,}\s+/, '') // Remove leading SKU
            .replace(/\s+/g, ' ')       // Normalize whitespace
            .trim();

          // Skip if description is too short or doesn't have at least 2 consecutive letters
          if (description.length >= 2 && /[a-zA-Z]{2,}/.test(description)) {
            items.push({
              id: `${Date.now()}_line${lineNumber}`,
              lineNumber: lineNumber++,
              description,
              quantity,
              unitPrice,
              amount,
              taxCode,
              confidence: 0.7,
            });
          }
        }
      }

      i++;

      // Limit to reasonable number of line items
      if (lineNumber > 100) break;
    }

    return items;
  }, []);

  // Process document with Tesseract.js OCR
  const processDocument = useCallback(async (file: AISFileInfo) => {
    setStatus(DocScanStatus.Scanning);
    setProgress(0.1);
    setError(null);

    const startTime = Date.now();

    try {
      setProgress(0.2);
      setStatus(DocScanStatus.Extracting);
      setActiveProvider(selectedProvider);

      let ocrText = '';

      // If self-mapping mode, skip OCR
      if (selectedProvider === AIProviderTier.SelfMapping) {
        setProgress(0.9);
      } else {
        // Use Tesseract.js for real OCR
        try {
          // Use the raw File object if available, otherwise try previewUrl
          let imageSource: File | string | undefined = file.file;
          if (!imageSource && file.previewUrl) {
            imageSource = file.previewUrl;
          }

          if (imageSource) {
            const tesseractResult = await Tesseract.recognize(
              imageSource,
              'eng',
              {
                logger: (m) => {
                  if (m.status === 'recognizing text') {
                    // Map Tesseract progress (0-1) to our progress (0.2-0.8)
                    setProgress(0.2 + m.progress * 0.6);
                  }
                },
              }
            );

            ocrText = tesseractResult.data.text;
          } else {
            console.warn('No file source available for OCR');
            setActiveProvider(AIProviderTier.SelfMapping);
          }
        } catch (ocrError) {
          console.error('Tesseract OCR failed:', ocrError);
          // Fall back to manual entry if OCR fails
          setActiveProvider(AIProviderTier.SelfMapping);
        }
      }

      setProgress(0.85);

      // Create result and parse extracted text
      const result = createEmptyResult(file.id);
      result.providerUsed = activeProvider;
      result.rawOCRText = ocrText;

      // Parse invoice fields from OCR text
      if (ocrText) {
        parseInvoiceFields(result, ocrText);
      }

      setProgress(0.95);

      const processingTime = Date.now() - startTime;
      result.processingTimeMs = processingTime;
      result.status = DocScanStatus.Review;

      setCurrentResult(result);
      setStatus(DocScanStatus.Review);
      setProgress(1.0);
    } catch (err) {
      // Fallback to manual entry
      const manualResult = createEmptyResult(file.id);
      manualResult.status = DocScanStatus.Review;

      setCurrentResult(manualResult);
      setStatus(DocScanStatus.Review);
      setError(err instanceof Error ? err.message : 'Processing failed');
      setProgress(1.0);
    }
  }, [selectedProvider, activeProvider, parseInvoiceFields]);

  // Validate result
  const validateResult = useCallback((): string[] => {
    if (!currentResult) return ['No document scanned'];

    const errors: string[] = [];
    if (!currentResult.vendorName.mappedValue) errors.push('Vendor name is required');
    if (!currentResult.invoiceNumber.mappedValue) errors.push('Invoice number is required');
    if (!currentResult.invoiceDate.mappedValue) errors.push('Invoice date is required');
    if (!currentResult.totalAmount.mappedValue) errors.push('Total amount is required');

    // Check amounts balance
    const subtotal = parseFloat(currentResult.subtotal.mappedValue) || 0;
    const tax = parseFloat(currentResult.taxAmount.mappedValue) || 0;
    const total = parseFloat(currentResult.totalAmount.mappedValue) || 0;
    if (subtotal > 0 && tax >= 0 && Math.abs(subtotal + tax - total) > 0.01) {
      errors.push('Subtotal + Tax does not equal Total');
    }

    return errors;
  }, [currentResult]);

  // Approve result
  const approveResult = useCallback(() => {
    if (!currentResult) return;

    const errors = validateResult();
    const newResult = { ...currentResult, validationErrors: errors };

    if (errors.length === 0) {
      newResult.status = DocScanStatus.Approved;
      setStatus(DocScanStatus.Approved);
    }

    setCurrentResult(newResult);
  }, [currentResult, validateResult]);

  // Reject result
  const rejectResult = useCallback(() => {
    if (!currentResult) return;

    setCurrentResult({ ...currentResult, status: DocScanStatus.Rejected });
    setStatus(DocScanStatus.Rejected);
  }, [currentResult]);

  // Reset
  const reset = useCallback(() => {
    setCurrentResult(null);
    setStatus(DocScanStatus.Pending);
    setProgress(0);
    setError(null);
    setActiveProvider(AIProviderTier.SelfMapping);
    setSelectedFile(null);
  }, []);

  // Update field
  const updateField = useCallback((fieldKey: string, newValue: string) => {
    if (!currentResult) return;

    const updateFieldInResult = (field: ExtractedField): ExtractedField => {
      if (field.fieldKey !== fieldKey) return field;
      return {
        ...field,
        mappedValue: newValue,
        isEdited: true,
        confidenceLevel: ExtractionConfidence.Manual,
      };
    };

    setCurrentResult({
      ...currentResult,
      vendorName: updateFieldInResult(currentResult.vendorName),
      vendorAddress: updateFieldInResult(currentResult.vendorAddress),
      invoiceNumber: updateFieldInResult(currentResult.invoiceNumber),
      invoiceDate: updateFieldInResult(currentResult.invoiceDate),
      dueDate: updateFieldInResult(currentResult.dueDate),
      poNumber: updateFieldInResult(currentResult.poNumber),
      subtotal: updateFieldInResult(currentResult.subtotal),
      taxAmount: updateFieldInResult(currentResult.taxAmount),
      totalAmount: updateFieldInResult(currentResult.totalAmount),
      currency: updateFieldInResult(currentResult.currency),
    });
  }, [currentResult]);

  // Computed values
  const overallConfidence = useMemo(() => {
    if (!currentResult) return 0;
    const fields = [
      currentResult.vendorName,
      currentResult.vendorAddress,
      currentResult.invoiceNumber,
      currentResult.invoiceDate,
      currentResult.dueDate,
      currentResult.poNumber,
      currentResult.subtotal,
      currentResult.taxAmount,
      currentResult.totalAmount,
      currentResult.currency,
    ];
    const total = fields.reduce((sum, f) => sum + f.confidence, 0);
    return total / fields.length;
  }, [currentResult]);

  // Render content based on status
  const renderContent = () => {
    switch (status) {
      case DocScanStatus.Pending:
        return renderFileSelection();
      case DocScanStatus.Scanning:
      case DocScanStatus.Extracting:
        return renderProcessing();
      case DocScanStatus.Review:
      case DocScanStatus.Approved:
        return renderReview();
      case DocScanStatus.Rejected:
        return renderRejected();
      case DocScanStatus.Error:
        return renderError();
      case DocScanStatus.Posted:
        return renderPosted();
      default:
        return renderFileSelection();
    }
  };

  // File selection view
  const renderFileSelection = () => (
    <div className="flex flex-col items-center space-y-6 py-8">
      <FileText size={64} style={{ color: tokens.actionPrimary.color }} />
      <div className="text-center">
        <h2 className="text-xl font-bold" style={{ color: tokens.onSurface }}>
          Scan Invoice Document
        </h2>
        <p className="mt-2" style={{ color: tokens.onSurfaceSecondary }}>
          Select an invoice image or PDF to extract vendor, amounts, and line items automatically.
        </p>
      </div>

      <AISMediaPicker
        allowedTypes={['image', 'pdf']}
        multiple={false}
        maxSizeBytes={50 * 1024 * 1024}
        label="Select Invoice"
        onFilesSelected={(files) => {
          if (files.length > 0) {
            setSelectedFile(files[0]);
            processDocument(files[0]);
          }
        }}
      />

      {/* Provider selection */}
      <div
        className="w-full max-w-md p-4 rounded-lg"
        style={{ backgroundColor: tokens.surfaceSecondary }}
      >
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
            AI Provider
          </label>
          <button
            onClick={() => setShowSettingsModal(true)}
            className="flex items-center space-x-1 px-2 py-1 rounded text-xs hover:opacity-80 transition-opacity"
            style={{ backgroundColor: tokens.actionPrimary.color, color: '#FFFFFF' }}
          >
            <Settings size={12} />
            <span>Setup</span>
          </button>
        </div>
        <div className="grid grid-cols-4 gap-2">
          {Object.values(AI_PROVIDERS).map((provider) => {
            const Icon = provider.icon;
            const isSelected = selectedProvider === provider.tier;
            return (
              <button
                key={provider.tier}
                onClick={() => setSelectedProvider(provider.tier)}
                className={clsx(
                  'flex flex-col items-center p-2 rounded-md border-2 transition-colors',
                  isSelected ? 'border-blue-500' : 'border-transparent'
                )}
                style={{
                  backgroundColor: isSelected ? `${tokens.actionPrimary.color}20` : tokens.surface,
                }}
                title={provider.description}
              >
                <Icon size={20} style={{ color: isSelected ? tokens.actionPrimary.color : tokens.onSurfaceSecondary }} />
                <span className="text-xs mt-1" style={{ color: tokens.onSurface }}>
                  {provider.displayName}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );

  // Processing view
  const renderProcessing = () => (
    <div className="flex flex-col items-center justify-center space-y-6 py-16">
      <div className="w-64">
        <div
          className="h-2 rounded-full overflow-hidden"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          <div
            className="h-full rounded-full transition-all duration-300"
            style={{
              width: `${progress * 100}%`,
              backgroundColor: tokens.actionPrimary.color,
            }}
          />
        </div>
      </div>
      <div className="flex flex-col items-center space-y-2">
        {status === DocScanStatus.Scanning ? (
          <Scan size={48} className="animate-pulse" style={{ color: tokens.actionPrimary.color }} />
        ) : (
          <Cpu size={48} className="animate-pulse" style={{ color: tokens.actionPrimary.color }} />
        )}
        <span className="text-lg font-bold" style={{ color: tokens.onSurface }}>
          {STATUS_CONFIG[status].displayName}
        </span>
        <span className="text-sm" style={{ color: tokens.onSurfaceSecondary }}>
          Using {AI_PROVIDERS[activeProvider].displayName}
        </span>
      </div>
    </div>
  );

  // Review view
  const renderReview = () => {
    if (!currentResult) return null;

    return (
      <div className="space-y-4">
        {/* Status and confidence */}
        <div className="flex items-center justify-between">
          <AISStateBadge
            state={STATUS_CONFIG[status].badgeState}
            label={STATUS_CONFIG[status].displayName}
          />
          <div className="flex items-center space-x-2">
            {currentResult.rawOCRText && (
              <button
                onClick={() => setShowRawOCR(!showRawOCR)}
                className="flex items-center space-x-1 text-sm"
                style={{ color: tokens.actionPrimary.color }}
              >
                <FileText size={14} />
                <span>Raw OCR</span>
              </button>
            )}
            <button
              onClick={() => setShowOCROutputModal(true)}
              className="flex items-center space-x-1 px-2 py-1 rounded text-xs hover:opacity-80 transition-opacity"
              style={{ backgroundColor: tokens.actionPrimary.color, color: '#FFFFFF' }}
            >
              <FileOutput size={12} />
              <span>View Full Output</span>
            </button>
          </div>
        </div>

        {/* Confidence bar */}
        <ConfidenceBar confidence={overallConfidence} tokens={tokens} />

        {/* Validation errors */}
        {currentResult.validationErrors.length > 0 && (
          <ValidationErrors errors={currentResult.validationErrors} tokens={tokens} />
        )}

        {/* Header fields */}
        <SectionHeader title="Invoice Details" icon={FileText} tokens={tokens} />
        <div className="grid grid-cols-2 gap-3">
          <EditableFieldRow field={currentResult.vendorName} onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.invoiceNumber} onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.invoiceDate} onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.dueDate} onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.poNumber} onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.vendorAddress} onUpdate={updateField} tokens={tokens} />
        </div>

        {/* Amount fields */}
        <SectionHeader title="Amounts" icon={DollarSign} tokens={tokens} />
        <div className="grid grid-cols-3 gap-3">
          <EditableFieldRow field={currentResult.subtotal} prefix="$" onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.taxAmount} prefix="$" onUpdate={updateField} tokens={tokens} />
          <EditableFieldRow field={currentResult.totalAmount} prefix="$" onUpdate={updateField} tokens={tokens} />
        </div>

        {/* Line items */}
        {currentResult.lineItems.length > 0 && (
          <>
            <SectionHeader title="Line Items" icon={List} tokens={tokens} />
            <LineItemsTable items={currentResult.lineItems} tokens={tokens} />
          </>
        )}

        {/* Raw OCR */}
        {showRawOCR && currentResult.rawOCRText && (
          <RawOCRSection text={currentResult.rawOCRText} tokens={tokens} />
        )}
      </div>
    );
  };

  // Rejected view
  const renderRejected = () => (
    <div className="flex flex-col items-center justify-center space-y-4 py-16">
      <XCircle size={64} style={{ color: tokens.stateError.color }} />
      <h2 className="text-xl font-bold" style={{ color: tokens.onSurface }}>
        Document Rejected
      </h2>
      <p style={{ color: tokens.onSurfaceSecondary }}>
        This invoice has been rejected and will not be posted.
      </p>
      <AISButton actionType="primary" onClick={reset}>
        Scan Another
      </AISButton>
    </div>
  );

  // Error view
  const renderError = () => (
    <div className="flex flex-col items-center justify-center space-y-4 py-16">
      <AlertTriangle size={64} style={{ color: tokens.stateError.color }} />
      <h2 className="text-xl font-bold" style={{ color: tokens.onSurface }}>
        Processing Error
      </h2>
      {error && (
        <p className="text-center" style={{ color: tokens.onSurfaceSecondary }}>
          {error}
        </p>
      )}
      <div className="flex space-x-3">
        <AISButton
          actionType="secondary"
          onClick={() => selectedFile && processDocument(selectedFile)}
        >
          Try Again
        </AISButton>
        <AISButton
          actionType="primary"
          onClick={() => {
            const result = createEmptyResult(selectedFile?.id || 'manual');
            result.status = DocScanStatus.Review;
            setCurrentResult(result);
            setStatus(DocScanStatus.Review);
          }}
        >
          Manual Entry
        </AISButton>
      </div>
    </div>
  );

  // Posted view
  const renderPosted = () => (
    <div className="flex flex-col items-center justify-center space-y-4 py-16">
      <ShieldCheck size={64} style={{ color: tokens.actionConfirm.color }} />
      <h2 className="text-xl font-bold" style={{ color: tokens.onSurface }}>
        Invoice Posted
      </h2>
      <p style={{ color: tokens.onSurfaceSecondary }}>
        The AP entry has been created successfully.
      </p>
      <AISButton actionType="primary" onClick={reset}>
        Scan Another
      </AISButton>
    </div>
  );

  return (
    <div
      className={clsx('flex flex-col h-full', className)}
      style={{ backgroundColor: tokens.surface }}
    >
      {/* Header */}
      <div
        className="flex items-center justify-between px-4 py-3 border-b"
        style={{ borderColor: `${tokens.onSurface}20` }}
      >
        <div>
          <h1 className="text-lg font-bold" style={{ color: tokens.onSurface }}>
            Document Scanner
          </h1>
          <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
            AP Invoice Entry
          </span>
        </div>
        <div
          className="flex items-center space-x-2 px-2 py-1 rounded"
          style={{ backgroundColor: tokens.surfaceSecondary }}
        >
          {React.createElement(AI_PROVIDERS[activeProvider].icon, {
            size: 16,
            style: { color: tokens.actionPrimary.color },
          })}
          <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
            {AI_PROVIDERS[activeProvider].displayName}
          </span>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">{renderContent()}</div>

      {/* Footer */}
      <div
        className="flex items-center justify-between px-4 py-3 border-t"
        style={{ borderColor: `${tokens.onSurface}20` }}
      >
        <AISButton actionType="secondary" onClick={onCancel}>
          Cancel
        </AISButton>
        {(status === DocScanStatus.Review || status === DocScanStatus.Approved) && (
          <div className="flex space-x-3">
            <AISButton actionType="destructive" onClick={rejectResult}>
              Reject
            </AISButton>
            <AISButton
              actionType="confirm"
              onClick={() => {
                if (status === DocScanStatus.Approved && currentResult) {
                  onComplete?.(currentResult);
                } else {
                  approveResult();
                }
              }}
            >
              {status === DocScanStatus.Approved ? 'Post' : 'Approve'}
            </AISButton>
          </div>
        )}
      </div>

      {/* Modals */}
      <AISettingsModal
        isOpen={showSettingsModal}
        onClose={() => setShowSettingsModal(false)}
        tokens={tokens}
      />
      <OCROutputModal
        isOpen={showOCROutputModal}
        onClose={() => setShowOCROutputModal(false)}
        result={currentResult}
        tokens={tokens}
      />
    </div>
  );
}

// ============================================================================
// Sub-components
// ============================================================================

interface SectionHeaderProps {
  title: string;
  icon: LucideIcon;
  tokens: ReturnType<typeof useAISTokens>;
}

function SectionHeader({ title, icon: Icon, tokens }: SectionHeaderProps) {
  return (
    <div className="flex items-center space-x-2 pt-3">
      <Icon size={18} style={{ color: tokens.actionPrimary.color }} />
      <span className="font-bold" style={{ color: tokens.onSurface }}>
        {title}
      </span>
    </div>
  );
}

interface ConfidenceBarProps {
  confidence: number;
  tokens: ReturnType<typeof useAISTokens>;
}

function ConfidenceBar({ confidence, tokens }: ConfidenceBarProps) {
  const color =
    confidence >= 0.9
      ? tokens.actionConfirm.color
      : confidence >= 0.7
      ? tokens.stateWarning.color
      : tokens.stateError.color;

  return (
    <div
      className="flex items-center justify-between p-2 rounded"
      style={{ backgroundColor: tokens.surfaceSecondary }}
    >
      <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
        Extraction Confidence
      </span>
      <div className="flex items-center space-x-2">
        <span className="text-xs font-bold" style={{ color }}>
          {Math.round(confidence * 100)}%
        </span>
        <div
          className="w-24 h-2 rounded-full overflow-hidden"
          style={{ backgroundColor: `${tokens.onSurface}20` }}
        >
          <div
            className="h-full rounded-full"
            style={{ width: `${confidence * 100}%`, backgroundColor: color }}
          />
        </div>
      </div>
    </div>
  );
}

interface ValidationErrorsProps {
  errors: string[];
  tokens: ReturnType<typeof useAISTokens>;
}

function ValidationErrors({ errors, tokens }: ValidationErrorsProps) {
  return (
    <div
      className="p-2 rounded"
      style={{ backgroundColor: `${tokens.stateError.color}20` }}
    >
      {errors.map((error, i) => (
        <div key={i} className="flex items-center space-x-2 py-1">
          <AlertCircle size={14} style={{ color: tokens.stateError.color }} />
          <span className="text-xs" style={{ color: tokens.stateError.color }}>
            {error}
          </span>
        </div>
      ))}
    </div>
  );
}

interface EditableFieldRowProps {
  field: ExtractedField;
  prefix?: string;
  onUpdate: (fieldKey: string, value: string) => void;
  tokens: ReturnType<typeof useAISTokens>;
}

function EditableFieldRow({ field, prefix = '', onUpdate, tokens }: EditableFieldRowProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editValue, setEditValue] = useState(field.mappedValue);

  const confidenceColor = getConfidenceColor(field.confidenceLevel, tokens);

  const handleSave = () => {
    onUpdate(field.fieldKey, editValue);
    setIsEditing(false);
  };

  return (
    <div
      className="p-2 rounded"
      style={{ backgroundColor: tokens.surfaceSecondary }}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-1">
          <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
            {field.displayName}
          </span>
          {field.isRequired && (
            <span style={{ color: tokens.stateError.color }}>*</span>
          )}
        </div>
        <div
          className="w-2 h-2 rounded-full"
          style={{ backgroundColor: confidenceColor }}
          title={`Confidence: ${Math.round(field.confidence * 100)}%`}
        />
      </div>
      <div className="flex items-center mt-1">
        {prefix && (
          <span className="text-sm mr-1" style={{ color: tokens.onSurfaceSecondary }}>
            {prefix}
          </span>
        )}
        {isEditing ? (
          <input
            type="text"
            value={editValue}
            onChange={(e) => setEditValue(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSave()}
            autoFocus
            className="flex-1 text-sm bg-transparent border-none outline-none"
            style={{ color: tokens.onSurface }}
          />
        ) : (
          <span
            className="flex-1 text-sm"
            style={{ color: field.mappedValue ? tokens.onSurface : tokens.onSurfaceSecondary }}
          >
            {field.mappedValue || '-'}
          </span>
        )}
        <button
          onClick={() => {
            if (isEditing) {
              handleSave();
            } else {
              setEditValue(field.mappedValue);
              setIsEditing(true);
            }
          }}
          className="ml-2 p-1 rounded hover:bg-black/10"
        >
          {isEditing ? (
            <Check size={14} style={{ color: tokens.actionPrimary.color }} />
          ) : (
            <Edit2 size={14} style={{ color: tokens.actionPrimary.color }} />
          )}
        </button>
      </div>
    </div>
  );
}

interface LineItemsTableProps {
  items: InvoiceLineItem[];
  tokens: ReturnType<typeof useAISTokens>;
}

function LineItemsTable({ items, tokens }: LineItemsTableProps) {
  return (
    <div
      className="rounded overflow-hidden border"
      style={{ borderColor: `${tokens.onSurface}20` }}
    >
      <div
        className="grid grid-cols-5 gap-2 p-2 text-xs font-bold"
        style={{ backgroundColor: tokens.surfaceSecondary, color: tokens.onSurfaceSecondary }}
      >
        <span>#</span>
        <span className="col-span-2">Description</span>
        <span className="text-right">Qty</span>
        <span className="text-right">Amount</span>
      </div>
      {items.map((item) => (
        <div
          key={item.id}
          className="grid grid-cols-5 gap-2 p-2 text-xs border-t"
          style={{ borderColor: `${tokens.onSurface}10`, color: tokens.onSurface }}
        >
          <span>{item.lineNumber}</span>
          <span className="col-span-2">{item.description}</span>
          <span className="text-right">{item.quantity}</span>
          <span className="text-right">${item.amount.toFixed(2)}</span>
        </div>
      ))}
    </div>
  );
}

interface RawOCRSectionProps {
  text: string;
  tokens: ReturnType<typeof useAISTokens>;
}

function RawOCRSection({ text, tokens }: RawOCRSectionProps) {
  return (
    <div
      className="p-3 rounded"
      style={{ backgroundColor: tokens.surfaceSecondary }}
    >
      <span className="text-xs font-bold" style={{ color: tokens.onSurfaceSecondary }}>
        Raw OCR Text
      </span>
      <div
        className="mt-2 max-h-48 overflow-auto text-xs font-mono whitespace-pre-wrap"
        style={{ color: tokens.onSurface }}
      >
        {text}
      </div>
    </div>
  );
}

// ============================================================================
// AI Settings Modal
// ============================================================================

interface AISettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  tokens: ReturnType<typeof useAISTokens>;
}

interface CloudProviderConfig {
  id: string;
  name: string;
  apiKey: string;
  endpoint: string;
}

interface LocalProviderConfig {
  id: string;
  name: string;
  endpoint: string;
  isEnabled: boolean;
}

function AISettingsModal({ isOpen, onClose, tokens }: AISettingsModalProps) {
  const [activeTab, setActiveTab] = useState<'cloud' | 'local'>('cloud');
  const [cloudProviders, setCloudProviders] = useState<CloudProviderConfig[]>([
    { id: 'claude', name: 'Claude (Anthropic)', apiKey: '', endpoint: 'https://api.anthropic.com/v1/messages' },
    { id: 'chatgpt', name: 'ChatGPT (OpenAI)', apiKey: '', endpoint: 'https://api.openai.com/v1/chat/completions' },
    { id: 'gemini', name: 'Gemini (Google)', apiKey: '', endpoint: 'https://generativelanguage.googleapis.com/v1beta/models' },
  ]);
  const [localProviders, setLocalProviders] = useState<LocalProviderConfig[]>([
    { id: 'ollama', name: 'Ollama', endpoint: 'http://localhost:11434/api/generate', isEnabled: false },
    { id: 'lmstudio', name: 'LM Studio', endpoint: 'http://localhost:1234/v1/chat/completions', isEnabled: false },
  ]);
  const [testResult, setTestResult] = useState<{ providerId: string; success: boolean; message: string } | null>(null);
  const [isTesting, setIsTesting] = useState<string | null>(null);

  const testCloudConnection = async (provider: CloudProviderConfig) => {
    setIsTesting(provider.id);
    setTestResult(null);

    // Validate API key format
    let isValid = false;
    if (provider.id === 'claude' && provider.apiKey.startsWith('sk-ant-')) {
      isValid = true;
    } else if (provider.id === 'chatgpt' && provider.apiKey.startsWith('sk-')) {
      isValid = true;
    } else if (provider.id === 'gemini' && provider.apiKey.length > 20) {
      isValid = true;
    }

    // Simulate delay
    await new Promise((resolve) => setTimeout(resolve, 500));

    if (!provider.apiKey) {
      setTestResult({ providerId: provider.id, success: false, message: 'API key is required' });
    } else if (!isValid) {
      setTestResult({ providerId: provider.id, success: false, message: 'Invalid API key format' });
    } else {
      setTestResult({ providerId: provider.id, success: true, message: 'API key format is valid' });
    }
    setIsTesting(null);
  };

  const testLocalConnection = async (provider: LocalProviderConfig) => {
    setIsTesting(provider.id);
    setTestResult(null);

    try {
      await fetch(provider.endpoint, {
        method: 'GET',
        mode: 'no-cors',
      });

      // With no-cors, we can't read the response status, but if no error is thrown,
      // we assume the server is reachable
      setTestResult({
        providerId: provider.id,
        success: true,
        message: 'Connection successful (server is reachable)',
      });
    } catch (err) {
      setTestResult({
        providerId: provider.id,
        success: false,
        message: `Connection failed: ${err instanceof Error ? err.message : 'Unknown error'}`,
      });
    }
    setIsTesting(null);
  };

  const updateCloudApiKey = (id: string, apiKey: string) => {
    setCloudProviders((providers) =>
      providers.map((p) => (p.id === id ? { ...p, apiKey } : p))
    );
  };

  const updateLocalEndpoint = (id: string, endpoint: string) => {
    setLocalProviders((providers) =>
      providers.map((p) => (p.id === id ? { ...p, endpoint } : p))
    );
  };

  const toggleLocalEnabled = (id: string) => {
    setLocalProviders((providers) =>
      providers.map((p) => (p.id === id ? { ...p, isEnabled: !p.isEnabled } : p))
    );
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div
        className="w-full max-w-lg max-h-[80vh] overflow-auto rounded-lg shadow-xl"
        style={{ backgroundColor: tokens.surface }}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between px-4 py-3 border-b"
          style={{ borderColor: `${tokens.onSurface}20` }}
        >
          <h2 className="text-lg font-bold" style={{ color: tokens.onSurface }}>
            AI Settings
          </h2>
          <button
            onClick={onClose}
            className="p-1 rounded hover:bg-black/10"
          >
            <X size={20} style={{ color: tokens.onSurfaceSecondary }} />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b" style={{ borderColor: `${tokens.onSurface}20` }}>
          <button
            onClick={() => setActiveTab('cloud')}
            className={clsx('flex-1 px-4 py-2 text-sm font-medium transition-colors')}
            style={{
              color: activeTab === 'cloud' ? tokens.actionPrimary.color : tokens.onSurfaceSecondary,
              borderBottom: activeTab === 'cloud' ? `2px solid ${tokens.actionPrimary.color}` : '2px solid transparent',
            }}
          >
            <div className="flex items-center justify-center space-x-2">
              <Cloud size={16} />
              <span>Cloud LLM</span>
            </div>
          </button>
          <button
            onClick={() => setActiveTab('local')}
            className={clsx('flex-1 px-4 py-2 text-sm font-medium transition-colors')}
            style={{
              color: activeTab === 'local' ? tokens.actionPrimary.color : tokens.onSurfaceSecondary,
              borderBottom: activeTab === 'local' ? `2px solid ${tokens.actionPrimary.color}` : '2px solid transparent',
            }}
          >
            <div className="flex items-center justify-center space-x-2">
              <Cpu size={16} />
              <span>Local AI</span>
            </div>
          </button>
        </div>

        {/* Content */}
        <div className="p-4 space-y-4">
          {activeTab === 'cloud' && (
            <>
              <p className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
                Configure cloud LLM provider API keys for document processing.
              </p>
              {cloudProviders.map((provider) => (
                <div
                  key={provider.id}
                  className="p-3 rounded space-y-2"
                  style={{ backgroundColor: tokens.surfaceSecondary }}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm" style={{ color: tokens.onSurface }}>
                      {provider.name}
                    </span>
                  </div>
                  <input
                    type="password"
                    placeholder="API Key"
                    value={provider.apiKey}
                    onChange={(e) => updateCloudApiKey(provider.id, e.target.value)}
                    className="w-full px-3 py-2 text-sm rounded border"
                    style={{
                      backgroundColor: tokens.surface,
                      borderColor: `${tokens.onSurface}20`,
                      color: tokens.onSurface,
                    }}
                  />
                  <div className="flex items-center justify-between">
                    <button
                      onClick={() => testCloudConnection(provider)}
                      disabled={isTesting === provider.id}
                      className="flex items-center space-x-1 px-3 py-1 text-xs rounded hover:opacity-80 transition-opacity disabled:opacity-50"
                      style={{ backgroundColor: tokens.actionPrimary.color, color: '#FFFFFF' }}
                    >
                      {isTesting === provider.id ? (
                        <span>Testing...</span>
                      ) : (
                        <>
                          <Scan size={12} />
                          <span>Test Connection</span>
                        </>
                      )}
                    </button>
                    {testResult?.providerId === provider.id && (
                      <span
                        className="text-xs"
                        style={{ color: testResult.success ? tokens.actionConfirm.color : tokens.stateError.color }}
                      >
                        {testResult.message}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </>
          )}

          {activeTab === 'local' && (
            <>
              <p className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
                Configure local AI providers for offline document processing.
              </p>
              {localProviders.map((provider) => (
                <div
                  key={provider.id}
                  className="p-3 rounded space-y-2"
                  style={{ backgroundColor: tokens.surfaceSecondary }}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm" style={{ color: tokens.onSurface }}>
                      {provider.name}
                    </span>
                    <label className="flex items-center space-x-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={provider.isEnabled}
                        onChange={() => toggleLocalEnabled(provider.id)}
                        className="w-4 h-4"
                      />
                      <span className="text-xs" style={{ color: tokens.onSurfaceSecondary }}>
                        Enabled
                      </span>
                    </label>
                  </div>
                  <input
                    type="text"
                    placeholder="Endpoint URL"
                    value={provider.endpoint}
                    onChange={(e) => updateLocalEndpoint(provider.id, e.target.value)}
                    className="w-full px-3 py-2 text-sm rounded border"
                    style={{
                      backgroundColor: tokens.surface,
                      borderColor: `${tokens.onSurface}20`,
                      color: tokens.onSurface,
                    }}
                  />
                  <div className="flex items-center justify-between">
                    <button
                      onClick={() => testLocalConnection(provider)}
                      disabled={isTesting === provider.id}
                      className="flex items-center space-x-1 px-3 py-1 text-xs rounded hover:opacity-80 transition-opacity disabled:opacity-50"
                      style={{ backgroundColor: tokens.actionPrimary.color, color: '#FFFFFF' }}
                    >
                      {isTesting === provider.id ? (
                        <span>Testing...</span>
                      ) : (
                        <>
                          <Scan size={12} />
                          <span>Test Connection</span>
                        </>
                      )}
                    </button>
                    {testResult?.providerId === provider.id && (
                      <span
                        className="text-xs"
                        style={{ color: testResult.success ? tokens.actionConfirm.color : tokens.stateError.color }}
                      >
                        {testResult.message}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </>
          )}
        </div>

        {/* Footer */}
        <div
          className="flex justify-end px-4 py-3 border-t"
          style={{ borderColor: `${tokens.onSurface}20` }}
        >
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm rounded hover:opacity-80 transition-opacity"
            style={{ backgroundColor: tokens.actionPrimary.color, color: '#FFFFFF' }}
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// OCR Output Modal
// ============================================================================

interface OCROutputModalProps {
  isOpen: boolean;
  onClose: () => void;
  result: DocScanResult | null;
  tokens: ReturnType<typeof useAISTokens>;
}

function OCROutputModal({ isOpen, onClose, result, tokens }: OCROutputModalProps) {
  const [activeTab, setActiveTab] = useState<'text' | 'json'>('text');
  const [copied, setCopied] = useState(false);

  const jsonOutput = result
    ? JSON.stringify(
        {
          vendorName: result.vendorName.mappedValue,
          vendorAddress: result.vendorAddress.mappedValue,
          invoiceNumber: result.invoiceNumber.mappedValue,
          invoiceDate: result.invoiceDate.mappedValue,
          dueDate: result.dueDate.mappedValue,
          poNumber: result.poNumber.mappedValue,
          subtotal: result.subtotal.mappedValue,
          taxAmount: result.taxAmount.mappedValue,
          totalAmount: result.totalAmount.mappedValue,
          currency: result.currency.mappedValue,
          lineItems: result.lineItems.map((item) => ({
            lineNumber: item.lineNumber,
            description: item.description,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            amount: item.amount,
          })),
          providerUsed: AIProviderTier[result.providerUsed],
          processingTimeMs: result.processingTimeMs,
        },
        null,
        2
      )
    : '';

  const copyToClipboard = async () => {
    const text = activeTab === 'text' ? result?.rawOCRText || '' : jsonOutput;
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  if (!isOpen || !result) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div
        className="w-full max-w-2xl max-h-[80vh] overflow-auto rounded-lg shadow-xl"
        style={{ backgroundColor: tokens.surface }}
      >
        {/* Header */}
        <div
          className="flex items-center justify-between px-4 py-3 border-b"
          style={{ borderColor: `${tokens.onSurface}20` }}
        >
          <h2 className="text-lg font-bold" style={{ color: tokens.onSurface }}>
            OCR Output
          </h2>
          <button
            onClick={onClose}
            className="p-1 rounded hover:bg-black/10"
          >
            <X size={20} style={{ color: tokens.onSurfaceSecondary }} />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b" style={{ borderColor: `${tokens.onSurface}20` }}>
          <button
            onClick={() => setActiveTab('text')}
            className={clsx('flex-1 px-4 py-2 text-sm font-medium transition-colors')}
            style={{
              color: activeTab === 'text' ? tokens.actionPrimary.color : tokens.onSurfaceSecondary,
              borderBottom: activeTab === 'text' ? `2px solid ${tokens.actionPrimary.color}` : '2px solid transparent',
            }}
          >
            <div className="flex items-center justify-center space-x-2">
              <FileText size={16} />
              <span>Text</span>
            </div>
          </button>
          <button
            onClick={() => setActiveTab('json')}
            className={clsx('flex-1 px-4 py-2 text-sm font-medium transition-colors')}
            style={{
              color: activeTab === 'json' ? tokens.actionPrimary.color : tokens.onSurfaceSecondary,
              borderBottom: activeTab === 'json' ? `2px solid ${tokens.actionPrimary.color}` : '2px solid transparent',
            }}
          >
            <div className="flex items-center justify-center space-x-2">
              <Code size={16} />
              <span>JSON</span>
            </div>
          </button>
        </div>

        {/* Content */}
        <div className="p-4">
          <div
            className="p-4 rounded font-mono text-xs whitespace-pre-wrap max-h-96 overflow-auto"
            style={{ backgroundColor: tokens.surfaceSecondary, color: tokens.onSurface }}
          >
            {activeTab === 'text' ? (result.rawOCRText || 'No raw OCR text available') : jsonOutput}
          </div>
        </div>

        {/* Footer */}
        <div
          className="flex justify-between items-center px-4 py-3 border-t"
          style={{ borderColor: `${tokens.onSurface}20` }}
        >
          <button
            onClick={copyToClipboard}
            className="flex items-center space-x-1 px-3 py-2 text-sm rounded hover:opacity-80 transition-opacity"
            style={{ backgroundColor: tokens.surfaceSecondary, color: tokens.onSurface }}
          >
            <Copy size={14} />
            <span>{copied ? 'Copied!' : 'Copy to Clipboard'}</span>
          </button>
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm rounded hover:opacity-80 transition-opacity"
            style={{ backgroundColor: tokens.actionPrimary.color, color: '#FFFFFF' }}
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

export default AISDocScanWidget;
