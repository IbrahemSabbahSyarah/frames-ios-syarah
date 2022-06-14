import Foundation
import UIKit

extension String {

    private func getBundle(forClass: AnyClass) -> Bundle {
        let baseBundle = Bundle(for: forClass)
        let path = baseBundle.path(forResource: "FramesIos", ofType: "bundle")
        return path == nil ? baseBundle : Bundle(path: path!)!
    }

    func localized(forClass: AnyClass, comment: String = "") -> String {
        //let bundle = getBundle(forClass: forClass)
        return self.localized(forLanguage: Locale.current.languageCode ?? "ar")// NSLocalizedString(self, bundle: bundle, comment: "")
    }

    func image(forClass: AnyClass) -> UIImage {
        let bundle = getBundle(forClass: forClass)
        return UIImage(named: self, in: bundle, compatibleWith: nil) ?? UIImage()
    }

    func localized(forLanguage language: String = Locale.preferredLanguages.first!.components(separatedBy: "-").first!) -> String {

            guard let path = Bundle.main.path(forResource: language == "en" ? "en" : language, ofType: "lproj") else {

                let basePath = Bundle.main.path(forResource: "ar", ofType: "lproj")!

                return Bundle(path: basePath)!.localizedString(forKey: self, value: "", table: nil)
            }

            return Bundle(path: path)!.localizedString(forKey: self, value: "", table: nil)
        }
}
