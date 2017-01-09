//
//  Networking.swift
//  Concentrate
//
//  Created by Ian Dundas on 09/01/2017.
//  Copyright © 2017 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveKit

let KEY_500PX_CONSUMER = "wC5NJbxW42PPzkc2volg6HcFUIjSZG8wCfpykYqy"
//let NetworkQueue = DispatchQueue(label: "Concrete.Networking", qos: DispatchQoS.background)

typealias JSONDictionary = [String: AnyObject]
typealias JSONArray = [JSONDictionary]

func getData(url: URL) -> Signal<Data, String> {
    return Signal { observer in
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data: Data?, response:URLResponse?, error: Error?) in
            if let error = error {observer.failed(error.localizedDescription); return }
            guard let data = data else { observer.failed("Received blank response"); return }
            
            observer.completed(with: data)
        })
        
        task.resume()
        
        return BlockDisposable {
            task.cancel()
        }
    }
}

func getJSONDictionary(url: URL) -> Signal<JSONDictionary, String> {
    return getData(url: url)
        .flatMapLatest(transform: { (data: Data) -> Signal<JSONDictionary, String> in
            guard let parsed = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                return Signal.failed("Could not parse JSON data")
            }
            guard let json = parsed, JSONSerialization.isValidJSONObject(json) else {
                return Signal.failed("Didn't receive valid JSON")
            }
            return Signal.just(json)
        })
}

struct PhotoNetworkAsset {
    let name: String
    let image_url: URL
}

func fetchPhotoAssets(tag: String) -> Signal<[PhotoNetworkAsset], String> {
    
    guard let url = URL(string: "https://api.500px.com/v1/photos/search?feature=popular&tag=\(tag)&sort=highest_rating&image_size=3&consumer_key=\(KEY_500PX_CONSUMER)") else {
        return Signal.failed("Unable to form URL");
    }
 
    let signal: Signal<[PhotoNetworkAsset], String> = getJSONDictionary(url: url)
        .flatMapLatest { (received: JSONDictionary) -> Signal<JSONArray, String> in
            guard let photos = received["photos"] as? JSONArray else { return Signal.failed("No photo array in received JSON")}
            return Signal.just(photos)
        }
        .flatMapLatest { (photos: JSONArray) -> Signal<[PhotoNetworkAsset], String> in
            let photoAssets = photos.map { (photo: JSONDictionary) -> PhotoNetworkAsset? in
                guard let urlString = photo["image_url"] as? String
                    , let name = photo["name"] as? String
                    , let url = URL(string: urlString) else {return nil}
                
                return PhotoNetworkAsset(name: name, image_url: url)
            }
            
            // return assets, stripping optionals to make concrete [PhotoNetworkAsset]
            return Signal.just(photoAssets.flatMap{$0})
        }
    
    return signal
}
