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
    var release_date : String?
    var title : String
    
    /// Returns formatted date from "yyyy-MM-dd" format to "MMM dd, yyyy"
    func getReleaseDateWithDateFormat() -> String {
        guard let release_date = self.release_date else {
            return "No Release Date Available"
        }
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd,yyyy"
        
        if let date = dateFormatterGet.date(from: release_date) {
            return (dateFormatterPrint.string(from: date))
        } else {
            return release_date
        }

    }
}
