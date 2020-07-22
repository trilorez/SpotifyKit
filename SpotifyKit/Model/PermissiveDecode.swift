//
//  PermissiveDecode.swift
//  SpotifyKit
//
//  Created by Daniel Resnick on 7/21/20.
//  Copyright © 2020 Alex Havermale.
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

// This is needed because Spotify doesn't follow it's own api schema

public protocol PermissiveDecodable: Decodable {
    static var decodeFallback: Self { get }
}

@propertyWrapper
public struct PermissiveDecode<T: PermissiveDecodable>: Decodable {

    public var wrappedValue: T

    public init(value: T) {
        wrappedValue = value
    }

    public init(from decoder: Decoder) throws {
        do {
            wrappedValue = try T.init(from: decoder)
        } catch {
            wrappedValue = T.decodeFallback
        }
    }
}

// See https://forums.swift.org/t/using-property-wrappers-with-codable/29804/12
extension KeyedDecodingContainer {
    func decode<T>(_ type: PermissiveDecode<T?>.Type, forKey key: Self.Key) throws -> PermissiveDecode<T?> {
        return try decodeIfPresent(type, forKey: key) ?? PermissiveDecode(value: T?.decodeFallback)
    }
}

extension Optional: PermissiveDecodable where Wrapped: Decodable {
    public static var decodeFallback: Self {
        nil
    }
}

extension Array: PermissiveDecodable where Element: Decodable {
    public static var decodeFallback: Self {
        []
    }
}

extension String: PermissiveDecodable {
    public static var decodeFallback: String {
        "null"
    }
}

extension URL: PermissiveDecodable {
    public static var decodeFallback: URL {
        URL(string: "https://www.spotify.com")!
    }
}
