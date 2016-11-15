//
//  TaskListViewController.swift
//  TaskWranglr
//
//  Created by Elisa Idrobo on 11/13/16.
//  Copyright © 2016 Elisa Idrobo. All rights reserved.
//

import UIKit

class TaskListViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10 //each input field needs 1 cell
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

}
