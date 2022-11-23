//
//  Channel.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import Foundation

struct Channel: Decodable {

    struct Current: Decodable {
        let title: String
    }

    private let current: Current?

    let id: Int
    let name: String
    let url: String
    let image: String?

    var title: String {
        return current?.title ?? ""
    }

    var isFavorite: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name_ru"
        case image = "image"
        case current = "current"
        case url = "url"
    }

}
