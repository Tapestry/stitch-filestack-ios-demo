//
//  FilePickerIO.swift
//  PlugDemo
//
//  Created by Darren McKee on 30/10/18.
//

import UIKit
import Filestack
import FilestackSDK

typealias sourcesDict = (local: [LocalSource], cloud: [CloudSource])

@objc(FilePickerIO) class FilePickerIO: CDVPlugin {

    var actionCallbackId = ""
    var keyCallbackId = ""
    var nameCallbackId = ""
    var apiKey = ""
    var title = ""
    var config: Config?

    @objc func setKey(_ command: CDVInvokedUrlCommand?) {
        if config == nil {
            config = Config()
        }
        
        if let keyCallbackId = command?.callbackId {
            self.keyCallbackId = keyCallbackId
        }
        
        commandDelegate.run(inBackground: {
            if let apiKey = command?.arguments[0] as? String {
                self.apiKey = apiKey
            }
            
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate.send(result, callbackId: self.keyCallbackId)
        })
    }

    @objc func setName(_ command: CDVInvokedUrlCommand?) {
        if config == nil {
            config = Config()
        }
        
        if let nameCallbackId = command?.callbackId {
            self.nameCallbackId = nameCallbackId
        }
        
        commandDelegate.run(inBackground: {
            if let title = command?.arguments[0] as? String {
                self.title = title
            }
            
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate.send(result, callbackId: self.nameCallbackId)
        })
    }

    @objc func pick(_ command: CDVInvokedUrlCommand?) {
        if let actionCallbackId = command?.callbackId {
            self.actionCallbackId = actionCallbackId
        }
        
        showPicker(command, storeOptions: nil)
    }

    @objc func pickAndStore(_ command: CDVInvokedUrlCommand?) {
        if let actionCallbackId = command?.callbackId {
            self.actionCallbackId = actionCallbackId
        }

        var location = StorageLocation.s3
        if let commandString = command?.arguments[5] as? String {
            if commandString == "azure" {
                location = .azure
            } else if commandString == "dropbox" {
                location = .dropbox
            } else if commandString == "rackspace" {
                location = .rackspace
            } else if commandString == "gcs" {
                location = .gcs
            }
        }

        let storeOptions = StorageOptions(location: location)

        if let path = command?.arguments[6] as? String {
            storeOptions.path = path
        }
        
        if let container = command?.arguments[7] as? String {
            storeOptions.container = container
        }
        
        if let access = command?.arguments[8] as? String {
            if (access == "public") {
                storeOptions.access = StorageAccess.public
            } else {
                storeOptions.access = StorageAccess.private
            }
        }

        
        showPicker(command, storeOptions: storeOptions)

    }

    @objc func showPicker(_ command: CDVInvokedUrlCommand?, storeOptions: StorageOptions?) {
        commandDelegate.run(inBackground: {
            if self.config == nil {
                self.config = Config()
            }
            
            // Set allowed mime types, all mime types by default
            //config.mimeTypes = [self parseMimeTypes: [command.arguments objectAtIndex:0]];
            // Set services, all services by default
            if let rawSources = command?.arguments[1] as? [String] {
            
                let sources = self.parseSources(rawSources)
                self.config?.availableLocalSources = sources.local
                self.config?.availableCloudSources = sources.cloud
            }
            
            // Allowing multiple file selection
            if let multiple = command?.arguments[2] as? String {
                if multiple.boolValue == false {
                    self.config?.maximumSelectionAllowed = 1
                } else if let maxFiles = command?.arguments[3] as? UInt {
                    self.config?.maximumSelectionAllowed = maxFiles
                }
            }
            
            let client = Filestack.Client(apiKey: self.apiKey, security: nil, config: self.config!)
            
            let picker = client.picker(storeOptions: storeOptions!)
            
            // Optional. Set the picker's delegate.
            picker.pickerDelegate = self
            DispatchQueue.main.async(execute: {
                // Finally, present the picker on the screen.
                self.viewController.present(picker, animated: true)
            })
        })
    }

    func parseSources(_ array: [String]) -> sourcesDict {

        var localSources: [LocalSource] = []
        var cloudSources: [CloudSource] = []
        
        // Swift has an issue with these for some reason. Adding them manually and we can try to
        // use the static variables once the private var issue is fixed.
        
        var allLocalSources = LocalSource.all()
        
        for i in 0..<array.count {
            if array[i] == "GALLERY" {
                localSources.append(allLocalSources[1])
            } else if array[i] == "CAMERA" {
                localSources.append(allLocalSources[0])
            } else if array[i] == "DOCUMENTS" {
                // A new option for iOS Files
                localSources.append(allLocalSources[2])
            } else if array[i] == "FACEBOOK" {
                cloudSources.append(CloudSource.facebook)
            } else if array[i] == "CLOUDDRIVE" {
                cloudSources.append(CloudSource.amazonDrive)
            } else if array[i] == "DROPBOX" {
                cloudSources.append(CloudSource.dropbox)
            } else if array[i] == "BOX" {
                cloudSources.append(CloudSource.box)
            } else if array[i] == "GMAIL" {
                cloudSources.append(CloudSource.gmail)
            } else if array[i] == "INSTAGRAM" {
                cloudSources.append(CloudSource.instagram)
            } else if array[i] == "FLICKR" {
                // Flickr no longer supported
            } else if array[i] == "PICASA" {
                // Ensure this is now Google Photos
                cloudSources.append(CloudSource.googlePhotos)
            } else if array[i] == "GITHUB" {
                cloudSources.append(CloudSource.gitHub)
            } else if array[i] == "GOOGLE_DRIVE" {
                cloudSources.append(CloudSource.googleDrive)
            } else if array[i] == "EVERNOTE" {
                // Evernote no longer seems to be supported
            } else if array[i] == "SKYDRIVE" {
                // Ensure this is One Drive now
                cloudSources.append(CloudSource.oneDrive)
            } else if array[i] == "IMAGE_SEARCH" {
                // No image search is yet available. If the custom implementation occurs, then add the option here.
            }
        }

        let sources = sourcesDict(local: localSources, cloud: cloudSources)
        return sources
    }
}

extension FilePickerIO: PickerNavigationControllerDelegate {
    func pickerStoredFile(picker: PickerNavigationController, response: StoreResponse) {
        
    }
    
    func pickerUploadedFiles(picker: PickerNavigationController, responses: [NetworkJSONResponse]) {
        if responses.count == 0 {
            print("Nothing was picked.")
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "cancelled");
            commandDelegate.send(result, callbackId: actionCallbackId)
            return
        }
        
        var files: [[String:Any]] = []
        for info in responses {
            if let json = info.json {
                files.append(json)
            }
        }
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: files);
        commandDelegate.send(result, callbackId: actionCallbackId)
        picker.dismiss(animated: true) {
            
        }
    }
    
    
}

extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}
