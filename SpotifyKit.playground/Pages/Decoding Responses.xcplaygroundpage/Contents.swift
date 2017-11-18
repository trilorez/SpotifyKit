/*:
 [Table of Contents](Introduction) | [Previous](@previous) | [Next](@next)
 ***
 
 # Decoding Responses
 Nearly every request sent to the [Spotify Web API](https://developer.spotify.com/web-api/) returns some sort of JSON-encoded data, typically representing one of the objects outlined in the API's [object model](https://developer.spotify.com/web-api/object-model/). One of the core functions of this framework is decoding these JSON objects into "Swift-esque," protocol-oriented value types that you can use within your own application.
 
 With the introduction of the Encoding & Decoding APIs in the Swift 4 [Standard Library](apple-reference-documentation://ts2902609) and Xcode 9 [SDK](apple-reference-documentation://ts2877770), parsing JSON payloads has become relatively painless—however, the the following page will illustrate how **SpotifyKit** makes this process even easier for you by introducing some simple protocols along with the framework.
 
 ## JSON Codable Protocols
 
 [`Decodable`]: apple-reference-documentation://hs4cSpS_o7
 [`Encodable`]: apple-reference-documentation://hsdjwRFzpr
 [`JSONDecoder`]: apple-reference-documentation://hsUvF1DNNn
 [`JSONEncoder`]: apple-reference-documentation://hsSkCX8JwI
 
 **SpotifyKit** includes two supporting protocols—`JSONDecodable` and `JSONEncodable`—that inherit from [`Decodable`] and [`Encodable`], respectively. Each provides a layer of abstraction by creating the respective [`JSONDecoder`] or [`JSONEncoder`] instance for you and configuring it to handle API-specific formatting.
 
 ## Decoding JSON Data
 Take a look at the example struct below:
 */

import SpotifyKit
import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

struct ExampleAlbum: JSONDecodable {
    let name: String
    let releaseDate: Date?
    let url: URL
    
    enum CodingKeys: String, CodingKey {
        case name
        case releaseDate = "release_date"
        case url = "href"
    }
}

//: Here we're conforming our `ExampleAlbum` type to `JSONDecodable` just like we would conform to [`Decodable`](apple-reference-documentation://hs4cSpS_o7), providing any custom coding keys if necessary—and because `JSONDecodable` already specifies a default implementation for its initializer, this is all we need to do before providing it the JSON data we want to decode:

let albumData = """
{
    "name": "Believer",
    "release_date": "2017-01-31T11:59:59Z",
    "href": "https://api.spotify.com/v1/albums/3KzCJaaRVza9FnSsqtAFeO"
}
""".data(using: .utf8)!

let album = try! ExampleAlbum(from: albumData)

//: A practical use for this initializer is in the completion handler of an `SKRequest`, where we're expecting a JSON payload that represents a specific object:

SPTAuth.defaultInstance().session = SPTSession(userName: username, accessToken: accessToken, expirationDate: Date.distantFuture)

let artistRequest = SKRequest(method: .GET, endpoint: "/v1/artists/7mnBLXK823vNxN3UWB7Gfz")!

artistRequest.perform { (data, status, error) in
    // Check the status code and error value here.
    
    if let data = data {
        do {
            let artist = try SKArtist(from: data)
            // Do all the things.
        } catch {
            print(error.localizedDescription)
        }
    }
}

/*:
 In fact, this is similar to what the generic `perform` method does; given a type that conforms to `JSONDecodable`, the method will decode the data for you, passing along any decoding errors it encounters to the completion handler.
 
 - Note:
    All **SpotifyKit** types that can be returned by the Web API as top-level items conform to `JSONDecodable`. Other notable types that also conform to `JSONDecodable` are:
    * [`Array`](apple-reference-documentation://hs7p05Ce6o) *(**Note**: associated type `Element` must conform to `Decodable`.)*
    * [`Dictionary`](apple-reference-documentation://hsGesNl6rx) *(**Note**: associated types `Key` and `Value` must conform to `Decodable`.)*
    * [`Optional`](apple-reference-documentation://hsjZfnklDG) *(**Note**: associated type `Wrapped` must conform to `Decodable`.)*
 */

/*:
 ## Encoding JSON Data
 Similarly, the `JSONEncodable` protocol provides a method with a default implementation to encode the conforming type into JSON data formatted for the Web API.
 
 Although no **SpotifyKit** types adopt this protocol directly, the `JSONEncodable` protocol can be used to encode values as data for request bodies:
 */

struct PlaylistDetails: JSONEncodable {
    let name: String
    let description: String?
    let isPublic: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, description, isPublic = "public"
    }
}

let details = PlaylistDetails(name: "Hey, Look! A New Playlist!", description: "How'd this get here?", isPublic: false)
let data = try! details.data()

let newPlaylistRequest = SKRequest(method: .POST, endpoint: "/v1/users/\(username)/playlists")!
newPlaylistRequest.add(data, type: .json)

newPlaylistRequest.perform { (playlist: SKPlaylist?, error) in
    
    if let playlist = playlist {
        // Soo, you may have a new playlist in your Spotify library...
    }
}

//: As you'll see in [Request Factories](Request%20Factories), nearly all of the encoding and decoding has been done for you behind the scenes; however, should you wish to handle requests and responses yourself, using `JSONDecodable` and `JSONEncodable` will help you in the process.
//:
//: Next we'll take a quick look at how paginated responses are handled.
//: ***
//: [Table of Contents](Introduction) | [Previous](@previous) | [Next](@next)
