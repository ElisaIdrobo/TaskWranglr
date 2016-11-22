//
// Name: Elisa Idrobo
// Course: CSC 415
// Semester: Fall 2016
// Instructor: Dr. Pulimood
// Project name: TaskWranglr
// Description: An app to plan when to work on various homework assignments based on the user's schedule.
// Filename: TaskListViewController.swift
// Description: view controller for the task list view. lists all tasks the user has created and allows the user to view task details of a selected task.
// Last modified on: 11/20/16
//  Created by Elisa Idrobo on 11/13/16.
//
import CoreData
import UIKit

class TaskListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    
    //when first needed create the FetchedResultsController that keeps the table updated with task data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Task")
        let deadlineSort = NSSortDescriptor(key: "deadline", ascending: true)
        fetchRequest.sortDescriptors = [deadlineSort]
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext =  appDelegate.managedObjectContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "deadline", cacheName: nil)
        frc.delegate = self
        return frc
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: -TableView methods
    
    /*
     * sets number of sections to the number of sections returned by the fetchedResultsController(aka 1)
     */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let count = fetchedResultsController.sections{
            return count.count
        }
        return 0
    }
    /*
     * set the number of rows to the number of saved tasks
     */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let sections = fetchedResultsController.sections{
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    /*
     *set the text in a cell to the name of the task
     */
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath){
        let task = fetchedResultsController.objectAtIndexPath(indexPath)
        if let name = task.valueForKey("name") as? String{
            cell.textLabel!.text = name
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    /*
     *do initial fetching of task data
     */
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        do{
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("failed to initialize fetchedResultsController: \(error)")
        }
    }
    
    // Mark: - fetchedResultsController methods
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath{
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Delete:
            if let indexPath = indexPath{
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Move:
            if let indexPath = indexPath{
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            if let newIndexPath = newIndexPath{
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
            break;
        case .Update:
            if let indexPath = indexPath{
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                configureCell(cell!, indexPath: indexPath)   
            }
            break;
        }
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Move: break;
        case .Update: break;
            
        }
    }

    // MARK: - Navigation


    /*
     * if the user has selected a task, the appropriate task/subsets are passed to the new ShowTaskViewController
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addTask" {
            print("adding task")
        }else if segue.identifier == "showTask" {
            //pass new showtaskviewcontroller the task the user selected
            let taskVC = segue.destinationViewController as! ShowTaskViewController
            if let selectedCell = sender as? UITableViewCell{
                if let task = fetchedResultsController.objectAtIndexPath(tableView.indexPathForCell(selectedCell)!) as? NSManagedObject{
                    taskVC.task = task
                    //pass subtasks of task
                    let subtasksSet = task.mutableOrderedSetValueForKey("subtask")
                    let subtasks = subtasksSet.array
                    taskVC.subtasks = subtasks as? [NSManagedObject]
                    
                    
                }
                
            }
        }
        
    }
    
    /*
     *placeholders for unwinding from the create task screen
     */
    @IBAction func saveFromTask(unwindSegue: UIStoryboardSegue){
        
    }
    @IBAction func cancelFromTask(unwindSegue: UIStoryboardSegue){
        
    }
    /*
     *delete task from persistant store if user dismisses it
     */
    @IBAction func dismissTask(unwindSegue: UIStoryboardSegue){
        let vc = unwindSegue.sourceViewController as? ShowTaskViewController
        let taskToDismiss = vc!.task
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext =  appDelegate.managedObjectContext
        managedContext.deleteObject(taskToDismiss)
        do{
            try managedContext.save()
        } catch let error as NSError{
            print("could not delete \(error), \(error.userInfo)")
        }
    }

}
