// Name: Elisa Idrobo
// Course: CSC 415
// Semester: Fall 2016
// Instructor: Dr. Pulimood
// Project name: TaskWranglr
// Description: An app to plan when to work on various homework assignments based on the user's schedule.
// Filename: ShowTaskViewController.swift
// Description: view controller for view that displays task data to user
// Last modified on: 11/20/16
// Created by Elisa Idrobo on 11/18/16.

import UIKit
import CoreData

class ShowTaskViewController: UITableViewController {

    //must be passed by previous view controller
    weak var task: NSManagedObject!
    var subtasks: [NSManagedObject]! = [NSManagedObject]()//subtasks should be passed by previous vc
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        if task == nil{
            fatalError("task was not passed to ShowTaskViewController")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /*
     * four sections: name, time to complete, deadline, subtasks
     */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    /*
     * sets rows to appropriate number
     */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3{
            return subtasks.count
        }
        return 1
    }
    /*
     * sets titles of sections to info they display
     */
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "Name"
        }else if(section == 1 ){
            return "Time to complete"
        }else if(section == 2){
            return "Deadline"
        }else if(section == 3){
                return "Subtasks"
        }else{
            return "default"
        }
    }

    /*
     * customizes label of cell based on type of data
     */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        let ct = task.valueForKey("completionTime") as? NSTimeInterval
        let minutes = Int((ct! / 60) % 60)
        let hours = Int(ct! / 3600)
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.FullStyle
        let deadline = formatter.stringFromDate((task.valueForKey("deadline") as? NSDate)!)
        switch indexPath.section {
            case 0:
                cell.textLabel?.text = task.valueForKey("name") as? String
            case 1:
                cell.textLabel?.text = "\(hours) Hours \(minutes) Minutes"
            case 2:
                cell.textLabel?.text = deadline
            case 3:
                cell.textLabel?.text = subtasks[indexPath.row].valueForKey("name") as? String
            default:
                cell.textLabel?.text = "oops"
        }

        return cell
    }
    
    //if dismiss button unwind and dismiss task(segue currently goes to tasklistviewcontroller)
    @IBAction func dismissTask(sender: UIButton) {
        performSegueWithIdentifier("dismissTask", sender: self)
    }
    
    // MARK: - Navigation

    /*
     * when user wants to update the displayed task the task/subtask data is passed to the new TaskFormViewController 
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editTask" {
            //pass the task the user selected to the new TaskFormViewController
            let taskVC = segue.destinationViewController as! TaskFormViewController
                    taskVC.task = task
            //pass subtasks of task
            let subtasksSet = task.mutableOrderedSetValueForKey("subtask")
            let subtasks = subtasksSet.array
            taskVC.subtasks = subtasks as? [NSManagedObject]
        }
    }
 

}
