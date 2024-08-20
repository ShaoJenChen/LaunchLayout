//
//  ThumbNailGenerator.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/5/31.
//

import Cocoa
import QuickLookThumbnailing

class ThumbNailGenerator {
    
    class func generateThumbnailRepresentations(filePath: String,
                                                completion: @escaping ((QLThumbnailRepresentation?) -> Void)) {
        
        let url = URL(fileURLWithPath: filePath)
        
        let size: CGSize = CGSize(width: 60, height: 90)
        
        let scale = NSScreen.main!.backingScaleFactor
        
        // Create the thumbnail request.
        let request = QLThumbnailGenerator.Request(fileAt: url,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .all)
        
        // Retrieve the singleton instance of the thumbnail generator and generate the thumbnails.
        let generator = QLThumbnailGenerator.shared
        
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            
            DispatchQueue.main.async {
                
                // Handle the error case gracefully
                guard thumbnail != nil, error == nil else { return }
                
                // Display the thumbnail that you created.
                completion(thumbnail)
                
            }
        }
    }
}
