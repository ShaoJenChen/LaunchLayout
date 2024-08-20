//
//  Utilities.swift
//  AutoLayout
//
//  Created by 陳劭任 on 2021/10/19.
//

import Cocoa

public func getMDItems() -> [NSMetadataItem] {

    //Applications/...
    guard let applicationsFolderUrl = try? FileManager.default.url(for: .applicationDirectory,
                                                                   in: .localDomainMask,
                                                                   appropriateFor: nil,
                                                                   create: false) else { return [] }
    
    let applicationUrls = try! FileManager().contentsOfDirectory(at: applicationsFolderUrl ,
                                                                 includingPropertiesForKeys: [],
                                                                 options: [.skipsPackageDescendants,
                                                                           .skipsSubdirectoryDescendants])
    
    //System/Applications
    guard let systemApplicationsFolderUrl = try? FileManager.default.url(for: .applicationDirectory,
                                                                         in: .systemDomainMask,
                                                                         appropriateFor: nil, create: false) else { return [] }
    
    guard let systemApplicationsUrls = try? FileManager().contentsOfDirectory(at: systemApplicationsFolderUrl,
                                                                              includingPropertiesForKeys: [],
                                                                              options: [.skipsPackageDescendants,
                                                                                        .skipsSubdirectoryDescendants]) else { return [] }
    
    //System/Applications/Utilities/...
    guard let utilitiesFolderUrl = URL(string: "\(systemApplicationsFolderUrl.path)/Utilities") else { return [] }
    
    guard let utilitiesUrls = try? FileManager().contentsOfDirectory(at: utilitiesFolderUrl,
                                                                     includingPropertiesForKeys: [],
                                                                     options: [.skipsPackageDescendants,
                                                                               .skipsSubdirectoryDescendants]) else { return [] }
    
    let urls = applicationUrls + systemApplicationsUrls + utilitiesUrls

    let mdItems = urls.compactMap { url -> NSMetadataItem? in
        
        guard FileManager().isExecutableFile(atPath: url.path) else { return nil }
        
        return NSMetadataItem(url: url)
        
    }

    return mdItems
}

public func getMDItem(with appPath: String) -> NSMetadataItem? {
    
    return getMDItems().first(where: { $0.value(forAttribute: String(kMDItemPath)) as! String == appPath })
    
}

public func getAppPath(with bundleID: String) -> String? {
    
    guard let appItem = getMDItems().filter({ mdItem in
        
        guard let itemID = mdItem.value(forAttribute: String(kMDItemCFBundleIdentifier)) as? String else { return false }
        return itemID == bundleID
        
    }).first else { return nil }
    
    guard let appPath = appItem.value(forAttribute: String(kMDItemPath)) as? String else { return nil }
    
    return appPath
    
}

public func getAppID(with appPath: String, from mdItems: [NSMetadataItem]) -> String? {
    
    guard let mdItem = mdItems.filter({ mdItem in
        
        guard let mdItemPath = mdItem.value(forAttribute: String(kMDItemPath))
                as? String else { return false }
        
        return mdItemPath == appPath
        
    }).first else { return nil }
    
    guard let bundleID = mdItem.value(forAttribute: String(kMDItemCFBundleIdentifier)) as? String else { return nil }
    
    return bundleID
    
}
