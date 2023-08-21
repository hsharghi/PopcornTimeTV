//
//  JSONDecoder + Utils.swift
//  Networking
//
//  Created by Sergiu Corbu on 26.11.2021.
//

import Foundation

extension DateFormatter {
    
    var defaultDateFormatter: DateFormatter {
        self.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return self
    }
}

extension JSONDecoder {
    
    static var `default`: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter().defaultDateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension DecodingError {
    
    var debugDescription:String {
        switch self {
        case .dataCorrupted(let context):
            return context.debugDescription
        case .keyNotFound(_, let context):
            return context.debugDescription
        case .typeMismatch(let type, let context):
            return "\(type) was expected" + context.debugDescription
        case .valueNotFound(let type, let context):
            return "no value was found for \(type)" + context.debugDescription
        default:
            return self.localizedDescription
        }
    }
}

extension JSONDecoder {
    
    public func decode<T>(_ type: T.Type, from data: Data, keyPath: String, separator: Character = ".") throws -> T where T : Decodable {
        self.userInfo[JSONDecoder.keyPaths] = keyPath.split(separator: separator).map({ String($0) })
        return try decode(ProxyModel<T>.self, from: data).object
    }
    
    static let keyPaths: CodingUserInfoKey = CodingUserInfoKey(rawValue: "keyPath")!
    
    public func decode<T>(_ type: T.Type, from dict: [String:Any], keyPath: String? = nil, separator: Character = ".") throws -> T where T : Decodable {
        let data = try JSONSerialization.data(withJSONObject: dict)
        if let keyPath = keyPath {
            return try self.decode(type, from: data, keyPath: keyPath, separator: separator)
        } else {
            return try self.decode(type, from: data)
        }
    }
}

struct ProxyModel<T: Decodable>: Decodable {
    var object: T
    
    struct Key: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let stringKeyPaths = decoder.userInfo[JSONDecoder.keyPaths] as! [String]
        var keyPaths = stringKeyPaths.map({ Key(stringValue: $0)! })
        var container = try! decoder.container(keyedBy: Key.self)
        var key = keyPaths.removeFirst()
        for newKey in keyPaths {
            container = try container.nestedContainer(keyedBy: Key.self, forKey: key)
            key = newKey
        }
        
        object = try container.decode(T.self, forKey: key)
    }
}

extension Optional where Wrapped == Data {
    
    /// useful for debugging
    var dataAsString: String? {
        guard let data = self else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
