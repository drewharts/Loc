//
//  Place.swift
//  loc
//
//  Created by Andrew Hartsfield II on 12/14/24.
//

import Foundation

struct Place: Codable,Identifiable {
    let id: String
    let name: String
    let address: String
}
