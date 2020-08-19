//
//  ViewController.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import UIKit

class MovieViewController: UITableViewController {
    
    var movieSearch = [Movie]()
    var currentPage = 1
    var currentSearch = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieSearch.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = movieSearch[indexPath.row]
        cell.name.text = movie.title
        cell.overview.text = movie.overview
        cell.poster.load(string: movie.poster_path)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currentPosition = indexPath.row
        let totalRows = movieSearch.count
        
        if (Double(currentPosition)/Double(totalRows) >= 0.85) {
            MovieManager.shared.getMoviesNames(query: currentSearch, page: String(currentPage + 1))
            { [weak self] results in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch results {
                case .success(let movies):
                    DispatchQueue.main.async {
                        self?.movieSearch.append(contentsOf: movies)
                        self?.currentPage += 1
                        self?.tableView.reloadData()
                    }

                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.showError(errorToDisplay : error)
                    }
                }
                
            }
            
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
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        
        MovieManager.shared.getMoviesNames(query: searchText)
        { [weak self] results in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            switch results {
            case .success(let movies):
                self?.movieSearch = movies
                self?.currentSearch = searchText
                self?.currentPage = 1
                self?.tableView.reloadData()
            case .failure(let error):
                self?.showError(errorToDisplay : error)
            }
            
        }
    }
    func showError(errorToDisplay: MovieManager.MovieManagerError){
        
        let alert = UIAlertController(title: "Error on Search", message: errorToDisplay.localizedDescription, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
        
    }
    
}

extension UIImageView {
    func load(string: String?) {
        DispatchQueue.global().async { [weak self] in
            guard let url = string else {
                if #available(iOS 13.0, *) {
                    self?.image = UIImage(systemName: "questionmark.square")
                } else {
                    return
                }
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
}

