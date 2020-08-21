//
//  MovieViewModel.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/21/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import Foundation
import CoreData

class MoviewViewModel {
    private var currentPage = 1
    private var totalPages = 1
    private var currentSearch = ""
    private var lastSearches = [String]()
    private let defaults = UserDefaults.standard
    
    var movies : [Movie]
    private let context :  NSManagedObjectContext
    init(context :  NSManagedObjectContext) {
        self.movies = [Movie]()
        self.context = context
        // Load latestes searches at loading time
        if let searches = self.defaults.array(forKey: "lastSearches") as? [String] {
            self.lastSearches = searches
        }
    }
    
    func getTitleForMovie(at index: Int) -> String{
        return movies[index].title
    }
    
    func getOverviewForMovie(at index: Int) -> String{
        return movies[index].overview
    }
    
    func getPosterForMovie(at index: Int) -> String?{
        return movies[index].poster_path
    }
    
    func getReleaseDateForMovie(at index: Int) -> String {
        return movies[index].release_date
    }
    
    func getMovieCount() -> Int {
        return movies.count
    }
    
    func getMovieAt(index: Int) -> Movie {
        return movies[index]
    }
    
    func findOrCreateMovie(movieName : String) -> Movie {
        return movies.first!
    }
    
    func getLatestSearches() -> [String] {
        if let searches = self.defaults.array(forKey: "lastSearches") as? [String] {
            self.lastSearches = searches
        }
        
        return self.lastSearches
    }
    
    /// Makes a call to the API requesting movies. It updates the internal values for total pages, current search, current page, and movies
    ///
    ///- Parameters:
    ///     - movieName: name of the movie to search
    ///     - isFollowUpRequest:indicates if the request requires a page number. If true, the page number will be updated to the next available page.
    /// if false, the request will be done to the first page
    /// - Throws: If there was an error while performing the API request
    func makeAPIRequest(movieName : String, isFollowUpRequest: Bool = false) throws {
        var returnError : MovieManager.MovieManagerError?
        var pageNumber : Int
        if isFollowUpRequest && self.requiresPaging() {
            pageNumber = self.currentPage + 1
        } else {
            pageNumber = 1
        }
        
        MovieManager.shared.getMoviesNames(query: movieName, page: String(pageNumber))
        { [weak self] results in
            guard let self = self else {return}
            switch results {
            case .success(let movieResult):
                if pageNumber > 1 {
                    self.movies.append(contentsOf: movieResult.0)
                    self.currentPage += 1
                } else {
                    self.movies = movieResult.0
                    self.totalPages = movieResult.1
                    self.currentSearch = movieName
                    self.currentPage = 1
                    self.updateLastSearchResults(movieName: movieName)
                }
                
            case .failure(let error):
                returnError = error
            }
        }
        if let error = returnError as MovieManager.MovieManagerError? {
            throw error
        }
        
    }
    
    /// Returns if the request qualifies as a new page request
    private func requiresPaging() -> Bool {
        return self.currentPage < self.totalPages
    }
    
    /// Updates the last searches done by the user. No duplicates are added and the size is kept to 10
    ///
    /// - Parameter movieName: Name of the movie to add to the list.
    private func updateLastSearchResults(movieName: String) {
        if !self.lastSearches.contains(movieName){
            if self.lastSearches.count == 10 {
                self.lastSearches.removeLast()
            }
            self.lastSearches.insert(movieName, at: 0)
            self.defaults.set(self.lastSearches, forKey: "lastSearches")
        }
        
        
    }
}
