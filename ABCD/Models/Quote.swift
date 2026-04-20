//
//  Quote.swift
//  ABCD
//

import Foundation

struct Quote: Codable {
    let content: String
    let author: String
}

struct ZenQuoteDTO: Codable {
    let q: String
    let a: String
}
