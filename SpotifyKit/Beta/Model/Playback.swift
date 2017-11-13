//
//  Playback.swift
//  SpotifyKit
//
//  Created by Alexander Havermale on 7/31/17.
//  Copyright © 2017 Alex Havermale. All rights reserved.
//

import Foundation

// MARK: Supporting Types

/// A mode for repeating playback in a Spotify player.
public enum SKRepeatMode: String, Codable {
    
    /// Nothing is repeated during playback.
    case off
    
    /// A single track is repeated indefinitely.
    case one = "track"
    
    /// The current playback context is repeated indefinitely.
    case all = "context"
    
    /// Creates an `SKRepeatMode` equal to that of the given `SPTRepeatMode` value.
    ///
    /// - Parameter value: The `SPTRepeatMode` value.
    public init(_ value: SPTRepeatMode) {
        switch value {
            case .off:     self = .off
            case .one:     self = .one
            case .context: self = .all
        }
    }
}

extension SPTRepeatMode {
    
    /// Creates an `SPTRepeatMode` equal to that of the given `SKRepeatMode` value.
    ///
    /// - Parameter value: The `SKRepeatMode` value.
    public init(_ value: SKRepeatMode) {
        switch value {
            case .off: self = .off
            case .one: self = .one
            case .all: self = .context
        }
    }
}

//public typealias SKRepeatMode = SPTRepeatMode
//
//extension SPTRepeatMode: Codable {
//    public init?(rawValue: String) {
//        switch rawValue {
//        case "off": self = .off
//        case "context": self = .context
//        case "track": self = .one
//        default: return nil
//        }
//    }
//}

// MARK: - Playback Context

/// A structure containing values identifying the context in which a particular track is played, such as an album, artist, or playlist.
public struct SKPlaybackContext: Decodable { // SKPlaybackSource
    
    /// The possible contexts in which a track can be played.
    public enum ContextType: String, Codable {
        
        /// The current track is being played as part of an album.
        case album
        
        /// The current track is being played as part of an artist's tracks.
        case artist
        
        /// The current track is being played as part of a playlist.
        case playlist
    }
    
    /// The type of context, such as an album, artist, or playlist. See `ContextType` for more details.
    public let type: ContextType
    
    /// Known external URLs for this context. See ["external URL object"](https://developer.spotify.com/web-api/object-model/#external-url-object) for more details.
    public let externalURLs: [String: URL]
    
    /// The [Spotify URI](https://developer.spotify.com/web-api/user-guide/#spotify-uris-and-ids) for the context.
    public let uri: String
    
    /// A link to the Web API endpoint providing full details of the context.
    public let url: URL
    
    private enum CodingKeys: String, CodingKey {
        case externalURLs = "external_urls"
        case url = "href"
        case type
        case uri
    }
}

// MARK: - Playback State (Currently Playing Object) (βeta)

/// An aggregated collection of values defining the current state of a Spotify player.
///
/// - SeeAlso: The Web API [Currently Playing](https://developer.spotify.com/web-api/get-information-about-the-users-current-playback/) object.
public struct SKPlaybackState: JSONDecodable {
    
    /// The device that is currently active.
    public let device: SKDevice? // - Note: When retrieving the currently playing track, this property will be `nil`. // Just don't support that endpoint. It's redundant anyways.
    
    /// The current repeat mode. See `SKRepeatMode` for possible values.
    public let repeatMode: SKRepeatMode? // - Note: When retrieving the currently playing track, this property will be `nil`.
    
    /// A Boolean value indicating whether shuffling is turned on.
    public let isShuffling: Bool? // - Note: When retrieving the currently playing track, this property will be `nil`.
    
    /// The context in which the current track is played, such as an album, artist, or playlist.
    ///
    /// If no track is currently playing, this property will be `nil`.
    public let context: SKPlaybackContext?
    
    /// The Unix millisecond timestamp when the data was fetched.
    private let _timestamp: Int
    
    /// The date and time that this data was fetched, with millisecond precision.
    ///
    /// You can use this date in conjuntion with the `progress` property to determine the currently elapsed playback time of the current track, if one is playing.
    public var timestamp: Date {
        return Date(timeIntervalSince1970: TimeInterval(_timestamp) / 1000)
    }
    
    /// The progress into the currently playing track, in milliseconds.
    private let _progress: Int?
    
    /// The progress into the currently playing track in seconds, with millisecond precision.
    ///
    /// If no track is currently playing, this property will be `nil`.
    public var progress: TimeInterval? {
        switch _progress {
            case .some(let t): return TimeInterval(t) / 1000
            case .none: return nil
        }
    }
    
    /// A Boolean value indicating whether a track is currently playing.
    public let isPlaying: Bool
    
    /// The currently playing track.
    ///
    /// If no track is currently playing, this property will be `nil`.
    public let track: SKTrack?
    
    // MARK: Keys
    
    private enum CodingKeys: String, CodingKey {
        case device
        case repeatMode = "repeat_state"
        case isShuffling = "shuffle_state"
        case context
        case _timestamp = "timestamp"
        case _progress = "progress_ms"
        case isPlaying = "is_playing"
        case track = "item"
    }
}

//public protocol SKValueConvertible {
//    associatedtype ValueType
//    init?(from value: ValueType) // init?(converting:)
//}

extension SPTPlaybackState/*: SKValueConvertible */{
    
    public convenience init?(from value: SKPlaybackState) {
        
        guard
            let device = value.device,
            let repeatMode = value.repeatMode,
            let isShuffling = value.isShuffling,
            let progress = value.progress else {
                return nil
        }
        
        self.init(isPlaying: value.isPlaying,
                  isRepeating: repeatMode == .one || repeatMode == .all,
                  isShuffling: isShuffling,
                  isActiveDevice: UIDevice.current.name == device.name,
                  position: progress)
    }
}

//public protocol SPTConvertible { // SDKConvertible
//    associatedtype ReferenceType
//    func makeSPTInstance() -> ReferenceType
//    //var sptInstance: ReferenceType { get }
//}
//
//extension SKPlaybackState: SPTConvertible {
//
//    public func makeSPTInstance() -> SPTPlaybackState? {
//
//        guard let device = device, let repeatMode = repeatMode, let isShuffling = isShuffling, let progress = progress else {
//            return nil
//        }
//
//        return SPTPlaybackState(isPlaying: isPlaying,
//                                isRepeating: repeatMode == .all || repeatMode == .one,
//                                isShuffling: isShuffling,
//                                isActiveDevice: device.type == .mobile, // No good... find a better way.
//                                position: TimeInterval(progress))!
//    }
//}