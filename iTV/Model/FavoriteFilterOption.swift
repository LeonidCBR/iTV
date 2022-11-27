//
//  FavoriteFilterOption.swift
//  iTV
//
//  Created by Яна Латышева on 27.11.2022.
//

import Foundation

enum FavoriteFilterOption: CaseIterable, CustomStringConvertible { //Int
    case all
    case favorites

    var description: String {
        switch self {
        case .all:
            return "Все"
        case .favorites:
            return "Избранные"
        }
    }
}
