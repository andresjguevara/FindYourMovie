//
//  Movie.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import Foundation

struct MovieResponse : Decodable {
    var page : Int
    var results : [Movie]
    var total_pages : Int
}

struct Movie : Decodable {
    var poster_path : String?
    var overview : String
    var release_date : String
    var title : String
}
