//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Mahmoud Tawfik on 10/18/16.
//  Copyright © 2016 Mahmoud Tawfik. All rights reserved.
//

import Foundation
import MapKit

let Flickr = FlickrClient.sharedInstance

struct FlickrClient {
    
    typealias CompletionHandler = ((_ result: [String:Any]?, _ error: Error?) -> Void)?

    //MARK: Public methods

    func displayImageFromFlickrBySearch(coordinate: CLLocationCoordinate2D, completionHandler: CompletionHandler) {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(coordinate),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage
        ]
        
        displayImageFromFlickrBySearch(methodParameters) { result, error in
            guard error == nil else {
                self.performOnMain(completionHandler, result: nil, error: error)
                return
            }
            
            guard let totalPages = result![Constants.FlickrResponseKeys.Pages] as? Int else {
                let error = NSError(domain: "displayImageFromFlickrBySearch", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(result)"])
                self.performOnMain(completionHandler, result: nil, error: error)

                return
            }
            
            // pick a random page!
            let pageLimit = min(totalPages, Int(4000 / Int(Constants.FlickrParameterValues.PerPage)!))
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage, completionHandler: completionHandler)
        }
    }

    //MARK: Private methods

    private func displayImageFromFlickrBySearch(_ methodParameters: [String:Any], withPageNumber: Int? = nil, completionHandler: CompletionHandler) {
        
        var methodParametersWithPageNumber = methodParameters
        if let withPageNumber = withPageNumber {
            methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber
        }
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParametersWithPageNumber))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                let error = NSError(domain: "displayImageFromFlickrBySearch", code: 1, userInfo: [NSLocalizedDescriptionKey : error])
                self.performOnMain(completionHandler, result: nil, error: error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:Any] else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }

            self.performOnMain(completionHandler, result: photosDictionary, error: nil)
        }
        
        // start the task!
        task.resume()
    }
    
    private func flickrURLFromParameters(_ parameters: [String:Any]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    private func bboxString(_ coordinate: CLLocationCoordinate2D) -> String {
        // ensure bbox is bounded by minimum and maximums
            let minimumLon = max(coordinate.longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(coordinate.latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(coordinate.longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(coordinate.latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }

    private func performOnMain(_ completionHandler: CompletionHandler, result: [String: Any]?, error: Error?) {
        DispatchQueue.main.async {
            if let completionHandler = completionHandler {
                completionHandler(result, error)
            }
        }
    }
    
    //MARK: Singleton
    static var sharedInstance = FlickrClient()
}
