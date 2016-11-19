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
    
    
    //values in fields
    var nameField: String! = ""
    var completionTimeField: NSTimeInterval = NSTimeInterval()
    var deadlineField: NSDate! = NSDate()
    
    //variables needed to save a task
    weak var managedContext: NSManagedObjectContext!
    weak var task: NSManagedObject!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        if task == nil {
            //create task(NSManagedObject to be stored by coredata) if a task has not been passed as a segue(to update a task)
            let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: managedContext)
            task = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
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
        return 3 //3 fields need to be inputed
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
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier("textFieldCell") as UITableViewCell!
            return cell
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 //each input field needs 1 cell
    }
    //define what input fields are
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "Name"
        }else if(section == 1 ){
            return "Time to complete"
        }else if(section == 2){
            return "Deadline"
        }else{
            return "default"
        }
    }
    
    // MARK: - Navigation

   
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if saveButton === sender{
          //save to core data
            nameField = nameFieldCell.nameField.text
            completionTimeField = completionTimeFieldCell.timeField.countDownDuration
            deadlineField = deadlineFieldCell.dateField.date

            task.setValue(nameField, forKey:"name")
            task.setValue(completionTimeField, forKey: "completionTime")
            task.setValue(deadlineField, forKey: "deadline")
            do{
                try managedContext.save()
                print("Success \(nameField)")
            }catch let error as NSError{
                print("could not save \(error), \(error.userInfo)")
            }
        }
        if (sender === cancelButton && !(task.valueForKey("name") != nil)){//only delete if doesn't exist
            managedContext.deleteObject(task)
        }
    }
    //MARK: -UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkValidNameEntered()
        textField.resignFirstResponder()
        return true
    }
    
    func checkValidNameEntered(){
        let entered = nameFieldCell.nameField.text ?? ""
        saveButton.enabled = !entered.isEmpty
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



