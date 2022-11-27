//
//  FavoriteFilterOption.swift
//  iTV
//
//  Created by Яна Латышева on 27.11.2022.
//

import Foundation

enum FavoriteFilterOption: Int, CaseIterable, CustomStringConvertible { //Int
    case all = 0
    case favorites = 1

    var description: String {
        switch self {
        case .all:
            return "Все"
        case .favorites:
            return "Избранные"
        }
    }
}

