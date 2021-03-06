//
//  MainView.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/15.
//

import SwiftUI
import CCDB
class MainViewModel: ObservableObject {
    @Published var datas = [MainViewCellModel]()
    @Published var shouldGo15UserList = false
    @Published var shouldGo30UserList = false
    @Published var shouldGoAllUserList = false

    init() {
        self.datas.append(MainViewCellModel(name: "Users 0-15", clickHandler: {
            self.shouldGo15UserList.toggle()
        }))
        
        self.datas.append(MainViewCellModel(name: "Users 16-30", clickHandler: {
            self.shouldGo30UserList.toggle()
        }))
        
        self.datas.append(MainViewCellModel(name: "All Users", clickHandler: {
            self.shouldGoAllUserList.toggle()
        }))
    }
}

struct MainView: View {
    
    @ObservedObject var viewModel = MainViewModel()
    
    var body: some View {
        
        NavigationView {
            VStack {
                NavigationLink(
                    destination: UserList(viewModel: UserListViewModel(start: 0, end: 15)),
                    isActive: self.$viewModel.shouldGo15UserList,
                    label: {})
                
                NavigationLink(
                    destination: UserList(viewModel: UserListViewModel(start: 16, end: 30)),
                    isActive: self.$viewModel.shouldGo30UserList,
                    label: {})
                
                NavigationLink(
                    destination: UserList(viewModel: UserListViewModel(start: 0, end: 30)),
                    isActive: self.$viewModel.shouldGoAllUserList,
                    label: {})

                List(self.viewModel.datas) { data in
                    Button(action: data.clickHandler) {
                        MainViewCell(cellModel: data)
                    }
                }
            }
            .navigationTitle("Main")
        }
    }
}

class MainViewCellModel: ObservableObject, Identifiable {
    var name: String
    var clickHandler: ()->Void
    
    init(name: String, clickHandler: @escaping ()->Void) {
        self.name = name
        self.clickHandler = clickHandler
    }
}

struct MainViewCell: View {
    @ObservedObject var cellModel: MainViewCellModel
    
    var body: some View {
        Text(self.cellModel.name)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
