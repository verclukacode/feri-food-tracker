//
//  ArticleData.swift
//  Citrus
//
//  Created by Luka Verč on 27. 7. 24.
//

import UIKit

class ArticleData {

    enum TextElementType: String {
        case heading = "heading"
        case bold = "bold"
        case paragraph = "paragraph"
        case space = "space"
    }
    
    public var dictionary: [String: Any] = [:]
    convenience init(dictionary: [String: Any]) {
        self.init()
        self.dictionary = dictionary
        self.title = dictionary["title"] as? String ?? "No title"
    }
    
    public var title: String = ""
    
    private var image: UIImage?
    private var alreadyLoadingImage: Bool = false
    public func getImage(completion: @escaping (UIImage?)->()) {
        
        if let img = image {
            completion(img)
            return
        }
        
        if self.alreadyLoadingImage {
            DispatchQueue(label: "waiting", qos: .userInitiated).async {
                while self.alreadyLoadingImage {
                    //Wait
                }
                if let img = self.image {
                    completion(img)
                } else {
                    completion(nil)
                }
            }
            return
        }
        self.alreadyLoadingImage = true
        
        if let urlString = dictionary["image_url"] as? String, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil {
                    self.image = UIImage(data: data)
                    self.alreadyLoadingImage = false
                    completion(self.image!)
                } else {
                    self.alreadyLoadingImage = false
                    completion(nil)
                }
            }.resume()
        }
    }
    
    public var nutritionInfo: [[String: Any]] {
        return self.dictionary["nutrition_info"] as? [[String: Any]] ?? [[:]]
    }
    
    public var ingredients: [(String, String)] {
        var array: [(String, String)] = []
        for row in self.dictionary["ingredients"] as? [String: String] ?? [:] {
            array.append((row.0, row.1))
        }
        return array.sorted(by: {$0.0 < $1.0})
    }
    
    func getParsedBody() -> [TextElement] {
        var content: [TextElement] = []
        
        let body = self.dictionary["instructions"] as? String ?? ""
        
        let elements = body.replacingOccurrences(of: "\n", with: "").components(separatedBy: ">")
        for element in elements {
            if element.hasPrefix("h<") {
                let text = String(element.trimmingPrefix("h<"))
                content.append(TextElement(text: text, type: .heading))
            } else if element.hasPrefix("b<") {
                let text = String(element.trimmingPrefix("b<"))
                content.append(TextElement(text: text, type: .bold))
            } else if element.hasPrefix("p<") {
                let text = String(element.trimmingPrefix("p<"))
                content.append(TextElement(text: text, type: .paragraph))
            } else if element.hasPrefix("s<") {
                content.append(TextElement(text: "", type: .space))
            }
            
        }
        return content
    }
    
    
    class TextElement {
        public var text: String = ""
        public var type: TextElementType = .paragraph
        
        convenience init(text: String, type: TextElementType) {
            self.init()
            self.text = text
            self.type = type
        }
    }
    
    
    class func loadData(completion: @escaping ([ArticleData]) -> ()) {
        guard let url = URL(string: "https://getyoa.app/foodies/recipes/recipes.txt") else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard
                let data = data,
                error == nil,
                let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let articles = jsonArray.map { ArticleData(dictionary: $0) }
            DispatchQueue.main.async { completion(articles) }
        }.resume()
    }

}
