// =============================================================================
// AISComponentsTests.swift
// AIS Demo App - Unit Tests
// =============================================================================
//
// PURPOSE:
// Unit tests for AIS component library ensuring conformance and correctness.
//
// =============================================================================

import XCTest
@testable import AISComponents

final class AISComponentsTests: XCTestCase {

    // MARK: - Token Tests

    func testLightTokensExist() {
        let tokens = AISTokenSet.light

        // Verify all action tokens exist
        XCTAssertNotNil(tokens.actionPrimary)
        XCTAssertNotNil(tokens.actionConfirm)
        XCTAssertNotNil(tokens.actionCaution)
        XCTAssertNotNil(tokens.actionDestructive)
        XCTAssertNotNil(tokens.actionNeutral)

        // Verify all state tokens exist
        XCTAssertNotNil(tokens.stateError)
        XCTAssertNotNil(tokens.stateWarning)
        XCTAssertNotNil(tokens.stateInfo)
        XCTAssertNotNil(tokens.stateUnavailable)
    }

    func testDarkTokensExist() {
        let tokens = AISTokenSet.dark

        // Verify all action tokens exist
        XCTAssertNotNil(tokens.actionPrimary)
        XCTAssertNotNil(tokens.actionConfirm)
        XCTAssertNotNil(tokens.actionCaution)
        XCTAssertNotNil(tokens.actionDestructive)
        XCTAssertNotNil(tokens.actionNeutral)

        // Verify all state tokens exist
        XCTAssertNotNil(tokens.stateError)
        XCTAssertNotNil(tokens.stateWarning)
        XCTAssertNotNil(tokens.stateInfo)
        XCTAssertNotNil(tokens.stateUnavailable)
    }

    func testTokensHaveIcons() {
        // AIS §2.3: Color is never the only signal
        let tokens = AISTokenSet.light

        XCTAssertFalse(tokens.actionPrimary.iconName.isEmpty)
        XCTAssertFalse(tokens.actionConfirm.iconName.isEmpty)
        XCTAssertFalse(tokens.actionCaution.iconName.isEmpty)
        XCTAssertFalse(tokens.actionDestructive.iconName.isEmpty)
        XCTAssertFalse(tokens.actionNeutral.iconName.isEmpty)
        XCTAssertFalse(tokens.stateError.iconName.isEmpty)
        XCTAssertFalse(tokens.stateWarning.iconName.isEmpty)
        XCTAssertFalse(tokens.stateInfo.iconName.isEmpty)
        XCTAssertFalse(tokens.stateUnavailable.iconName.isEmpty)
    }

    // MARK: - Spacing Tests

    func testSpacingValues() {
        // Verify 8-point grid system
        XCTAssertEqual(AISSpacing.xs, 4)
        XCTAssertEqual(AISSpacing.sm, 8)
        XCTAssertEqual(AISSpacing.md, 16)
        XCTAssertEqual(AISSpacing.lg, 24)
        XCTAssertEqual(AISSpacing.xl, 32)
        XCTAssertEqual(AISSpacing.xxl, 48)
    }

    func testRadiusValues() {
        XCTAssertEqual(AISRadius.sm, 4)
        XCTAssertEqual(AISRadius.md, 8)
        XCTAssertEqual(AISRadius.lg, 12)
        XCTAssertEqual(AISRadius.xl, 16)
        XCTAssertGreaterThan(AISRadius.full, 1000) // Pill shape
    }

    // MARK: - File Info Tests

    func testAISFileInfoCreation() {
        let file = AISFileInfo(
            fileName: "test.pdf",
            mimeType: "application/pdf",
            fileSize: 1024,
            checksum: "abc123",
            localPath: "/tmp/test.pdf"
        )

        XCTAssertEqual(file.fileName, "test.pdf")
        XCTAssertEqual(file.mimeType, "application/pdf")
        XCTAssertEqual(file.fileSize, 1024)
        XCTAssertEqual(file.checksum, "abc123")
        XCTAssertEqual(file.localPath, "/tmp/test.pdf")
    }

    func testAISFileInfoHashable() {
        let file1 = AISFileInfo(
            fileName: "test.pdf",
            mimeType: "application/pdf",
            fileSize: 1024,
            checksum: "abc123",
            localPath: "/tmp/test.pdf"
        )

        let file2 = AISFileInfo(
            fileName: "test.pdf",
            mimeType: "application/pdf",
            fileSize: 1024,
            checksum: "abc123",
            localPath: "/tmp/test.pdf"
        )

        // Different UUIDs should make them not equal
        XCTAssertNotEqual(file1, file2)
        XCTAssertNotEqual(file1.id, file2.id)
    }

    // MARK: - Semantic State Tests

    func testSemanticStateLabels() {
        XCTAssertEqual(AISSemanticState.draft.label, "Draft")
        XCTAssertEqual(AISSemanticState.pending.label, "Pending")
        XCTAssertEqual(AISSemanticState.active.label, "Active")
        XCTAssertEqual(AISSemanticState.completed.label, "Completed")
        XCTAssertEqual(AISSemanticState.archived.label, "Archived")
        XCTAssertEqual(AISSemanticState.error.label, "Error")
        XCTAssertEqual(AISSemanticState.warning.label, "Warning")
        XCTAssertEqual(AISSemanticState.inactive.label, "Inactive")
    }

    func testSemanticStateIcons() {
        // All states must have icons (AIS §2.3)
        for state in AISSemanticState.allCases {
            XCTAssertFalse(state.iconName.isEmpty, "\(state) should have an icon")
        }
    }

    // MARK: - Loading State Tests

    func testLoadingStateProperties() {
        let idle: AISLoadingState<String> = .idle
        let loading: AISLoadingState<String> = .loading
        let success: AISLoadingState<String> = .success("data")
        let failure: AISLoadingState<String> = .failure(
            AISErrorInfo(title: "Error", message: "Test")
        )

        XCTAssertFalse(idle.isLoading)
        XCTAssertTrue(loading.isLoading)
        XCTAssertFalse(success.isLoading)
        XCTAssertFalse(failure.isLoading)

        XCTAssertNil(idle.value)
        XCTAssertNil(loading.value)
        XCTAssertEqual(success.value, "data")
        XCTAssertNil(failure.value)

        XCTAssertNil(idle.error)
        XCTAssertNil(loading.error)
        XCTAssertNil(success.error)
        XCTAssertNotNil(failure.error)
    }

    // MARK: - Error Info Tests

    func testErrorInfoCreation() {
        let error = AISErrorInfo(
            title: "Test Error",
            message: "This is a test",
            severity: .error,
            code: "TEST_001"
        )

        XCTAssertEqual(error.title, "Test Error")
        XCTAssertEqual(error.message, "This is a test")
        XCTAssertEqual(error.code, "TEST_001")
    }

    func testErrorInfoFactoryMethods() {
        var retryCalled = false
        let networkError = AISErrorInfo.networkError(
            onRetry: { retryCalled = true }
        )

        XCTAssertEqual(networkError.title, "Connection Failed")
        XCTAssertEqual(networkError.code, "NET_001")
        XCTAssertFalse(networkError.actions.isEmpty)

        // Execute retry action
        networkError.actions.first?.action()
        XCTAssertTrue(retryCalled)
    }

    // MARK: - File Category Tests

    func testFileCategoryUTTypes() {
        // All categories should have valid UTTypes
        for category in AISFileCategory.allCases {
            XCTAssertNotNil(category.utType)
        }
    }

    func testFileCategoryDisplayNames() {
        // All categories should have display names
        for category in AISFileCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }
}
