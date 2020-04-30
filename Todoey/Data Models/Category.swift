import Foundation
import RealmSwift

class Category: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var colour: String = ""
    let items = List<Item>() // Forward Relationship // List is the container type in Realm used to define to-many relationships.
}
