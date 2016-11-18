//
//  ScheduleViewController.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/13/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
//

import UIKit
import EventKitUI

class ScheduleViewController: UIViewController, EKCalendarChooserDelegate {
    
    //eventStore needed to access any calendar data
    lazy var eventStore = EKEventStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        //create button programmically so that the EKCalendarChooser can be used
        let leftButton =  UIBarButtonItem(title: "calendars", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ScheduleViewController.chooseCalendar))
        navigationItem.leftBarButtonItem = leftButton
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
    }
    @IBAction func cancelFromTask(unwindSegue: UIStoryboardSegue){
    }
    func chooseCalendar() {
        let calendarVC = EKCalendarChooser(selectionStyle: .Multiple, displayStyle: .AllCalendars, entityType: .Event, eventStore: eventStore)
        calendarVC.showsDoneButton = true
        calendarVC.modalPresentationStyle = .Popover
        calendarVC.delegate = self
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        if status == EKAuthorizationStatus.Authorized{
            self.navigationController?.pushViewController(calendarVC, animated:true)
        }else if status == EKAuthorizationStatus.NotDetermined{
            eventStore.requestAccessToEntityType(EKEntityType.Event, completion: {
                (accessGranted: Bool, error: NSError?) in
                if accessGranted == true{
                    self.navigationController?.pushViewController(calendarVC, animated:true)
                }else{
                    print("calendar access not granted")
                }
            })
        }else if status == EKAuthorizationStatus.Denied || status == EKAuthorizationStatus.Restricted{
            print("implementation of calandar access denied message needed")
        }
    }
    func calendarChooserDidFinish(calendarChooser: EKCalendarChooser) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
