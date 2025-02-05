import Foundation

struct Course: Codable, Identifiable {
    let id: Int
    let termId: Int
    let userId: Int
    let name: String
    let credits: Double
    let average: Double
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case termId = "term_id"
        case userId = "user_id"
        case name
        case credits
        case average
        case createdAt
        case updatedAt
    }
}
