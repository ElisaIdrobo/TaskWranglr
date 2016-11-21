//
//  ShowTaskViewController.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/18/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
//

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
        print(subtasks)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3{
            return subtasks.count
        }
        return 1
    }
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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
