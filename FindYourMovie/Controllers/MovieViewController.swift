//
//  ViewController.swift
//  FindYourMovie
//
//  Created by Andres Guevara Caprio on 8/18/20.
//  Copyright © 2020 Andres Guevara Caprio. All rights reserved.
//

import UIKit

class MovieViewController: UITableViewController {
    
    @IBOutlet weak var movieSearchBar: UISearchBar!
    var movieSearch = [Movie]()
    var currentPage = 1
    var currentSearch = ""
    var totalPages = 1
    var last10searches = [String]()
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let searches = self.defaults.array(forKey: "lastSearches") as? [String] {
            self.last10searches = searches
        }
        // Do any additional setup after loading the view.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieSearch.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = movieSearch[indexPath.row]
        cell.name.text = movie.title
        cell.releaseDate.text = movie.release_date
        cell.overview.text = movie.overview
        cell.poster.load(string: movie.poster_path)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let currentPosition = indexPath.row
        let totalRows = movieSearch.count
        
        if (self.currentPage < self.totalPages && Double(currentPosition)/Double(totalRows) >= 0.9) {
            MovieManager.shared.getMoviesNames(query: currentSearch, page: String(currentPage + 1))
            { [weak self] results in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch results {
                case .success(let movieResult):
                    self?.movieSearch.append(contentsOf: movieResult.0)
                    self?.currentPage += 1
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showError(errorToDisplay : error)
                    
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
        
        guard var searchText = searchBar.text, !searchText.isEmpty else {
            return
        }
        searchText = searchText.replacingOccurrences(of: " ", with: "+")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        
        MovieManager.shared.getMoviesNames(query: searchText)
        { [weak self] results in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            switch results {
            case .success(let movieResult):
                self?.movieSearch = movieResult.0
                self?.totalPages = movieResult.1
                self?.currentSearch = searchText
                self?.currentPage = 1
                self?.last10searches.append(item: searchBar.text!)
                self?.defaults.set(self?.last10searches, forKey: "lastSearches")
                self?.tableView.reloadData()
            case .failure(let error):
                self?.showError(errorToDisplay : error)
            }
            
        }
        
    }
    

    
    func showError(errorToDisplay: MovieManager.MovieManagerError){
        
        let alert = UIAlertController(title: "Error on Search", message: errorToDisplay.getCustomError(), preferredStyle: .alert)
        
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
                    DispatchQueue.main.async {
                        self?.image = UIImage(systemName: "questionmark.square")
                    }
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

extension Array {
    mutating func append(item: String) {
        if(self.count == 10){
            self.removeLast()
        }
        self.insert(item as! Element, at: 0)
    }
}

