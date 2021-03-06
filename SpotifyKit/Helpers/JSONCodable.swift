//
//  JSONCodable.swift
//  SpotifyKit
//
//  Created by Alexander Havermale on 7/23/17.
//  Copyright © 2018 Alex Havermale.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

// MARK: JSON Encoding & Decoding

/// A type that can be both decoded from and encoded to a JSON representation.
public typealias JSONCodable = JSONDecodable & JSONEncodable

/// A type that can decode itself from a JSON representation.
public protocol JSONDecodable: Decodable {
    
    /// Creates a SpotifyKit type from the specified JSON data.
    ///
    /// - Parameter jsonData: The data containing the JSON-encoded [Spotify object](https://developer.spotify.com/documentation/web-api/reference/object-model/).
    ///
    /// - Note: The default implementation of this method decodes date values using the ISO 8601 timestamp format [specified by the Web API](https://developer.spotify.com/documentation/web-api/#timestamps). If your need another date decoding strategy, you must provide your own custom implementation.
    init(from jsonData: Data) throws
}

extension JSONDecodable {
    
    public init(from jsonData: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Self.self, from: jsonData)
    }
}

/// A type that can encode itself to a JSON representation.
public protocol JSONEncodable: Encodable {
    
    /// Encodes the given type to a JSON representation suitable for the [Spotify Web API](https://developer.spotify.com/documentation/web-api/).
    ///
    /// - Returns: A `Data` value containing the payload.
    /// - Throws: Any errors encountered during encoding. See [EncodingError](apple-reference-documentation://hsJCtRo9pa) for more details.
    func data() throws -> Data
}

extension JSONEncodable {

    public func data() throws -> Data {
        let encoder = JSONEncoder()
        
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted // Do we need this?
        if #available(iOS 11.0, *) {
            encoder.outputFormatting.insert(.sortedKeys)
        }
        
        return try encoder.encode(self)
    }
}

// MARK: - Array Conformance

extension Array: JSONDecodable where Element: Decodable {
    
    public init(from jsonData: Data) throws {
        
        self.init() // Initialize self here so we can get type(of: self).
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // First try decoding a top-level array as normal:
        do { self = try decoder.decode([Element].self, from: jsonData) }
        
        // If we found a type other than a top-level array (which is common for many Spotify Web API requests),
        catch DecodingError.typeMismatch(_, let context) where context.debugDescription.contains("dictionary") { // "where context.valueFound is [String: Any]"
            // then try decoding as an array wrapped in a single key-value pair dictionary,
            guard let array = try decoder.decode([String: [Element]].self, from: jsonData).first?.value else {
                // throwing an error if there is no "first" element (implying the dictionary was just an empty object):
                throw DecodingError.dataCorruptedError(atCodingPath: context.codingPath, debugDescription: "JSON object is empty.")
            }
            
            self = array
        }
        
        // Otherwise, throw any other errors encountered:
        catch { throw error }
    }
}

//extension Array: JSONEncodable where Element: Encodable {
//    // TODO: Design JSONEncodable.
//}

// MARK: - Dictionary Conformance

extension Dictionary: JSONDecodable where Key: Decodable, Value: Decodable {
    
    public init(from jsonData: Data) throws {
        
        self.init() // Initialize self here so we can get type(of: self).
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode([Key: Value].self, from: jsonData)
    }
}

//extension Dictionary: JSONEncodable where Key: Encodable, Value: Encodable {
//    // TODO: Design JSONEncodable.
//}

// MARK: - Optional Conformance

extension Optional: JSONDecodable where Wrapped: Decodable {
    
    public init(from jsonData: Data) throws {
        
        self = .none // Initialize self here so we can get type(of: self).
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Wrapped?.self, from: jsonData)
    }
}

//extension Optional: JSONEncodable where Wrapped: Encodable {
//    // TODO: Design JSONEncodable.
//}

// MARK: - Decoding Error Convenience Methods

extension DecodingError {
    
    /// A convenience method which creates a new .dataCorrupted error using the given coding path and debug description.
    ///
    /// - Parameters:
    ///   - codingPath: The path of `CodingKeys` taken to get to the point of the failing decode call.
    ///   - debugDescription: A description of what went wrong, for debugging purposes.
    internal static func dataCorruptedError(atCodingPath codingPath: [CodingKey], debugDescription: String, underlyingError: Error? = nil) -> DecodingError {
        return .dataCorrupted(Context(codingPath: codingPath, debugDescription: debugDescription, underlyingError: underlyingError))
    }
}

// MARK: - Custom Raw Representable Decoding
//
// - Abstract: Decoding with String Case Tolerance
//
// In some instances, certain objects returned by the Web API contain strings
// whose formatting differs from their expected or documented values. For
// example, when requesting "recommendations based on seeds," cartain fields
// that are otherwise always lowercased strings are returned in all caps —
// making raw representable types based on these fields hard to instantiate.
// The following extension provides a succinct solution to this case-sensitive
// conflict by implicitly converting each raw value between lowercase,
// uppercase, and sentence cases before throwing an error any time we decode
// a raw representable type.
//
extension RawRepresentable where RawValue == String, Self: Decodable {
    
    // MARK: Custom Decoding
    
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: This initializer throws an error if reading from the decoder fails, or if the data read is corrupted or otherwise invalid.
    public init(from decoder: Decoder) throws {
        let decoded = try decoder.singleValueContainer().decode(RawValue.self)

        guard let value = Self(rawValue: decoded) ??
                          Self(rawValue: decoded.lowercased()) ??
                          Self(rawValue: decoded.uppercased()) ??
                          Self(rawValue: decoded.capitalized)
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot initialize \(Self.self) from invalid \(RawValue.self) value \"\(decoded)\" or any case-sensitive variant."))
        }
        
        self = value
    }
}
