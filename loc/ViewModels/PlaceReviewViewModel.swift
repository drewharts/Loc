//
//  PlaceReviewViewModel.swift
//  loc
//
//  Created by Andrew Hartsfield II on 1/18/25.
//

import SwiftUI
import Combine
import GooglePlaces
import MapboxSearch

class PlaceReviewViewModel: ObservableObject {
    // MARK: - Published Properties (bound to the View)
    @Published var foodRating: Double = 0
    @Published var serviceRating: Double = 0
    @Published var ambienceRating: Double = 0
    @Published var favoriteDishes: [String] = []
    @Published var reviewText: String = ""
    @Published var images: [UIImage] = []

    // You might track loading & error states for UI feedback:
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private/Internal
    private let place: DetailPlace
    private let userId: String
    private let userFirstName: String
    private let userLastName: String
    private let profilePhotoUrl: String
    private let firestoreService: FirestoreService

    // MARK: - Init
    init(place: DetailPlace,
         userId: String,
         userFirstName: String,
         userLastName: String,
         profilePhotoUrl: String,
         firestoreService: FirestoreService = FirestoreService()) {
        self.place = place
        self.userId = userId
        self.userFirstName = userFirstName
        self.userLastName = userLastName
        self.profilePhotoUrl = profilePhotoUrl
        self.firestoreService = firestoreService
    }

    func submitReview(completion: @escaping (Result<Review, Error>) -> Void) {
            isLoading = true
            errorMessage = nil
            
            var newReview = Review(
                id: UUID().uuidString, // Temporary ID, may be overridden by Firestore
                userId: userId,
                profilePhotoUrl: profilePhotoUrl,
                userFirstName: userFirstName,
                userLastName: userLastName,
                placeId: place.id.uuidString ?? "unknown_place_id",
                placeName: place.name ?? "Unnamed Place",
                foodRating: foodRating,
                serviceRating: serviceRating,
                ambienceRating: ambienceRating,
                favoriteDishes: favoriteDishes,
                reviewText: reviewText,
                timestamp: Date(),
                images: [] // Will be updated after upload
            )

            // Call FirestoreService and pass the result
            firestoreService.saveReviewWithImages(review: newReview, images: images) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoading = false

                    switch result {
                    case .success(let savedReview):
                        // Return the saved review (with Firestore ID, image URLs, etc.)
                        completion(.success(savedReview))
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                }
            }
        }

}

