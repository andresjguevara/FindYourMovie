//
//  ViewController.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import UIKit

/// Controller for main view. It is a Table View that contains a search controller to search for movies through a movie databse API.
/// The last 10 movies are persisted locally and displayed as a suggestion when the user searches for movies
class MovieViewController: UITableViewController {
    
    var movieSearch = [Movie]()
    var currentPage = 1
    var currentSearch = ""
    var totalPages = 1
    var last10searches = [String]()
    var lastSearchesController : MovieSearchController!
    var searchController : UISearchController!
    let defaults = UserDefaults.standard
    let FETCH_THRESHOLD = 0.9
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create an instance of the second controller once main controller loads
        lastSearchesController = MovieSearchController()
        // Make the second controller a search result controller
        searchController = UISearchController(searchResultsController: lastSearchesController)
        searchController.searchResultsUpdater = self
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.placeholder = "Search for a Movie"
        } else {
            searchController.searchBar.placeholder = "Search for a Movie"
        }
        // Add search controller to navigation controller
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        // Load latestes searches at loading time
        if let searches = self.defaults.array(forKey: "lastSearches") as? [String] {
            self.last10searches = searches
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieSearch.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        // Configure each cell
        let movie = movieSearch[indexPath.row]
        cell.configure(movie: movie)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currentPosition = indexPath.row
        let totalRows = movieSearch.count
        // If the user has scrolled more than the set threshold of the list, then get the next available page, if available
        if self.currentPage < self.totalPages && Double(currentPosition)/Double(totalRows) >= FETCH_THRESHOLD {
            requestMovies(movieName: self.currentSearch, paging: true)
        }
    }

    
    /// Makes a call to the API requesting movies. It updates the internal values for total pages, current search, current page, and movies
    ///
    ///- Parameters:
    ///     - movieName: name of the movie to search
    ///     - paging:indicates if the request requires a page number. If true, the page number will be updated to the next available page.
    /// if false, the request will be done to the first page
    func requestMovies(movieName : String, paging: Bool = false)  {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        var pageNumber : Int
        if paging {
            pageNumber = self.currentPage + 1
        } else {
            pageNumber = 1
        }
        
        MovieManager.shared.getMoviesNames(query: movieName, page: String(pageNumber))
        { [weak self] results in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard let self = self else {return}
            switch results {
            case .success(let movieResult):
                if pageNumber > 1 {
                    self.movieSearch.append(contentsOf: movieResult.0)
                    self.currentPage += 1
                } else {
                    self.movieSearch = movieResult.0
                    self.totalPages = movieResult.1
                    self.currentSearch = movieName
                    self.currentPage = 1
                    self.updateLastSearchResults(movieName: movieName)
                }
                self.tableView.reloadData()
            case .failure(let error):
                self.showError(errorToDisplay : error)
            }
        }
        
    }
    
    /// Displays an error as an alert. It uses the parameters custom error message to display.
    ///
    /// - Parameter errorToDisplay: The type of error that was generated
    private func showError(errorToDisplay: MovieManager.MovieManagerError){
        
        let alert = UIAlertController(title: "Error on Search", message: errorToDisplay.getCustomError(), preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
        
    }
    
    /// Updates the last searches done by the user. No duplicates are added and the size is kept to 10
    ///
    /// - Parameter movieName: Name of the movie to add to the list.
    private func updateLastSearchResults(movieName: String) {
        if !last10searches.contains(movieName){
            if self.last10searches.count == 10 {
                self.last10searches.removeLast()
            }
            self.last10searches.insert(movieName, at: 0)
            self.defaults.set(self.last10searches, forKey: "lastSearches")
        }
        
        
    }
    
}

// MARK: - Search Bar Delegate
//
extension MovieViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            return
        }
        requestMovies(movieName: searchText)
        searchBar.text = ""
        searchController.dismiss(animated: true, completion: nil)
        
    }
    
    
}

// MARK: - UISearchControllerDelegate

extension MovieViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        if #available(iOS 13.0, *) {
            searchController.showsSearchResultsController = true
        } else {
            show(searchController.searchResultsController!, sender: self )
        }
        
    }
}

// MARK: - UISearchResultsUpdating

extension MovieViewController: UISearchResultsUpdating {
    
    // Called when the search bar's text has changed or when the search bar becomes first responder.
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searches = self.defaults.array(forKey: "lastSearches") as? [String] {
            self.last10searches = searches
        }
        
        if let resultsController = searchController.searchResultsController as? MovieSearchController {
            resultsController.parentController = self
            resultsController.searches = self.last10searches
            resultsController.tableView.reloadData()
        }
    }
    
}


extension UIImageView {
    func load(urlAsString: String?) {
        DispatchQueue.global().async { [weak self] in
            guard let url = urlAsString else {
                self?.setDefaultImage()
                return
            }
            let newURL = URL(string: url)
            if let data = try? Data(contentsOf: newURL!) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
        
    }
    private func setDefaultImage() {
        if #available(iOS 13.0, *) {
        DispatchQueue.main.async {
                self.image = UIImage(systemName: "questionmark.square")
            }
        } else {
            self.image = UIImage(named: "ios12_not_available")
            return
        }
        
    }
}

