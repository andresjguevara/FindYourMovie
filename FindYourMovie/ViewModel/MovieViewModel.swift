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
    var isPageFetchRequired = [Int : Bool]()
    
    private var movies = [Movie]()
    private let context :  NSManagedObjectContext
    init(context :  NSManagedObjectContext) {
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
        return movies[index].release_date ?? "No Release Date Available"
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
    func makeAPIRequest(movieName : String, isFollowUpRequest: Bool = false, completion: @escaping (Result<[Movie], MovieManager.MovieManagerError>) -> Void)  {
        var pageNumber : Int
        if isFollowUpRequest && self.requiresPaging() {
            self.isPageFetchRequired[self.currentPage] = false
            pageNumber = self.currentPage + 1
            print(movieName)
            print(pageNumber)
        } else if self.currentPage == 1 && !isFollowUpRequest {
            pageNumber = 1
        } else {
            return
        }
        
        MovieManager.shared.getMoviesNames(query: movieName, page: String(pageNumber))
        { [weak self] results in
            switch results {
            case .success(let movieResult):
                if pageNumber > 1 {
                    self?.movies.append(contentsOf: movieResult.0)
                    self?.currentPage += 1
                    completion(.success(self!.movies))
                } else {
                    self?.movies = movieResult.0
                    self?.totalPages = movieResult.1
                    self?.currentSearch = movieName
                    self?.updateLastSearchResults(movieName: movieName)
                    completion(.success(self!.movies))
                }
                
            case .failure(let error):
                completion(.failure(error as MovieManager.MovieManagerError))
            }
        }
        
    }
    
    /// Returns if the request qualifies as a new page request
    private func requiresPaging() -> Bool {
        return self.currentPage < self.totalPages && self.isPageFetchRequired[self.currentPage] ?? true
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
