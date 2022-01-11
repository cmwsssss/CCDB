//
//  UserDetailView.swift
//  CCModelExample
//
//  Created by cmw on 2021/11/15.
//

import SwiftUI

class UserDetailViewModel: ObservableObject {
    @Published var user: UserModel?
    
    init(user: UserModel?) {
        self.user = user

        UserModel.addViewNotifier {
            self.objectWillChange.send()
        }
    }
    
    func onClickLike() {
        self.user?.liked = !(self.user?.liked ?? false)
        self.user?.replaceIntoDB()
    }
    
    func onChangeUsername() {
        self.user?.username = "changed \(self.user?.username ?? "")"
        self.user?.replaceIntoDB()
    }
}

struct UserDetailView: View {
    
    @ObservedObject var viewModel: UserDetailViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0, content: {
                HStack {
                    Spacer()
                }
                if let avatar = self.viewModel.user?.avatar {
                    Image(avatar.url)
                        .resizable()
                        .frame(width: 300, height: 300, alignment: .center)
                        .clipped()
                        .padding([.top, .bottom], 30)
                }
                
                Text("Username")
                    .padding(.bottom, 30)
                
                HStack {
                    Text(self.viewModel.user?.username ?? "")
                    Spacer()
                    Button(action: self.viewModel.onChangeUsername) {
                        Text("change")
                    }
                    .padding(.leading, 30)
                }
                .padding(.bottom, 30)
                
                
                Text("Info")
                    .padding(.bottom, 30)
                
                Text(self.viewModel.user?.info ?? "")
                    .padding(.bottom, 30)

                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        Spacer()
                    }
                    Button(action: self.viewModel.onClickLike) {
                        Text(self.viewModel.user?.liked ?? false ? "Unlike" : "Like")
                    }
                }
            })
                .padding([.leading, .trailing], 30)
        }
        .navigationTitle(self.viewModel.user?.username ?? "")
    }
}
