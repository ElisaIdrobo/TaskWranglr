//
//  TaskFormViewController.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/13/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
//

import UIKit
import CoreData

class TaskFormViewController: UITableViewController, UINavigationControllerDelegate, UITextFieldDelegate{

    //field cells needed to access what user inputs
    weak var nameFieldCell: TextFieldCell!
    var completionTimeFieldCell: TimeFieldCell!
    weak var deadlineFieldCell: DateFieldCell!
    weak var subtaskCell: SubtaskCell!
    
    
    //values in fields
    var nameField: String! = ""
    var completionTimeField: NSTimeInterval = NSTimeInterval()
    var deadlineField: NSDate! = NSDate()
    
    var subtasks: [NSManagedObject]! = [NSManagedObject]()
    var newSubtasks = 0
    
    //variables needed to save a task
    weak var managedContext: NSManagedObjectContext!
    weak var task: NSManagedObject!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        if task == nil {
            saveButton.enabled = false//not allow save until name entered
        }else{
            //set fields to task's values
            nameField = task.valueForKey("name") as? String
            completionTimeField = (task.valueForKey("completionTime") as? NSTimeInterval)!
            deadlineField = task.valueForKey("deadline") as? NSDate
        }
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4 //4 fields need to be inputed
    }
    
    //link each cell to its cell type
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if(indexPath.section == 0){
            let cell = tableView.dequeueReusableCellWithIdentifier("textFieldCell") as! TextFieldCell
            cell.nameField.text = nameField
            nameFieldCell = cell
            nameFieldCell.nameField.delegate = self
            return cell
        }else if(indexPath.section == 1 ){
           let cell = tableView.dequeueReusableCellWithIdentifier("timeFieldCell") as! TimeFieldCell
            cell.timeField.countDownDuration = completionTimeField
            completionTimeFieldCell = cell
            return cell
        }else if(indexPath.section == 2){
            let cell = tableView.dequeueReusableCellWithIdentifier("dateFieldCell") as! DateFieldCell
            cell.dateField.date = deadlineField
            deadlineFieldCell = cell
            return cell
        }else if indexPath.section == 3{
            
            let cell = tableView.dequeueReusableCellWithIdentifier("subtaskCell") as! SubtaskCell
            subtaskCell = cell
            subtaskCell.nameField.delegate = self
            if indexPath.row < subtasks.count{
                subtaskCell.nameField.text = subtasks[indexPath.row].valueForKey("name") as? String
                subtaskCell.timeField.countDownDuration = (subtasks[indexPath.row].valueForKey("completionTime") as? NSTimeInterval)!
            }
            return cell
        
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier("textFieldCell") as UITableViewCell!
            return cell
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3{
            return subtasks.count + newSubtasks + 1
        }else{
            return 1 //each input field needs 1 cell
        }
    }
    //define what input fields are
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "Name"
        }else if(section == 1 ){
            return "Time to complete"
        }else if(section == 2){
            return "Deadline"
        }else if(section == 3){
            return "Subtasks"
        }
        else{
            return "default"
        }
    }
    
    // MARK: - Navigation

   
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if saveButton === sender{
          //save to core data
            save()
        }
 
    }
    /*
     * create objects accociated with ManagedObjectContext. If updating, update the fields of the task. If creating a new task create the NSManagedObject. DOES NOT COMMIT
     */
    func saveTask(){
        nameField = nameFieldCell.nameField.text
        completionTimeField = completionTimeFieldCell.timeField.countDownDuration
        deadlineField = deadlineFieldCell.dateField.date
        if task == nil{
            let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: managedContext)
            task = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        }
        task.setValue(nameField, forKey:"name")
        task.setValue(completionTimeField, forKey: "completionTime")
        task.setValue(deadlineField, forKey: "deadline")
    }
    /*
     * create objects accociated with ManagedObjectContext. If updating, update the fields of the subtask. If creating a new subtask create the NSManagedObject. DOES NOT COMMIT
     */
    func saveSubtasks(){
        let entity = NSEntityDescription.entityForName("SubTask", inManagedObjectContext: managedContext)
        
        for row in 0..<tableView.numberOfRowsInSection(3){
            let index = NSIndexPath(forItem: row, inSection: 3)
            let cell=tableView.cellForRowAtIndexPath(index) as? SubtaskCell
            let subtaskName = cell?.nameField.text
            let subtaskTimeToComplete = cell?.timeField.countDownDuration
            if subtaskName != ""{ //skip any empty cells
                if index.row >= subtasks.count{
                    //create what doesn't already exist
                    let subtask = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                    subtasks.insert(subtask, atIndex: index.row)
                    subtask.setValue(task, forKey: "subtask")
                }
                let subtask = subtasks[index.row]
                subtask.setValue(subtaskName, forKey: "name")
                subtask.setValue(subtaskTimeToComplete, forKey: "completionTime")
                task.setValue(NSOrderedSet(array: subtasks), forKey: "subtask")
            }
        }
        
    }
    //saves everything to core data
    func save(){
        saveTask()
        saveSubtasks()
        do{
            try managedContext.save()
            print("Successful saving of task/subtasks")
        }catch let error as NSError{
            print("could not save \(error), \(error.userInfo)")
        }
    }
    //MARK: -UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkValidNameEntered()
        textField.resignFirstResponder()
        return true
    }
    
    func checkValidNameEntered(){
        var entered = nameFieldCell.nameField.text ?? ""
        saveButton.enabled = !entered.isEmpty
        entered = subtaskCell.nameField.text ?? ""
        if !entered.isEmpty{
            addSubtask()
        }
        
    }
    
    func addSubtask() {
        newSubtasks += 1
        let index = NSIndexPath(forRow: tableView.numberOfRowsInSection(3), inSection: 3)
        tableView.insertRowsAtIndexPaths([index], withRowAnimation: .Fade)
        print("subtask added")
    }
    
}


//cell type classes. linked to prototype cells in storyboard
class TextFieldCell: UITableViewCell {
    @IBOutlet weak var nameField: UITextField!
}
class TimeFieldCell: UITableViewCell {
    @IBOutlet weak var timeField: UIDatePicker!
}
class DateFieldCell: UITableViewCell {
    @IBOutlet weak var dateField: UIDatePicker!

}
class SubtaskCell: UITableViewCell {
    @IBOutlet weak var timeField: UIDatePicker!
    @IBOutlet weak var nameField: UITextField!
}
class SubtaskAdderCell: UITableViewCell{
    @IBOutlet weak var addButton: UIButton!
}


