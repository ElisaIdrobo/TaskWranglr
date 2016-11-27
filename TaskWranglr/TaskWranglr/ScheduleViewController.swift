//
// Name: Elisa Idrobo
// Course: CSC 415
// Semester: Fall 2016
// Instructor: Dr. Pulimood
// Project name: TaskWranglr
// Description: An app to plan when to work on various homework assignments based on the user's schedule.
// Filename:  ScheduleViewController.swift
// Description: View controller for the schedule view. Displays any task or calendar events on the user's schedule. It is in charge of running the scheduling algorithm.
// Last modified on: 11/21/16
// Created by Elisa Idrobo on 11/13/16.
//

import UIKit
import EventKitUI
import CoreData

class ScheduleViewController: UIViewController, EKCalendarChooserDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    //eventStore needed to access any calendar data
    lazy var eventStore:EKEventStore = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.eventStore
    }()
    lazy var managedContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }()
    weak var taskCalendar: EKCalendar!
    var day = Day.Monday
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Task")
        let deadlineSort = NSSortDescriptor(key: "deadline", ascending: true)
        fetchRequest.sortDescriptors = [deadlineSort]
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "deadline", cacheName: nil)
        frc.delegate = self
        return frc
    }()
    lazy var formatter:NSDateFormatter = {
        let f = NSDateFormatter()
        f.dateFormat = "h:mma"
        return f
    }()
    var scheduleDict: [Day: [EKEvent]]!
    var scheduler:Scheduler!
    @IBOutlet weak var tableView: UITableView!
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function:  viewDidLoad()
//  
// Pre-condition: the view loaded
//
// Post-condition: if the user has not given access to their calendar the Schedule View and its accociated functionality(a schedule) is disabled
//----------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        print("did stuff")
        //create button programmically so that the EKCalendarChooser can be used
        let leftButton =  UIBarButtonItem(title: "calendars", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ScheduleViewController.chooseCalendar))
        navigationItem.leftBarButtonItem = leftButton
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        if status == EKAuthorizationStatus.Authorized{
            //if there is calendar access run the scheduler and connect the schedule it returns to the tableview
            scheduler = Scheduler(eStore: eventStore, mContext: managedContext, frc: fetchedResultsController)
            scheduleDict = scheduler.getScheduleAsDictionary()
            tableView.delegate = self
            tableView.dataSource = self
            //make ScheduleViewController an observer of nsnotificationcenter
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ScheduleViewController.runSchedulingAlgorithm(_:)), name:"UpdateSchedule", object: nil)
        }
        if status == EKAuthorizationStatus.Denied || status == EKAuthorizationStatus.Restricted{
            calendarDeniedMessage()//disable the schedule component of the app if no calendar access
        }
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
//  
// Pre-condition: this method is not called by the developer
//
// Post-condition: sets the labels of the table cells to the name and times of each task or calendar event
//----------------------------------------------------------------------------------------------------------------------------------
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        let event = scheduleDict[day]![indexPath.row]
        let time = "\(formatter.stringFromDate(event.startDate)) - \(formatter.stringFromDate(event.endDate))"
        cell.textLabel?.text = "\(event.title): \(time)"
        return cell
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    /*
     * unwind segue after a task is saved(new or updated). 
     */
    @IBAction func saveFromTask(unwindSegue: UIStoryboardSegue){
    }
    
    /*
     * unwind segue after updating/creating a task is cancelled.
     */
    @IBAction func cancelFromTask(unwindSegue: UIStoryboardSegue){
    }
    // MARK: - UITableViewDataSource
    /*
     * one section in the view's table
     */
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    /*
     *set the number of rows to the number of events for the currently selected day
     */
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleDict[day]!.count
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: dayChange(sender: UISegmentedControl)
//  
// Pre-condition: this method is called in response to the user selecting another day in the segmented control
//
// Post-condition: Updated the day being displayed
//----------------------------------------------------------------------------------------------------------------------------------
    @IBAction func dayChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            day = Day.Monday
        case 1:
            day = Day.Tuesday
        case 2:
            day = Day.Wednesday
        case 3:
            day = Day.Thursday
        case 4:
            day = Day.Friday
        case 5:
            day = Day.Saturday
        case 6:
            day = Day.Sunday
        default:
            print("other segment not implemented")
        }
        tableView.reloadData()
    }
    
    // MARK: -Calendar Events
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: chooseCalendar()
//  
// Pre-condition: called if user presses calendar button
//
// Post-condition: opened the calendar chooser UI if calendar access is authorized
//----------------------------------------------------------------------------------------------------------------------------------
    func chooseCalendar() {
        let calendarVC = EKCalendarChooser(selectionStyle: .Multiple, displayStyle: .AllCalendars, entityType: .Event, eventStore: eventStore)
        calendarVC.showsDoneButton = true
        calendarVC.modalPresentationStyle = .Popover
        calendarVC.delegate = self
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        if status == EKAuthorizationStatus.Authorized{
            self.navigationController?.pushViewController(calendarVC, animated:true)
        }
        else if status == EKAuthorizationStatus.Denied || status == EKAuthorizationStatus.Restricted{
            calendarDeniedMessage()
        }
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: calendarChooserDidFinish(calendarChooser: EKCalendarChooser)
//  
// Pre-condition: called after user selected the done button of the calendar chooser view
//
// Post-condition: closes the calendar view.  To-Do: save calendars they select
//----------------------------------------------------------------------------------------------------------------------------------
    func calendarChooserDidFinish(calendarChooser: EKCalendarChooser) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: calendarDeniedMessage()
//  
// Pre-condition: EKAuthorizationStatus == denied or restricted
//
// Post-condition:  displayed a popup to the user telling them that they calendar access denied
//----------------------------------------------------------------------------------------------------------------------------------
    func calendarDeniedMessage(){
        let alert = UIAlertController(title: "Oops", message: "TaskWranglr needs access to calendars to create a schedule. Calendars can be enabled in settings", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(OKAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: runSchedulingAlgorithm(notification: NSNotification)
//  
// Pre-condition: A task or event has been added or updated so the schedule must be updated as well
//
// Post-condition:  the scheduling algorithm was ran and the table reloaded
//----------------------------------------------------------------------------------------------------------------------------------    
    func runSchedulingAlgorithm(notification: NSNotification){
        scheduleDict = scheduler.getScheduleAsDictionary()
        tableView.reloadData()
    }
    
}
