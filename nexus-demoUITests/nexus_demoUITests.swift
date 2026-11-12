import XCTest

final class NexusDemoUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Domain Selection Screen

    func testDomainSelectionScreenLoads() throws {
        // The root screen should show the domain grid
        XCTAssertTrue(app.staticTexts["Choose a domain"].waitForExistence(timeout: 5),
                      "Domain selection header should be visible")
        XCTAssertTrue(app.staticTexts["E-commerce"].exists, "E-commerce tile should exist")
        XCTAssertTrue(app.staticTexts["Healthcare"].exists, "Healthcare tile should exist")
        XCTAssertTrue(app.staticTexts["BFSI"].exists, "BFSI tile should exist")
        XCTAssertTrue(app.staticTexts["Travel"].exists, "Travel tile should exist")
    }

    // MARK: - BFSI Login + State Propagation

    func testBFSILoginStoresUserAndShowsOnDashboard() throws {
        // Tap BFSI tile
        app.staticTexts["BFSI"].tap()

        // Should land on BFSI login
        XCTAssertTrue(app.staticTexts["DemoBank"].waitForExistence(timeout: 5),
                      "DemoBank login title should appear")

        // Enter credentials
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("alex.morgan@example.com")

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        passwordField.tap()
        passwordField.typeText("password123")

        app.buttons["Sign In"].tap()

        // Dashboard should appear with the user's name
        XCTAssertTrue(app.staticTexts["Accounts"].waitForExistence(timeout: 5),
                      "Dashboard Accounts title should appear after login")
        XCTAssertTrue(app.staticTexts["Alex Morgan"].waitForExistence(timeout: 3),
                      "Logged-in user name should appear on dashboard")

        // Navigate to Profile tab and verify name is replicated
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Alex Morgan"].waitForExistence(timeout: 3),
                      "User name should be replicated on Profile screen")
        XCTAssertTrue(app.staticTexts["alex.morgan@example.com"].waitForExistence(timeout: 3),
                      "User email should be replicated on Profile screen")
    }

    // MARK: - E-commerce Login + State Propagation

    func testECommerceLoginStoresUserAndShowsOnProfile() throws {
        app.staticTexts["E-commerce"].tap()

        XCTAssertTrue(app.staticTexts["ShopNexus"].waitForExistence(timeout: 5),
                      "ShopNexus login title should appear")

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("jane.doe@shop.com")

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        passwordField.tap()
        passwordField.typeText("shoppass")

        app.buttons["Sign In"].tap()

        // Should land on Shop tab
        XCTAssertTrue(app.staticTexts["Shop"].waitForExistence(timeout: 5),
                      "Shop screen should appear after e-commerce login")

        // Navigate to Profile and verify name
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Jane Doe"].waitForExistence(timeout: 3),
                      "Derived user name should appear on e-commerce Profile screen")
        XCTAssertTrue(app.staticTexts["jane.doe@shop.com"].waitForExistence(timeout: 3),
                      "User email should appear on e-commerce Profile screen")
    }

    // MARK: - Healthcare Login + State Propagation

    func testHealthcareLoginStoresUserAndShowsOnProfile() throws {
        app.staticTexts["Healthcare"].tap()

        XCTAssertTrue(app.staticTexts["CareNexus"].waitForExistence(timeout: 5),
                      "CareNexus login title should appear")

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("dr.smith@care.com")

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        passwordField.tap()
        passwordField.typeText("carepass")

        app.buttons["Sign In"].tap()

        XCTAssertTrue(app.staticTexts["Care"].waitForExistence(timeout: 5),
                      "Care screen should appear after healthcare login")

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Dr Smith"].waitForExistence(timeout: 3),
                      "Derived user name should appear on healthcare Profile screen")
    }

    // MARK: - Travel Login + State Propagation

    func testTravelLoginStoresUserAndShowsOnProfile() throws {
        app.staticTexts["Travel"].tap()

        XCTAssertTrue(app.staticTexts["TripNexus"].waitForExistence(timeout: 5),
                      "TripNexus login title should appear")

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        emailField.tap()
        emailField.typeText("traveler@trips.com")

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        passwordField.tap()
        passwordField.typeText("trippass")

        app.buttons["Sign In"].tap()

        XCTAssertTrue(app.staticTexts["Trips"].waitForExistence(timeout: 5),
                      "Trips screen should appear after travel login")

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Traveler"].waitForExistence(timeout: 3),
                      "Derived user name should appear on travel Profile screen")
    }

    // MARK: - QR Code Scanner

    func testQRCodeScannerScreenLoads() throws {
        // Navigate to Standalone demo
        let standaloneButton = app.buttons["Standalone demo, Test features without the full flow"]
        XCTAssertTrue(standaloneButton.waitForExistence(timeout: 5),
                      "Standalone demo button should be visible on home screen")
        standaloneButton.tap()

        // Scroll down to reveal item 11
        app.collectionViews.firstMatch.swipeUp()

        // Tap QR code scanner entry
        let qrCell = app.buttons["11, QR code scanner, Scan QR → view text result"]
        XCTAssertTrue(qrCell.waitForExistence(timeout: 5),
                      "QR code scanner entry should be visible after scrolling")
        qrCell.tap()

        // Handle camera permission if it appears
        let allowButton = app.alerts.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 3) {
            allowButton.tap()
        }

        // Verify scanner screen loaded
        XCTAssertTrue(app.navigationBars["Scan QR Code"].waitForExistence(timeout: 5),
                      "Scan QR Code navigation bar should appear")
        XCTAssertTrue(app.staticTexts["Point your camera at a QR code"].waitForExistence(timeout: 5),
                      "Scanner instruction text should be visible")
    }

    // MARK: - Sign Out clears state

    func testBFSISignOutReturnsToLogin() throws {
        // Login first
        app.staticTexts["BFSI"].tap()
        XCTAssertTrue(app.staticTexts["DemoBank"].waitForExistence(timeout: 5))
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("user@bank.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("pass")
        app.buttons["Sign In"].tap()

        XCTAssertTrue(app.staticTexts["Accounts"].waitForExistence(timeout: 5))

        // Go to Profile and sign out
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Sign Out"].tap()

        // Should return to BFSI login
        XCTAssertTrue(app.staticTexts["DemoBank"].waitForExistence(timeout: 5),
                      "Should return to DemoBank login after sign out")
    }
}