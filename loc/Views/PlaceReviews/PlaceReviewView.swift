//
//  PlaceReviewView.swift
//  loc
//
//  Created by Andrew Hartsfield II on 1/13/25.
//

import SwiftUI
import GooglePlaces
import PhotosUI

struct PlaceReviewView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var isPresented: Bool
    @EnvironmentObject var profile: ProfileViewModel
    @State private var showButtonHighlight = false

    
    let place: GMSPlace

    @StateObject private var viewModel: PlaceReviewViewModel
    
    // Image picker states
    @State private var showingImagePicker = false
    @State private var inputImages: [UIImage] = []
    
    init(isPresented: Binding<Bool>, place: GMSPlace, userId: String, userFirstName: String, userLastName: String) {
        self._isPresented = isPresented
        self.place = place

        // Initialize the ViewModel with place/user info
        _viewModel = StateObject(
            wrappedValue: PlaceReviewViewModel(
                place: place,
                userId: userId,
                userFirstName: userFirstName,
                userLastName: userLastName
            )
        )
    }
    
    var btnBack : some View { Button(action: {
        self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
            Image(systemName: "chevron.left") // set image here
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    PlaceReviewHeaderView(placeName: place.name ?? "Unnamed Place")

                    RatingSlidersView(foodRating: $viewModel.foodRating, serviceRating: $viewModel.serviceRating, ambienceRating: $viewModel.ambienceRating)

                    UpvoteFavDishesView(favoriteDishes: $viewModel.favoriteDishes)
                    
                    Divider()
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                        .padding(.horizontal, -10)

                    ReviewTextView(reviewText: $viewModel.reviewText)
                    
                    Divider()
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                        .padding(.horizontal, -10)

                    // Upload photos button
                    UploadPhotosButtonView(showingImagePicker: $showingImagePicker)
                    
                    // Display selected images
                    if !inputImages.isEmpty {
                        SelectedImagesView(images: inputImages)
                    }
                    
                    Divider()
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                        .padding(.horizontal, -10)

                    PostReviewButtonView(highlighted: $showButtonHighlight) {
                        // 1. Immediately highlight the button
                        showButtonHighlight = true
                        
                        // 2. Pass the selected images to the ViewModel
                        viewModel.images = inputImages
                        
                        // 3. Submit the review
                        viewModel.submitReview { success in
                            if success {
                                // Optional: Wait briefly so user sees the highlight
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showButtonHighlight = false
                                     presentationMode.wrappedValue.dismiss()
                                }
                            } else {
                                // On failure, remove highlight
                                showButtonHighlight = false
                            }
                        }
                    }

                }
                .padding(.horizontal, 40)
            }
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .background(Color(.white))
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: btnBack)
        .sheet(isPresented: $showingImagePicker) {
            MultiImagePicker(images: $inputImages, selectionLimit: 0)
        }

    }
}
