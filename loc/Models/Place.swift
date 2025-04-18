//
//  Place.swift
//  loc
//
//  Created by Andrew Hartsfield II on 12/14/24.
//

import Foundation
import FirebaseFirestore

struct Place: Codable, Identifiable {
    var id: String // Using String instead of UUID for Firestore compatibility
    let name: String
    let address: String?
    let city: String?
    let mapboxId: String?
    let coordinate: GeoPoint?
    let categories: [String]?
    let phone: String?
    let rating: Double?
    let openHours: [String]?
    let description: String?
    let priceLevel: String?
    let reservable: Bool?
    let servesBreakfast: Bool?
    let servesLunch: Bool?
    let servesDinner: Bool?
    let instagram: String?
    let twitter: String?
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    // Computed property to get the document ID
    var documentId: String {
        return id
    }
    
    // Initialize from a basic place
    init(id: String = UUID().uuidString,
         name: String,
         address: String? = nil,
         city: String? = nil,
         mapboxId: String? = nil,
         coordinate: GeoPoint? = nil,
         categories: [String]? = nil,
         phone: String? = nil,
         rating: Double? = nil,
         openHours: [String]? = nil,
         description: String? = nil,
         priceLevel: String? = nil,
         reservable: Bool? = nil,
         servesBreakfast: Bool? = nil,
         servesLunch: Bool? = nil,
         servesDinner: Bool? = nil,
         instagram: String? = nil,
         twitter: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.mapboxId = mapboxId
        self.coordinate = coordinate
        self.categories = categories
        self.phone = phone
        self.rating = rating
        self.openHours = openHours
        self.description = description
        self.priceLevel = priceLevel
        self.reservable = reservable
        self.servesBreakfast = servesBreakfast
        self.servesLunch = servesLunch
        self.servesDinner = servesDinner
        self.instagram = instagram
        self.twitter = twitter
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
    // Initialize from a DetailPlace
    init(from detailPlace: DetailPlace) {
        self.id = detailPlace.id
        self.name = detailPlace.name
        self.address = detailPlace.address
        self.city = detailPlace.city
        self.mapboxId = detailPlace.mapboxId
        self.coordinate = detailPlace.coordinate
        self.categories = detailPlace.categories
        self.phone = detailPlace.phone
        self.rating = detailPlace.rating
        self.openHours = detailPlace.OpenHours
        self.description = detailPlace.description
        self.priceLevel = detailPlace.priceLevel
        self.reservable = detailPlace.reservable
        self.servesBreakfast = detailPlace.servesBreakfast
        self.servesLunch = detailPlace.serversLunch
        self.servesDinner = detailPlace.serversDinner
        self.instagram = detailPlace.Instagram
        self.twitter = detailPlace.X
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        
        // Add optional fields only if they have values
        if let address = address { dict["address"] = address }
        if let city = city { dict["city"] = city }
        if let mapboxId = mapboxId { dict["mapboxId"] = mapboxId }
        if let coordinate = coordinate { dict["coordinate"] = coordinate }
        if let categories = categories { dict["categories"] = categories }
        if let phone = phone { dict["phone"] = phone }
        if let rating = rating { dict["rating"] = rating }
        if let openHours = openHours { dict["openHours"] = openHours }
        if let description = description { dict["description"] = description }
        if let priceLevel = priceLevel { dict["priceLevel"] = priceLevel }
        if let reservable = reservable { dict["reservable"] = reservable }
        if let servesBreakfast = servesBreakfast { dict["servesBreakfast"] = servesBreakfast }
        if let servesLunch = servesLunch { dict["servesLunch"] = servesLunch }
        if let servesDinner = servesDinner { dict["servesDinner"] = servesDinner }
        if let instagram = instagram { dict["instagram"] = instagram }
        if let twitter = twitter { dict["twitter"] = twitter }
        
        return dict
    }
}
