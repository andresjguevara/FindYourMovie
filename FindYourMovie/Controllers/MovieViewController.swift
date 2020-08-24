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
    
    var currentMovieSearch = ""
    var lastSearchesController : MovieSearchController!
    var searchController : UISearchController!
    
    let movieViewModel = MoviewViewModel(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
    
    let FETCH_THRESHOLD = 0.95
    
    
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
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.movieViewModel.getMovieCount()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        // Configure each cell
        self.configureCell(cell: cell, at: indexPath.row)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currentPosition = indexPath.row
        let totalRows = self.movieViewModel.getMovieCount()
        // If the user has scrolled more than the set threshold of the list, then get the next available page, if available
        if Double(currentPosition)/Double(totalRows) >= FETCH_THRESHOLD {
            requestMovies(movieName: self.currentMovieSearch, isFollowUpRequest: true)
        }
    }
    
    
    /// Makes a call to the API requesting movies.
    ///
    ///- Parameters:
    ///     - movieName: name of the movie to search
    ///     - isFollowUpRequest:indicates if the request is a follow up from a previous request
    func requestMovies(movieName : String, isFollowUpRequest : Bool = false)  {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.movieViewModel.makeAPIRequest(movieName: movieName, isFollowUpRequest: isFollowUpRequest)
        {
            [weak self] result in
            
            switch result {
                
            case .success(_):
                DispatchQueue.main.async {
                    self?.currentMovieSearch = movieName
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showError(errorToDisplay: error)
                    self?.tableView.reloadData()
                }
            }
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    /// Displays an error as an alert. It uses the parameters custom error message to display.
    ///
    /// - Parameter errorToDisplay: The type of error that was generated
    private func showError(errorToDisplay: MovieManager.MovieManagerError?){
        var customError = "Unknown error"
        
        if let errorMessage = errorToDisplay?.getCustomError() as String? {
            customError = errorMessage
        }
        let alert = UIAlertController(title: "Error on Search", message: customError, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
        
    }
    
}

extension MovieViewController {
    func configureCell(cell : MovieCell, at index: Int){
        cell.name.text = self.movieViewModel.getTitleForMovie(at: index)
        cell.releaseDate.text = self.movieViewModel.getReleaseDateForMovie(at: index)
        cell.overview.text = self.movieViewModel.getOverviewForMovie(at: index)
        cell.poster.load(urlAsString: self.movieViewModel.getPosterForMovie(at: index))
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
        
        if let resultsController = searchController.searchResultsController as? MovieSearchController {
            resultsController.parentController = self
            resultsController.viewModel = self.movieViewModel
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

