//
//  UserProfileViewModel.swift
//  loc
//
//  Created by Andrew Hartsfield II on 1/29/25.
//

import Foundation
import GooglePlaces
import UIKit
import SwiftUICore
import MapboxSearch

class UserProfileViewModel: ObservableObject {
    @Published var selectedUser: ProfileData?
    @Published var isUserDetailPresented = false
    
    @Published var userFavorites: [DetailPlace] = []
    @Published var userLists: [PlaceList] = []
    @Published var placeListMapboxPlaces: [UUID: [DetailPlace]] = [:] // Store places per list
    @Published var placeImages: [String: UIImage] = [:] // Store images by placeID
    @Published var isFollowing: Bool = false  // ✅ Track follow state
    @Published var followers: Int = 0
    private let firestoreService = FirestoreService()
    private let mapboxSearchService = MapboxSearchService()
    
    
    func selectUser(_ user: ProfileData, currentUserId: String) {
        DispatchQueue.main.async {
            self.selectedUser = user
            self.isUserDetailPresented = true
            self.checkIfFollowing(currentUserId: currentUserId)
        }
        
        fetchProfileFavorites(userId: user.id)
        fetchLists(userId: user.id)
        fetchFollowers(userId: user.id)
    }
    func fetchFollowers(userId: String) {
        firestoreService.getNumberFollowers(forUserId: userId) { (count, error) in
            if let error = error {
                print("Error fetching followers: \(error.localizedDescription)")
                return
            }
            self.followers = count
        }
    }
    func checkIfFollowing(currentUserId: String) {
        // Ensure that selectedUser is set and has a valid id
        guard let targetUserId = selectedUser?.id, !targetUserId.isEmpty else {
            DispatchQueue.main.async { self.isFollowing = false }
            return
        }
        
        // Call the firestore service to check the following status.
        firestoreService.isFollowingUser(followerId: currentUserId, followingId: targetUserId) { [weak self] isFollowing in
            // Always update UI state on the main thread.
            DispatchQueue.main.async {
                self?.isFollowing = isFollowing
            }
        }
    }
    
    /// Follows or unfollows the selected user.
    func toggleFollowUser(currentUserId: String) {
              let targetUserId = selectedUser?.id ?? ""


        if isFollowing {
            firestoreService.unfollowUser(followerId: currentUserId, followingId: targetUserId) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isFollowing = false
                    }
                }
            }
        } else {
            firestoreService.followUser(followerId: currentUserId, followingId: targetUserId) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isFollowing = true
                    }
                }
            }
        }
    }
    
    func followUser(currentUserId: String, targetUserId: String) {
        
        firestoreService.followUser(followerId: currentUserId, followingId: targetUserId) { success, error in
            if let error = error {
                print("Error following user: \(error.localizedDescription)")
            } else if success {
                print("Successfully followed user \(targetUserId).")
            }
        }
    }
    
    private func fetchProfileFavorites(userId: String) {
        firestoreService.fetchProfileFavorites(userId: userId) { places in
            DispatchQueue.main.async {
                if ((places?.isEmpty) != nil) {
                    print("No favorite places found.")
                    self.userFavorites = []
                } else {
                    self.userFavorites = places ?? []
                }
            }
        }
    }

    private func fetchLists(userId: String) {
        firestoreService.fetchLists(userId: userId) { lists in
            DispatchQueue.main.async {
                self.userLists = lists
                
                // Fetch GMSPlaces for each PlaceList
                for list in lists {
                    self.fetchFirestorePlaces(for: list.places) { place in
                        self.placeListMapboxPlaces[list.id] = place
                    }
                }
            }
        }
    }

    func fetchFirestorePlaces(for places: [Place], completion: @escaping ([DetailPlace]) -> Void) {
        var fetchedPlaces: [DetailPlace] = []
        let dispatchGroup = DispatchGroup()
        
        for place in places {
            dispatchGroup.enter()
            
            // Convert the UUID to a String since Firestore expects document IDs as Strings.
            let documentId = place.id.uuidString
            
            firestoreService.fetchPlace(withId: documentId) { result in
                switch result {
                case .success(let detailPlace):
                    fetchedPlaces.append(detailPlace)
                case .failure(let error):
                    print("Error fetching place from Firestore: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            DispatchQueue.main.async {
                completion(fetchedPlaces)
            }
        }
    }
    
    /// Fetches a photo for a given `GMSPlace` and stores it in `placeImages`
//    private func fetchPhoto(for place: GMSPlace) {
//        guard let placeID = place.placeID else { return }
//        if placeImages[placeID] != nil { return } // Avoid redundant fetching
//        
//        googlePlacesService.fetchPhoto(placeID: placeID) { image in
//            DispatchQueue.main.async {
//                self.placeImages[placeID] = image
//            }
//        }
//    }
}
