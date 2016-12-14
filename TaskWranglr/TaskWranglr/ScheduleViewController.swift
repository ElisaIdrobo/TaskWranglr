//
// Name: Elisa Idrobo
// Course: CSC 415
// Semester: Fall 2016
// Instructor: Dr. Pulimood
// Project name: TaskWranglr
// Description: An app to plan when to work on various homework assignments based on the user's schedule.
// Filename:  ScheduleViewController.swift
// Description: View controller for the schedule view. Displays any task or calendar events on the user's schedule. It is in charge of running the scheduling algorithm.
// Last modified on: 12/14/16
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
    
    lazy var tasks: [String] = [String]()
    
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
        //create button programmically so that the EKCalendarChooser can be used
        let leftButton =  UIBarButtonItem(title: "calendars", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ScheduleViewController.chooseCalendar))
        navigationItem.leftBarButtonItem = leftButton
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        if status == EKAuthorizationStatus.Authorized{
            //if there is calendar access run the scheduler and connect the schedule it returns to the tableview
            initScheduler()
            
        }
        if status == EKAuthorizationStatus.Denied || status == EKAuthorizationStatus.Restricted{
            calendarDeniedMessage()//disable the schedule component of the app if no calendar access
        }
    }
    
    //----------------------------------------------------------------------------------------------------------------------------------
    //
    //  Function: viewDidAppear()
    //
    // Pre-condition: not called by user
    //
    // Post-condition: schedule view appeared and if a scheduler needs to be created do so, if there were tasks that could not
    // be scheduled notify the user
    //----------------------------------------------------------------------------------------------------------------------------------
    override func viewDidAppear(animated: Bool) {
        if tasks.count > 0{
            let alert = UIAlertController(title: "Task(s) could not scheduled", message: "\(tasks)", preferredStyle: .Alert)
            let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(OKAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        //this should only be called the first time the user enables calendars
        if(scheduler == nil && EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.Authorized){
            initScheduler()
        }
        
    }
    //----------------------------------------------------------------------------------------------------------------------------------
    //
    //  Function: initScheduler()
    //
    // Pre-condition: calendar authorization status is authorized and no scheduler currently exists
    //
    // Post-condition: the scheduler is set up and the tableview delegates are set to self
    //----------------------------------------------------------------------------------------------------------------------------------

    func initScheduler(){
        scheduler = Scheduler(eStore: eventStore, mContext: managedContext, frc: fetchedResultsController)
        scheduleDict = scheduler.getScheduleAsDictionary()
        //make ScheduleViewController an observer of nsnotificationcenter for when to update a schedule and when a task could not be scheduled
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ScheduleViewController.runSchedulingAlgorithm(_:)), name:"UpdateSchedule", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ScheduleViewController.taskUnscheduledMessage(_:)), name:"TasksNotSchedueled", object: nil)
        tableView.delegate = self
        tableView.dataSource = self
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
// Post-condition: opened the calendar chooser UI if calendar access is authorized. previously selected calendars are checked.
//----------------------------------------------------------------------------------------------------------------------------------
    func chooseCalendar() {
        let calendarVC = EKCalendarChooser(selectionStyle: .Multiple, displayStyle: .WritableCalendarsOnly, entityType: .Event, eventStore: eventStore)
        //fetch saved calendars and make them selected in the view
        var set:Set = Set<EKCalendar>()
        var calendars = [NSManagedObject]()
        let req = NSFetchRequest(entityName: "Calendar")
        do{
            calendars = try managedContext.executeFetchRequest(req) as! [NSManagedObject]
        }catch{
            print("could not fetch calendar to be deleted")
        }
        if calendars.count > 0 {
            for item in calendars{
                print(item)
                let id = item.valueForKey("eventStoreID") as! String
                let cal = eventStore.calendarWithIdentifier(id)
                set.insert(cal!)
            }
        }
        calendarVC.selectedCalendars = set//when multiple selections are allowed selectedCalendars must be initialized to a valid set
        calendarVC.showsDoneButton = true
        calendarVC.modalPresentationStyle = .Popover
        calendarVC.delegate = self
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        //if calendar access is authorized display calendar view
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
// Post-condition: updates which calendars taskwranglr will use in core data then closes the calendar view.
//----------------------------------------------------------------------------------------------------------------------------------
    func calendarChooserDidFinish(calendarChooser: EKCalendarChooser) {
        //update selected calendars in core data
        let newCalendars:NSMutableSet = NSMutableSet(set: calendarChooser.selectedCalendars)
        let currentCalendars: NSMutableSet = NSMutableSet()
        //create set of all EKCalendar objects whose IDs are stored in core data
        let req = NSFetchRequest(entityName: "Calendar")
        do{
            let currentCalendarsArr = try managedContext.executeFetchRequest(req) as! [NSManagedObject]
            for calMO in currentCalendarsArr{
                let calID = calMO.valueForKey("eventStoreID") as! String
                let cal = eventStore.calendarWithIdentifier(calID)
                currentCalendars.addObject(cal!)
            }
        }catch{
            print("could not fetch saved calendars")
        }
        //remove unchanged calendars from add/remove sets
        let sharedCalendars = NSMutableSet(set: currentCalendars)
        sharedCalendars.filterUsingPredicate(NSPredicate(format: "SELF in %@", newCalendars))
        currentCalendars.filterUsingPredicate(NSPredicate(format: "NOT SELF in %@", sharedCalendars))
        newCalendars.filterUsingPredicate(NSPredicate(format: "NOT SELF in %@", sharedCalendars))
        //add newly checked calendars to core data
        for addCal in newCalendars{
            //add to core data
            let entity = NSEntityDescription.entityForName("Calendar", inManagedObjectContext: managedContext)
            let c = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            c.setValue(addCal.calendarIdentifier, forKey: "eventStoreID")
            c.setValue(addCal.title, forKey: "title")
            
        }//remove newly unchecked calendars from core data
        for delCal in currentCalendars{
            let id = delCal.calendarIdentifier
            let req = NSFetchRequest(entityName: "Calendar")
            req.predicate = NSPredicate(format: "eventStoreID ==%@", id)
            do{
                let c = try managedContext.executeFetchRequest(req)
                managedContext.deleteObject(c.first as! NSManagedObject)
            }catch{
                print("could not fetch calendar to be deleted")
            }
        }//save changes
        do{
            try managedContext.save()
        }catch{
            print("could not update calendars in core data")
        }
        //close calendar view
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
        print("running scheduling algorithm")
        scheduleDict = scheduler.getScheduleAsDictionary()
        tableView.reloadData()
    }
    
    func taskUnscheduledMessage(notification: NSNotification){
        tasks = [String]()//clear it
        for task in (notification.object as! [NSManagedObject]){
            tasks.append(task.valueForKey("name") as! String)
        }
    }
    
}
