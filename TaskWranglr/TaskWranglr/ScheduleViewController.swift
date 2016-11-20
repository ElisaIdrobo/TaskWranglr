//
//  ScheduleViewController.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/13/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
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
    var scheduleDict: [Day: [EKEvent]]!
    var scheduler:Scheduler!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
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
        }
        if status == EKAuthorizationStatus.Denied || status == EKAuthorizationStatus.Restricted{
            calendarDeniedMessage()//disable the schedule component of the app if no calendar access
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = scheduleDict[day]![indexPath.row].title
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
    
    @IBAction func saveFromTask(unwindSegue: UIStoryboardSegue){
        scheduleDict = scheduler.getScheduleAsDictionary()
    }
    @IBAction func cancelFromTask(unwindSegue: UIStoryboardSegue){
    }
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleDict[day]!.count
    }
    @IBAction func dayChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            day = Day.Monday
        case 1:
            day = Day.Tuesday
        case 2:
            day = Day.Wednesday
        case 3:
            day = Day.Thuresday
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
    func calendarChooserDidFinish(calendarChooser: EKCalendarChooser) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    func calendarDeniedMessage(){
        let alert = UIAlertController(title: "Oops", message: "TaskWranglr needs access to calendars to create a schedule. Calendars can be enabled in settings", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(OKAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
