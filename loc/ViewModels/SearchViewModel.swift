//
//  SearchViewModel.swift
//  loc
//
//  Created by Andrew Hartsfield II on 11/5/24.
//

import SwiftUI
import Combine
import MapboxSearch
import CoreLocation
import FirebaseFirestore

class SearchViewModel: ObservableObject {
    @Published var searchText = ""  // User's search input
    @Published var searchResults: [SearchSuggestion] = []
    @Published var userResults: [ProfileData] = []
    @Published var searchError: String?
    @Published var selectedUser: ProfileData?

    weak var selectedPlaceVM: SelectedPlaceViewModel?

    private let firestoreService = FirestoreService()
    private let mapboxSearchService = MapboxSearchService()
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        
        // ✅ Debounce to limit API calls while typing
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main) // 300ms delay
            .removeDuplicates() // Avoid duplicate searches
            .sink { [weak self] text in
                self?.searchPlaces(query: text)
                self?.searchUsers(query: text)
            }
            .store(in: &cancellables)
    }

    func searchPlaces(query: String) {
        mapboxSearchService.searchPlaces(
            query: query,
            onResultsUpdated: { [weak self] results in
                DispatchQueue.main.async {
                    self?.searchResults = results
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.searchError = error
                }
            }
        )
    }
    
    private func searchResultToDetailPlace(place: SearchResult, completion: @escaping (DetailPlace) -> Void) {
        // First, check if the DetailPlace exists in Firestore using mapboxId
        firestoreService.findPlace(mapboxId: place.mapboxId!) { [weak self] existingDetailPlace, error in
            if let error = error {
                print("Error checking for existing place: \(error.localizedDescription)")
                // If there's an error, proceed to create a new DetailPlace (or handle differently)
            }
            
            if let existingDetailPlace = existingDetailPlace {
                // If the place exists, return it immediately
                completion(existingDetailPlace)
                return
            }
            
            // If no existing place is found, create a new DetailPlace
            let uuid = UUID(uuidString: place.id) ?? UUID()
            
            var detailPlace = DetailPlace(
                id: uuid,
                name: place.name,
                address: place.address?.formattedAddress(style: .medium) ?? "", city: place.address?.place ?? ""
            )
            
            detailPlace.mapboxId = place.mapboxId
            detailPlace.coordinate = GeoPoint(
                latitude: Double(place.coordinate.latitude),
                longitude: Double(place.coordinate.longitude)
            )
            detailPlace.categories = place.categories
            detailPlace.phone = place.metadata?.phone
            detailPlace.rating = place.metadata?.rating ?? 0
            detailPlace.description = place.metadata?.description ?? ""
            detailPlace.priceLevel = place.metadata?.priceLevel
            detailPlace.reservable = place.metadata?.reservable ?? false
            detailPlace.servesBreakfast = place.metadata?.servesBreakfast ?? false
            detailPlace.serversLunch = place.metadata?.servesLunch ?? false
            detailPlace.serversDinner = place.metadata?.servesDinner ?? false
            detailPlace.Instagram = place.metadata?.instagram
            detailPlace.X = place.metadata?.twitter
            
            // Optionally, save the new DetailPlace to Firestore if it doesn’t exist
            self?.firestoreService.addToAllPlaces(detailPlace: detailPlace) { error in
                if let error = error {
                    print("Error saving new place to Firestore: \(error.localizedDescription)")
                }
            }
            
            // Return the newly created DetailPlace
            completion(detailPlace)
        }
    }
    
    func selectSuggestion(_ suggestion: SearchSuggestion) {
        print("🔍 User selected suggestion: \(suggestion.id) - \(suggestion.name)")
        mapboxSearchService.selectSuggestion(
            suggestion,
            onResultResolved: { [weak self] result in
                DispatchQueue.main.async {
                    print("✅ Resolved result: \(result.id) - \(result.name)")

                    // Use the asynchronous searchResultToDetailPlace with a completion handler
                    self?.searchResultToDetailPlace(place: result) { [weak self] detailPlace in
                        guard let self = self else { return }
                        self.selectedPlaceVM?.selectedPlace = detailPlace
                        self.selectedPlaceVM?.isDetailSheetPresented = true
                    }
                }
            }
        )
    }
    
    private func searchUsers(query: String) {
        guard !query.isEmpty else {
            userResults = []
            return
        }

        firestoreService.searchUsers(query: query) { [weak self] users, error in
            if let error = error {
                print("Error searching users: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self?.userResults = users ?? []
            }
        }
    }
}

//class SearchViewModel: ObservableObject, SearchEngineDelegate {
//    
//    @Published var searchText = ""
//    @Published var searchResults: [GMSAutocompletePrediction] = []
//    @Published var userResults: [ProfileData] = []
//    @Published var selectedUser: ProfileData?
//    @Published var isUserDetailPresented = false
//    @Published var userLocation: CLLocationCoordinate2D?
//    private let googlePlacesService = GooglePlacesService()
//    private let mapboxSearchEngine = SearchEngine()
//    private let firestoreService = FirestoreService()
//
//    weak var selectedPlaceVM: SelectedPlaceViewModel?
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    init() {
//        mapboxSearchEngine.delegate = self
//        // Observing searchText changes with debounce to limit API calls
//        $searchText
//            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
//            .sink { [weak self] text in
//                self?.searchPlaces(query: text)
//                self?.searchUsers(query: text)
//            }
//            .store(in: &cancellables)
//    }
//
//    private func searchPlaces(query: String) {
//        guard !query.isEmpty else {
//            searchResults = []
//            return
//        }
//        
//        mapboxSearchEngine.query = query
//        if let location = userLocation {
//            let options = SearchOptions(proximity: location)
//            mapboxSearchEngine.search(query: query, options: options)
//        } else {
//            mapboxSearchEngine.search(query: query)
//        }
////        googlePlacesService.performSearch(query: query, userLocation: userLocation) { [weak self] results, error in
////            if let error = error {
////                print("Error fetching autocomplete results: \(error.localizedDescription)")
////                return
////            }
////            DispatchQueue.main.async {
////                self?.searchResults = results ?? []
////            }
////        }
//    }
//    
//    private func searchUsers(query: String) {
//        guard !query.isEmpty else {
//            userResults = []
//            return
//        }
//        
//        firestoreService.searchUsers(query: query) { [weak self] users, error in
//            if let error = error {
//                print("Error searching users: \(error.localizedDescription)")
//                return
//            }
//            DispatchQueue.main.async {
//                self?.userResults = users ?? []
//            }
//        }
//    }
//    
//    func selectPlace(_ prediction: GMSAutocompletePrediction) {
//        googlePlacesService.fetchPlace(placeID: prediction.placeID) { [weak self] place, error in
//            if let error = error {
//                print("Error fetching place: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let place = place else {
//                print("No place details found.")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self?.selectedPlaceVM?.selectedPlace = place
//                self?.selectedPlaceVM?.isDetailSheetPresented = true
//            }
//        }
//    }
//}
