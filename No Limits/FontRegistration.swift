import CoreText
import Foundation

enum FontRegistration {
    @discardableResult
    static func registerBundledFonts() -> Bool {
        guard let fontURL = Bundle.main.url(
            forResource: "BebasNeue-Regular",
            withExtension: "ttf"
        ) else {
            return false
        }

        return CTFontManagerRegisterFontsForURL(
            fontURL as CFURL,
            .process,
            nil
        )
    }
}
