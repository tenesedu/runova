import Foundation

extension String {
    var localized: String {
        let language = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        let bundle = path != nil ? Bundle(path: path!) : Bundle.main
        return NSLocalizedString(self, tableName: nil, bundle: bundle ?? Bundle.main, value: "", comment: "")
    }
} 