//
//  MovieSearchController.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/19/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import UIKit

/// Controller used when the user is going to search for movies. This is a Table View that displays the last 10 searches made by the user.
class MovieSearchController: UITableViewController {

    var searches = [String]()
    var parentController : MovieViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searches.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell")!
        cell.textLabel?.text = searches[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Tell the parent controller to make a movie request and dismiss this controller
        tableView.deselectRow(at: indexPath, animated: true)
        parentController?.requestMovies(movieName: searches[indexPath.row])
        dismiss(animated: true, completion: nil)
        
    }

}
