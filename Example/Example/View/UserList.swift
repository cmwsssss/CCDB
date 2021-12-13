//
//  UserList.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/12.
//

import SwiftUI
import Combine
class UserListViewModel: ObservableObject {
    @Published var title = ""
    @Published var users = [UserModel]()
    @Published var shouldGoDetail = false
    var targetUser: UserModel?
    
    var start: Int
    var end: Int
    
    var containerId: Int {
        var containerId = 1
        if end == 15 {
            containerId = 2
        } else if end == 30 && start == 16 {
            containerId = 3
        }
        return containerId
    }
    
    
    init(start: Int, end: Int) {
        
        self.start = start
        self.end = end
        
        self.users = UserModel.queryAll(true, withContainerId: containerId)
        weak var weakSelf = self
        UserModel.addViewNotifier {
            weakSelf?.objectWillChange.send()
        }

        PhotoModel.addViewNotifier {
            weakSelf?.objectWillChange.send()
        }
    }
    
    func onClickUserDetail(user: UserModel) {
        self.targetUser = user
        if var viewCount = user.viewCount {
            viewCount += 1
            user.viewCount = viewCount
        } else {
            user.viewCount = 1
        }
        user.replaceIntoDB()
        self.shouldGoDetail.toggle()
    }

    func refreshData() {
        self.title = "Loading..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.title = "Finished"
            self.users.removeAll()
            UserModel.removeAll(containerId: self.containerId)
            let datas: Any
            if self.containerId == 1 {
                datas = JSONLoader.loadDatasFromJSON(filename: "User_list.json")
            } else if self.containerId == 2 {
                datas = JSONLoader.loadDatasFromJSON(filename: "User_list_1_15.json")
            } else {
                datas = JSONLoader.loadDatasFromJSON(filename: "User_list_16_30.json")
            }
            self.users = UserModel.updateWithJSON(mapper: [UserModel].self, jsonData: datas)
            for user in self.users {
                user.replaceIntoDB(containerId: self.containerId, top: false)
            }
        }
    }
}

struct UserList: View {
    
    @ObservedObject var viewModel: UserListViewModel
    
    var body: some View {
        
        NavigationLink(
            destination: UserDetailView(viewModel: UserDetailViewModel(user: self.viewModel.targetUser)),
            isActive: self.$viewModel.shouldGoDetail,
            label: {})
        
        List(self.viewModel.users) {user in
            Button {
                self.viewModel.onClickUserDetail(user: user)
            } label: {
                UserListCell(user: user)
                    .foregroundColor(Color.black)
            }
        }
        .refreshable {
            self.viewModel.refreshData()
        }
        .onAppear(perform: {
            if self.viewModel.users.count == 0 {
                self.viewModel.refreshData()
            }
        })
        .navigationTitle(self.viewModel.title)
    }
}

struct UserListCell: View {
    
    @ObservedObject var user: UserModel
    
    var body: some View {
        HStack {
            if let avatar = user.avatar {
                Image(avatar.url)
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .clipped()
            }
            VStack(alignment: .leading, spacing: 0, content: {
                Text(user.username)
                    .padding(.bottom, 10)
                Text(user.info)
            })
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                if let liked = user.liked, liked {
                    Text("Liked")
                        .padding(.bottom, 10)
                }
                Text("view: \(user.viewCount ?? 0)")
            }
        }
    }
}

