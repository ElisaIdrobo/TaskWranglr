//
// Name: Elisa Idrobo
// Course: CSC 415
// Semester: Fall 2016
// Instructor: Dr. Pulimood
// Project name: TaskWranglr
// Description: An app to plan when to work on various homework assignments based on the user's schedule.
// Filename: TaskFormViewController.swift
// Description: view controller for the new task and update task screens. Allows the user to input data about a task
// Last modified on: 11/20/16
//  Created by Elisa Idrobo on 11/13/16.
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
    

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: viewDidLoad()
//  
// Pre-condition: called when the view loaded
//
// Post-condition: if the user is updating, populated the input fields with the saved task data 
//----------------------------------------------------------------------------------------------------------------------------------
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

// 4 sections: name, time needed to complete, deadline, subtasks
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4 //4 fields need to be inputed
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
//  
// Pre-condition: not called by developer
//
// Post-condition: linked each cell to its cell type
//----------------------------------------------------------------------------------------------------------------------------------
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

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: tableView(tableView: UITableView, numberOfRowsInSection section: Int)
//  
// Pre-condition: not called by developer
//
// Post-condition: set number of rows to one on all input fields unless it is the subtasks section. In that case number of rows is
// now equal to the number of subtasks +1
//----------------------------------------------------------------------------------------------------------------------------------
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3{
            return subtasks.count + newSubtasks + 1
        }else{
            return 1 //each input field needs 1 cell
        }
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: tableView(tableView: UITableView, titleForHeaderInSection section: Int)
//  
// Pre-condition: not called by developer
//
// Post-condition: labeled each of the input fields
//----------------------------------------------------------------------------------------------------------------------------------
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
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
//  
// Pre-condition: not called by developer. called when the view is about to close.
//
// Post-condition: if the save button triggered this function, the task was saved/updated
//----------------------------------------------------------------------------------------------------------------------------------
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if saveButton === sender{
          //save to core data
            save()
        }
 
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: saveTask()
//  
// Pre-condition: the task has been given a name by the user
//
// Post-condition: created objects accociated with ManagedObjectContext. If updating, updated the fields of the task. If creating
// a new task created the NSManagedObject. DOES NOT COMMIT
//----------------------------------------------------------------------------------------------------------------------------------
    func saveTask(){
        //if task completion time is smaller than the total amount inputed for subtasks update completion time to the real total time
        var subtaskTotalDuration = NSTimeInterval()
        for row in 0..<tableView.numberOfRowsInSection(3){
            let index = NSIndexPath(forItem: row, inSection: 3)
            let cell=tableView.cellForRowAtIndexPath(index) as? SubtaskCell
            let subtaskName = cell?.nameField.text
            if subtaskName != ""{
                let subtaskTimeToComplete = cell?.timeField.countDownDuration
                subtaskTotalDuration += subtaskTimeToComplete!
            }
        }
        completionTimeField = completionTimeFieldCell.timeField.countDownDuration
        if completionTimeField < subtaskTotalDuration{
            completionTimeField = subtaskTotalDuration
        }
        nameField = nameFieldCell.nameField.text
        deadlineField = deadlineFieldCell.dateField.date
        if task == nil{
            let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: managedContext)
            task = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        }
        task.setValue(nameField, forKey:"name")
        task.setValue(completionTimeField, forKey: "completionTime")
        task.setValue(deadlineField, forKey: "deadline")
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: saveSubtask()
//  
// Pre-condition: the task has been given a name by the user
//
// Post-condition: created objects accociated with ManagedObjectContext. If updating, updated the fields of the subtask. If 
// creating a new subtask created the NSManagedObject. DOES NOT COMMIT
//----------------------------------------------------------------------------------------------------------------------------------
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

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: save()
//  
// Pre-condition: the task/subtask has a name
//
// Post-condition: the task and its subtasks are saved to core data
//----------------------------------------------------------------------------------------------------------------------------------
    func save(){
        saveTask()
        saveSubtasks()
        do{
            try managedContext.save()
            print("Successful saving of task/subtasks")
            //let scheduleViewController know that schedule needs to be updated
            NSNotificationCenter.defaultCenter().postNotificationName("UpdateSchedule", object: nil)
        }catch let error as NSError{
            print("could not save \(error), \(error.userInfo)")
        }
    }
    //MARK: -UITextFieldDelegate
    

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: textFieldShouldReturn(textField: UITextField)
//
// Parameters: UITextField; the textfield for the name of the task or subtasks(this class was made their delegate)
//
// Pre-condition: user pressed enter
//
// Post-condition: deselected textfields 
//----------------------------------------------------------------------------------------------------------------------------------
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkValidNameEntered()
        textField.resignFirstResponder()
        return true
    }
    
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: checkValidNameEntered()
//
// Pre-condition: user pressed enter
//
// Post-condition: If the name field is non-empty the user is allowed to save, or added new subtask row if subtask name is non-empty
//----------------------------------------------------------------------------------------------------------------------------------
    func checkValidNameEntered(){
        var entered = nameFieldCell.nameField.text ?? ""
        saveButton.enabled = !entered.isEmpty
        entered = subtaskCell.nameField.text ?? ""
        if !entered.isEmpty{
            addSubtask()
        }
        
    }

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: addSubtask()
//
// Pre-condition: the previous subtask has been given a name
//
// Post-condition: added a subtask row
//----------------------------------------------------------------------------------------------------------------------------------
    func addSubtask() {
        newSubtasks += 1
        let index = NSIndexPath(forRow: tableView.numberOfRowsInSection(3), inSection: 3)
        tableView.insertRowsAtIndexPaths([index], withRowAnimation: .Fade)
        print("subtask added")
    }
    
}


//----------------------------------------------------------------------------------------------------------------------------------
//
// cell type classes. linked to prototype cells in storyboard
//----------------------------------------------------------------------------------------------------------------------------------
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


