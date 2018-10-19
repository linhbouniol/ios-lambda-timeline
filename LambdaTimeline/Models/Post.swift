//
//  Post.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import FirebaseAuth
import MapKit

enum MediaType: String {
    case image
    case audio
    case video
}

class Post: NSObject, MKAnnotation {
    
    static private let mediaKey = "media"
    static private let ratioKey = "ratio"
    static private let mediaTypeKey = "mediaType"
    static private let authorKey = "author"
    static private let commentsKey = "comments"
    static private let timestampKey = "timestamp"
    static private let idKey = "id"
    static private let coordinatesKey = "coordinates"
    static private let latitudeKey = "latitude"
    static private let longitudeKey = "longitude"
    
    var mediaURL: URL
    let mediaType: MediaType
    let author: Author
    let timestamp: Date
    var comments: [Comment]
    var id: String?
    var ratio: CGFloat?
    
    // an actual coordinate2D, but it has an internal flag that marks it as invalid (aka nil in forever ago's coding practice)
    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    var title: String? {
        return comments.first?.text
    }
    
    var subtitle: String? {
        return author.displayName
    }
    
    var dictionaryRepresentation: [String : Any] {
        var dict: [String: Any] = [Post.mediaKey: mediaURL.absoluteString,
                                   Post.mediaTypeKey: mediaType.rawValue,
                                   Post.commentsKey: comments.map({ $0.dictionaryRepresentation }),
                                   Post.authorKey: author.dictionaryRepresentation,
                                   Post.timestampKey: timestamp.timeIntervalSince1970,
                                   Post.latitudeKey: coordinate.latitude,
                                   Post.longitudeKey: coordinate.longitude
                                   ]
        
        // Firebase will not store the CLLocationCoordinate2D, so we need to break it up into a key-value pair for the latitude and longitude.
        
        guard let ratio = self.ratio else { return dict }
        
        dict[Post.ratioKey] = ratio
        
        return dict
    }
    
    init(title: String, mediaURL: URL, mediaType: MediaType, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, ratio: CGFloat? = nil, author: Author, timestamp: Date = Date()) {
        self.mediaURL = mediaURL
        self.ratio = ratio
        self.mediaType = mediaType //.image
        self.author = author
        self.comments = [Comment(text: title, author: author)]
        self.timestamp = timestamp
        self.coordinate = coordinate
    }
    
    init?(dictionary: [String : Any], id: String) {
        guard let mediaURLString = dictionary[Post.mediaKey] as? String,
            let mediaURL = URL(string: mediaURLString),
            let mediaTypeString = dictionary[Post.mediaTypeKey] as? String,
            let mediaType = MediaType(rawValue: mediaTypeString),
            let authorDictionary = dictionary[Post.authorKey] as? [String: Any],
            let author = Author(dictionary: authorDictionary),
            let timestampTimeInterval = dictionary[Post.timestampKey] as? TimeInterval,
            let captionDictionaries = dictionary[Post.commentsKey] as? [[String: Any]] else
        { return nil }
        
        self.mediaURL = mediaURL
        self.mediaType = mediaType
        self.ratio = dictionary[Post.ratioKey] as? CGFloat
        self.author = author
        self.timestamp = Date(timeIntervalSince1970: timestampTimeInterval)
        self.comments = captionDictionaries.compactMap({ Comment(dictionary: $0) })
        self.id = id
        
        // only make a coordinate if the latitude and longitude are non-nil. Otherwise, leave the coordinate be the default value (invalid coordinate)
        // If we leave these two properties as a part of the guard statement, since they might be nil, it will result in an invalid Post, since the guard statement returns nil if any of the properties are nil.
        if let latitude = dictionary[Post.latitudeKey] as? Double,
            let longitude = dictionary[Post.longitudeKey] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
