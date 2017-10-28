//
//  ChatRoomViewController.swift
//  SimpleChat
//
//  Created by Eugene Mekhedov on 28.10.2017.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseStorage
import Photos

class ChatRoomViewController: JSQMessagesViewController {

    var currentMyUser : EMUser!
    private var messages = [Message]()
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()

    var messagesRef = Database.database().reference().child("messages")
    private var newMessageRefHandle: DatabaseHandle?
    private var photoMessageMap = [String: JSQPhotoMediaItem]()

    private lazy var userIsTypingRef: DatabaseReference = Database.database().reference().child("typingIndicator").child(self.senderId)
    private var localTyping = false
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    private lazy var usersTypingQuery: DatabaseQuery = Database.database().reference().child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    private var updatedMessageRefHandle: DatabaseHandle?
    private var messageToDetailUserVC : Message!
    
    lazy var storageRef = Storage.storage().reference(forURL: "gs://simplechat-45e63.appspot.com/")
    private let imageURLNotSetKey = "NOTSET"

    //MARK: Life cicle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.senderId = Auth.auth().currentUser?.uid
        self.senderDisplayName = Auth.auth().currentUser?.displayName
        observeMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
    }
    
    deinit {
        if let refHandle = newMessageRefHandle {
            messagesRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messagesRef.removeObserver(withHandle: refHandle)
        }
    }

    // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        let data : Data!
        let image : UIImage
        
        if let imageURL = message.imageURL{
            guard message.imageURL?.absoluteString != "https://scontent.xx.fbcdn.net/v/t1.0-1/s100x100/10354686_10150004552801856_220367501106153455_n.jpg?oh=80d060a30bceadf69840724b4c2a3a14&oe=5A7AB573" else{
                image = UIImage(named: "user")!
                return JSQMessagesAvatarImageFactory.avatarImage(with:image, diameter: 30)
            }
            do {
                data = try Data(contentsOf: imageURL )
                image = UIImage(data: data as Data)!
            } catch{
                print(error.localizedDescription)
                image = UIImage(named: "user")!
            }
        }else{
            image = UIImage(named: "user")!
        }
        return JSQMessagesAvatarImageFactory.avatarImage(with:image, diameter: 30)

    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        messageToDetailUserVC = messages[indexPath.item]
        self.performSegue(withIdentifier: "userDetail", sender: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    //MARK: Firebase related methods
    
    
    private func observeMessages() {
        let messageQuery = messagesRef.queryLimited(toLast:500)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, Any>
            let sender = messageData["sender"] as! Dictionary<String, String>
            let text = messageData["text"]
            if let text = messageData["text"] as! String!, text.characters.count > 0{
            self.addMessage(withId: sender["senderID"]!, name: sender["fullName"]!, text: text as! String, imageURL: sender["imageURL"]!, city: sender["currentCity"], birthday: sender["birthday"], largeImageURL: sender["largeImageURL"], facebookID: sender["facebookID"])
                self.finishReceivingMessage()
            }else if let id = messageData["senderId"] as! String!,
                let photoURL = messageData["photoURL"] as! String! { // 1
                    // 2
                    if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                        // 3
                        self.addPhotoMessage(withId: id, name: sender["fullName"]!, text: "", imageURL: sender["imageURL"]!, city: sender["currentCity"], birthday: sender["birthday"], largeImageURL: sender["largeImageURL"], facebookID: sender["facebookID"], key: snapshot.key, mediaItem: mediaItem)
                        // 4
                        if photoURL.hasPrefix("gs://") {
                            self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                        }
                    }
                }
        })
        
                updatedMessageRefHandle = messagesRef.observe(.childChanged, with: { (snapshot) in
                    let key = snapshot.key
                    let messageData = snapshot.value as! Dictionary<String, Any> // 1
                    
                    if let photoURL = messageData["photoURL"] as! String? { // 2
                        // The photo has been updated.
                        if let mediaItem = self.photoMessageMap[key] { // 3
                            self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                        }
                    }
                })
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messagesRef.childByAutoId() // 1
        let messageItem : [String : Any] = [ // 2
            "text": text!,
            "sender" : self.currentMyUser.propertyListRepresentation
        ]
        
        itemRef.setValue(messageItem) // 3
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
        
        isTyping = false
    }
    
    private func observeTyping() {
        let typingIndicatorRef = Database.database().reference().child("typingIndicator")
        let userIsTypingRef = typingIndicatorRef.child(self.senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        usersTypingQuery.observe(.value) { (data: DataSnapshot) in
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
    func sendPhotoMessage() -> String? {
        let itemRef = messagesRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            "sender" : self.currentMyUser.propertyListRepresentation
            ] as [String : Any]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messagesRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }

    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = Storage.storage().reference(forURL: photoURL)
        
        // 2

        storageRef.getData(maxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.getMetadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4
                if (metadata?.contentType == "image/gif") {
                    mediaItem.image = UIImage.gifWithData(data!)
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    // MARK: UI and User Interaction
    private func addMessage(withId id: String, name: String, text: String, imageURL: String?, city: String?, birthday: String?, largeImageURL: String?, facebookID: String?) {
        if let message = Message(senderId: id,
                                 displayName: name,
                                 text: text,
                                 imageURL: URL(string: imageURL ?? ""),
                                 city: city,
                                 birthday: birthday,
                                 largeImageURL: URL(string: largeImageURL ?? ""),
                                 facebookID : facebookID) {
            messages.append(message)
        }
    }
    
    private func addPhotoMessage(withId id: String, name: String, text: String?, imageURL: String?, city: String?, birthday: String?, largeImageURL: String?, facebookID: String?, key: String, mediaItem: JSQPhotoMediaItem ) {
        if let message = JSQMessage(senderId: id, displayName: name, media: mediaItem) {
            let myMessage = Message(with: message,
                                    imageURL: URL(string: imageURL ?? ""),
                                    city: city,
                                    birthday: birthday,
                                    largeImageURL:URL.init(string: largeImageURL ?? ""),
                                    facebookID: facebookID)
            messages.append(myMessage!)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        } else {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        
        present(picker, animated: true, completion:nil)
    }
    
    // MARK: UITextViewDelegate methods
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }

    //MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LogoutVC"{
            let vc = segue.destination as! LogoutViewController
            vc.prevVC = self
        }
        if segue.identifier == "userDetail"{
            let vc = segue.destination as! UserDetailViewController
            vc.message = messageToDetailUserVC
        }
    }
}

// MARK: Image Picker Delegate
extension ChatRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        // 1
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            // 2
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            // 3
            if let key = sendPhotoMessage() {
                // 4
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                    
                    // 5
                    
                    let path = "\(String(describing: Auth.auth().currentUser?.uid))/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    // 6
                    self.storageRef.child(path).putFile(from: imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        // 7
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // 1
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // 2
            if let key = sendPhotoMessage() {
                // 3
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                // 4
                let imagePath = (Auth.auth().currentUser?.uid)! + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                // 5
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                // 6
                storageRef.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    // 7
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
