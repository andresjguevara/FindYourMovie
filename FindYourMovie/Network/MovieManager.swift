//
//  MovieManager.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import Foundation

/// Class involved of the networking side of the application. It is a Singleton with "shared" attribute that gives access to make API requests
class MovieManager {
    

    /// Custom error messages containing a detailed messagge of the error occured
    enum MovieManagerError : Error {
        case errorRequestingData(errorMessage: String)
        case badRequest(errorMessage: String)
        case errorProcessingData(errorMessage: String)
        case movieNotFound(errorMessage: String)
        
        /// Returns the custom error description
        func getCustomError() -> String {
            switch self {
            case .badRequest(let error):
                return error
            case .errorProcessingData(let error):
                return error
            case .errorRequestingData(let error):
                return error
            case .movieNotFound(let error):
                return error
                
            }
        }
    }
    static let shared = MovieManager()
    private static let API_KEY = "2696829a81b1b5827d515ff121700838"
    private static let BASE_IMAGE_URL = "https://image.tmdb.org/t/p/w92"
    
    /// The result of a request. Corresponds to the list of movies fetched, and the total number of pages on the request.
    typealias MovieResult = ([Movie], Int)
        
    private init(){
    }
    
    /// Main function to create API requests. The GET request is done to the movie databse. On completion, a result or an error is returned
    ///
    /// - Parameters:
    ///     - query: Name of the movie to find.
    ///     - page: String indicating which page number to fetch
    ///     - completion: A Result object is return.
    ///     -  result: On  success, a pair of movie results and page number is returned. On failure, a error enum is returned
    func getMoviesNames(query : String, page : String, completion: @escaping(_ result: Result<MovieResult,MovieManagerError>) -> Void) {
        
        var getURL = ""
        
        if let movieNameformatted = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            getURL = "https://api.themoviedb.org/3/search/movie?api_key=\(MovieManager.API_KEY)&query=\(movieNameformatted)&page=\(page)"
        }
    
        
        guard let url = URL(string: getURL) else {
                completion(.failure(.errorRequestingData(errorMessage: "Invalid URL")))
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) {data, response, error in
            
            if let error = error {
                    completion(.failure(.errorRequestingData(errorMessage: error.localizedDescription)))
            } else if
                let jsonData = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()
                    let movieResponse = try decoder.decode(MovieResponse.self, from: jsonData)
                    var movieResults = movieResponse.results
                    if movieResponse.results.isEmpty {
                            completion(.failure(.movieNotFound(errorMessage: "Search returned no results")))
                    } else {
                        self.setMoviePosterPath(movies: &movieResults)
                            completion(.success((movieResults, movieResponse.total_pages)))
                    }
                    
                } catch {
                        completion(.failure(.errorProcessingData(errorMessage: error.localizedDescription)))
                }
            }
        }
        dataTask.resume()
    }
    
    /// Add base URL to movies by mutating the pposter field of a movie.
    ///
    /// - Parameters:
    ///     - movies: List of fectched movies
    ///
    /// - Important: The poster field of the movie gets mutated
    func setMoviePosterPath(movies :inout [Movie]) {
        for (index, _) in movies.enumerated() {
               guard let posterPath = movies[index].poster_path else { continue }
               movies[index].poster_path = "\(MovieManager.BASE_IMAGE_URL)\(posterPath)"
        }
    }
}
