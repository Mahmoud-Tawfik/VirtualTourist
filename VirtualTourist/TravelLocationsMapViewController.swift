//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/17/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TravelLocationsMapViewController: UIViewController {
    
    //MARK: Variables
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
            updateAllPins()
        }
    }

    //MARK: IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    
    //MARK: IBActions

    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if !isEditing{
                let newPinCoordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
                _ = Pin(latitude: newPinCoordinate.latitude, longitude: newPinCoordinate.longitude, context: fetchedResultsController!.managedObjectContext)
                Stack.saveContext()
                
            }
        }
    }
    
    @IBAction func edit() {
        isEditing = !isEditing
        labelHeightConstraint.constant = isEditing ? 70 : 0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutSubviews()
        }
        
        let newButton = UIBarButtonItem(barButtonSystemItem: (isEditing) ? .done : .edit, target: self, action: #selector(self.edit))
        self.navigationItem.setRightBarButton(newButton, animated: true)
    }
    
    //MARK: View Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide edit guide label
        labelHeightConstraint.constant = 0
        
        // Create a fetchrequest
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Load last map region into map view
        if UserDefaults.standard.bool(forKey: "hasMapRegion") {
            let lat = CLLocationDegrees(UserDefaults.standard.float(forKey: "latitude"))
            let lon = CLLocationDegrees(UserDefaults.standard.float(forKey: "longitude"))
            let latDelta = CLLocationDegrees(UserDefaults.standard.float(forKey: "latitudeDelta"))
            let lonDelta = CLLocationDegrees(UserDefaults.standard.float(forKey: "longitudeDelta"))
            mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        }

    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Photo Album"{
            if let destination = segue.destination as? PhotoAlbumViewController{
                if let sender = sender as? Pin {
                    destination.pin = sender
                }
            }
        }
    }

}

// MARK: - extension - Fetches

extension TravelLocationsMapViewController {
    
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

// MARK: - extension - NSFetchedResultsControllerDelegate

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let pin = anObject as? Pin{
            switch type {
            case .insert:
                insertPin(pin)
            case .delete:
                deletePin(pin)
            case .update, .move:
                deletePin(pin)
                insertPin(pin)
            }
        }
    }
    
    func insertPin(_ pin :Pin) {
        mapView.addAnnotation(pin)
    }
    
    func deletePin(_ pin :Pin) {
        mapView.removeAnnotation(pin)
    }
    
    func updateAllPins() {
        mapView.removeAnnotations(mapView.annotations)
        if let allPins = fetchedResultsController?.fetchedObjects{
            for pin in allPins{
                if let pin = pin as? Pin{
                    insertPin(pin)
                }
            }
        }
    }

}

// MARK: - extension - MKMapViewDelegate

extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        if isEditing {
            if let pin = view.annotation as? Pin{
                fetchedResultsController?.managedObjectContext.delete(pin)
            }
        } else {
            performSegue(withIdentifier: "Photo Album", sender: view.annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // save map region
        UserDefaults.standard.set(true, forKey: "hasMapRegion")
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "latitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        UserDefaults.standard.synchronize()
    }

}
