//
//  Movie.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import Foundation

/// Structure used to match API response
struct MovieResponse : Decodable {
    var page : Int
    var results : [Movie]
    var total_pages : Int
}

/// Structure used to match API response for a particular movie
struct Movie : Decodable {
    var poster_path : String?
    var overview : String
    var release_date : String
    var title : String
}
