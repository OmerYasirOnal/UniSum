// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Access AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text(authViewModel.user?.email ?? "User Email")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text(authViewModel.user?.university ?? "University")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    authViewModel.logout()
                }) {
                    Text(LocalizedStringKey("logout"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedStringKey("profile"))
        }
    }
}
