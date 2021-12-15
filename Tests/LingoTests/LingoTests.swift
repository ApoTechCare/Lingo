import XCTest
import Logging
@testable import Lingo

class LingoTests: XCTestCase {
    
    let localizationsRootPath = NSTemporaryDirectory().appending("LingoTests")
    private let logger = Logger(label: "test")
    
    override func setUp() {
        super.setUp()
        try! DefaultFixtures.setup(atPath: self.localizationsRootPath) // swiftlint:disable:this force_try
    }
    
    func testNonExistingKeyReturnsRawKeyAsLocalization() throws {
        let lingo = try Lingo(rootPath: self.localizationsRootPath, defaultLocale: "en", logger: logger)
        XCTAssertEqual(lingo.localize("non.existing.key", locale: "en"), "non.existing.key")
    }
    
    func testFallbackToDefaultLocale() throws {
        let lingo = try Lingo(rootPath: self.localizationsRootPath, defaultLocale: "en", logger: logger)
        XCTAssertEqual(lingo.localize("hello.world", locale: "non-existing-locale"), "Hello World!")
    }

    func testFallbackToLanguageCodeWhenExactLocaleDoesntExist() throws {
        let lingo = try Lingo(rootPath: self.localizationsRootPath, defaultLocale: "en", logger: logger)
        XCTAssertEqual(lingo.localize("unread.messages", locale: "de_CH", interpolations: ["unread-messages-count": 24]), "Du hast 24 ungelesene Nachrichten.")
    }

    func testLocalizationWithoutInterpolations() throws {
        let lingo = try Lingo(rootPath: self.localizationsRootPath, defaultLocale: "en", logger: logger)
        XCTAssertEqual(lingo.localize("hello.world", locale: "en"), "Hello World!")
        XCTAssertEqual(lingo.localize("hello.world", locale: "de"), "Hallo Welt!")
    }

    func testLocalizationWithInterpolations() throws {
        let lingo = try Lingo(rootPath: self.localizationsRootPath, defaultLocale: "en", logger: logger)
        XCTAssertEqual(lingo.localize("unread.messages", locale: "en", interpolations: ["unread-messages-count": 1]), "You have an unread message.")
        XCTAssertEqual(lingo.localize("unread.messages", locale: "en", interpolations: ["unread-messages-count": 24]), "You have 24 unread messages.")
    }

    func testPluralizationFallbackWhenPluralizationRuleIsMissing() throws {
        let lingo = try Lingo(rootPath: self.localizationsRootPath, defaultLocale: "en", logger: logger)
        XCTAssertEqual(lingo.localize("unread.messages", locale: "en_XX", interpolations: ["unread-messages-count": 1]), "You have an unread message.")
        XCTAssertEqual(lingo.localize("unread.messages", locale: "en_XX", interpolations: ["unread-messages-count": 24]), "You have 24 unread messages.")
    }
    
}
