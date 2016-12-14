// Name: Elisa Idrobo
// Course: CSC 415
// Semester: Fall 2016
// Instructor: Dr. Pulimood
// Project name: TaskWranglr
// Description: An app to plan when to work on various homework assignments based on the user's schedule.
// Filename: Scheduler.swift
// Description: Runs the scheduling algorithm. Scheduler should never be instantiated if calendar access is not authorized
// Last modified on: 12/14/16
// Created by Elisa Idrobo on 11/19/16.

import Foundation
import EventKit
import CoreData

class Scheduler{
    
    var eventStore: EKEventStore!
    var managedContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController!
    weak var taskCalendar: EKCalendar!
    var tempSchedule: [Day: CalendarDay] = [Day:CalendarDay]()
    var taskEvents:[EKEvent] = [EKEvent]()
    var tasksNotFullyScheduled:[NSManagedObject] = [NSManagedObject]()
    init(eStore: EKEventStore, mContext: NSManagedObjectContext, frc:NSFetchedResultsController){
        eventStore = eStore
        managedContext = mContext
        fetchedResultsController = frc // should have a fetch request specifying all tasks in order of soonest deadline
        //even though not currently saving to calendar, it is still needed to create EKEvents
        taskCalendar = eventStore.calendarWithIdentifier(NSUserDefaults.standardUserDefaults().stringForKey("TaskWranglrCalendar")!)!
        
    }

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: getScheduleAsDictionary()
//   
// Pre-condition: the schedule object has been initialized
//
// Post-condition: returns a dictionary of days of the week and their scheduled events. Events include calendar and task events that
//ensure that tasks will be completed by their due date. All have no overlap with other events. Events are saved to calendar
// Exceptions: an event is past its deadline, not enough time to schedule between 9am and 11:59 pm
//----------------------------------------------------------------------------------------------------------------------------------
    func getScheduleAsDictionary()->[Day:[EKEvent]]{
        var scheduleDict:[Day:[EKEvent]] = [:]
        //first empty current TaskWranglr calendar
        let currentDate = NSDate().addDays(-7)
        let sevenDaysDate = currentDate.addDays(14)
        let eventsPredicate = eventStore.predicateForEventsWithStartDate(currentDate, endDate: sevenDaysDate, calendars: [taskCalendar])
        for task in eventStore.eventsMatchingPredicate(eventsPredicate){
            do{
                try eventStore.removeEvent(task, span: EKSpan.ThisEvent, commit: false)
                
            }catch{
                print("task event could not be removed: \(task.title)")
            }
        }
        do{
            try eventStore.commit()
        }catch {
            print("task events could not be removed from taskwranglr calendar")
        }
        //create schedule
        let events = schedule()
        scheduleDict[.Monday] = filterByDay(events, day: "Monday")
        scheduleDict[.Tuesday] = filterByDay(events, day: "Tuesday")
        scheduleDict[.Wednesday] = filterByDay(events, day: "Wednesday")
        scheduleDict[.Thursday] = filterByDay(events, day: "Thursday")
        scheduleDict[.Friday] = filterByDay(events, day: "Friday")
        scheduleDict[.Saturday] = filterByDay(events, day: "Saturday")
        scheduleDict[.Sunday] = filterByDay(events, day: "Sunday")
        //save to calendar
        do{
            try eventStore.commit()
        }catch {
            print("task events could not be saved to taskwranglr calendar")
        }
        if(tasksNotFullyScheduled.count > 0){
            NSNotificationCenter.defaultCenter().postNotificationName("TasksNotSchedueled", object: tasksNotFullyScheduled)
        }
        return scheduleDict
    }
    
    
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: schedule()
//   
// Pre-condition: the schedule object has been initialized
//
// Post-condition: returns an array of calendar and task events that they ensure that tasks will be completed by their due date.
// All have no overlap with other events.
// Exceptions: an event is past its deadline(no events are created), not enough time to schedule between 9am and 11:59 pm(the task is partially scheduled)
//----------------------------------------------------------------------------------------------------------------------------------
    private func schedule()->[EKEvent]{
        
        //Initialize
        //----------------------------------------------------------------------------------------------------------------------------------
        
        //get calendar events ordered by what comes first
        var calendars = [EKCalendar]()
        //get EKCalendars corresponding to the calendarIDs saved in core data
        let req = NSFetchRequest(entityName: "Calendar")
        do{
            let calendarIDs = try managedContext.executeFetchRequest(req)
            for c in calendarIDs{
                let cal = eventStore.calendarWithIdentifier(c.valueForKey("eventStoreID") as! String)
                calendars.append(cal!)
            }
        }catch{
            print("calendars could not be fetched from core data")
        }

        let cEvents = fetchCalendarEvents(calendars).sort(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == NSComparisonResult.OrderedAscending
        }
        //get tasks from core data
        do{
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("failed to initialize fetchedResultsController: \(error)")
        }
        let tasks:[NSManagedObject] = (fetchedResultsController.fetchedObjects as? [NSManagedObject])!
        
        //clear taskEvents array
        taskEvents = [EKEvent]()//reinit empty task events array
        tasksNotFullyScheduled = [NSManagedObject]()
        
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE"
        let rawDay = formatter.stringFromDate(NSDate())
        let today = Day(rawValue: rawDay)
        
        //create a dictionary of days containing the segments of available time
        tempSchedule = [Day: CalendarDay]()
        tempSchedule[.Monday] = initTempDay(filterByDay(cEvents, day: "Monday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Monday, currentDay: today!))))
        tempSchedule[.Tuesday] = initTempDay(filterByDay(cEvents, day: "Tuesday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Tuesday, currentDay: today!))))
        tempSchedule[.Wednesday] = initTempDay(filterByDay(cEvents, day: "Wednesday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Wednesday, currentDay: today!))))
        tempSchedule[.Thursday] = initTempDay(filterByDay(cEvents, day: "Thursday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Thursday, currentDay: today!))))
        tempSchedule[.Friday] = initTempDay(filterByDay(cEvents, day: "Friday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Friday, currentDay: today!))))
        tempSchedule[.Saturday] = initTempDay(filterByDay(cEvents, day: "Saturday"),dayOfWeek:  NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Saturday, currentDay: today!))))
        tempSchedule[.Sunday] = initTempDay(filterByDay(cEvents, day: "Sunday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Sunday, currentDay: today!))))
        //----------------------------------------------------------------------------------------------------------------------------------
        //Main Algorithm
        
        //print("INIT: \(tempSchedule)")
        
        //for each task schedule it
        for t in tasks{

            
            //track edge cases
            var willCreateEvents = true
            var willFinishCreatingEvents = true
            
            let name = t.valueForKey("name") as? String
            var taskDuration = t.valueForKey("CompletionTime") as? NSTimeInterval
            
          
            
            // 1. find how many days the task will be assigned to
            // if deadline has passed set do not create events for it
            var numDaysToWorkOn = daysTillDeadline((t.valueForKey("deadline") as? NSDate)!)
            if numDaysToWorkOn <= 0{
                willCreateEvents = false
                print("deadline of task:\(name) passed")
            }
            //if deadline is in > 1 week for the purpose of scheduling change the number of days to work on to 7 and set the duration to the sum of available hours(avoid adding any hours to a day)
            if numDaysToWorkOn > 7 {
                numDaysToWorkOn = 7
                var newDuration = 0.0
                for (_,calDay) in tempSchedule{
                    newDuration += calDay.availableHours
                }
                if newDuration < taskDuration{
                    taskDuration = newDuration
                }
            }
            
            var dayOrder = [Day]()
            var durations = [NSTimeInterval]()
            // 2. find how long user will work on task each day
            // if durations is not valid-add available hours and re-run until valid durations are found or it is impossible
            if willCreateEvents {
                dayOrder = dayOrderSubarray(numDaysToWorkOn, today: today!)
                durations = durationPerDayAssigned(numDaysToWorkOn, days: dayOrder, taskDuration: taskDuration!)
                //if empty
                while durations.count == 0 && willFinishCreatingEvents{
                    //check if possible aka there is enough available time
                    var time = 0.0//total available time from all days
                    for day in dayOrder{
                        time += tempSchedule[day]!.totalAvailableTimeDuration()
                    }
                    if time < taskDuration{ //scheduling not possible
                        willFinishCreatingEvents = false
                        for i in 0..<dayOrder.count{
                            let dur = tempSchedule[dayOrder[i]]!.totalAvailableTimeDuration()
                            durations.append(dur)
                        }
                    }else{
                        //add 1 hour to available hours and rerun
                        for i in 0..<dayOrder.count{
                            time = tempSchedule[dayOrder[i]]!.totalAvailableTimeDuration()
                            if time > (3600 + tempSchedule[dayOrder[i]]!.availableHours){
                                tempSchedule[dayOrder[i]]!.availableHours += 3600
                            }else{
                                tempSchedule[dayOrder[i]]!.availableHours = time
                            }
                        }
                        durations = durationPerDayAssigned(numDaysToWorkOn, days: dayOrder, taskDuration: taskDuration!)
                    }
                }
            }

            // 3. now that durations are correct,assign them to times in their corresponding days(this method creates EKEvent for each task segment)
            if willCreateEvents{
                for i in 0..<dayOrder.count{
                    timeSegsToAssign(dayOrder[i], duration: durations[i], task: t)
                }
            }
            // 4. handle errors
            if !willCreateEvents || !willFinishCreatingEvents{
                tasksNotFullyScheduled.append(t)
                print("Task: \(name) is either past its deadline or cannot be finished before its deadline either because it is impossible or because sleep would be lost. willCreateEvents: \(willCreateEvents)")
            }
        }
        
        //------------------------------------------------------------------------------------------------------------------------------------
        //combine generated events with calendar events and return
        var events = cEvents + taskEvents
        events.sortInPlace(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == NSComparisonResult.OrderedAscending
        }
        return events
    }

   
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: fetchCalendarEvents(calendars: [EKCalendar])
//
// Parameters:
//      input [EKCalendar]; an array of all calendars that the scheduling algorithm will use(calendar selection by the user is unimplemented)
//   
// Pre-condition: the eventStore object exists
//
// Post-condition: Returns an array of calendar events that happen over the next 7 days including the current day. if calendars is 
// empty an empty array is returned
//----------------------------------------------------------------------------------------------------------------------------------
    private func fetchCalendarEvents(calendars: [EKCalendar]) -> [EKEvent] {
        if calendars.isEmpty{
            return [EKEvent]()
        }
        let currentDate = NSDate().toLocalTime()
        let sevenDaysDate = currentDate.addDays(6)
        let eventsPredicate = eventStore.predicateForEventsWithStartDate(currentDate, endDate: sevenDaysDate, calendars: calendars)
        let calEvents: [EKEvent] = eventStore.eventsMatchingPredicate(eventsPredicate)
        return calEvents
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: initTempDay(eventsOnDay: [EKEvent], dayOfWeek: NSDate)
//
// Parameters:
//      input [EKEvent]; an array of all calendar events for the day of the week given
//      input NSDate; the day of the week to be initalized
//   
// Pre-condition: the eventsOnDay is sorted by what comes earlier
//
// Post-condition: Returns a CalendarDay object which assumes that no more than 12 hours a day can be scheduled
//----------------------------------------------------------------------------------------------------------------------------------
    private func initTempDay(eventsOnDay: [EKEvent], dayOfWeek: NSDate) -> CalendarDay {
        //edgecases
        if( eventsOnDay.count) == 0{
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Month, .Day,.Year], fromDate: dayOfWeek)
            components.hour = 9
            components.minute = 0
            components.second = 0
            let startDate = calendar.dateFromComponents(components)
            components.hour = 23
            components.minute = 59
            components.second = 0
            let endDate = calendar.dateFromComponents(components)
            return CalendarDay(availableHours: NSTimeInterval(3600*12), shortestSeg: NSTimeInterval(3600*12), availableTime: [TimeSeg(startTime: startDate! ,endTime: endDate!)], calendarScheduledHours: 0.0)
        }else if(eventsOnDay.count == 1){
            let calendar = NSCalendar.currentCalendar()
            let event = eventsOnDay[0]
            let components = calendar.components([.Month, .Day,.Year], fromDate: event.startDate)
            components.hour = 9
            components.minute = 0
            components.second = 0
            let startDate = calendar.dateFromComponents(components)
            components.hour = 23
            components.minute = 59
            components.second = 0
            let endDate = calendar.dateFromComponents(components)
            
            let timeSegOne = TimeSeg(startTime: startDate!, endTime: event.startDate)
            var shortestSeg = timeSegOne.duration()
            let timeSegTwo = TimeSeg(startTime: event.endDate, endTime: endDate!)
            let timeSegTwoDuration = timeSegTwo.duration()
            if timeSegTwoDuration < shortestSeg{
                shortestSeg = timeSegTwoDuration
            }
            let eventDuration = event.endDate.timeIntervalSinceDate(event.startDate)
            var availableHours = NSTimeInterval(3600 * 12 - eventDuration)
            if availableHours < 0{
                availableHours = 0
            }
            var availableTime = [TimeSeg]()
            var checkEventDuration = timeSegOne.duration()
            if checkEventDuration > 1800{ //remove available time if less than half an hour
                availableTime.append(timeSegOne)
            }else{
                shortestSeg = timeSegTwo.duration()
            }
            checkEventDuration = timeSegTwo.duration()
            if checkEventDuration > 1800{ //remove available time if less than half an hour
                availableTime.append(timeSegTwo)
            }else{
                shortestSeg = timeSegOne.duration()
            }
            if availableTime.count == 0{
                shortestSeg = 0.0
                availableHours = 0.0
            }

            return CalendarDay(availableHours: availableHours, shortestSeg: shortestSeg, availableTime: availableTime, calendarScheduledHours: eventDuration)
        }
        //expected case
        var eTime = 0.0
        for event in eventsOnDay{
            let dur = event.endDate.timeIntervalSinceDate(event.startDate)
            eTime += dur
        }
        //var availableTime = 0
        var shortestSeg = 60*60*12.0
        var availableTimeSegs = [TimeSeg]()
        let components = NSCalendar.currentCalendar().components([.Month, .Day,.Year], fromDate: eventsOnDay[eventsOnDay.count-1].endDate)
        components.hour = 9
        components.minute = 0
        components.second = 0
        var newdate = NSCalendar.currentCalendar().dateFromComponents(components)
        var check = TimeSeg.init(startTime: newdate!, endTime: eventsOnDay[0].startDate)
        var checkEventDuration = check.duration()
        if checkEventDuration >= 1800{ //make sure time segment is longer than half an hour
            availableTimeSegs.append(check)
            shortestSeg = check.duration()
        }
        for i in 0..<eventsOnDay.count-1{
            let newSeg = TimeSeg.init(startTime: eventsOnDay[i].endDate, endTime: eventsOnDay[i+1].startDate)
            if newSeg.startTime != newSeg.endTime{
                availableTimeSegs.append(newSeg)
                let duration = eventsOnDay[i+1].startDate.timeIntervalSinceDate(eventsOnDay[i].endDate)
                //availableTime = availableTime + duration
                if shortestSeg > duration{
                    shortestSeg = duration
                }
            }
        }
        components.hour = 23
        components.minute = 59
        newdate = NSCalendar.currentCalendar().dateFromComponents(components)
        check = TimeSeg.init(startTime: eventsOnDay[eventsOnDay.count-1].endDate, endTime: newdate!)
        checkEventDuration = check.duration()
        if checkEventDuration >= 1800{ //make sure time segment is longer than half an hour
            availableTimeSegs.append(check)
            let duration = newdate!.timeIntervalSinceDate(eventsOnDay[eventsOnDay.count-1].endDate)
            //availableTime = availableTime + duration
            if shortestSeg > duration{
                shortestSeg = duration
            }
        }
        availableTimeSegs.sortInPlace({
            (t1:TimeSeg, t2:TimeSeg)->Bool in
            let t1Duration = t1.duration()
            let t2Duration = t2.duration()
            return t1Duration < t2Duration
        })
        var availableHours = ((3600*12) - eTime)
        if availableHours < 0{
            availableHours = 0
        }
        let calendarDay = CalendarDay(availableHours: NSTimeInterval(availableHours), shortestSeg: NSTimeInterval(shortestSeg), availableTime: availableTimeSegs, calendarScheduledHours: eTime)
        return calendarDay
    }
    
   
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: filterByDay(arr:[EKEvent], day:String)
//
// Parameters:
//      input [EKEvent]; an array of events
//      input string; the day of the week filtered for(ex. "Monday")
//   
// Pre-condition: the day string is a vaild day of the week
//
// Post-condition: returns the events happening on the specified day
//----------------------------------------------------------------------------------------------------------------------------------
    private func filterByDay(arr:[EKEvent], day:String)->[EKEvent]{
        return arr.filter({
            (e1: EKEvent) -> Bool in
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let dayString = dateFormatter.stringFromDate(e1.startDate)
            return dayString == day
        })
    }
    

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: daysTillDeadline(deadline: NSDate)
//
// Parameters:
//      input NSDate; date of the deadline
//   
// Pre-condition: the deadline is 11:59pm of the given date
//
// Post-condition: returns the number of days until the deadline including the current day and day of deadline
//----------------------------------------------------------------------------------------------------------------------------------
    private func daysTillDeadline(deadline: NSDate)->Int{
        let currentDate = NSDate().stripToDay()
        let deadlineDay = deadline.stripToDay()
        let timeTill = deadlineDay.timeIntervalSinceDate(currentDate) + (3600*24) //add one day so it includes the current day
        let daysToWorkOn = (timeTill / (3600.0*24.0))
        return Int(daysToWorkOn)
    }

    
    

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: daysUntil(day:Day, currentDay: Day)
//
// Parameters:
//      input day; the later day
//      input currentDay: the earlierDay
//   
// Pre-condition: current day is earlier than day
//
// Post-condition: returns the number ofdays between them(ex. thursday till monday->4)
//----------------------------------------------------------------------------------------------------------------------------------
    private func daysUntil(day:Day, currentDay: Day)->Int{
        let order = dayOrderSubarray(7, today: currentDay)//return full week starting with currentDay
        return order.indexOf(day)!
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: durationPerDayAssigned(numDaysToWorkOn: Int, days: [Day], taskDuration: NSTimeInterval)
//
// Parameters:
//      input Int; the number of days to work on the task
//      input [Day]: an array of the days to work on(ex:[.Friday, .Saturday, .Sunday, .Monday, .Tuesday])
//      input NSTimeInterval: a NSTimeInterval representing the time to complete the  task that the user inputed
//  
// Pre-condition: the number of days to work on is < 7, the taskDuration is correct(in seconds)
//
// Post-condition: returns an array of time per day to work on the task corresponding to the days array
//  exception: returns an empty array if not enough available hours. Has not updated any instance variables, particallly tempSchedule
//----------------------------------------------------------------------------------------------------------------------------------
    private func durationPerDayAssigned(numDaysToWorkOn: Int, days: [Day], taskDuration: NSTimeInterval)->[NSTimeInterval]{
        var numDays = numDaysToWorkOn
        var dur = taskDuration
        var dayOrder = days
        var segByDay = [NSTimeInterval](count: numDaysToWorkOn, repeatedValue: NSTimeInterval(-1))//create empty array to return
        //initialize segByDay
        for i in 0..<segByDay.count{
            if tempSchedule[dayOrder[i]]!.shortestSeg == 0{
                segByDay[i] = 0 //if there are no available hours that day assign no time to it
                numDays -= 1
            }
        }// make sure that if all days have been assigned zero an empty array will be returned
        var count = 0.0
        for value in segByDay{
            count += value
        }
        if count == 0.0 {return [NSTimeInterval]() }
        
        var segDuration:[NSTimeInterval] = segmentTask(numDays, duration: dur)
        //add expected durations
        var restart = false
        repeat{
            restart = false
            for i in 0..<dayOrder.count{
                if restart == true {break}
                if segByDay[i] == -1 {
                    let availableHours:NSTimeInterval = (tempSchedule[dayOrder[i]]?.availableHours)!
                    if availableHours < segDuration[0]{
                        let durForDay = availableHours - (availableHours % 1800)
                        segByDay[i] = durForDay
                        numDays -= 1
                        dur = dur - durForDay
                        if numDays == 0{
                            //not enough available hours
                            return [NSTimeInterval]()
                        }
                        segDuration = segmentTask(numDays, duration: dur)
                        restart = true
                    }
                }
            }
        } while restart
        //add the extra min:
        for i in 0..<segByDay.count{
            if segByDay[i] == -1{
                if (tempSchedule[dayOrder[i]]?.availableHours)! > segDuration[1]{ //if there are no available time segments available hours should equal 0
                    segByDay[i] = segDuration[1]
                    segDuration[1] = segDuration[0]
                    
                }else{
                    segByDay[i] = segDuration[0]
                }
                dur = dur - segByDay[i]
            }
        }
        if dur > 0.0 {
            return [NSTimeInterval]()}
        
        return segByDay
    }

//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: dayOrderSubarray(numDaysToWorkOn: Int,today: Day)
//
// Parameters:
//      input Int; the number of days to work on the task
//      input Day: the day that will be the first element of the returned array
//  
// Pre-condition: the number of days to work on is < 7
//
// Post-condition: returns an array of days ordered with the given day(today) first
//----------------------------------------------------------------------------------------------------------------------------------
    private func dayOrderSubarray(numDaysToWorkOn: Int,today: Day)->[Day]{
        let dayOrder: [Day] = [.Monday, .Tuesday, .Wednesday, .Thursday, .Friday, .Saturday, .Sunday]
        var subarray: [Day]
        //expected case
        let index:Int = dayOrder.indexOf(today)!
        let endIndex = index+numDaysToWorkOn
        if endIndex > dayOrder.count{
            //wrapcase
            subarray = Array(dayOrder[index..<dayOrder.count])
            let dif = (endIndex) - dayOrder.count
            if dif ==  0{
                subarray.append(dayOrder[0])
            }else{
                subarray.appendContentsOf(dayOrder[0..<dif])
            }
        }else{
            subarray = Array(dayOrder[index..<endIndex])
        }
        return subarray
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function:segmentTask(num: Int, duration: NSTimeInterval)
//
// Parameters:
//      input Int; number of segments to make
//      input NSTimeInterval: the time interval to segment
//  
// Pre-condition: num is > 0, the time interval is correct(in seconds)
//
// Post-condition: returns an array of NSTimeInterval [segment time, segment time+extra] of the duration segmented, rounding to nearest halfhour
//----------------------------------------------------------------------------------------------------------------------------------
    private func segmentTask(num: Int, duration: NSTimeInterval)->[NSTimeInterval]{
        //need to do calculations as minutes to round days to nearest half hour
        let halfHour = 15
        let durMin = duration/60.0//temp make minutes
        var seg = Int( durMin / Double(num) )
        seg = seg / halfHour// currently number of half hours
        seg = seg*halfHour //back to min
        var lastExtraSeg = seg + Int(((durMin/Double(num)) % Double(halfHour)) * Double(num))
        //make sure that there was no precision errors
        seg = seg * 60
        lastExtraSeg = lastExtraSeg * 60
        let totalSeconds:Double = Double(seg * (num-1) + lastExtraSeg)
        if totalSeconds < duration{
            let difference = duration - totalSeconds
            lastExtraSeg = lastExtraSeg + Int(difference)
        }
        let a = NSTimeInterval(seg)
        let b = NSTimeInterval(lastExtraSeg)
        return [ a , b ]
    }
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: timeSegsToAssign(dayOfWeek: Day, duration: NSTimeInterval, task:NSManagedObject)
//
// Parameters:
//      input Day; the day of the week to schedule
//      input NSTimeInterval; the time interval representing the time to schedule for the given day
//      input NSManagedObject; the task that is being scheduled 
//  
// Pre-condition: the given duration corresponds to the given day ie it is possible to schedule the task for the given duration on the day
//
// Post-condition: finds available time segments in tempSchedule[dayOfWeek], updates dayOfWeek's availableHours and available 
// time segments, and creates an EKEvent for the task and saves it to taskEvents[]
//----------------------------------------------------------------------------------------------------------------------------------
    private func timeSegsToAssign(dayOfWeek: Day, duration: NSTimeInterval, task:NSManagedObject){
        if duration == 0{ return }//a day with no scheduled time is not an error but no task should be created
        var eventCreated = false
        var dur = duration
        while !eventCreated{
            let timeSeg = findSegInDay( tempSchedule[dayOfWeek]!, duration: dur)
            var newTimeSeg: TimeSeg
            if(timeSeg.duration() < dur){
                //timeseg is too short
                createTaskEvent(timeSeg, task: task)
                newTimeSeg = TimeSeg(startTime: timeSeg.endTime, endTime: timeSeg.endTime)
            }else{
                //timseg is >= duration
                let newStartTime = timeSeg.startTime.dateByAddingTimeInterval(dur)
                newTimeSeg = TimeSeg(startTime: newStartTime, endTime: timeSeg.endTime)
                
                let taskSeg = TimeSeg(startTime: timeSeg.startTime, endTime: newTimeSeg.startTime)
                createTaskEvent(taskSeg, task: task)
                eventCreated =  true
            }
            let index = tempSchedule[dayOfWeek]!.availableTime.indexOf({
                (t:TimeSeg)->Bool in
                return t.startTime == timeSeg.startTime && t.endTime == timeSeg.endTime
            })
            tempSchedule[dayOfWeek]!.updateTimeSeg(newTimeSeg, segIndex: index!)
            dur -= timeSeg.duration()
        }
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: findSegInDay(day: CalendarDay, duration: NSTimeInterval)
//
// Parameters:
//      input Day; the day of the week to schedule
//      input NSTimeInterval; the time interval representing the time to schedule for the given day 
//  
// Pre-condition: the given duration is in seconds, the day given has available time segments
//
// Post-condition: finds available time segment in tempSchedule[dayOfWeek] >= duration(shortest possible). If no time segment 
// is long enough returns the longest. Nothing in tempSchedule is updated, the appropriate time segment is only returned
//----------------------------------------------------------------------------------------------------------------------------------
    private func findSegInDay(day: CalendarDay, duration: NSTimeInterval)->TimeSeg{
        let timeSegs = day.availableTime
        if day.shortestSeg == 0{
            print("Error: a day with no available time segments was passed to the findSegInDay")
            print(day.availableHours)
        }
        var j = 0
        while j < timeSegs.count{
            if timeSegs[j].duration() >= duration{
                return timeSegs[j]
            }
            j += 1
        }
        //if none of available timeSegs are long enough
        j = j - 1//undo increment
        return timeSegs[j]
    }
    
//----------------------------------------------------------------------------------------------------------------------------------
//
//  Function: createTaskEvent(timeSeg:TimeSeg, task:NSManagedObject)
//
// Parameters:
//      input TimeSeg; timeSegment of the task event to be created
//      input NSManagedObject; the corresponding task to the event that will be created
//  
// Pre-condition: timeSeg is correct and has no overlap with other events
//
// Post-condition: made an EKEvent for a task event and linked it to its corresponding task in the core data model, does not change the tempScheduled, saved the event in taskEvents
//----------------------------------------------------------------------------------------------------------------------------------
    private func createTaskEvent(timeSeg:TimeSeg, task:NSManagedObject){
        let name = task.valueForKey("name") as? String
        if(timeSeg.startTime == timeSeg.endTime){
            print("start time of segment == end time. event not created")
            return}//ToDo: find actual problem causing this
        let taskEvent = EKEvent(eventStore: eventStore)
        taskEvent.calendar = taskCalendar
        taskEvent.title = name!
        taskEvent.startDate = timeSeg.startTime
        taskEvent.endDate = timeSeg.endTime
        taskEvent.addAlarm(EKAlarm(absoluteDate: timeSeg.startTime))
         //save event but do not commit
         do{
            try eventStore.saveEvent(taskEvent, span: .ThisEvent,commit: false)
         }catch {
            print("task event could not save")
         }
        taskEvents.append(taskEvent)
        
        let taskEventId = taskEvent.eventIdentifier
        let entity = NSEntityDescription.entityForName("TaskEvent", inManagedObjectContext: managedContext)
        let taskEventEntity = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        taskEventEntity.setValue(taskEventId, forKey: "id")
        //taskEventEntity.setValue(NSSet(object: task), forKey: "task")
        taskEventEntity.setValue(task, forKey: "task")
        do{
            try managedContext.save()
            print("Success saving taskevent")
        }catch let error as NSError{
            print("could not save \(error), \(error.userInfo)")
        }
    }
    

}

/*
 * data structures used by the scheduling algorithm to store segments of time and represent a day- storing segments of available time
 */
struct TimeSeg{
    var startTime: NSDate
    var endTime: NSDate
    
    func duration() -> NSTimeInterval{
        return endTime.timeIntervalSinceDate(startTime)
    }
}
struct CalendarDay{
    var availableHours: NSTimeInterval //in seconds
    var shortestSeg: NSTimeInterval
    var availableTime: [TimeSeg]
    var calendarScheduledHours: NSTimeInterval
    //
    func totalAvailableTimeDuration()-> NSTimeInterval{
        var time = 0.0
        for s in availableTime{
            time += s.duration()
        }
        return time
    }
    
    //sorted by time order doesnt need to be assumed
    mutating func updateTimeSeg(newSeg: TimeSeg, segIndex: Int){
        let currSeg = availableTime[segIndex]
        let oldDuration = currSeg.endTime.timeIntervalSinceDate(currSeg.startTime)
        let newDuration = newSeg.endTime.timeIntervalSinceDate(newSeg.startTime)
        let difference = oldDuration - newDuration
        availableHours = availableHours - difference
        if newDuration < (60*30){
           availableHours = availableHours - newDuration
            availableTime.removeAtIndex(segIndex)
            if availableTime.count == 0{
                shortestSeg = 0
                availableHours = 0.0
            }
        }else{
            if shortestSeg > newDuration{
                shortestSeg = newDuration
            }
            availableTime[segIndex] = newSeg
        }
    }
}
