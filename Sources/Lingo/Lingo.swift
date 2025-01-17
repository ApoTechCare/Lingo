import Foundation
import Logging

public typealias LocalizationKey = String
public typealias LocaleIdentifier = String

public final class Lingo {
    
    public let defaultLocale: LocaleIdentifier
    public let dataSource: LocalizationDataSource
    private let logger: Logger
    
    private let model: LocalizationsModel
    
    /// Convenience initializer for Lingo.
    ///
    /// - `rootPath` should contain localization files in JSON format
    /// named based on relevant locale. For example: en.json, de.json etc.
    /// - `defaultLocale` will be used as a fallback when no localizations are available for a requested locale.
    public convenience init(
        rootPath: String,
        defaultLocale: LocaleIdentifier,
        logger: Logger
    ) throws {
        let dataSource = FileDataSource(rootPath: rootPath)
        try self.init(
            dataSource: dataSource,
            defaultLocale: defaultLocale,
            logger: logger
        )
    }
    
    /// Initializes Lingo with a `LocalizationDataSource`.
    /// - `defaultLocale` will be used as a fallback when no localizations are available for a requested locale.
    public init(
        dataSource: LocalizationDataSource,
        defaultLocale: LocaleIdentifier,
        logger: Logger
    ) throws {
        self.dataSource = dataSource
        self.defaultLocale = defaultLocale
        self.logger = logger
        self.model = LocalizationsModel()
        
        let validator = LocaleValidator()

        for locale in try dataSource.availableLocales() {
            // Check if locale is valid. Invalid locales will not cause any problems in the runtime,
            // so this validation should only warn about potential mistype in locale names.
            if !validator.validate(locale: locale) {
                logger.warning("\(Lingo.self): Invalid locale identifier: \(locale)")
            }

            let localizations = try dataSource.localizations(forLocale: locale)
            self.model.addLocalizations(localizations, for: locale)
        }
    }
    
    /// Returns localized string for the given key in the requested locale.
    /// If string contains interpolations, they are replaced from the `interpolations` dictionary.
    public func localize(_ key: LocalizationKey, locale: LocaleIdentifier, interpolations: [String: Any]? = nil) -> String {
        let result = self.model.localize(key, locale: locale, interpolations: interpolations, logger: logger)
        switch result {
            case .success(let localizedString):
                return localizedString

            case .missingKey:
                logger.trace("No localizations found for key: \(key), locale: \(locale). Will fallback to raw value of the key.")
                return key
            
            case .missingLocale:
                /// If exact locale is not found (exact meaning that both language and country match),
                /// and the locale has a country code, fall back to matching only by a language code.
                if locale.hasCountryCode {
                    let languageCodeResult = self.model.localize(key, locale: locale.languageCode, interpolations: interpolations, logger: logger)
                    if case LocalizationsModel.LocalizationResult.success(let localizationResult) = languageCodeResult {
                        return localizationResult
                    }
                }

                /// Fall back to default locale
                let defaultLocaleResult = self.model.localize(key, locale: self.defaultLocale, interpolations: interpolations, logger: logger)
                if case LocalizationsModel.LocalizationResult.success(let localizationResult) = defaultLocaleResult {
                    return localizationResult
                }
            
                logger.trace("Missing localization for key: \(key), locale: \(locale). Will fallback to raw value of the key.")
                return key
        }
    }
 
    /// Returns a list of all available PluralCategories for locale
    public static func availablePluralCategories(forLocale locale: LocaleIdentifier) -> [PluralCategory] {
        return PluralizationRuleStore.availablePluralCategories(forLocale: locale)
    }
    
}

extension LocaleIdentifier {

    /// Returns `true` if the locale identifier contains both, language and country code
    var hasCountryCode: Bool {
        return self.components(separatedBy: "_").count == 2
    }

    /// Returns language code from the locale identifier string.
    /// For locales which contains a country code (en_US, de_CH), the country code is removed.
    var languageCode: String {
        let components = self.components(separatedBy: "_")
        return components.count == 2 ? components.first! : self
    }

}
