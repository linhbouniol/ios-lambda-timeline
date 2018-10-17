//
//  Comment.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import FirebaseAuth

struct Comment: FirebaseConvertible, Equatable {
    
    static private let textKey = "text"
    static private let author = "author"
    static private let timestampKey = "timestamp"
    static private let urlKey = "url"
    
    let text: String?
    let author: Author
    let timestamp: Date
    let url: URL?
    
    init(text: String, author: Author, timestamp: Date = Date()) {
        self.text = text
        self.author = author
        self.timestamp = timestamp
        self.url = nil
    }
    
    init(url: URL, author: Author, timestamp: Date = Date()) {
        self.url = url
        self.author = author
        self.timestamp = timestamp
        self.text = nil
    }
    
    init?(dictionary: [String : Any]) {
        guard let authorDictionary = dictionary[Comment.author] as? [String: Any],
            let author = Author(dictionary: authorDictionary),
            let timestampTimeInterval = dictionary[Comment.timestampKey] as? TimeInterval else { return nil }
        
        if let text = dictionary[Comment.textKey] as? String {
            self.text = text
            self.url = nil
        } else if let urlString = dictionary[Comment.urlKey] as? String, let url = URL(string: urlString) {
            self.url = url
            self.text = nil
        } else {
            return nil
        }
        
        self.author = author
        self.timestamp = Date(timeIntervalSince1970: timestampTimeInterval)
    }
    
    var dictionaryRepresentation: [String: Any] {
        if let text = text {
            return [Comment.textKey: text,
                    Comment.author: author.dictionaryRepresentation,
                    Comment.timestampKey: timestamp.timeIntervalSince1970]
        } else if let urlString = url?.absoluteString {
            return [Comment.urlKey: urlString,
                    Comment.author: author.dictionaryRepresentation,
                    Comment.timestampKey: timestamp.timeIntervalSince1970]
        }
        
        return [:]
    }
}
