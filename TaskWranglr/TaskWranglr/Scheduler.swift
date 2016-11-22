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
    var tempSchedule: [Day: CalendarDay] = [Day:CalendarDay]()
    var taskEvents:[EKEvent] = [EKEvent]()
    init(eStore: EKEventStore, mContext: NSManagedObjectContext, frc:NSFetchedResultsController){
        eventStore = eStore
        managedContext = mContext
        fetchedResultsController = frc // should have a fetch request specifying all tasks in order of soonest deadline
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
    //make a EKEvent for a task event and link it to its corresponding task in the core data model, does not change the tempSchedule
    func createTaskEvent(name:String, timeSeg:TimeSeg, task:NSManagedObject){
        if(timeSeg.startTime == timeSeg.endTime){return}//ToDo: find actual problem causing this
        let taskEvent = EKEvent(eventStore: eventStore)
        taskEvent.calendar = taskCalendar
        taskEvent.title = name
        taskEvent.startDate = timeSeg.startTime
        taskEvent.endDate = timeSeg.endTime
        /*
        do{
            try eventStore.saveEvent(taskEvent, span: .ThisEvent,commit: false)
                    }catch {
            print("task event could not save")
        }*/
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
    /*scheduling algorithm
     *precondidtion: there are calendar events and tasks that exist
     * makes events for each task so that they will be completed by their due date and have no overlap with other events. Each task cannot be broken up into segments smaller than 30 minutes
     *returns: an array of task events([EKEvent])
     */
    func schedule()->[EKEvent]{
        //TO-DO: implement scheduling algorithm
        //get calendar events ordered by what comes first
        let cEvents = fetchCalendarEvents(eventStore.calendarsForEntityType(EKEntityType.Event)).sort(){
                (e1: EKEvent, e2: EKEvent) -> Bool in
                return e1.startDate.compare(e2.startDate) == NSComparisonResult.OrderedAscending
        }
        //tasks
        do{
            try fetchedResultsController.performFetch()
        } catch{
            fatalError("failed to initialize fetchedResultsController: \(error)")
        }
        let tasks:[NSManagedObject] = (fetchedResultsController.fetchedObjects as? [NSManagedObject])!
        taskEvents = [EKEvent]()//reinit empty task events array
       
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEEE"
        let rawDay = formatter.stringFromDate(NSDate())
        let today = Day(rawValue: rawDay)
        //create a dictionary of days containing the segments of available time
        
        tempSchedule = [Day: CalendarDay]()
        tempSchedule[.Monday] = initTempDay(filterByDay(cEvents, day: "Monday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Monday, currentDay: today!))))
        tempSchedule[.Tuesday] = initTempDay(filterByDay(cEvents, day: "Tuesday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Tuesday, currentDay: today!))))
        tempSchedule[.Wednesday] = initTempDay(filterByDay(cEvents, day: "Wednesday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Wednesday, currentDay: today!))))
        tempSchedule[.Thuresday] = initTempDay(filterByDay(cEvents, day: "Thuresday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Thuresday, currentDay: today!))))
        tempSchedule[.Friday] = initTempDay(filterByDay(cEvents, day: "Friday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Friday, currentDay: today!))))
        tempSchedule[.Saturday] = initTempDay(filterByDay(cEvents, day: "Saturday"),dayOfWeek:  NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Saturday, currentDay: today!))))
        tempSchedule[.Sunday] = initTempDay(filterByDay(cEvents, day: "Sunday"), dayOfWeek: NSDate().dateByAddingTimeInterval(Double(3600 * 24 * daysUntil(.Sunday, currentDay: today!))))
        /*print(tempSchedule)
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.FullStyle
        let exdate = tempSchedule[.Monday]
        let exdatec = exdate?.availableTime
        print(formatter.stringFromDate(exdatec![0].endTime))
        */
        
        //for each task schedule it
        
        for t in tasks{
            //get duration to work on task for each day
            let numDaysToWorkOn = daysTillDeadline((t.valueForKey("deadline") as? NSDate)!)
            let dayOrder = dayOrderSubarray(numDaysToWorkOn, today: today!)
            var durations = daysToAssignTo(numDaysToWorkOn,today: today!, days: dayOrder, duration: (t.valueForKey("CompletionTime") as? NSTimeInterval)!)
            while durations.count == 0{
                for day in dayOrder{
                    //if not enough available hours add 1 more hour a day and recalculate
                    var calDay = tempSchedule[day]
                    calDay!.availableHours += 3600
                    tempSchedule[day]=calDay
                }
                durations = daysToAssignTo(numDaysToWorkOn,today: today!, days: dayOrder, duration: (t.valueForKey("CompletionTime") as? NSTimeInterval)!)
            }
            //now that durations are correct,assign them to times in their corresponding days
            timeSegsToAssignTo(dayOrder, durations: durations, task: t)
        }
        
        //---------------------------------------------------------------------------------
        let currentDate = NSDate()
        let ti = NSTimeInterval(604800)//seconds in 7 days = 60sec x 60min x24hours x 7days
        let sevenDaysDate = currentDate.dateByAddingTimeInterval(ti)
        //let taskEventPredicate = eventStore.predicateForEventsWithStartDate(currentDate, endDate: sevenDaysDate, calendars: [taskCalendar])
        //let taskEvents = eventStore.eventsMatchingPredicate(taskEventPredicate)
        var events = cEvents + taskEvents
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
    func daysUntil(day:Day, currentDay: Day)->Int{
        let order = dayOrderSubarray(7, today: currentDay)
        return order.indexOf(day)!
    }
    //parameter: eventsOnDay are events from the same day sorted by what comes earlier
    //returns an an instance of CalendarDay for that day assuming no more than 12 hours a day of time that can be scheduled
    private func initTempDay(eventsOnDay: [EKEvent], dayOfWeek: NSDate) -> CalendarDay {
        //edgecases
        if( eventsOnDay.count) == 0{
            let components = NSCalendar.currentCalendar().components([.Month, .Day,.Year], fromDate: dayOfWeek)
            components.hour = 9
            components.minute = 0
            let startDate = NSCalendar.currentCalendar().dateFromComponents(components)
            components.hour = 23
            components.minute = 59
            let endDate = NSCalendar.currentCalendar().dateFromComponents(components)
            return CalendarDay(availableHours: NSTimeInterval(3600*12), shortestSeg: NSTimeInterval(3600*12), availableTime: [TimeSeg(startTime: startDate! ,endTime: endDate!)])
        }else if(eventsOnDay.count == 1){
            let event = eventsOnDay[0]
            let components = NSCalendar.currentCalendar().components([.Month, .Day,.Year], fromDate: event.startDate)
            components.hour = 9
            components.minute = 0
            let startDate = NSCalendar.currentCalendar().dateFromComponents(components)
            components.hour = 23
            components.minute = 59
            let endDate = NSCalendar.currentCalendar().dateFromComponents(components)
            let timeSegOne = TimeSeg(startTime: startDate!, endTime: event.startDate)
            var shortestSeg = timeSegOne.endTime.timeIntervalSinceDate(timeSegOne.startTime)
            let timeSegTwo = TimeSeg(startTime: event.endDate, endTime: endDate!)
            let timeSegTwoDuration = timeSegTwo.endTime.timeIntervalSinceDate(timeSegTwo.startTime)
            if timeSegTwoDuration < shortestSeg{
                shortestSeg = timeSegTwoDuration
            }
            let eventDuration = event.endDate.timeIntervalSinceDate(event.startDate)
            let availableHours = NSTimeInterval(3600 * 12 - eventDuration)
            return CalendarDay(availableHours: availableHours, shortestSeg: shortestSeg, availableTime: [timeSegOne,timeSegTwo])
        }
        //expected case
        var eTime = 0
        for event in eventsOnDay{
            let dur = event.endDate.timeIntervalSinceDate(event.startDate)
            eTime += Int(dur)
        }
        //var availableTime = 0
        var shortestSeg = 60*60*12
        var availableTimeSegs = [TimeSeg]()
        for i in 0..<eventsOnDay.count-1{
            availableTimeSegs.append(TimeSeg.init(startTime: eventsOnDay[i].endDate, endTime: eventsOnDay[i+1].startDate))
            let duration = Int(eventsOnDay[i+1].startDate.timeIntervalSinceDate(eventsOnDay[i].endDate))
            //availableTime = availableTime + duration
            if shortestSeg > duration{
                shortestSeg = duration
            }
        }
        let components = NSCalendar.currentCalendar().components([.Month, .Day,.Year], fromDate: eventsOnDay[eventsOnDay.count-1].endDate)
        components.hour = 23
        components.minute = 59
        let newdate = NSCalendar.currentCalendar().dateFromComponents(components)
        availableTimeSegs.append(TimeSeg.init(startTime: eventsOnDay[eventsOnDay.count-1].endDate, endTime: newdate!))
        let duration = Int(newdate!.timeIntervalSinceDate(eventsOnDay[eventsOnDay.count-1].endDate))
        //availableTime = availableTime + duration
        if shortestSeg > duration{
            shortestSeg = duration
        }
        availableTimeSegs.sortInPlace({
            (t1:TimeSeg, t2:TimeSeg)->Bool in
                let t1Duration = t1.endTime.timeIntervalSinceDate(t1.startTime)
                let t2Duration = t2.endTime.timeIntervalSinceDate(t2.startTime)
                return t1Duration < t2Duration
        })
        let availableTime = ((3600*12) - eTime)
        let calendarDay = CalendarDay(availableHours: NSTimeInterval(availableTime), shortestSeg: NSTimeInterval(shortestSeg), availableTime: availableTimeSegs)
        return calendarDay
    }
    
    func daysTillDeadline(deadline: NSDate)->Int{
        let currentDate = NSDate().stripToDay()
        let deadlineDay = deadline.stripToDay()
        let timeTill = deadlineDay.timeIntervalSinceDate(currentDate) + (3600*24) //add one day so it includes the current day
        let daysToWorkOn = (timeTill / (3600.0*24.0))
        return Int(daysToWorkOn)
    }
    //returns an array of time per day to work on assignment corresponding to the array generated by the dayOrderSubarray method
    //returns an empty array if not enough available hours
    func daysToAssignTo(numDaysToWorkOn: Int,today: Day, days: [Day], duration: NSTimeInterval)->[NSTimeInterval]{
        var segDuration = segmentTask(numDaysToWorkOn, duration: duration)
        var segByDay = [NSTimeInterval](count: numDaysToWorkOn, repeatedValue: NSTimeInterval(-1))
        var numDays = numDaysToWorkOn
        var dur = duration
        var dayOrder = days
        //add expected durations
        var restart = true
        repeat{
            for i in 0..<dayOrder.count{
                if segByDay[i] == -1 {
                    let aT:NSTimeInterval = (tempSchedule[dayOrder[i]]?.availableHours)!
                    if aT < segDuration[0]{
                        segByDay[i] = aT
                        numDays -= 1
                        dur = duration - aT
                        if numDays == 0{
                            //not enough available hours
                            return [NSTimeInterval]()
                        }
                        segDuration = segmentTask(numDays, duration: dur)
                        restart = false
                    }
                }
            }
        } while !restart
        //add the extra min:
        for i in 0..<segByDay.count{
            if segByDay[i] == -1{
                if (tempSchedule[dayOrder[i]]?.availableHours)! > segDuration[1]{
                    segByDay[i] = segDuration[1]
                    segDuration[1] = segDuration[0]
                }else{
                    segByDay[i] = segDuration[0]
                }
            }
        }
        return segByDay
    }


//precondition: num is <= 7
    func dayOrderSubarray(numDaysToWorkOn: Int,today: Day)->[Day]{
        let dayOrder: [Day] = [.Monday, .Tuesday, .Wednesday, .Thuresday, .Friday, .Saturday, .Sunday]
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
    //segment a task rounding to nearest halfhour
    func segmentTask(num: Int, duration: NSTimeInterval)->[NSTimeInterval]{
        //need to do calculations as minutes to round days to nearest half hour
        let halfHour = 30
        let durMin:Int = Int(duration)/60//temp make minutes
        var seg = Int( Double(durMin) / Double(num) )
        seg = seg / halfHour// currently number of half hours
        seg = seg*30 //back to min
        let lastExtraSeg = seg + (((durMin/num) % halfHour) * num)
        return [ NSTimeInterval(seg*60), NSTimeInterval(lastExtraSeg*60) ]
    }
    //parameters: arrays of how long to work on task and array for mapping to day of the week
    //precondition assumes that durations are correct and the availableTime[] in tempschedule are sorted by duration of each available TimeSeg
    //postconditions: all events for tasks have been made and the available time each day has been updated
    func timeSegsToAssignTo(days: [Day], durations: [NSTimeInterval], task: NSManagedObject){
        let name = task.valueForKey("name") as? String
        for i in 0..<days.count{
            var day: CalendarDay = tempSchedule[days[i]]!
            let availableHours = day.availableHours
            var duration = durations[i]
            var eventCreated = false
            while !eventCreated{
                if availableHours >= durations[i]{
                    //create event and update day's availableTimes
                    let timeSeg = findSegInDay( day, duration: duration)
                    
                    if(timeSeg.endTime.timeIntervalSinceDate(timeSeg.startTime) < duration){
                        //timeseg is too short
                        createTaskEvent(name!, timeSeg: timeSeg, task: task)
                        let newTimeSeg = TimeSeg(startTime: timeSeg.endTime, endTime: timeSeg.endTime)
                        let index = day.availableTime.indexOf({
                            (t:TimeSeg)->Bool in
                            return t.startTime == timeSeg.startTime && t.endTime == timeSeg.endTime
                        })
                        day.updateTimeSeg(newTimeSeg, segIndex: index!)
                        tempSchedule[days[i]] = day
                        
                        duration = duration - timeSeg.endTime.timeIntervalSinceDate(timeSeg.startTime)
                    }else{
                        //task fits into segment
                        let newStartTime = timeSeg.startTime.dateByAddingTimeInterval(duration)
                        let newTimeSeg = TimeSeg(startTime: newStartTime, endTime: timeSeg.endTime)
                        let index = day.availableTime.indexOf({
                            (t:TimeSeg)->Bool in
                            return t.startTime == timeSeg.startTime && t.endTime == timeSeg.endTime
                        })
                        day.updateTimeSeg(newTimeSeg, segIndex: index!)
                        tempSchedule[days[i]] = day
                        let taskSeg = TimeSeg(startTime: timeSeg.startTime, endTime: newTimeSeg.startTime)
                        createTaskEvent(name!, timeSeg: taskSeg, task: task)
                        eventCreated =  true
                    }
                }else{
                    day.availableHours = availableHours + 3600 //add another hour
                }
            }
        }
    }
    //given a calendar day return a segment of available time that is >= duration(but the shortest possible)
    //if none are long enough returns the longest
    func findSegInDay(day: CalendarDay, duration: NSTimeInterval)->TimeSeg{
        let timeSegs = day.availableTime
        var j = 0
        while j < timeSegs.count{
            if timeSegs[j].endTime.timeIntervalSinceDate(timeSegs[j].startTime) >= duration{
                return timeSegs[j]
            }
            j += 1
        }
        //if none of available timeSegs are long enough
        j = j - 1//undo increment
        return timeSegs[j]
    }
    /*
    func getCalendarEvents(){
        let cEvents = fetchCalendarEvents(eventStore.calendarsForEntityType(EKEntityType.Event)).sort(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == NSComparisonResult.OrderedAscending
        }
        

    }*/
    
}
struct TimeSeg{
    var startTime: NSDate
    var endTime: NSDate
}
struct CalendarDay{
    var availableHours: NSTimeInterval //in seconds
    var shortestSeg: NSTimeInterval
    var availableTime: [TimeSeg]
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
        }else{
            if shortestSeg > newDuration{
                shortestSeg = newDuration
            }
            availableTime[segIndex] = newSeg
        }
    }
}
