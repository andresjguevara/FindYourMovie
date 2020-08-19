//
//  MovieManager.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import Foundation

class MovieManager {
    

    
    enum MovieManagerError : Error {
        case errorRequestingData(errorMessage: String)
        case badRequest(errorMessage: String)
        case errorProcessingData(errorMessage: String)
        case movieNotFound(errorMessage: String)
        
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
    typealias MovieResult = ([Movie], Int)
        
    private init(){
    }
    
    func getMoviesNames(query : String, page : String = "1", completion: @escaping(Result<MovieResult, MovieManagerError>) -> Void) {
         
        let getURL = "https://api.themoviedb.org/3/search/movie?api_key=\(MovieManager.API_KEY)&query=\(query)&page=\(page)"
        
        guard let url = URL(string: getURL) else {
            completion(.failure(.errorRequestingData(errorMessage: "Invalid URL")))
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) {data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.errorRequestingData(errorMessage: error.localizedDescription)))
                }
            } else if
                let jsonData = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()
                    let movieResponse = try decoder.decode(MovieResponse.self, from: jsonData)
                    var movieResults = movieResponse.results
                    if movieResponse.results.isEmpty {
                        DispatchQueue.main.async {
                            completion(.failure(.movieNotFound(errorMessage: "Search returned no results")))
                        }
                    }
                    self.setMoviePosterPath(movies: &movieResults)
                    DispatchQueue.main.async {
                        completion(.success((movieResults, movieResponse.total_pages)))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(.errorProcessingData(errorMessage: error.localizedDescription)))
                    }
                    
                }
            }
        }
        dataTask.resume()
    }
    
    func setMoviePosterPath(movies :inout [Movie]) {
        for (index, movie) in movies.enumerated() {
            if movies[index].poster_path != nil {
                movies[index].poster_path = "\(MovieManager.BASE_IMAGE_URL)\(movie.poster_path!)"
            }
        }
            
    }
    
}
