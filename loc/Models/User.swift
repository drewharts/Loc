//
//  User.swift
//  loc
//
//  Created by Andrew Hartsfield II on 11/18/24.
//


import Foundation

struct User: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let profilePhotoURL: URL?
}
