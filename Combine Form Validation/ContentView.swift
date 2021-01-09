//
//  ContentView.swift
//  Combine Form Validation
//
//  Created by Sai Nikhit Gulla on 09/01/21.
//

import SwiftUI
import Combine


// Model
enum PasswordStatus: String {
    case notStrong = "Please pick a strong password"
    case notSame = "Passwords don't match"
    case empty = "Password is empty"
    case valid = ""
}

// View Model
final class ViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var repeatPassword: String = ""
    
    @Published var isValid: Bool = false
    
    @Published var passwordErrorText = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private var emailValidPublisher: AnyPublisher<Bool, Never> {
        $email
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.count >= 3 }
            .eraseToAnyPublisher()
    }
    
    private var isPasswordStrongPublisher: AnyPublisher<Bool, Never> {
        $password
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.count >= 6}
            .eraseToAnyPublisher()
    }
    private var arePasswordsEqualPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($password, $repeatPassword)
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .map { $0 == $1 }
            .eraseToAnyPublisher()
    }
    
    private var isPasswordEmptyPublisher: AnyPublisher<Bool, Never> {
        $password
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    private var isPasswordValidPublisher: AnyPublisher<PasswordStatus, Never> {
        Publishers.CombineLatest3(isPasswordEmptyPublisher, isPasswordStrongPublisher, arePasswordsEqualPublisher)
            .map {
                if $0 {
                    return PasswordStatus.empty
                }
                if !$1 {
                    return PasswordStatus.notStrong
                }

                if !$2 {
                    return PasswordStatus.notSame
                }

                return PasswordStatus.valid

            }
            .eraseToAnyPublisher()
            

    }
    
    
    private var isFormValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(isPasswordValidPublisher, emailValidPublisher)
            .map {
                $0 == .valid && $1
            }
            .eraseToAnyPublisher()
    }
    
    init() {
        isFormValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValid, on: self)
            .store(in: &cancellables)
        
        isPasswordValidPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .map { $0.rawValue }
            .assign(to: \.passwordErrorText, on: self)
            .store(in: &cancellables)
    }
}

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("EMAIL")) {
                        TextField("Email Address", text: $viewModel.email)
                    }
                    Section(header: Text("PASSWORD"), footer: Text(viewModel.passwordErrorText).foregroundColor(.red)) {
                        SecureField("Password", text: $viewModel.password)
                        SecureField("Re-Enter Password", text: $viewModel.repeatPassword)
                    }
                }
                
                Button(action: {}) {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.gray)
                        .frame(height: 60)
                        .overlay(Text("Login").font(.system(size: 20)).foregroundColor(.white))
                        .padding()
                        
                }.disabled(!viewModel.isValid)
               
            } .navigationBarTitle("Combine Demo")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
