//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/18/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    //MARK: Variables
    
    let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var pin: Pin!
    var  selectMode: Bool { return photoCollectionView.indexPathsForSelectedItems?.count != 0}
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
        }
    }
    
    //MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    //MARK: IBActions
    
    @IBAction func newCollection() {
        if !selectMode{
            loadNewCollection()
        } else {
            for indexPath in photoCollectionView.indexPathsForSelectedItems! {
                if let photo = fetchedResultsController!.object(at: indexPath) as? Photo{
                    fetchedResultsController?.managedObjectContext.delete(photo)
                }
            }
        }
    }
    
    //MARK: View Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingIndicator.center = view.center
        view.addSubview(loadingIndicator)
        
        
        // Create a Fetch Request
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor]()
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Stack.context, sectionNameKeyPath: nil, cacheName: nil)


        mapView.region = MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpanMake(0.2, 0.2))
        mapView.addAnnotation(pin)
        if fetchedResultsController!.fetchedObjects!.count == 0 {
            loadNewCollection()
        }
        
        photoCollectionView.allowsMultipleSelection = true
        updateFlowLayoutToFit(items: 3, inWidth: view.frame.size.width)
    }

    //MARK: update UICollectionViewFlowLayout
    
    func updateFlowLayoutToFit(items: Int, inWidth width: CGFloat) {
        let space: CGFloat = 3.0
        let dimension = (width - (CGFloat(items-1) * space)) / CGFloat(items)
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    //MARK: View Rotation
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        updateFlowLayoutToFit(items: 3, inWidth: view.frame.size.height)
    }

    //MARK: Load New Photo Collection
    
    func loadNewCollection() {
        loadingIndicator.startAnimating()
        updateUI(loading: true)
        Flickr.displayImageFromFlickrBySearch(coordinate: pin.coordinate) { result, error in
            self.loadingIndicator.stopAnimating()

            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            guard let photosArray = result!["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key photo in \(result)")
                return
            }
            
            // Delete all old photos
            for photo in self.fetchedResultsController!.fetchedObjects! {
                self.fetchedResultsController?.managedObjectContext.delete(photo as! NSManagedObject)
            }
            
            var photosToBeLoaded = self.fetchedResultsController!.fetchedObjects!.count
            
            for photoObject in photosArray {
                let photo = Photo(photoData: nil, pin: self.pin, context: self.fetchedResultsController!.managedObjectContext)
                
                DispatchQueue.global(qos: .utility).async {
                    let photoData = NSData(contentsOf: URL(string: photoObject["url_m"] as! String)!)!
                    photosToBeLoaded -= 1
                    DispatchQueue.main.async {
                        photo.photoData = photoData
                        if photosToBeLoaded <= 0 {
                            self.updateUI(loading: false)
                        }
                    }
                }
            }
            
        }
    }
    
    func updateUI(loading: Bool) {
        newCollectionButton.isEnabled = !loading
        photoCollectionView.allowsSelection = !loading
    }

}

// MARK: - extension - UICollectionViewDataSource

extension PhotoAlbumViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.alpha = cell.isSelected ? 0.3 : 1.0

        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        let imageView = cell.viewWithTag(10) as! UIImageView
        if let photoData = photo.photoData{
            imageView.image = UIImage(data: photoData as Data)
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
}

// MARK: - extension - UICollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 0.3
        newCollectionButton.setTitle(selectMode ? "Remove Selected Pictures" : "New Collection", for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 1.0
        newCollectionButton.setTitle(selectMode ? "Remove Selected Pictures" : "New Collection", for: .normal)
    }
}

// MARK: - extension - Fetches

extension PhotoAlbumViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK: - extension NSFetchedResultsControllerDelegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photoCollectionView.reloadData()
        newCollectionButton.setTitle(selectMode ? "Remove Selected Pictures" : "New Collection", for: .normal)
    }
}
