//
//  TaskFormViewController.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/13/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
//

import UIKit
import CoreData

class TaskFormViewController: UITableViewController, UINavigationControllerDelegate{

    
    weak var nameFieldCell: TextFieldCell!
    var completionTimeFieldCell: TimeFieldCell!
    weak var deadlineFieldCell: DateFieldCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            nameFieldCell = cell
            return cell
        }else if(indexPath.section == 1 ){
           let cell = tableView.dequeueReusableCellWithIdentifier("timeFieldCell") as! TimeFieldCell
            completionTimeFieldCell = cell
            return cell
        }else if(indexPath.section == 2){
            let cell = tableView.dequeueReusableCellWithIdentifier("dateFieldCell") as! DateFieldCell
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
            return "deadline"
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
            let nameField = nameFieldCell.nameField.text
            let completionTimeField = completionTimeFieldCell.timeField.countDownDuration
            let deadlineField = deadlineFieldCell.dateField.date
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: managedContext)
            let task = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
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



