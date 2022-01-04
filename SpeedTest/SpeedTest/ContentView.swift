//
//  ContentView.swift
//  SpeedTest
//
//  Created by cmw on 2021/12/13.
//

import SwiftUI
import CCDB
import RealmSwift
class CellDataSource: Identifiable {
    let title: String
    let handler: ()->(Void)
    
    init (title: String, handler: @escaping ()->(Void)) {
        self.title = title
        self.handler = handler
    }
}

class ContentViewModel: ObservableObject {
    var datas = [CellDataSource]()
    @Published var showAlert = false
    @Published var alertTitle = ""
    init() {
        self.datas.append(contentsOf: [
            CellDataSource(title: "Insert 10000 data with CCDB", handler: self.insert10000WithCCDB),
            CellDataSource(title: "Insert 10000 data with Realm", handler: self.insert10000WithRealm),
            CellDataSource(title: "Insert 100000 data with CCDB", handler: self.insert100000WithCCDB),
            CellDataSource(title: "Insert 100000 data with Realm", handler: self.insert100000WithRealm),
            CellDataSource(title: "Query all data with CCDB", handler: self.queryAllDatasWithCCDB),
            CellDataSource(title: "Query all data with Realm", handler: self.queryAllDatasWithRealm),
            CellDataSource(title: "Get 10000 data with CCDB", handler: self.get10000DataWithCCDB),
            CellDataSource(title: "Get 10000 data with Realm", handler: self.get10000DataWithRealm)
        ])
    }
    
    func insert10000WithCCDB() {
        let date = Date()
        for i in 0..<10000 {
            let model = CCDBModel()
            model.compareId = i
            model.replaceIntoDB()
        }
        
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
    
    func insert10000WithRealm() {
        let date = Date()
        let realm = RealmHelper.getDB()
        do {
            try realm.write {
                for i in 0..<10000 {
                    let model = RealmModel.init()
                    model.compareId = i
                    realm.add(model as! Object)
                }
            }
        } catch {
            
        }
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
        
    }
    
    func insert100000WithCCDB() {
        let date = Date()
        for i in 0..<100000 {
            let model = CCDBModel()
            model.compareId = i
            model.replaceIntoDB()
        }
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
    
    func insert100000WithRealm() {
        let date = Date()
        let realm = RealmHelper.getDB()
        do {
            try realm.write {
                for i in 0..<100000 {
                    let model = RealmModel.init()
                    model.compareId = i
                    realm.add(model as! Object)
                }
            }
        } catch {
            
        }
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
    
    func queryAllDatasWithCCDB() {
        let date = Date()
        let results = CCDBModel.queryAll(false)
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
    
    func queryAllDatasWithRealm() {
        let date = Date()
        let realm = RealmHelper.getDB()
        let results = realm.objects(RealmModel.self)
        //Make a real query
        for res in results {
        }
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
    
    func get10000DataWithCCDB() {
        let date = Date()
        for i in 0...10000 {
            _ = CCDBModel.initWithPrimaryPropertyValue(i)
        }
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
    
    func get10000DataWithRealm() {
        let date = Date()
        let realm = RealmHelper.getDB()
        for i in 0...10000 {
            _ = realm.objects(RealmModel.self).filter("compareId = \(i)")
        }
        self.alertTitle = "\(-date.timeIntervalSinceNow)"
        self.showAlert.toggle()
    }
}

struct ContentView: View {
    
    @ObservedObject var viewModel = ContentViewModel()
    
    var body: some View {
        List(viewModel.datas) { data in
            Button(action: data.handler) {
                Text(data.title)
            }.alert(isPresented: self.$viewModel.showAlert) {
                Alert(title: Text("Duration:"),
                      message: Text("\(self.viewModel.alertTitle) s"),
                 dismissButton: .default(Text("Got it!"))
                 )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
