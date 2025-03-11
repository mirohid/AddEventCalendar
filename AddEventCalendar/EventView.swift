//
//  EventView.swift
//  AddEventCalendar
//
//  Created by MacMini6 on 11/03/25.
//

import SwiftUI
import EventKit

struct EventView: View {
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var calendarAccessStatus: EKAuthorizationStatus = .notDetermined
    
    // Event store to interact with the Calendar
    let eventStore = EKEventStore()
    
    var body: some View {
        NavigationView {
            ScrollView{
            VStack(spacing: 20) {
                // Date picker
                DatePicker("Select Date and Time", selection: $eventDate)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                // Text field for event title
                TextField("Event Title", text: $eventTitle)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Add button
                Button(action: {
                    checkCalendarAuthorizationStatus()
                }) {
                    Text("Add to Calendar")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Calendar Event")
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                // Check calendar authorization status when the view appears
                calendarAccessStatus = EKEventStore.authorizationStatus(for: .event)
            }
        }
        }
    }
    
    // Check and request calendar authorization if needed
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            addEventToCalendar()
        case .denied, .restricted:
            // User has denied access to calendar
            alertTitle = "Calendar Access Denied"
            alertMessage = "Please go to Settings and enable calendar access for this app"
            showAlert = true
        case .notDetermined:
            // Request permission
            requestCalendarAccess()
        @unknown default:
            alertTitle = "Error"
            alertMessage = "Unknown authorization status"
            showAlert = true
        }
    }
    
    // Request calendar access
    func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            // iOS 17 and newer
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.addEventToCalendar()
                    } else {
                        self.alertTitle = "Access Denied"
                        self.alertMessage = "Calendar access was denied"
                        self.showAlert = true
                    }
                }
            }
        } else {
            // iOS 16 and older
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.addEventToCalendar()
                    } else {
                        self.alertTitle = "Access Denied"
                        self.alertMessage = "Calendar access was denied"
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    func addEventToCalendar() {
        // Check if event title is empty
        if eventTitle.isEmpty {
            alertTitle = "Error"
            alertMessage = "Please enter an event title"
            showAlert = true
            return
        }
        
        // Create event
        let event = EKEvent(eventStore: self.eventStore)
        event.title = self.eventTitle
        event.startDate = self.eventDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: self.eventDate)
        
        // Get default calendar
        guard let calendar = self.eventStore.defaultCalendarForNewEvents else {
            alertTitle = "Error"
            alertMessage = "Could not access default calendar"
            showAlert = true
            return
        }
        
        event.calendar = calendar
        
        do {
            try self.eventStore.save(event, span: .thisEvent)
            self.alertTitle = "Success"
            self.alertMessage = "Event added to calendar"
            self.eventTitle = ""
        } catch {
            self.alertTitle = "Error"
            self.alertMessage = "Failed to save event: \(error.localizedDescription)"
        }
        showAlert = true
    }
}


#Preview {
    EventView()
}
