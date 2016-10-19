//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/17/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import Foundation
import CoreData

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var photoData: NSData?
    @NSManaged public var pin: Pin?

}
