import Foundation

public struct Source: Object {
    public typealias CreateParameter = CreateSourceParameter
   
    public static let postURL: URL = URL(string: "https://api.omise.co/sources")!
    
    public let object: String
    public let id: String
    
    public let type: String
    
    public let flow: String
    public var isUsed: Bool
    
    public let amount: Int64
    
    public let currency: String
}

public struct CreateSourceParameter: Encodable {
    public let type: String
    public let amount: Int64
    public let currency: String
}
