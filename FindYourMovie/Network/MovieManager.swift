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
        case errorRequestingData(String)
        case badRequest(String)
        case errorProcessingData(String)
    }
    static let shared = MovieManager()
    private static let API_KEY = "2696829a81b1b5827d515ff121700838"
    private static let BASE_IMAGE_URL = "https://image.tmdb.org/t/p/w92"

    private init(){
    }
    
    func getMoviesNames(query : String, page : String = "1", completion: @escaping(Result<[Movie], MovieManagerError>) -> Void) {
        
        let getURL = "https://api.themoviedb.org/3/search/movie?api_key=\(MovieManager.API_KEY)&query=\(query)&page=\(page)"
        
        guard let url = URL(string: getURL) else {
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) {data, response, error in
            
            if let error = error {
                completion(.failure(.errorRequestingData(error.localizedDescription)))
            } else if
                let jsonData = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()
                    let movieResponse = try decoder.decode(MovieResponse.self, from: jsonData)
                    var movieResults = movieResponse.results
                    self.setMoviePosterPath(movies: &movieResults)
                    DispatchQueue.main.async {
                        completion(.success(movieResults))
                    }
                } catch {
                    print(error)
                    completion(.failure(.errorProcessingData(error.localizedDescription)))
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
