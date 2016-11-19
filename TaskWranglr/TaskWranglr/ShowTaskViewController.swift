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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
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
            default:
                cell.textLabel?.text = "oops"
        }

        return cell
    }
    
    //if dismiss button unwind and dismiss task
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
        }
    }
 

}
