//
//  NearestTableViewController.swift
//  MetroExplorerApp
//
//  Created by Joshua on 11/24/18.
//  Copyright © 2018 Joshua. All rights reserved.
//

import UIKit
import MBProgressHUD

class LandmarksViewController: UITableViewController {
    var favorites = PersistenceManager.sharedInstance.fetchFavorites()
    var lat: Double = 0
    var lon: Double = 0
    let yelpAPIManager = YelpAPIManager()
    var station = Station(name: "", address: "", lineCode1: "", lineCode2: "", lineCode3: "", lat: 0, lon: 0)
    
    var landmarks = [Landmark]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.title == "Landmarks" {
            self.navigationItem.title = station.name
            self.lat = station.lat
            self.lon = station.lon
            yelpAPIManager.delegate = self
            fetchLandmark()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.favorites = PersistenceManager.sharedInstance.fetchFavorites()
        tableView.reloadData()
    }
    
    private func fetchLandmark() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        yelpAPIManager.fetchLandmarks(lat: self.lat, lon: self.lon)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int = 0
        if self.title == "Landmarks" {
            count = landmarks.count
        } else {
            count = favorites.count
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellToReturn = UITableViewCell()
        if self.title == "Landmarks" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "landmarkCell", for: indexPath) as! LandmarksTableViewCell
            
            let landmark = landmarks[indexPath.row]
            
            cell.landmarkNameLabel.text = landmark.name
            cell.landmarkAddressLabel.text = landmark.address
            
            var urlString:String = ""
            urlString = landmark.image_url
            if let url = URL(string: urlString) {
                cell.landmarkImage.load(url: url)
            } else {
                cell.landmarkImage.image = UIImage(named: "no_image_available")
            }
            cellToReturn = cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteCell", for: indexPath) as! FavoritesTableViewCell
            
            let favorite = favorites[indexPath.row]
            
            cell.favoriteNameLabel.text = favorite.name
            cell.favoriteAddressLabel.text = favorite.address
            
            var urlString:String = ""
            urlString = favorite.image_url
            if let url = URL(string: urlString) {
                cell.favoriteImage.load(url: url)
            } else {
                cell.favoriteImage.image = UIImage(named: "no_image_available")
            }
            cellToReturn = cell
        }
        return cellToReturn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.title == "Landmarks" {
            performSegue(withIdentifier: "segue", sender: indexPath.row)
        } else {
            performSegue(withIdentifier: "segueFavorites", sender: indexPath.row)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //pass the data to your next view controller
        
        let row = sender as! Int
        
        let vc = segue.destination as! LandmarkDetailViewController
        if self.title == "Landmarks" {
            vc.landmark = landmarks[row]
        } else {
            vc.landmark = favorites[row]
        }
    }
}

extension LandmarksViewController: FetchLandmarksDelegate {
    func landmarksFound(_ landmarks: [Landmark]) {
        print("landmarks found - here they are in the controller.")
        DispatchQueue.main.async {
            self.landmarks = landmarks
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    func landmarksNotFound(reason: YelpAPIManager.FailureReason) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
            let alertController = UIAlertController(title: "Problem fetching landmarks", message: reason.rawValue, preferredStyle: .alert)
            
            switch(reason) {
            case .noResponse:
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                    self.fetchLandmark()
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler:nil)
                
                alertController.addAction(cancelAction)
                alertController.addAction(retryAction)
                
            case .non200Response, .noData, .badData:
                let okayAction = UIAlertAction(title: "OK", style: .default, handler:nil)
                
                alertController.addAction(okayAction)
            }
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

