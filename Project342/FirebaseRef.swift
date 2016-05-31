//
//  FirebaseRef.swift
//  Project342
//
//  Created by Fagan Ooi on 31/05/2016.
//  Copyright © 2016 UOW. All rights reserved.
//

import Firebase


/// All the Firebase References
struct FirebaseRef {
    
    /** Points to the node that contains all the conversations */
    static var conversationsRef: FIRDatabaseReference? {
        return FIRDatabase.database().reference().child("conversations")
    }
    
    /** Points to the node that contains all the members of conversations */
    static var conversationMembersRef: FIRDatabaseReference? {
        return FIRDatabase.database().reference().child("conversationMembers")
    }
    
    /** Points to the node that contains all the messages of conversations */
    static var msgRef: FIRDatabaseReference? {
        return FIRDatabase.database().reference().child("messages")
    }
    
    /** Points to the node that contains the logged in user's conersations IDs */
    static var userContactsRef: FIRDatabaseReference? {
        guard
            let currentUser = FIRAuth.auth()?.currentUser
            else {
                print("No logged in user")
                return nil
        }
        
        let conversationIDs = conversationMembersRef?.child(currentUser.uid)
        return conversationIDs
    }
    
    /** Points to the node that stores all the searches */
    static var searchRef: FIRDatabaseReference? {
        return FIRDatabase.database().reference().child("search")
    }
    
    /** Points to the node where search request is to be made to ElasticSearch  */
    static var searchRequestRef: FIRDatabaseReference? {
        return searchRef?.child("request")
    }
    
    /** Points to the node where ElasticSearch returns the search response */
    static var searchResponseRef: FIRDatabaseReference? {
        return searchRef?.child("response")
    }
    
}

struct StorageRef {
    
    static var profilePicRef: FIRStorageReference {
        return FIRStorage.storage().reference().child("ProfilePic")
    }
    
}
