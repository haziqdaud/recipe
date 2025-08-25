import Foundation

struct Recipe: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var typeId: Int
    var imageFilename: String?
    var imageAssetName: String?
    var ingredients: [String]
    var steps: [String]
    var createdAt: Date = Date()
}
