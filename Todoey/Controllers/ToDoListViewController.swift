import UIKit
import RealmSwift
import ChameleonFramework

class ToDoListViewController: SwipeTableViewController {
    
    //MARK: - Global
    // Variables and Constants
    let realm = try! Realm()
    var items: Results<Item>?
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    // Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let hexColour = selectedCategory?.colour {
            
            guard let navBar = navigationController?.navigationBar else { fatalError("Navigation Controller does not exist.") }
            
            if let navBarColour = UIColor(hexString: hexColour) {
                navBar.backgroundColor = navBarColour // NavigationBar Background Colour
                navBar.tintColor = ContrastColorOf(navBarColour, returnFlat: true) // NavigationBar Buttons Colour
                navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColour, returnFlat: true), NSAttributedString.Key.font : UIFont(name: "Papyrus", size: 30) ?? UIFont.systemFont(ofSize: 30)] // NavigationBar Title Colour
                searchBar.barTintColor = navBarColour // SearchBar Colour
            }
            title = selectedCategory!.name // Set the title to a human-readable string that describes the view. If the view controller has a valid navigation item or tab-bar item, assigning a value to this property updates the title text of those objects.
        }
    }
    
    
    
    //MARK: - TableView DataSource Methods
    // Return the number of rows for the table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 1
    }
    
    // Provide a cell object for each row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = items?[indexPath.row] {
            cell.textLabel?.text = item.title
            
            if let colour = UIColor(hexString: selectedCategory!.colour)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(items!.count) ) { // Safe to force unwrap because this would't be called if it was nil
                cell.backgroundColor = colour
                cell.textLabel?.textColor = ContrastColorOf(colour, returnFlat: true)
            }
            cell.accessoryType = item.done == true ? .checkmark : .none // Ternary operator, if the condition is true set accessory type to .checkmark, if not set to .none
        } else {
            cell.textLabel?.text = "No Items Found"
        }
        return cell
    }
    
    
    
    //MARK: - TableView Delegate Methods
    // Tells the delegate that the specified row is now selected.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = items?[indexPath.row] {
            do {
                try realm.write {
                    item.done = !item.done
                }
            } catch {
                print("Error while trying to save data into 'Realm (Item)': \(error)")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
    
    
    
    //MARK: - Model Data Manipulation Methods
    func loadItems() {
        items = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData() // Re-build TableView
    }
    
    override func updateModel(at indexPath: IndexPath) {
        
        if let itemToDelete = self.items?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(itemToDelete)
                }
            } catch {
                print("Error while trying to delete data from 'Realm (Item): \(error)")
            }
        }
    }
    
    
    
    //MARK: - Actions
    // Add New Item
    @IBAction func addPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New ToDoey Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            if textField.text != nil {
                
                if let currentCategory = self.selectedCategory {
                    do {
                        try self.realm.write { // Save the new Realm Object
                            let newItem = Item() // Create a new Realm Object
                            newItem.title = textField.text!.capitalizingFirstLetter()
                            newItem.dateCreated = Date()
                            currentCategory.items.append(newItem)
                        }
                    } catch {
                        print("Error while trying to save data into 'Realm (Item)': \(error)")
                    }
                }
                self.tableView.reloadData() // Re-build TableView
            }
        }
        alert.addAction(action)
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Insert Item"
            textField = alertTextField
        }
        present(alert, animated: true, completion: nil)
    }
}



//MARK: - Extension
//MARK: - SearchBarDelegate Methods
extension ToDoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else {
            items = items?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
            tableView.reloadData()
        }
    }
}
