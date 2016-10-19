//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/17/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    convenience init(photoData: NSData?, pin: Pin, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.pin = pin
            self.photoData = photoData
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
