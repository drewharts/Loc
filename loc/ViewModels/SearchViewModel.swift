//
//  SearchViewModel.swift
//  loc
//
//  Created by Andrew Hartsfield II on 11/5/24.
//

import SwiftUI
import Combine
import CoreLocation
import FirebaseFirestore

class SearchViewModel: ObservableObject {
    @Published var searchText = ""  // User's search input
    @Published var searchResults: [MesaSuggestion] = []
    @Published var userResults: [ProfileData] = []
    @Published var searchError: String?
    @Published var selectedUser: ProfileData?

    weak var selectedPlaceVM: SelectedPlaceViewModel?

    private let firestoreService = FirestoreService()
    private let mesaSearchService = MesaSearchService()
    
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
        mesaSearchService.searchPlaces(query: query) { [weak self] suggestions, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.searchError = error.localizedDescription
                    self?.searchResults = []
                } else {
                    self?.searchResults = suggestions
                    self?.searchError = nil
                }
            }
        }
    }
    
    func selectSuggestion(_ suggestion: MesaSuggestion) {
        print("🔍 User selected suggestion: \(suggestion.id) - \(suggestion.name)")
        mesaSearchService.getPlaceDetails(id: suggestion.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let detailPlace):
                    print("✅ Resolved result: \(detailPlace.id) - \(detailPlace.name)")
                    self?.selectedPlaceVM?.selectedPlace = detailPlace
                    self?.selectedPlaceVM?.isDetailSheetPresented = true
                case .failure(let error):
                    print("❌ Error getting place details: \(error.localizedDescription)")
                    self?.searchError = error.localizedDescription
                }
            }
        }
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
