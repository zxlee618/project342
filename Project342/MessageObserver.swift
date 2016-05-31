//
//  MessageObserver.swift
//  Project342
//
//  Created by Fagan Ooi on 01/06/2016.
//  Copyright © 2016 UOW. All rights reserved.
//


import CoreData
import Firebase


class MessageObserver {
    
    static let observer = MessageObserver()
    
    
    let managedObjectContext: NSManagedObjectContext
    
    // MARK: Firebase event handles
    
    var messageChangedEventHandle: FIRDatabaseHandle?
    
    
    private init() {
        managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        // TODO: Remove this one the login VC is done
        FIRAuth.auth()?.signInWithEmail("9w2owd@gmail.com", password: "password", completion: nil)
    }
    
    func observeMessageEvents() {
        // Remove any existing observer
        stopObservingMessageEvents()
        
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            print("No logged in user")
            return
        }
        // Get a list of conversation
        let fetchRequest = NSFetchRequest(entityName: "Conversation")
        fetchRequest.propertiesToFetch = ["conversationID"]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        var conversationIDs: [[String: String]] = []
        do {
            conversationIDs = try managedObjectContext.executeFetchRequest(fetchRequest) as! [[String: String]]
        }
        catch {
            print(error)
        }
        for eachConversation in conversationIDs
        {
            for (key,_) in eachConversation{
                messageChangedEventHandle = FirebaseRef.msgRef?.child(key).observeEventType(.Value, withBlock: { (conversationSnapshot) in
                    self.didFirebaseMessageValueChange(conversationSnapshot, conversationID: key)
                })
            }
        }
        
    }
    
    func stopObservingMessageEvents() {
        guard
            let messageChangedEventHandle = messageChangedEventHandle
            else {
                return
        }
        FirebaseRef.msgRef?.removeObserverWithHandle(messageChangedEventHandle)
    }
    
    private func didFirebaseMessageValueChange(snapshot: FIRDataSnapshot, conversationID:String) {
        guard
            let snapshotValues = snapshot.value as? [String: AnyObject]
            else {
                return
        }
        
        let count = snapshotValues["count"] as? Int

        
        for index in 0..<count!{
            let key = "message\(index+1)"
            let message = snapshotValues[key] as? [String: AnyObject]
            
            // Check if the message exists
            let fetchRequest = NSFetchRequest(entityName: "Message")
            fetchRequest.predicate = NSPredicate(format: "conversation.conversationID = %@ AND sentDate = %@", conversationID, (message!["sentDate"] as? String)!)
            
            
            let fetchRequest2 = NSFetchRequest(entityName: "Conversation")
            fetchRequest2.predicate = NSPredicate(format: "conversationID = %@", conversationID)
            var result = 0
            var conversation : Conversation?
            do {
                result = ((try managedObjectContext.executeFetchRequest(fetchRequest) as? [Conversation])?.count)!
                conversation = (try managedObjectContext.executeFetchRequest(fetchRequest) as? [Conversation])?.first
            }
            catch {
                print(error)
            }
            
            if result <= 0 {
                var memberArray = conversation?.messages?.allObjects as! [Message]
                let msg = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: managedObjectContext) as! Message
                msg.type = message!["type"] as! Int
                if msg.type == MessageType.Image.rawValue {
                    let attachment = NSEntityDescription.insertNewObjectForEntityForName("Attachment", inManagedObjectContext: managedObjectContext) as! Attachment
                    
                    // Create img Path
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy_MM_ddHHmm"
                    let imgName = "\(dateFormatter.stringFromDate(NSDate())).png"
                    
                    let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                    let documentDirectory = documentPath[0]
                    let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent(imgName)
                    
                    if let data = snapshotValues["image"] as? NSData{
                        data.writeToURL(url, atomically: true)
                        print("Success save image to\n\(url)")
                    }
                    
                    
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    attachment.sentDate = dateFormatter.dateFromString(snapshotValues["sentDate"] as! String)
                    attachment.filePath = imgName
                    msg.attachements = NSSet(array: [attachment])
                }
                msg.senderID = snapshotValues["senderID"] as? String
                msg.shouldCover = snapshotValues["shouldCover"] as? Int
                
                memberArray.append(msg)
                
                
                conversation?.messages = NSSet(array: memberArray)
                
                // Save it
                do {
                    try self.managedObjectContext.save()
                }
                catch {
                    print(error)
                }
                

            }
        }
    }
    
}

