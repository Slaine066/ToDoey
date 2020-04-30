import UIKit
import RealmSwift
import ChameleonFramework

class CategoryViewController: SwipeTableViewController {

    //MARK: - Global
    // Variables and Constants
    let realm = try! Realm()
    var categories: Results<Category>? // Results is an auto-updating container type in Realm returned from object queries.
    let coloursArray = ["#FFB9B3", "#FFD5B8", "#FFF9AA", "#ACECD5", "#7799CC", "#957DAD", "#E0BBE4"] 
    var arrayIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategories()
        tableView.rowHeight = 60
        if let numberOfCategories = categories?.count {
            arrayIndex = numberOfCategories
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) { // Re-set NavigationBar properties
        
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation Controller does not exist.") }
        
        navBar.backgroundColor = .white
        navBar.tintColor = ContrastColorOf(.white, returnFlat: true) // NavigationBar Buttons Colour
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(.white, returnFlat: true), NSAttributedString.Key.font : UIFont(name: "Papyrus", size: 30) ?? UIFont.systemFont(ofSize: 30)] // NavigationBar Title Colour
    }
    
    
    
    // MARK: - TableView DataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let category = categories?[indexPath.row] {
            cell.textLabel?.text = category.name
            
            guard let categoryColour = UIColor(hexString: category.colour) else { fatalError() }
            
            cell.backgroundColor = categoryColour
            cell.textLabel?.textColor = ContrastColorOf(categoryColour, returnFlat: true)
        }
        return cell
    }
    
    
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // Called just before the performSegue
        let destinationViewController = segue.destination as! ToDoListViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationViewController.selectedCategory = categories?[indexPath.row]
        }
    }
    
    
    
    //MARK: - Model Data Manipulation Methods
    func loadCategories() { // Load all the Realm Objects
        categories = realm.objects(Category.self) // Returns all objects of the given type stored in the Realm.
        tableView.reloadData() // Reloads the rows and sections of the table view.
    }
    
    func saveCategory(category: Category) { // Save the new Realm Object
        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
            print("Error while trying to save data into 'Realm (Category)': \(error)")
        }
        tableView.reloadData() // Re-build TableView
    }
    
    override func updateModel(at indexPath: IndexPath) {
        if let categoryToDelete = self.categories?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(categoryToDelete)
                }
            } catch {
                print("Error while trying to delete data from 'Realm (Category): \(error)")
            }
        }
        if let numberOfCategories = categories?.count {
            arrayIndex = numberOfCategories
        }
    }
    
    
    
    //MARK: - Actions
    // Add New Category
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New ToDoey Category", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Category", style: .default) { (action) in
            if textField.text != nil {
                let newCategory = Category() // Create a new Realm Object
                newCategory.name = textField.text!.capitalizingFirstLetter()
                //newCategory.colour = UIColor.randomFlat().hexValue()
                if self.arrayIndex < 7 {
                    newCategory.colour = self.coloursArray[self.arrayIndex]
                    self.arrayIndex += 1
                } else {
                    self.arrayIndex = 0
                    newCategory.colour = self.coloursArray[self.arrayIndex]
                    self.arrayIndex += 1
                }
                self.saveCategory(category: newCategory) // Save the new Realm Object
            }
        }
        alert.addAction(action)
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Insert Category"
            textField = alertTextField
        }
        present(alert, animated: true, completion: nil)
    }
}



//MARK: - Extension
//MARK: - Capitalize First Letter Methods
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
