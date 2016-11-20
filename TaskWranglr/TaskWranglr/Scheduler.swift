//
//  Scheduler.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/19/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
//
//Scheduler should never be instantiated if calendar access is not authorized

import Foundation
import EventKit
import CoreData

class Scheduler{
    
    var eventStore: EKEventStore!
    var managedContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController!
    weak var taskCalendar: EKCalendar!
    init(eStore: EKEventStore, mContext: NSManagedObjectContext, frc:NSFetchedResultsController){
        eventStore = eStore
        managedContext = mContext
        fetchedResultsController = frc
        taskCalendar = eventStore.calendarWithIdentifier(NSUserDefaults.standardUserDefaults().stringForKey("TaskWranglrCalendar")!)!
    }
    
        
    //get events from the user's calendars
    func fetchCalendarEvents(calendars: [EKCalendar]) -> [EKEvent] {
        let currentDate = NSDate().toLocalTime()
        //let dateFormatter = NSDateFormatter()
        //dateFormatter.dateFormat = "EEEE, MMM dd, yyyy GGG"
        let sevenDaysDate = currentDate.addDays(6)
        let eventsPredicate = eventStore.predicateForEventsWithStartDate(currentDate, endDate: sevenDaysDate, calendars: calendars)
        let calEvents: [EKEvent] = eventStore.eventsMatchingPredicate(eventsPredicate)
        return calEvents
    }
    //make a EKEvent for a task event and store it in the calandar and link it to its corresponding task in the core data model
    func createTaskEvent(name:String, scheduledTime:NSDate, duration: NSTimeInterval, task:NSManagedObject){
        let taskEvent = EKEvent(eventStore: eventStore)
        taskEvent.calendar = taskCalendar
        taskEvent.title = name
        taskEvent.startDate = scheduledTime
        taskEvent.endDate = scheduledTime.dateByAddingTimeInterval(duration)
        do{
            try eventStore.saveEvent(taskEvent, span: .ThisEvent)
        }catch {
            print("task event could not save")
        }
        let taskEventId = taskEvent.eventIdentifier
        let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: managedContext)
        let taskEventEntity = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        taskEventEntity.setValue(taskEventId, forKey: "id")
        taskEventEntity.setValue(NSSet(object: task), forKey: "task")
        do{
            try managedContext.save()
            print("Success saving taskevent")
        }catch let error as NSError{
            print("could not save \(error), \(error.userInfo)")
        }
    }
    //scheduling algorithm
    func schedule()->[EKEvent]{
        //TO-DO: implement scheduling algorithm
        
        let cEvents = fetchCalendarEvents(eventStore.calendarsForEntityType(EKEntityType.Event)).sort(){
                (e1: EKEvent, e2: EKEvent) -> Bool in
                return e1.startDate.compare(e2.startDate) == NSComparisonResult.OrderedAscending
        }
        do{
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("failed to initialize fetchedResultsController: \(error)")
        }
        //do stuff
        let currentDate = NSDate()
        let ti = NSTimeInterval(604800)//seconds in 7 days = 60sec x 60min x24hours x 7days
        let sevenDaysDate = currentDate.dateByAddingTimeInterval(ti)
        let taskEventPredicate = eventStore.predicateForEventsWithStartDate(currentDate, endDate: sevenDaysDate, calendars: [taskCalendar])
        let tasks = eventStore.eventsMatchingPredicate(taskEventPredicate)
        var events = cEvents + tasks
        events.sortInPlace(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == NSComparisonResult.OrderedAscending
        }
        return events
    }
    func getScheduleAsDictionary()->[Day:[EKEvent]]{
        var scheduleDict:[Day:[EKEvent]] = [:]
        
        let events = schedule()
        scheduleDict[.Monday] = filterByDay(events, day: "Monday")
        scheduleDict[.Tuesday] = filterByDay(events, day: "Tuesday")
        scheduleDict[.Wednesday] = filterByDay(events, day: "Wednesday")
        scheduleDict[.Thuresday] = filterByDay(events, day: "Thuresday")
        scheduleDict[.Friday] = filterByDay(events, day: "Friday")
        scheduleDict[.Saturday] = filterByDay(events, day: "Saturday")
        scheduleDict[.Sunday] = filterByDay(events, day: "Sunday")
        return scheduleDict
    }
    func filterByDay(arr:[EKEvent], day:String)->[EKEvent]{
        return arr.filter({
            (e1: EKEvent) -> Bool in
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let dayString = dateFormatter.stringFromDate(e1.startDate)
            return dayString == day
        })

    }

}