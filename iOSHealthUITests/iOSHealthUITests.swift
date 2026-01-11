import XCTest

final class iOSHealthUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLoginScreenElements() throws {
        // Verify login screen elements are present
        XCTAssertTrue(app.staticTexts["iOSHealth"].exists)
        XCTAssertTrue(app.textFields["E-post"].exists || app.textFields["email"].exists)
        XCTAssertTrue(app.secureTextFields["Lösenord"].exists || app.secureTextFields["password"].exists)
        XCTAssertTrue(app.buttons["Logga in"].exists)
    }

    func testNavigationToSignUp() throws {
        let signUpButton = app.buttons["Skapa konto"]
        if signUpButton.exists {
            signUpButton.tap()
            XCTAssertTrue(app.staticTexts["Skapa konto"].exists)
        }
    }

    func testSignInWithAppleButton() throws {
        let appleSignInButton = app.buttons["Fortsätt med Apple"]
        XCTAssertTrue(appleSignInButton.exists || app.buttons["Sign in with Apple"].exists)
    }
}
