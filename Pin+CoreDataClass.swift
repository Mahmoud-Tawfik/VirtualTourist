//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/17/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class Pin: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
